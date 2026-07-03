import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_interface.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_domain/gch_entity/gch_payment_flow_state.dart';

/// 支付策略接口 - 策略模式核心
///
/// 设计原则：
/// 1. 每种支付方式实现各自的策略
/// 2. 策略只负责支付流程编排，不直接操作 UI
/// 3. 底层调用委托给现有的 PaymentProvider，不修改现有逻辑
/// 4. 策略可以组合使用（如：先创建订单，再调用 SDK）
///
/// 使用示例：
/// ```dart
/// final strategy = strategyFactory.getStrategy(PayProvider.inAppPurchase);
/// final result = await strategy.execute(context);
/// ```
abstract class PaymentStrategy {
  /// 支付方式标识
  PayProvider get method;

  /// 支付方式显示名称（用于日志）
  String get displayName;

  /// 是否需要 SDK 支持（如 App Store、微信等）
  bool get requiresSdk;

  /// 检查支付方式是否可用
  ///
  /// 包括：SDK 是否安装、网络是否正常、配置是否完整等
  Future<PaymentAvailability> checkAvailability();

  /// 执行支付流程
  ///
  /// 返回支付结果状态，策略内部处理：
  /// 1. 预支付/创建订单（如需要）
  /// 2. 调用支付 SDK
  /// 3. 等待支付结果
  /// 4. 验证支付（如需要）
  ///
  /// [context] 支付上下文，包含商品、用户、订单信息
  Future<PaymentFlowState> execute(PaymentContext context);

  /// 取消支付
  ///
  /// 用于用户主动取消或超时取消
  Future<PaymentFlowState> cancel(String? orderId);

  /// 查询支付状态
  ///
  /// 用于支付结果不确定时主动查询
  Future<PaymentFlowState> queryStatus(String orderId);

  /// 处理支付回调
  ///
  /// 用于异步支付结果回调（如微信、支付宝）
  Future<PaymentFlowState> handleCallback(Map<String, dynamic> callbackData);
}

/// 支付可用性检查结果
class PaymentAvailability {
  final bool isAvailable;
  final PaymentFailureReason? unavailableReason;
  final String? message;

  /// 可用
  const PaymentAvailability.available()
      : isAvailable = true,
        unavailableReason = null,
        message = null;

  /// 不可用
  const PaymentAvailability.unavailable({
    required PaymentFailureReason reason,
    String? message,
  })  : isAvailable = false,
        unavailableReason = reason,
        message = message;

  /// 转换为失败状态（如果不可用）
  PaymentFlowState? toFailedState() {
    if (isAvailable) return null;
    return PaymentFlowState.failed(
      reason: unavailableReason ?? PaymentFailureReason.unknown,
      message: message ?? '支付方式不可用',
      canRetry: false,
    );
  }
}

/// 支付上下文 - 传递给策略的所有必要信息
class PaymentContext {
  /// 商品信息
  final ProductInfo product;

  /// 支付方式（标准化枚举）
  final PayProvider method;

  /// 用户 ID
  final String? userId;

  /// 已存在的订单 ID（续费/重试场景）
  final String? existingOrderId;

  /// 额外参数（各支付方式特有）
  final Map<String, dynamic> extra;

  const PaymentContext({
    required this.product,
    required this.method,
    this.userId,
    this.existingOrderId,
    this.extra = const {},
  });

  /// 转换为支付参数 Map
  Map<String, dynamic> toParamsMap() => {
        'id': product.id,
        'productId': product.productId,
        'priceId': product.priceId,
        'amount': product.price,
        'currency': product.currency,
        'subject': product.title,
        'description': product.description,
        'payMethod': method.name,
        'userId': userId,
        'orderId': existingOrderId,
        ...extra,
      };
}

/// 通用支付参数实现
class GenericPaymentParams implements IParams<Map<String, dynamic>> {
  final Map<String, dynamic> _params;

  GenericPaymentParams(this._params);

  factory GenericPaymentParams.fromContext(PaymentContext context) {
    return GenericPaymentParams(context.toParamsMap());
  }

  @override
  Map<String, dynamic> toMap() => _params;
}

/// 支付策略基类 - 提供通用实现
///
/// 子类只需覆盖特定方法即可
abstract class BasePaymentStrategy implements PaymentStrategy {
  /// 底层 PaymentProvider（委托调用）
  PaymentProvider? get provider;

  @override
  bool get requiresSdk => provider?.requiresSdk ?? false;

  @override
  Future<PaymentAvailability> checkAvailability() async {
    if (provider == null) {
      return const PaymentAvailability.unavailable(
        reason: PaymentFailureReason.paymentMethodNotAvailable,
        message: '支付方式未初始化',
      );
    }

    try {
      final available = await provider!.isAvailable();
      if (!available) {
        return PaymentAvailability.unavailable(
          reason: PaymentFailureReason.paymentMethodNotAvailable,
          message: '$displayName 不可用',
        );
      }
      return const PaymentAvailability.available();
    } catch (e) {
      return PaymentAvailability.unavailable(
        reason: PaymentFailureReason.sdkInitializationFailed,
        message: '检查 $displayName 可用性失败: $e',
      );
    }
  }

  @override
  Future<PaymentFlowState> cancel(String? orderId) async {
    return PaymentFlowState.cancelled(
      orderId: orderId,
      message: '用户取消支付',
    );
  }

  @override
  Future<PaymentFlowState> queryStatus(String orderId) async {
    if (provider == null) {
      return const PaymentFlowState.failed(
        reason: PaymentFailureReason.paymentMethodNotAvailable,
        message: '支付方式未初始化',
        canRetry: false,
      );
    }

    try {
      final params = GenericPaymentParams({'orderId': orderId});
      final result = await provider!.query(params);

      return _convertResponseToState(result, orderId: orderId);
    } catch (e) {
      return PaymentFlowState.failed(
        reason: PaymentFailureReason.unknown,
        message: '查询订单状态失败: $e',
        orderId: orderId,
        canRetry: true,
      );
    }
  }

  @override
  Future<PaymentFlowState> handleCallback(Map<String, dynamic> callbackData) async {
    // 默认实现：不处理回调
    // 需要处理异步回调的支付方式（如微信、支付宝）应覆盖此方法
    return const PaymentFlowState.failed(
      reason: PaymentFailureReason.unknown,
      message: '不支持回调处理',
      canRetry: false,
    );
  }

  /// 将 IResponse 转换为 PaymentFlowState
  PaymentFlowState _convertResponseToState(
    IResponse response, {
    String? orderId,
    String? productId,
  }) {
    switch (response.result) {
      case PaymentResult.success:
        return PaymentFlowState.success(
          orderId: orderId ?? '',
          productId: productId ?? '',
          method: method,
          transactionId: response.data?['transactionId']?.toString(),
          receipt: response.data,
        );

      case PaymentResult.cancelled:
        return PaymentFlowState.cancelled(
          orderId: orderId,
          productId: productId,
          method: method,
          message: response.message,
        );

      case PaymentResult.processing:
      case PaymentResult.pending:
        return PaymentFlowState.processing(
          orderId: orderId ?? '',
          productId: productId ?? '',
          method: method,
          transactionId: response.data?['transactionId']?.toString(),
        );

      case PaymentResult.alreadyOwned:
        return PaymentFlowState.failed(
          reason: PaymentFailureReason.alreadyOwned,
          message: response.message ?? '您已订阅此商品',
          orderId: orderId,
          productId: productId,
          method: method,
          canRetry: false,
        );

      case PaymentResult.networkError:
        return PaymentFlowState.failed(
          reason: PaymentFailureReason.networkError,
          message: response.message ?? '网络连接失败',
          orderId: orderId,
          productId: productId,
          method: method,
          canRetry: true,
        );

      case PaymentResult.serviceUnavailable:
        return PaymentFlowState.failed(
          reason: PaymentFailureReason.serviceUnavailable,
          message: response.message ?? '支付服务不可用',
          orderId: orderId,
          productId: productId,
          method: method,
          canRetry: true,
        );

      case PaymentResult.serviceTimeout:
        return PaymentFlowState.failed(
          reason: PaymentFailureReason.serviceTimeout,
          message: response.message ?? '服务响应超时',
          orderId: orderId,
          productId: productId,
          method: method,
          canRetry: true,
        );

      case PaymentResult.subscriptionChangeBlocked:
        return PaymentFlowState.failed(
          reason: PaymentFailureReason.subscriptionChangeBlocked,
          message: response.message ?? '订阅变更被阻止',
          orderId: orderId,
          productId: productId,
          method: method,
          canRetry: false,
        );

      case PaymentResult.failed:
      case PaymentResult.refunded:
      case PaymentResult.partialRefunded:
        return PaymentFlowState.failed(
          reason: PaymentFailureReason.unknown,
          message: response.message ?? '支付失败',
          orderId: orderId,
          productId: productId,
          method: method,
          canRetry: true,
          details: response.data,
        );
    }
  }
}
