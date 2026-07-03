import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_model/gch_order_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_svc/gch_order_service.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_event_bus.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_manager.dart';
import 'package:guichao/gch_base/gch_biz/gch_wire/gch_appprovider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 订单恢复处理结果
class OrderRecoveryResult {
  final int totalProcessed;
  final int successCount;
  final int failedCount;
  final List<String> failedOrderIds;
  final Map<String, String> errors;

  const OrderRecoveryResult({
    required this.totalProcessed,
    required this.successCount,
    required this.failedCount,
    required this.failedOrderIds,
    required this.errors,
  });

  bool get hasErrors => failedCount > 0;
  bool get allSuccessful => failedCount == 0 && totalProcessed > 0;
}

/// 通用订单恢复服务 - 处理所有支付方式的未完成订单
class OrderRecoveryService {
  final OrderService _orderService;
  final PaymentManager _paymentManager;
  
  bool _isProcessing = false;
  DateTime? _lastProcessTime;
  
  static const Duration _processingTimeout = Duration(minutes: 5);
  static const Duration _minProcessInterval = Duration(minutes: 1);

  OrderRecoveryService(this._orderService, this._paymentManager);

  /// 处理所有未完成的订单
  Future<OrderRecoveryResult> processIncompleteOrders() async {
    if (_isProcessing) {
      debugPrint('订单恢复正在进行中，跳过');
      return const OrderRecoveryResult(
        totalProcessed: 0, successCount: 0, failedCount: 0,
        failedOrderIds: [], errors: {},
      );
    }

    if (_lastProcessTime != null) {
      final timeSinceLastProcess = DateTime.now().difference(_lastProcessTime!);
      if (timeSinceLastProcess < _minProcessInterval) {
        debugPrint('距离上次处理时间太短，跳过');
        return const OrderRecoveryResult(
          totalProcessed: 0, successCount: 0, failedCount: 0,
          failedOrderIds: [], errors: {},
        );
      }
    }

    _isProcessing = true;
    _lastProcessTime = DateTime.now();

    try {
      debugPrint('开始处理未完成订单...');
      
      final incompleteOrders = await _queryIncompleteOrders();
      
      if (incompleteOrders.isEmpty) {
        debugPrint('没有未完成的订单');
        return const OrderRecoveryResult(
          totalProcessed: 0, successCount: 0, failedCount: 0,
          failedOrderIds: [], errors: {},
        );
      }

      debugPrint('发现${incompleteOrders.length}个未完成订单');
      return await _processMultipleOrders(incompleteOrders);
    } catch (e, stackTrace) {
      debugPrint('处理未完成订单异常: $e\n$stackTrace');
      return OrderRecoveryResult(
        totalProcessed: 0, successCount: 0, failedCount: 1,
        failedOrderIds: ['unknown'], errors: {'unknown': e.toString()},
      );
    } finally {
      _isProcessing = false;
    }
  }

  /// 查询未完成的订单
  Future<List<OrderEntry>> _queryIncompleteOrders() async {
    final List<OrderEntry> incompleteOrders = [];

    try {
      // 1. 查询支付中的订单
      final processingOrders = await _orderService.getOrdersByOrderStatus(OrderStatus.processing);
      incompleteOrders.addAll(processingOrders.where(_shouldProcessOrder));

      // 2. 查询等待支付的订单
      final pendingOrders = await _orderService.getOrdersByOrderStatus(OrderStatus.pending);
      incompleteOrders.addAll(pendingOrders.where(_shouldProcessOrder));

      // 3. 查询最近24小时内未支付的订单
      final unpaidOrders = await _orderService.getOrdersByPayStatus(PayStatus.unpaid);
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
      incompleteOrders.addAll(unpaidOrders.where((order) =>
          _shouldProcessOrder(order) && 
          !incompleteOrders.contains(order) &&
          order.createAt.isAfter(cutoffTime)));

      debugPrint('找到${incompleteOrders.length}个需要恢复的订单');
    } catch (e) {
      debugPrint('查询未完成订单异常: $e');
    }

    return incompleteOrders;
  }

  /// 判断订单是否需要处理
  bool _shouldProcessOrder(OrderEntry order) {
    // 只处理未完成且未支付的订单
    if (order.status == OrderStatus.completed.value || 
        order.status == OrderStatus.failed.value ||
        order.status == OrderStatus.expired.value ||
        order.payStatus == PayStatus.paid.value) {
      return false;
    }

    // 检查订单是否过期
    if (order.expireAt != null && order.expireAt!.isBefore(DateTime.now())) {
      return false;
    }

    return true;
  }

  /// 处理多个订单
  Future<OrderRecoveryResult> _processMultipleOrders(List<OrderEntry> orders) async {
    int successCount = 0;
    int failedCount = 0;
    final List<String> failedOrderIds = [];
    final Map<String, String> errors = {};

    const batchSize = 3;
    for (var i = 0; i < orders.length; i += batchSize) {
      final batch = orders.skip(i).take(batchSize);
      final futures = batch.map((order) async {
        try {
          final success = await _processSingleOrder(order);
          if (success) {
            successCount++;
          } else {
            failedCount++;
            failedOrderIds.add(order.orderNum);
            errors[order.orderNum] = '恢复失败';
          }
        } catch (e) {
          failedCount++;
          failedOrderIds.add(order.orderNum);
          errors[order.orderNum] = e.toString();
        }
      });
      await Future.wait(futures);
    }

    return OrderRecoveryResult(
      totalProcessed: orders.length,
      successCount: successCount,
      failedCount: failedCount,
      failedOrderIds: failedOrderIds,
      errors: errors,
    );
  }

  /// 处理单个订单
  Future<bool> _processSingleOrder(OrderEntry order) async {
    final orderNum = order.orderNum;
    
    try {
      debugPrint('恢复订单: $orderNum (支付方式: ${order.payProvider})');

      // 获取支付提供商
      final paymentProvider = await _getPaymentProviderForOrder(order);
      if (paymentProvider == null) {
        debugPrint('订单 $orderNum 的支付方式不可用');
        return false;
      }

      // 查询支付状态
      final queryResult = await paymentProvider.query(
        _OrderQueryParams(orderId: orderNum),
      ).timeout(_processingTimeout);

      // 根据查询结果更新订单状态
      return await _updateOrderBasedOnQueryResult(order, queryResult);

    } catch (e, stackTrace) {
      debugPrint('处理订单$orderNum失败: $e\n$stackTrace');
      
      PaymentEventBus.instance.publish(PaymentEvent(
        PaymentEventType.failed,
        orderId: orderNum,
        data: {'order': order},
        error: e,
        stackTrace: stackTrace,
      ));
      
      return false;
    }
  }

  /// 根据订单获取对应的支付提供商
  Future<PaymentProvider?> _getPaymentProviderForOrder(OrderEntry order) async {
    try {
      final payProviderId = order.payProvider;
      if (payProviderId == null) {
        debugPrint('订单 ${order.orderNum} 没有指定支付方式');
        return null;
      }

      // 仅支持 App 内购（IAP），其余 payProviderId 视为未知、放弃恢复
      String? payMethodCode;
      switch (payProviderId) {
        case 5:
          payMethodCode = 'apple_pay';
        default:
          payMethodCode = null;
      }

      if (payMethodCode == null) {
        debugPrint('订单 ${order.orderNum} 的支付提供商ID $payProviderId 未知');
        return null;
      }

      _paymentManager.setPaymentMethodByCode(payMethodCode);
      return _paymentManager.currentProvider;
    } catch (e) {
      debugPrint('获取订单 ${order.orderNum} 的支付提供商失败: $e');
      return null;
    }
  }

  /// 根据查询结果更新订单状态
  Future<bool> _updateOrderBasedOnQueryResult(OrderEntry order, IResponse queryResult) async {
    final orderNum = order.orderNum;

    try {
      switch (queryResult.result) {
        case PaymentResult.success:
          await _orderService.updatePayStatus(orderNum, PayStatus.paid);
          await _orderService.updateOrderStatus(orderNum, OrderStatus.completed);
          
          PaymentEventBus.instance.publish(PaymentEvent(
            PaymentEventType.completed,
            orderId: orderNum,
            data: {
              'order': order,
              'query_result': queryResult,
              'recovered_time': DateTime.now().toIso8601String(),
            },
          ));
          
          debugPrint('订单恢复成功: $orderNum');
          return true;

        case PaymentResult.failed:
        case PaymentResult.cancelled:
          await _orderService.updateOrderStatus(orderNum, OrderStatus.failed);
          
          PaymentEventBus.instance.publish(PaymentEvent(
            PaymentEventType.failed,
            orderId: orderNum,
            data: {'order': order, 'query_result': queryResult},
            error: queryResult.message,
          ));
          
          debugPrint('订单已失败: $orderNum');
          return true;

        case PaymentResult.pending:
        case PaymentResult.processing:
          debugPrint('订单仍在处理中: $orderNum');
          return true;

        default:
          debugPrint('订单 $orderNum 查询结果未知: ${queryResult.result}');
          return false;
      }
    } catch (e) {
      debugPrint('更新订单状态失败: $e');
      return false;
    }
  }

  Timer? _periodicTimer;
  
  void startPeriodicCheck({Duration interval = const Duration(hours: 1)}) {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(interval, (_) async {
      debugPrint('定期检查未完成订单');
      await processIncompleteOrders();
    });
  }

  void stopPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  Future<void> onNetworkRestored() async {
    debugPrint('网络恢复，检查未完成订单');
    await processIncompleteOrders();
  }

  void dispose() {
    stopPeriodicCheck();
    _isProcessing = false;
  }
}

/// 订单查询参数
class _OrderQueryParams implements IParams<Map<String, dynamic>> {
  final String orderId;

  _OrderQueryParams({required this.orderId});

  @override
  Map<String, dynamic> toMap() => {'orderId': orderId};
}

/// Riverpod Provider
final orderRecoveryServiceProvider = Provider<OrderRecoveryService>((ref) {
  // 明确使用 AppProvider 中的 orderService，避免命名冲突
  final orderService = ref.read(AppProvider.orders.service);
  // 使用 PaymentManager 单例，而不是创建新实例
  // 这确保订单恢复服务使用与整个应用相同的支付配置
  final paymentManager = ref.read(AppProvider.payment.manager);
  
  return OrderRecoveryService(orderService, paymentManager);
});
