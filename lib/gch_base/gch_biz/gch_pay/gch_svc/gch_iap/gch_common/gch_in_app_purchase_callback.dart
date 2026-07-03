// 应用内购买回调处理
// 从 google_apple_pay_provider.dart 提取，保持所有逻辑不变

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_event_bus.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_iap/gch_common/gch_purchase_error_handler.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// 应用内购买回调实现
class InAppPurchaseCallback extends StreamCallback<List<PurchaseDetails>> {
  final StreamController<IResponse> _controller =
      StreamController<IResponse>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _sub;
  StreamSubscription<IResponse>? _eventBusSub;
  bool _initialized = false;

  /// ✅ 是否已销毁，用于在 Future.delayed 回调中检查，防止 Activity 销毁后继续执行
  bool _disposed = false;

  /// 已处理的购买ID集合（防止重复触发验证）
  final Set<String> _processedPurchaseIds = {};

  /// 已验证的购买ID集合（防止重复验证成功的订单）
  final Set<String> _verifiedPurchaseIds = {};

  /// 清理过期的购买ID记录（保留最近1小时的记录）
  final Map<String, DateTime> _purchaseIdTimestamps = {};
  static const Duration _purchaseIdExpiry = Duration(hours: 1);

  /// 已恢复的产品ID集合（防止同一产品重复验证）
  final Set<String> _restoredProductIds = {};

  /// 清除已恢复产品记录
  void clearRestoredProducts() {
    _restoredProductIds.clear();
    debugPrint('🔄 已清除恢复购买产品记录，允许重新验证');
  }

  /// 清除指定产品的恢复记录（iOS 专用）
  void resetProductForNewPurchase(String productId) {
    _restoredProductIds.remove(productId);
    debugPrint('🔄 已重置产品 $productId 的恢复记录');
  }

  /// 检查并清理过期的购买ID
  void _cleanupExpiredPurchaseIds() {
    final now = DateTime.now();
    _purchaseIdTimestamps.removeWhere((id, timestamp) {
      final expired = now.difference(timestamp) > _purchaseIdExpiry;
      if (expired) {
        _processedPurchaseIds.remove(id);
        _verifiedPurchaseIds.remove(id);
      }
      return expired;
    });
  }

  /// 标记购买ID为已处理
  bool _markAsProcessed(String? purchaseId) {
    if (purchaseId == null || purchaseId.isEmpty) return false;
    _cleanupExpiredPurchaseIds();
    if (_processedPurchaseIds.contains(purchaseId)) {
      debugPrint('🔒 购买ID已处理过，跳过重复验证: $purchaseId');
      return false;
    }
    _processedPurchaseIds.add(purchaseId);
    _purchaseIdTimestamps[purchaseId] = DateTime.now();
    return true;
  }

  /// 标记购买ID为已验证成功
  void markAsVerified(String? purchaseId) {
    if (purchaseId == null || purchaseId.isEmpty) return;
    _verifiedPurchaseIds.add(purchaseId);
    debugPrint('✅ 购买ID已标记为验证成功: $purchaseId');
  }

  /// 检查购买ID是否已验证成功
  bool isVerified(String? purchaseId) {
    if (purchaseId == null || purchaseId.isEmpty) return false;
    return _verifiedPurchaseIds.contains(purchaseId);
  }

  /// 统一的去重检查
  bool shouldProcess(String? purchaseId) {
    if (purchaseId == null || purchaseId.isEmpty) return false;
    if (isVerified(purchaseId)) return false;
    return _markAsProcessed(purchaseId);
  }

  @override
  Stream<List<PurchaseDetails>> get platformStream {
    try {
      return InAppPurchase.instance.purchaseStream;
    } catch (e) {
      debugPrint('⚠️ 无法访问 InAppPurchase.instance.purchaseStream: $e');
      return const Stream<List<PurchaseDetails>>.empty();
    }
  }

  @override
  IResponse convert(dynamic event) {
    PurchaseDetails purchaseDetails;

    if (event is PurchaseDetails) {
      purchaseDetails = event;
    } else if (event is List<PurchaseDetails>) {
      if (event.isEmpty) {
        return const PaymentResponse(
          result: PaymentResult.failed,
          message: '没有收到购买信息',
        );
      }
      purchaseDetails = event.first;
    } else {
      return PaymentResponse(
        result: PaymentResult.failed,
        message: '收到未知类型的应用内购买回调',
        data: {'rawData': event.toString()},
      );
    }

    final Map<String, dynamic> data = {
      'productId': purchaseDetails.productID,
      'purchaseId': purchaseDetails.purchaseID,
      'orderId': purchaseDetails.purchaseID,
      'transactionDate': purchaseDetails.transactionDate,
      'verificationData': {
        'source': purchaseDetails.verificationData.source,
        'localVerificationData':
            purchaseDetails.verificationData.localVerificationData,
        'serverVerificationData':
            purchaseDetails.verificationData.serverVerificationData,
      },
    };

    switch (purchaseDetails.status) {
      case PurchaseStatus.pending:
        return PaymentResponse(
          result: PaymentResult.pending,
          message: '购买处理中',
          data: data,
        );
      case PurchaseStatus.purchased:
        return PaymentResponse(
          result: PaymentResult.success,
          message: '购买成功',
          data: data,
          transactionId: purchaseDetails.purchaseID,
        );
      case PurchaseStatus.error:
        return _handleErrorStatus(purchaseDetails, data);
      case PurchaseStatus.restored:
        return PaymentResponse(
          result: PaymentResult.success,
          message: '购买已恢复',
          data: data,
          transactionId: purchaseDetails.purchaseID,
        );
      case PurchaseStatus.canceled:
        return PaymentResponse(
          result: PaymentResult.cancelled,
          message: '购买已取消',
          data: data,
        );
    }
  }

  IResponse _handleErrorStatus(PurchaseDetails purchaseDetails, Map<String, dynamic> data) {
    final errorMessage = purchaseDetails.error?.message ?? '';
    final errorCode = purchaseDetails.error?.code ?? '';
    final errorDetails = purchaseDetails.error?.details?.toString() ?? '';
    debugPrint('📌 PurchaseStatus.error - code: $errorCode, message: $errorMessage, details: $errorDetails');

    final combinedError = '$errorCode $errorMessage $errorDetails'.toLowerCase();

    // 检查订阅变更被阻止
    if (combinedError.contains('cannot change') ||
        combinedError.contains('无法更改') ||
        combinedError.contains('subscription change') ||
        combinedError.contains('change subscription') ||
        combinedError.contains('upgrade') ||
        combinedError.contains('downgrade') ||
        combinedError.contains('订阅方案') ||
        errorCode == '7' ||
        errorCode.toLowerCase() == 'billingresponse.7' ||
        combinedError.contains('billingresponse.7') ||
        combinedError.contains('developererror') ||
        combinedError.contains('developer_error') ||
        combinedError.contains('billingresponse.developererror') ||
        errorCode == '5' ||
        errorCode.toLowerCase() == 'billingresponse.5' ||
        combinedError.contains('item already owned') ||
        combinedError.contains('you already own')) {
      debugPrint('📌 检测到订阅变更被阻止，返回 subscriptionChangeBlocked');
      return PaymentResponse.subscriptionChangeBlocked(
        message: '订阅变更被阻止',
        data: data,
      );
    }

    // 检查已订阅状态
    if (combinedError.contains('itemalreadyowned') ||
        combinedError.contains('item_already_owned') ||
        combinedError.contains('already_owned') ||
        combinedError.contains('已订阅') ||
        combinedError.contains('已购买')) {
      debugPrint('📌 检测到已订阅状态，返回 alreadyOwned');
      return PaymentResponse.alreadyOwned(
        message: '您已订阅此商品',
        data: data,
      );
    }

    // 检查网络错误
    if (isNetworkError(combinedError)) {
      debugPrint('📌 检测到网络错误，返回 networkError');
      return PaymentResponse.networkError(
        message: '网络连接失败，无法连接应用商店服务',
        data: data,
      );
    }

    // 检查服务不可用
    if (isServiceUnavailableError(combinedError)) {
      debugPrint('📌 检测到服务不可用，返回 serviceUnavailable');
      return PaymentResponse.serviceUnavailable(
        message: '应用商店服务不可用，请稍后重试',
        data: data,
      );
    }

    // 检查服务超时
    if (isTimeoutError(combinedError)) {
      debugPrint('📌 检测到服务超时，返回 serviceTimeout');
      return PaymentResponse.serviceTimeout(
        message: '连接应用商店服务超时，请稍后重试',
        data: data,
      );
    }

    // 检查服务断开
    if (isServiceDisconnectedError(combinedError)) {
      debugPrint('📌 检测到服务断开，返回 serviceUnavailable');
      return PaymentResponse.serviceUnavailable(
        message: '应用商店服务连接已断开，请重试',
        data: data,
      );
    }

    // 检查用户取消（使用通用错误处理函数，已包含 iOS storekit2_purchase_cancelled）
    if (isUserCancelledError(combinedError)) {
      debugPrint('📌 检测到用户取消购买，返回 cancelled');
      return PaymentResponse.cancelled(
        message: '用户取消了购买',
        data: data,
      );
    }

    return PaymentResponse(
      result: PaymentResult.failed,
      message: '购买失败: ${errorMessage.isNotEmpty ? errorMessage : "未知错误"}',
      data: data,
    );
  }

  @override
  Stream<IResponse> onResult() => _controller.stream;

  @override
  void initialize() {
    if (_initialized) return;

    debugPrint('🆕 InAppPurchaseCallback 初始化，实例: ${identityHashCode(this)}');

    _sub = platformStream.listen((purchaseDetailsList) async {
      debugPrint('📥 [StoreKit] 收到购买流事件，共 ${purchaseDetailsList.length} 条:');
      for (int i = 0; i < purchaseDetailsList.length; i++) {
        final p = purchaseDetailsList[i];
        debugPrint('   [$i] productId=${p.productID}, status=${p.status}, purchaseId=${p.purchaseID}');
      }

      final seenPurchaseIds = <String>{};

      for (final purchaseDetails in purchaseDetailsList) {
        final purchaseId = purchaseDetails.purchaseID;

        if (purchaseId != null && seenPurchaseIds.contains(purchaseId)) {
          debugPrint('🔒 跳过列表内重复的购买: $purchaseId');
          continue;
        }
        if (purchaseId != null) {
          seenPurchaseIds.add(purchaseId);
        }

        if (purchaseDetails.status == PurchaseStatus.purchased &&
            purchaseDetails.pendingCompletePurchase) {
          debugPrint('⚠️ 发现未确认的购买订单: ${purchaseDetails.productID}');
          debugPrint('   订单ID: $purchaseId');
          debugPrint('   需要验证并完成此订单');
        }

        if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          if (!shouldProcess(purchaseId)) {
            // 🍎 iOS 升级/降级场景特殊处理
            // 当用户从产品A升级到产品B时，StoreKit可能只发送A的restored事件
            // 此时需要检查是否有待处理的购买上下文，且productId不匹配
            final pendingContext = getPendingContext();
            final pendingProductId = pendingContext?['productId']?.toString();
            final isUpgradeScenario = Platform.isIOS &&
                purchaseDetails.status == PurchaseStatus.restored &&
                pendingContext != null &&
                pendingProductId != null &&
                pendingProductId.isNotEmpty &&
                pendingProductId != purchaseDetails.productID;

            if (isUpgradeScenario) {
              debugPrint('🔄 [iOS升级检测] 检测到升级场景:');
              debugPrint('   待购买产品: $pendingProductId');
              debugPrint('   收到的事件产品: ${purchaseDetails.productID}');
              // 不跳过，继续走升级处理流程
            } else {
              debugPrint('🔒 跳过已处理的购买事件: $purchaseId');
              if (Platform.isIOS) {
                _finishTransaction(purchaseDetails);
              }
              continue;
            }
          }
        }

        final resp = convert(purchaseDetails);
        _controller.add(resp);
        PaymentEventBus.instance.publish(_toPaymentEvent(resp));

        debugPrint('收到购买事件: ${purchaseDetails.productID}, 状态: ${purchaseDetails.status}, purchaseID: $purchaseId');

        if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          await _handlePurchasedOrRestored(purchaseDetails, purchaseId);
        }
      }
    });
    debugPrint('应用内购买回调监听器已初始化');
    _initialized = true;
  }

  Future<void> _handlePurchasedOrRestored(PurchaseDetails purchaseDetails, String? purchaseId) async {
    final isRestored = purchaseDetails.status == PurchaseStatus.restored;
    final productId = purchaseDetails.productID;

    // 先获取 pendingContext，用于判断是否是升级场景
    final pendingContext = getPendingContext();
    final pendingProductId = pendingContext?['productId']?.toString();

    // 🍎 iOS 升级场景检测：pendingProductId 与 eventProductId 不匹配
    final isUpgradeScenario = Platform.isIOS &&
        isRestored &&
        pendingContext != null &&
        pendingProductId != null &&
        pendingProductId.isNotEmpty &&
        pendingProductId != productId;

    // iOS restored 去重（升级场景除外）
    if (isRestored && Platform.isIOS && !isUpgradeScenario) {
      if (_restoredProductIds.contains(productId)) {
        debugPrint('🔒 [iOS] 跳过已恢复产品的历史交易: $productId, purchaseID: $purchaseId');
        _finishTransaction(purchaseDetails);
        return;
      }
      _restoredProductIds.add(productId);
      debugPrint('📌 [iOS] 恢复产品首笔交易: $productId, purchaseID: $purchaseId');
    } else if (isUpgradeScenario) {
      debugPrint('🔄 [iOS升级] 升级场景，跳过 restored 去重检查: pending=$pendingProductId, event=$productId');
    }
    final orderNumFromContext = pendingContext?['orderNum']?.toString();
    debugPrint('📖 读取支付上下文: hasContext: ${pendingContext != null}, orderNum: $orderNumFromContext');

    // iOS 专用逻辑
    String? transactionReason;
    if (Platform.isIOS) {
      try {
        final localData = purchaseDetails.verificationData.localVerificationData;
        if (localData.isNotEmpty) {
          final decoded = json.decode(localData) as Map<String, dynamic>;
          transactionReason = decoded['transactionReason']?.toString();
          debugPrint('📋 [iOS] 交易类型: transactionReason=$transactionReason');
        }
      } catch (e) {
        debugPrint('⚠️ [iOS] 解析 localVerificationData 失败: $e');
      }

      // 后台自动续费处理
      final isBackgroundRenewal = transactionReason == 'RENEWAL' &&
          (orderNumFromContext == null || orderNumFromContext.isEmpty);
      if (isBackgroundRenewal) {
        debugPrint('🔄 [iOS] 后台自动续费交易，完成交易但跳过验证: $productId, purchaseID: $purchaseId');
        _finishTransaction(purchaseDetails);
        return;
      }
    }

    // 检测"购买时发现已订阅"
    // pendingProductId 已在上方定义
    final productIdMatches = pendingProductId == null || pendingProductId == productId;
    final restoredDuringPurchase = Platform.isIOS &&
        isRestored &&
        pendingContext != null &&
        productIdMatches &&
        transactionReason != 'PURCHASE';

    if (Platform.isIOS && isRestored && pendingContext != null) {
      debugPrint('🔍 [iOS] restoredDuringPurchase 判断: pendingProductId=$pendingProductId, eventProductId=$productId, matches=$productIdMatches, reason=$transactionReason');
    }

    if (Platform.isIOS && isRestored && pendingContext != null && transactionReason == 'PURCHASE') {
      debugPrint('✅ [iOS] transactionReason=PURCHASE，走正常验证流程');
    }

    if (Platform.isIOS && isRestored && pendingContext != null && !productIdMatches) {
      debugPrint('⏭️ [iOS] productId 不匹配 (pending=$pendingProductId, event=$productId)');
      debugPrint('   检测到升级/降级场景...');

      if (transactionReason == 'PURCHASE') {
        debugPrint('🔔 [iOS] 升级场景收到 restored 事件，判定已订阅，结束流程');
        debugPrint('   pendingProductId=$pendingProductId, eventProductId=$productId, purchaseId=$purchaseId');
        final alreadySubscribedData = <String, dynamic>{
          'action': 'already_subscribed',
          'productId': pendingProductId,
          'purchaseId': purchaseId,
          'originalProductId': productId,
        };
        pendingContext.forEach((key, value) {
          alreadySubscribedData.putIfAbsent(key, () => value);
        });
        PaymentEventBus.instance.publish(PaymentEvent(
          PaymentEventType.custom,
          orderId: purchaseId,
          data: alreadySubscribedData,
        ));
        PaymentEventBus.instance.publish(PaymentEvent(
          PaymentEventType.cancelled,
          orderId: purchaseId,
          data: {
            'reason': 'already_subscribed',
            'productId': pendingProductId,
          },
        ));
        _finishTransaction(purchaseDetails);
        clearPendingContext();
        return;
      }

      // 🔑 升级场景：无论新订阅是否已激活，都应该发布 verify_needed
      // 使用 pendingProductId（用户实际要购买的产品）进行验证
      final capturedContext = pendingContext;
      final capturedOrderNum = capturedContext['orderNum']?.toString();

      debugPrint('📦 [iOS升级] 使用待购产品ID: $pendingProductId, orderNum: $capturedOrderNum');

      Future.delayed(Duration(milliseconds: 100), () {
        // ✅ 安全检查：如果已销毁则跳过执行
        if (_disposed) {
          debugPrint('⚠️ [iOS升级] 回调已被销毁，跳过发布 verify_needed 事件');
          return;
        }
        debugPrint('⏰ [iOS升级] 100ms 延迟后，发布 verify_needed 事件');
        final eventData = <String, dynamic>{
          'action': 'verify_needed',
          'purchaseDetails': purchaseDetails,
          'productId': pendingProductId,  // 🔑 使用待购产品ID
          'originalProductId': productId,
          'isRestored': false,
          'restoredDuringPurchase': false,
          'isUpgradeOrDowngrade': true,
        };
        capturedContext.forEach((key, value) {
          eventData.putIfAbsent(key, () => value);
        });
        debugPrint('📤 [iOS升级] 发布 verify_needed 事件: productId=$pendingProductId, orderNum=$capturedOrderNum');
        PaymentEventBus.instance.publish(PaymentEvent(
          PaymentEventType.custom,
          orderId: purchaseId,
          data: eventData,
        ));
      });
      return;
    }

    if (restoredDuringPurchase) {
      debugPrint('🔔 [iOS] 购买时发现已订阅: $productId');
      final alreadySubscribedData = <String, dynamic>{
        'action': 'already_subscribed',
        'productId': productId,
        'purchaseId': purchaseId,
      };
      pendingContext.forEach((key, value) {
        alreadySubscribedData.putIfAbsent(key, () => value);
      });
      PaymentEventBus.instance.publish(PaymentEvent(
        PaymentEventType.custom,
        orderId: purchaseId,
        data: alreadySubscribedData,
      ));

      debugPrint('📤 [iOS] 已订阅场景：发送 cancelled 事件终结支付监控');
      PaymentEventBus.instance.publish(PaymentEvent(
        PaymentEventType.cancelled,
        orderId: purchaseId,
        data: {
          'reason': 'already_subscribed',
          'productId': productId,
        },
      ));

      _finishTransaction(purchaseDetails);
      clearPendingContext();
      return;
    }

    debugPrint('✅ [购买流] ${isRestored ? "购买已恢复" : "购买成功"}，准备触发服务器验证');
    debugPrint('   productId: $productId, purchaseId: $purchaseId, orderNum: $orderNumFromContext');

    final capturedContext = pendingContext;
    debugPrint('📝 [购买流] 捕获 pendingContext: ${capturedContext != null ? "有数据" : "为空"}');

    // 🔑 关键检查：如果 transactionReason=PURCHASE 但 pendingContext 为空
    // 说明这是购买事件但 PrePay 还没完成，跳过处理，等待下一次事件
    if (Platform.isIOS && transactionReason == 'PURCHASE' && capturedContext == null) {
      debugPrint('⏳ [iOS] PURCHASE 交易但 pendingContext 为空，等待后续事件...');
      debugPrint('   取消标记 purchaseId: $purchaseId');
      // 从已处理列表中移除，让下次事件能被处理
      _purchaseIdTimestamps.remove(purchaseId);
      return;
    }

    Future.delayed(Duration(milliseconds: 100), () {
      // ✅ 安全检查：如果已销毁则跳过执行
      if (_disposed) {
        debugPrint('⚠️ [购买流] 回调已被销毁，跳过发布 verify_needed 事件');
        return;
      }
      debugPrint('⏰ [购买流] 100ms 延迟后，准备发布 verify_needed 事件');
      final eventData = <String, dynamic>{
        'action': 'verify_needed',
        'purchaseDetails': purchaseDetails,
        'productId': productId,
        'isRestored': isRestored,
        'restoredDuringPurchase': restoredDuringPurchase,
      };
      if (capturedContext != null) {
        capturedContext.forEach((key, value) {
          eventData.putIfAbsent(key, () => value);
        });
      }
      debugPrint('📤 [购买流] 发布 verify_needed 事件');
      PaymentEventBus.instance.publish(PaymentEvent(
        PaymentEventType.custom,
        orderId: purchaseId,
        data: eventData,
      ));
    });
  }

  @override
  bool get hasListeners => _controller.hasListener;

  @override
  bool get isInitialized => _initialized;

  static const _resultToEventType = {
    PaymentResult.success: PaymentEventType.processing,
    PaymentResult.failed: PaymentEventType.failed,
    PaymentResult.cancelled: PaymentEventType.cancelled,
    PaymentResult.alreadyOwned: PaymentEventType.cancelled,
    PaymentResult.subscriptionChangeBlocked: PaymentEventType.cancelled,
    PaymentResult.processing: PaymentEventType.dialogShown,
    PaymentResult.pending: PaymentEventType.dialogShown,
  };

  PaymentEvent _toPaymentEvent(IResponse resp) {
    final type = _resultToEventType[resp.result] ?? PaymentEventType.custom;
    final mergedData = mergeWithContext(resp.data);
    final rawOrderId = mergedData['orderId'] ??
        mergedData['purchaseId'] ??
        mergedData['purchaseID'];
    return PaymentEvent(
      type,
      orderId: rawOrderId?.toString(),
      data: mergedData,
      error: resp.result == PaymentResult.failed ? resp.message : null,
    );
  }

  void _finishTransaction(PurchaseDetails purchase) {
    try {
      InAppPurchase.instance.completePurchase(purchase).then((_) {
        debugPrint('✅ 交易已结束: ${purchase.productID}, purchaseID: ${purchase.purchaseID}');
      }).catchError((e) {
        debugPrint('⚠️ 结束交易失败: $e');
      });
    } catch (e) {
      debugPrint('⚠️ 结束交易异常: $e');
    }
  }

  @override
  void dispose() {
    // ✅ 设置销毁标志，阻止 Future.delayed 回调继续执行
    _disposed = true;
    _sub?.cancel();
    _controller.close();
    _eventBusSub?.cancel();
    debugPrint('应用内购买回调监听器已释放');
    super.dispose();
  }
}
