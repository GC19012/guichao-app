import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_manager.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_domain/gch_entity/gch_payment_flow_state.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_domain/gch_strategy/gch_payment_strategy.dart';

/// 应用内购买策略 (Apple App Store)
///
/// 设计原则：
/// 1. 包装现有 InAppPurchaseProvider，不修改底层逻辑
/// 2. 处理 Apple Store 特有的错误码
/// 3. 支持订阅升级/降级场景
class InAppPurchaseStrategy extends BasePaymentStrategy {
  final PaymentManager _paymentManager;

  InAppPurchaseStrategy(this._paymentManager);

  @override
  PayProvider get method => PayProvider.inAppPurchase;

  @override
  String get displayName => 'Apple Pay';

  @override
  PaymentProvider? get provider => _paymentManager.getProvider(PayProvider.inAppPurchase);

  @override
  Future<PaymentAvailability> checkAvailability() async {
    // 平台检查（在调用 provider 之前）
    if (!Platform.isIOS) {
      return const PaymentAvailability.unavailable(
        reason: PaymentFailureReason.paymentMethodNotAvailable,
        message: '当前平台不支持应用内购买',
      );
    }

    // 委托给基类检查（内部调用 provider.isAvailable()）
    final baseCheck = await super.checkAvailability();
    if (!baseCheck.isAvailable) {
      // 返回平台特定的错误信息
      return PaymentAvailability.unavailable(
        reason: baseCheck.unavailableReason ?? PaymentFailureReason.serviceUnavailable,
        message: _getPlatformUnavailableMessage(baseCheck.message),
      );
    }

    return baseCheck;
  }

  /// 获取平台特定的不可用消息
  String _getPlatformUnavailableMessage(String? originalMessage) {
    if (Platform.isIOS) {
      return originalMessage ?? 'App Store 不可用';
    }
    return originalMessage ?? '支付服务不可用';
  }

  @override
  Future<PaymentFlowState> execute(PaymentContext context) async {
    debugPrint('📱 InAppPurchaseStrategy.execute: ${context.product.productId}');

    // 1. 检查可用性
    final availability = await checkAvailability();
    if (!availability.isAvailable) {
      return availability.toFailedState()!;
    }

    // 2. 设置支付方式
    try {
      _paymentManager.setPaymentMethod(PayProvider.inAppPurchase);
    } catch (e) {
      return PaymentFlowState.failed(
        reason: PaymentFailureReason.paymentMethodNotAvailable,
        message: '设置支付方式失败: $e',
        productId: context.product.productId,
        canRetry: true,
      );
    }

    // 3. 执行支付（委托给现有 Provider）
    try {
      final params = GenericPaymentParams.fromContext(context);
      final result = await _paymentManager.pay(params);

      return _handlePaymentResult(result, context);
    } catch (e) {
      debugPrint('❌ InAppPurchase 支付异常: $e');
      return _handlePaymentException(e, context);
    }
  }

  /// 处理支付结果
  PaymentFlowState _handlePaymentResult(IResponse result, PaymentContext context) {
    final orderId = result.data?['orderId']?.toString() ?? context.existingOrderId;
    final transactionId = result.data?['transactionId']?.toString();

    switch (result.result) {
      case PaymentResult.success:
        return PaymentFlowState.success(
          orderId: orderId ?? '',
          productId: context.product.productId,
          method: method,
          transactionId: transactionId,
          receipt: result.data,
        );

      case PaymentResult.cancelled:
        return PaymentFlowState.cancelled(
          orderId: orderId,
          productId: context.product.productId,
          method: method,
          message: result.message,
        );

      case PaymentResult.processing:
      case PaymentResult.pending:
        return PaymentFlowState.processing(
          orderId: orderId ?? '',
          productId: context.product.productId,
          method: method,
          transactionId: transactionId,
        );

      case PaymentResult.alreadyOwned:
        // 商品已拥有
        // 这通常发生在用户已订阅，尝试再次购买
        return PaymentFlowState.failed(
          reason: PaymentFailureReason.alreadyOwned,
          message: result.message ?? '您已订阅此商品',
          orderId: orderId,
          productId: context.product.productId,
          method: method,
          canRetry: false,
          details: result.data,
        );

      case PaymentResult.subscriptionChangeBlocked:
        // 订阅变更被阻止
        // 当用户尝试从一个订阅切换到另一个时，商店可能会阻止
        return PaymentFlowState.cancelled(
          orderId: orderId,
          productId: context.product.productId,
          method: method,
          message: '订阅变更被阻止',
        );

      case PaymentResult.networkError:
        return PaymentFlowState.failed(
          reason: PaymentFailureReason.networkError,
          message: result.message ?? '网络连接失败，请检查网络后重试',
          orderId: orderId,
          productId: context.product.productId,
          method: method,
          canRetry: true,
        );

      case PaymentResult.serviceUnavailable:
        return PaymentFlowState.failed(
          reason: PaymentFailureReason.serviceUnavailable,
          message: result.message ?? _getServiceUnavailableMessage(),
          orderId: orderId,
          productId: context.product.productId,
          method: method,
          canRetry: true,
        );

      case PaymentResult.serviceTimeout:
        return PaymentFlowState.failed(
          reason: PaymentFailureReason.serviceTimeout,
          message: result.message ?? '服务响应超时，请稍后重试',
          orderId: orderId,
          productId: context.product.productId,
          method: method,
          canRetry: true,
        );

      case PaymentResult.failed:
      case PaymentResult.refunded:
      case PaymentResult.partialRefunded:
        return PaymentFlowState.failed(
          reason: PaymentFailureReason.unknown,
          message: result.message ?? '支付失败，请重试',
          orderId: orderId,
          productId: context.product.productId,
          method: method,
          canRetry: true,
          details: result.data,
        );
    }
  }

  /// 处理支付异常
  PaymentFlowState _handlePaymentException(Object error, PaymentContext context) {
    final errorStr = error.toString().toLowerCase();

    // 识别特定异常类型
    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return PaymentFlowState.failed(
        reason: PaymentFailureReason.networkError,
        message: '网络连接失败，请检查网络后重试',
        productId: context.product.productId,
        method: method,
        canRetry: true,
      );
    }

    if (errorStr.contains('billing') && errorStr.contains('unavailable')) {
      return PaymentFlowState.failed(
        reason: PaymentFailureReason.serviceUnavailable,
        message: _getServiceUnavailableMessage(),
        productId: context.product.productId,
        method: method,
        canRetry: true,
      );
    }

    if (errorStr.contains('cancel')) {
      return PaymentFlowState.cancelled(
        productId: context.product.productId,
        method: method,
        message: '用户取消支付',
      );
    }

    return PaymentFlowState.failed(
      reason: PaymentFailureReason.unknown,
      message: '支付过程中发生错误: $error',
      productId: context.product.productId,
      method: method,
      canRetry: true,
    );
  }

  /// 获取服务不可用消息（平台相关）
  String _getServiceUnavailableMessage() {
    if (Platform.isIOS) {
      return 'App Store 不可用，请检查网络连接';
    }
    return '支付服务不可用';
  }

  @override
  Future<PaymentFlowState> handleCallback(Map<String, dynamic> callbackData) async {
    // 应用内购买的回调由 InAppPurchaseCallback 处理
    // 这里主要用于外部回调转发
    debugPrint('📱 InAppPurchase 收到回调: $callbackData');

    final purchaseId = callbackData['purchaseId']?.toString();
    final status = callbackData['status']?.toString();
    final orderId = callbackData['orderId']?.toString();
    final productId = callbackData['productId']?.toString();

    if (status == 'success' || status == 'purchased') {
      return PaymentFlowState.success(
        orderId: orderId ?? '',
        productId: productId ?? '',
        method: method,
        transactionId: purchaseId,
        receipt: callbackData,
      );
    } else if (status == 'cancelled' || status == 'canceled') {
      return PaymentFlowState.cancelled(
        orderId: orderId,
        productId: productId,
        method: method,
      );
    } else if (status == 'pending') {
      return PaymentFlowState.processing(
        orderId: orderId ?? '',
        productId: productId ?? '',
        method: method,
        transactionId: purchaseId,
      );
    }

    return PaymentFlowState.failed(
      reason: PaymentFailureReason.unknown,
      message: '未知的回调状态: $status',
      orderId: orderId,
      productId: productId,
      method: method,
      canRetry: true,
      details: callbackData,
    );
  }
}
