import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_model/gch_order_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_svc/gch_order_service.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_event_bus.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_interface.dart' show RestoreSource;
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_receipt_verification_service.dart';
import 'package:guichao/gch_base/gch_biz/gch_wire/gch_appprovider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// 未完成购买处理结果
class PendingPurchaseResult {
  final int totalProcessed;
  final int successCount;
  final int failedCount;
  final List<String> failedPurchaseIds;
  final Map<String, String> errors;

  const PendingPurchaseResult({
    required this.totalProcessed,
    required this.successCount,
    required this.failedCount,
    required this.failedPurchaseIds,
    required this.errors,
  });

  bool get hasErrors => failedCount > 0;
  bool get allSuccessful => failedCount == 0 && totalProcessed > 0;
}

/// 未完成购买处理服务
/// 处理应用重启后或网络恢复后的未完成购买
class PendingPurchaseHandler {
  final InAppPurchase _inAppPurchase;
  final ReceiptVerificationService _verificationService;
  final OrderService _orderService;
  
  // 处理状态
  bool _isProcessing = false;
  DateTime? _lastProcessTime;
  
  // 配置
  static const Duration _processingTimeout = Duration(minutes: 5);
  static const Duration _minProcessInterval = Duration(minutes: 1);

  PendingPurchaseHandler(
    this._inAppPurchase,
    this._verificationService,
    this._orderService,
  );

  /// 处理所有未完成的购买
  ///
  /// [source] - 恢复来源，用于区分用户触发和自动触发
  /// - userTriggered: 用户点击"恢复购买"按钮，iOS 会调用 restorePurchases()
  /// - 其他来源: 自动触发，iOS 跳过 restorePurchases()，依赖 purchaseStream
  Future<PendingPurchaseResult> processPendingPurchases({
    RestoreSource source = RestoreSource.userTriggered,
  }) async {
    // 防止重复处理
    if (_isProcessing) {
      debugPrint('购买处理正在进行中，跳过');
      return const PendingPurchaseResult(
        totalProcessed: 0,
        successCount: 0,
        failedCount: 0,
        failedPurchaseIds: [],
        errors: {},
      );
    }

    // 检查处理间隔（用户触发时跳过间隔检查）
    if (source != RestoreSource.userTriggered && _lastProcessTime != null) {
      final timeSinceLastProcess = DateTime.now().difference(_lastProcessTime!);
      if (timeSinceLastProcess < _minProcessInterval) {
        debugPrint('距离上次处理时间太短，跳过');
        return const PendingPurchaseResult(
          totalProcessed: 0,
          successCount: 0,
          failedCount: 0,
          failedPurchaseIds: [],
          errors: {},
        );
      }
    }

    _isProcessing = true;
    _lastProcessTime = DateTime.now();

    try {
      debugPrint('🔄 开始处理未完成购买 (source: $source)...');

      // 查询未完成的购买
      final pendingPurchases = await _queryPendingPurchases(source: source);

      if (pendingPurchases.isEmpty) {
        debugPrint('没有未完成的购买');
        return const PendingPurchaseResult(
          totalProcessed: 0,
          successCount: 0,
          failedCount: 0,
          failedPurchaseIds: [],
          errors: {},
        );
      }

      debugPrint('发现${pendingPurchases.length}个未完成购买');

      // 处理每个未完成的购买
      return await _processMultiplePurchases(pendingPurchases);
    } catch (e, stackTrace) {
      debugPrint('处理未完成购买异常: $e\n$stackTrace');
      return PendingPurchaseResult(
        totalProcessed: 0,
        successCount: 0,
        failedCount: 1,
        failedPurchaseIds: ['unknown'],
        errors: {'unknown': e.toString()},
      );
    } finally {
      _isProcessing = false;
    }
  }

  /// 查询未完成的购买
  ///
  /// [source] - 恢复来源，决定 iOS 是否调用 restorePurchases()
  Future<List<PurchaseDetails>> _queryPendingPurchases({
    required RestoreSource source,
  }) async {
    final List<PurchaseDetails> pendingPurchases = [];

    try {
      // iOS: 根据来源决定是否调用 restorePurchases()
      if (source == RestoreSource.userTriggered) {
        // 用户主动点击"恢复购买" → 调用 restorePurchases()
        debugPrint('🍎 [iOS] 用户触发恢复购买，调用 restorePurchases()');
        await _inAppPurchase.restorePurchases();
        // 等待 purchaseStream 接收事件
        await Future.delayed(const Duration(seconds: 3));
      } else {
        // 自动触发 → 跳过 restorePurchases()（避免事件洪泛和 Apple ID 弹窗）
        debugPrint('🍎 [iOS] 自动检查模式 ($source)，跳过 restorePurchases()');
      }
      // iOS 的未完成购买会通过 purchaseStream 自动处理
    } catch (e) {
      debugPrint('查询未完成购买异常: $e');
    }

    return pendingPurchases;
  }

  /// 处理多个购买
  Future<PendingPurchaseResult> _processMultiplePurchases(
    List<PurchaseDetails> purchases,
  ) async {
    int successCount = 0;
    int failedCount = 0;
    final List<String> failedPurchaseIds = [];
    final Map<String, String> errors = {};

    // 使用批处理方式限制并发
    const batchSize = 3;
    for (var i = 0; i < purchases.length; i += batchSize) {
      final batch = purchases.skip(i).take(batchSize);
      final futures = batch.map((purchase) async {
        try {
          final success = await _processSinglePurchase(purchase);
          if (success) {
            successCount++;
          } else {
            failedCount++;
            final purchaseId = purchase.purchaseID ?? purchase.productID;
            failedPurchaseIds.add(purchaseId);
            errors[purchaseId] = '处理失败';
          }
        } catch (e) {
          failedCount++;
          final purchaseId = purchase.purchaseID ?? purchase.productID;
          failedPurchaseIds.add(purchaseId);
          errors[purchaseId] = e.toString();
        }
      });
      await Future.wait(futures);
    }

    return PendingPurchaseResult(
      totalProcessed: purchases.length,
      successCount: successCount,
      failedCount: failedCount,
      failedPurchaseIds: failedPurchaseIds,
      errors: errors,
    );
  }

  /// 处理单个购买
  Future<bool> _processSinglePurchase(PurchaseDetails purchase) async {
    final purchaseId = purchase.purchaseID ?? purchase.productID;
    
    try {
      debugPrint('处理购买: $purchaseId');
      
      // 1. 验证购买收据
      final verificationResult = await _verificationService.verifyInAppPurchase(
        purchase,
        orderId: purchaseId,
      ).timeout(_processingTimeout);
      
      if (!verificationResult.isValid) {
        debugPrint('购买验证失败: ${verificationResult.errorMessage}');
        
        // 验证失败的购买也要完成，避免无限重试
        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
        
        // 发送验证失败事件
        PaymentEventBus.instance.publish(PaymentEvent(
          PaymentEventType.failed,
          orderId: purchaseId,
          data: {'purchase': purchase, 'verification_result': verificationResult},
          error: verificationResult.errorMessage,
        ));
        
        return false;
      }

      // 2. 更新本地订单状态
      await _updateLocalOrder(purchase, verificationResult);

      // 3. 解锁相应的服务或内容
      await _unlockPurchasedContent(purchase);

      // 4. 完成购买确认
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
        debugPrint('购买确认完成: $purchaseId');
      }

      // 5. 发送成功事件
      PaymentEventBus.instance.publish(PaymentEvent(
        PaymentEventType.completed,
        orderId: purchaseId,
        data: {
          'purchase': purchase,
          'verification_result': verificationResult,
          'processed_time': DateTime.now().toIso8601String(),
        },
      ));

      debugPrint('购买处理成功: $purchaseId');
      return true;
    } catch (e, stackTrace) {
      debugPrint('处理购买$purchaseId失败: $e\n$stackTrace');
      
      // 即使处理失败，也要完成购买确认，避免无限重试
      try {
        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
      } catch (completeError) {
        debugPrint('完成购买确认失败: $completeError');
      }
      
      // 发送失败事件
      PaymentEventBus.instance.publish(PaymentEvent(
        PaymentEventType.failed,
        orderId: purchaseId,
        data: {'purchase': purchase},
        error: e,
        stackTrace: stackTrace,
      ));
      
      return false;
    }
  }

  /// 更新本地订单状态
  Future<void> _updateLocalOrder(
    PurchaseDetails purchase,
    ReceiptVerificationResult verificationResult,
  ) async {
    try {
      final purchaseId = purchase.purchaseID ?? purchase.productID;
      
      // 查找对应的本地订单
      final order = await _orderService.getOrderById(purchaseId);
      
      if (order != null) {
        // 更新订单状态
        await _orderService.updatePayStatus(purchaseId, PayStatus.paid);
        
        // 更新交易ID
        if (purchase.purchaseID != null) {
          // 这里可能需要额外的方法来更新transactionId
          debugPrint('更新交易ID: ${purchase.purchaseID}');
        }
        
        debugPrint('本地订单状态已更新: $purchaseId');
      } else {
        // 如果没有找到对应订单，创建一个新的
        await _createOrderFromPurchase(purchase, verificationResult);
      }
    } catch (e) {
      debugPrint('更新本地订单失败: $e');
      // 不抛出异常，避免影响主流程
    }
  }

  /// 从购买信息创建订单
  Future<void> _createOrderFromPurchase(
    PurchaseDetails purchase,
    ReceiptVerificationResult verificationResult,
  ) async {
    try {
      // 这里需要根据实际的Order模型来创建
      // 由于缺少一些必要信息，这只是一个示例
      debugPrint('需要创建新订单: ${purchase.purchaseID}');
      
      // final order = Order(
      //   ordernum: purchase.purchaseID ?? purchase.productID,
      //   userid: 'current_user_id', // 需要从用户服务获取
      //   productid: _getProductIdFromProductName(purchase.productID),
      //   productname: purchase.productID,
      //   total: 0.0, // 需要从产品信息获取
      //   currency: 'USD', // 需要从产品信息获取
      //   paystatus: PayStatus.paid.value,
      //   status: OrderStatus.completed.value,
      //   transactionid: purchase.purchaseID,
      //   createat: purchaseTime,
      //   updateat: now,
      //   payat: purchaseTime,
      //   // ... 其他必要字段
      // );
      // 
      // await _orderService.createOrder(order);
    } catch (e) {
      debugPrint('创建订单失败: $e');
    }
  }

  /// 解锁购买的内容或服务
  Future<void> _unlockPurchasedContent(PurchaseDetails purchase) async {
    try {
      // 根据产品ID解锁相应的功能
      switch (purchase.productID) {
        case 'premium_subscription':
          await _unlockPremiumFeatures();
          break;
        case 'remove_ads':
          await _removeAds();
          break;
        case 'extra_storage':
          await _addExtraStorage();
          break;
        default:
          debugPrint('未知产品ID: ${purchase.productID}');
      }
      
      debugPrint('内容解锁完成: ${purchase.productID}');
    } catch (e) {
      debugPrint('解锁内容失败: $e');
      // 不抛出异常，避免影响主流程
    }
  }

  /// 解锁高级功能
  Future<void> _unlockPremiumFeatures() async {
    // 实现高级功能解锁逻辑
    debugPrint('解锁高级功能');
  }

  /// 移除广告
  Future<void> _removeAds() async {
    // 实现移除广告逻辑
    debugPrint('移除广告');
  }

  /// 添加额外存储
  Future<void> _addExtraStorage() async {
    // 实现添加存储逻辑
    debugPrint('添加额外存储');
  }

  /// 启动定期检查（可选）
  /// 每隔一段时间检查未完成购买
  Timer? _periodicTimer;

  void startPeriodicCheck({Duration interval = const Duration(hours: 1)}) {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(interval, (_) async {
      debugPrint('定期检查未完成购买');
      await processPendingPurchases(source: RestoreSource.periodicCheck);
    });
  }

  void stopPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// 手动触发检查（用于网络恢复后）
  Future<void> onNetworkRestored() async {
    debugPrint('网络恢复，检查未完成购买');
    await processPendingPurchases(source: RestoreSource.networkRestore);
  }

  /// 清理资源
  void dispose() {
    stopPeriodicCheck();
    _isProcessing = false;
  }
}

/// Riverpod Provider
final pendingPurchaseHandlerProvider = Provider<PendingPurchaseHandler>((ref) {
  final verificationService = ref.read(receiptVerificationServiceProvider);
  final orderService = ref.read(AppProvider.orders.service);
  
  return PendingPurchaseHandler(
    InAppPurchase.instance,
    verificationService,
    orderService,
  );
});