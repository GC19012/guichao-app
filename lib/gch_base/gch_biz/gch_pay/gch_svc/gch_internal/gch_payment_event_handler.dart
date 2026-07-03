import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_event_bus.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_svc/gch_order_service.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_model/gch_order_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_wire/gch_appprovider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 支付事件处理服务
/// 职责：
/// 1. 监听支付事件
/// 2. 根据事件类型更新订单状态
/// 3. 处理事件异常
class PaymentEventHandler implements Disposable {
  final Ref? ref;
  StreamSubscription? _eventSub;

  PaymentEventHandler({this.ref});

  /// 开始监听事件
  void startListening() {
    if (_eventSub != null) {
      debugPrint('⚠️ 事件监听已启动，跳过重复启动');
      return;
    }

    _eventSub = PaymentEventBus.instance.subscribe(
      _handleEvent,
      onError: (error, stackTrace) {
        debugPrint('❌ 支付事件处理错误: $error');
        debugPrint('Stack trace: $stackTrace');
      },
    );

    debugPrint('✅ 支付事件监听已启动');
  }

  /// 停止监听事件
  void stopListening() {
    _eventSub?.cancel();
    _eventSub = null;
    debugPrint('✅ 支付事件监听已停止');
  }

  /// 处理支付事件
  Future<void> _handleEvent(PaymentEvent event) async {
    debugPrint('📨 收到支付事件: ${event.type}');

    if (ref == null) {
      debugPrint('⚠️ Ref为空，无法处理事件');
      return;
    }

    final orderService = ref!.read(orderServiceProvider);

    try {
      switch (event.type) {
        case PaymentEventType.completed:
          await _handleCompleted(orderService, event);
          break;

        case PaymentEventType.failed:
          await _handleFailed(orderService, event);
          break;

        case PaymentEventType.cancelled:
          await _handleCancelled(orderService, event);
          break;

        case PaymentEventType.processing:
          await _handleProcessing(orderService, event);
        case PaymentEventType.custom:
          await _handleCustomEvent(orderService, event);
          break;

        default:
          debugPrint('ℹ️ 未处理的事件类型: ${event.type}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 处理支付事件失败: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// 处理支付完成事件
  Future<void> _handleCompleted(OrderService orderService, PaymentEvent event) async {
    if (event.orderId == null) {
      debugPrint('⚠️ 支付完成事件缺少orderId');
      return;
    }

    try {
      await orderService.updatePayStatus(event.orderId!, PayStatus.paid);
      debugPrint('✅ 订单 ${event.orderId} 状态已更新为已支付');
    } catch (e) {
      debugPrint('❌ 更新订单状态失败: $e');
    }
  }

  /// 处理支付失败事件
  Future<void> _handleFailed(OrderService orderService, PaymentEvent event) async {
    if (event.orderId == null) {
      debugPrint('⚠️ 支付失败事件缺少orderId');
      return;
    }

    try {
      await orderService.updatePayStatus(event.orderId!, PayStatus.cancelled);
      debugPrint('✅ 订单 ${event.orderId} 状态已更新为已取消（支付失败）');
    } catch (e) {
      debugPrint('❌ 更新订单状态失败: $e');
    }
  }

  /// 处理支付取消事件
  Future<void> _handleCancelled(OrderService orderService, PaymentEvent event) async {
    if (event.orderId == null) {
      debugPrint('⚠️ 支付取消事件缺少orderId');
      return;
    }

    try {
      await orderService.updatePayStatus(event.orderId!, PayStatus.cancelled);
      debugPrint('✅ 订单 ${event.orderId} 状态已更新为已取消');
    } catch (e) {
      debugPrint('❌ 更新订单状态失败: $e');
    }
  }

  /// 处理支付处理中事件
  Future<void> _handleProcessing(OrderService orderService, PaymentEvent event) async {
    if (event.orderId == null) {
      debugPrint('⚠️ 支付待处理事件缺少orderId');
      return;
    }

    try {
      // 待处理状态可以根据业务需求决定是否更新订单
      debugPrint('ℹ️ 订单 ${event.orderId} 支付待处理');
    } catch (e) {
      debugPrint('❌ 处理待处理事件失败: $e');
    }
  }

  /// 处理自定义事件（already_subscribed 等由 PaymentService 处理）
  Future<void> _handleCustomEvent(OrderService orderService, PaymentEvent event) async {
    final action = event.data?['action']?.toString();
    debugPrint('ℹ️ 自定义事件: $action (由 PaymentService 处理)');
  }

  @override
  void dispose() {
    stopListening();
    debugPrint('✅ PaymentEventHandler已销毁');
  }
}
