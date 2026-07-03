import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_interface.dart';

part 'gch_payment_flow_state.freezed.dart';

/// 支付流程状态 - 纯业务状态，不包含任何 UI 元素
///
/// 设计原则：
/// 1. 不可变性：使用 Freezed 确保状态不可变
/// 2. 类型安全：密封类确保所有状态都被处理
/// 3. 无 UI 依赖：不包含 BuildContext、Widget、Color 等 UI 元素
/// 4. 可序列化：支持状态持久化和恢复
@freezed
sealed class PaymentFlowState with _$PaymentFlowState {
  /// 空闲状态 - 等待用户操作
  const factory PaymentFlowState.idle() = PaymentFlowIdle;

  /// 初始化中 - 正在加载支付配置和商品
  const factory PaymentFlowState.initializing({
    String? message,
  }) = PaymentFlowInitializing;

  /// 商品已加载 - 可以开始支付
  const factory PaymentFlowState.ready({
    required List<ProductInfo> products,
    required List<PayProvider> availableMethods,
  }) = PaymentFlowReady;

  /// 支付方式选择中
  const factory PaymentFlowState.selectingMethod({
    required List<PayProvider> availableMethods,
    PayProvider? currentMethod,
  }) = PaymentFlowSelectingMethod;

  /// 预支付处理中 - 创建订单
  const factory PaymentFlowState.preparingPayment({
    required String productId,
    required PayProvider method,
    String? orderId,
  }) = PaymentFlowPreparingPayment;

  /// 等待用户支付 - SDK 已唤起
  const factory PaymentFlowState.awaitingPayment({
    required String orderId,
    required String productId,
    required PayProvider method,
    DateTime? startTime,
  }) = PaymentFlowAwaitingPayment;

  /// 支付处理中 - 等待后端确认
  const factory PaymentFlowState.processing({
    required String orderId,
    required String productId,
    required PayProvider method,
    String? transactionId,
  }) = PaymentFlowProcessing;

  /// 支付成功
  const factory PaymentFlowState.success({
    required String orderId,
    required String productId,
    required PayProvider method,
    String? transactionId,
    Map<String, dynamic>? receipt,
  }) = PaymentFlowSuccess;

  /// 支付失败
  const factory PaymentFlowState.failed({
    required PaymentFailureReason reason,
    required String message,
    String? orderId,
    String? productId,
    PayProvider? method,
    @Default(true) bool canRetry,
    Map<String, dynamic>? details,
  }) = PaymentFlowFailed;

  /// 支付取消
  const factory PaymentFlowState.cancelled({
    String? orderId,
    String? productId,
    PayProvider? method,
    String? message,
  }) = PaymentFlowCancelled;

  /// 需要用户操作 - 如登录、验证等
  const factory PaymentFlowState.requiresAction({
    required PaymentActionRequired action,
    String? message,
    Map<String, dynamic>? data,
  }) = PaymentFlowRequiresAction;

  /// 存在未完成订单
  const factory PaymentFlowState.hasUnpaidOrder({
    required String orderId,
    required int productId,
    required String productName,
    required double amount,
    required String currency,
    DateTime? createdAt,
  }) = PaymentFlowHasUnpaidOrder;

  /// 支付超时 - 等待验证超时
  const factory PaymentFlowState.timeout({
    String? orderId,
    String? productId,
    PayProvider? method,
    String? message,
  }) = PaymentFlowTimeout;
}

/// 支付失败原因 - 细分错误类型，便于 UI 层精确处理
enum PaymentFailureReason {
  /// 网络错误
  networkError,

  /// 服务不可用（如 App Store 不可用）
  serviceUnavailable,

  /// 服务超时
  serviceTimeout,

  /// 商品已拥有（如已订阅）
  alreadyOwned,

  /// 订阅变更被阻止
  subscriptionChangeBlocked,

  /// 用户未登录
  notLoggedIn,

  /// 商品不可用
  productNotAvailable,

  /// 支付方式不可用
  paymentMethodNotAvailable,

  /// 订单创建失败
  orderCreationFailed,

  /// SDK 初始化失败
  sdkInitializationFailed,

  /// 验证失败
  verificationFailed,

  /// 支付失败（一般性支付失败）
  paymentFailed,

  /// 未知错误
  unknown,
}

/// 需要的用户操作类型
enum PaymentActionRequired {
  /// 需要登录
  login,

  /// 需要验证身份
  verify,

  /// 需要更新支付方式
  updatePaymentMethod,

  /// 需要确认订阅变更
  confirmSubscriptionChange,

  /// 需要处理未完成订单
  handleUnpaidOrder,
}

/// 商品信息 - 业务层使用的轻量模型
class ProductInfo {
  final int id;
  final String productId;
  final String? priceId;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String? formattedPrice;
  final String? type; // subscription, one_time
  final int? durationDays;
  final bool canPurchase;
  final Map<String, dynamic>? extra;

  const ProductInfo({
    required this.id,
    required this.productId,
    this.priceId,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    this.formattedPrice,
    this.type,
    this.durationDays,
    this.canPurchase = true,
    this.extra,
  });

  /// 从 Map 创建
  factory ProductInfo.fromMap(Map<String, dynamic> map) {
    return ProductInfo(
      id: map['id'] as int? ?? 0,
      productId: map['productId'] as String? ?? '',
      priceId: map['priceId'] as String? ?? map['priceid'] as String?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: ((map['rawPrice'] ?? map['price'] ?? 0) as num).toDouble(),
      currency: map['currency'] as String? ?? 'USD',
      formattedPrice: map['price'] as String?,
      type: map['type'] as String?,
      durationDays: map['duration'] as int?,
      canPurchase: map['canPurchase'] as bool? ?? true,
      extra: map,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'productId': productId,
        'priceId': priceId,
        'title': title,
        'description': description,
        'price': price,
        'currency': currency,
        'formattedPrice': formattedPrice,
        'type': type,
        'duration': durationDays,
        'canPurchase': canPurchase,
        ...?extra,
      };
}

/// PaymentFlowState 扩展方法
extension PaymentFlowStateX on PaymentFlowState {
  /// 是否为终态（成功、失败、取消、超时）
  bool get isTerminal => switch (this) {
        PaymentFlowSuccess() => true,
        PaymentFlowFailed() => true,
        PaymentFlowCancelled() => true,
        PaymentFlowTimeout() => true,
        _ => false,
      };

  /// 是否为错误状态
  bool get isError => this is PaymentFlowFailed;

  /// 是否正在处理中
  bool get isProcessing => switch (this) {
        PaymentFlowInitializing() => true,
        PaymentFlowPreparingPayment() => true,
        PaymentFlowAwaitingPayment() => true,
        PaymentFlowProcessing() => true,
        _ => false,
      };

  /// 是否可以开始新支付
  bool get canStartPayment => switch (this) {
        PaymentFlowIdle() => true,
        PaymentFlowReady() => true,
        PaymentFlowSuccess() => true,
        PaymentFlowFailed(canRetry: true) => true,
        PaymentFlowCancelled() => true,
        PaymentFlowTimeout() => true,
        _ => false,
      };

  /// 获取订单 ID（如果有）
  String? get orderId => switch (this) {
        PaymentFlowPreparingPayment(:final orderId) => orderId,
        PaymentFlowAwaitingPayment(:final orderId) => orderId,
        PaymentFlowProcessing(:final orderId) => orderId,
        PaymentFlowSuccess(:final orderId) => orderId,
        PaymentFlowFailed(:final orderId) => orderId,
        PaymentFlowCancelled(:final orderId) => orderId,
        PaymentFlowHasUnpaidOrder(:final orderId) => orderId,
        PaymentFlowTimeout(:final orderId) => orderId,
        _ => null,
      };

  /// 获取商品 ID（如果有）
  String? get productId => switch (this) {
        PaymentFlowPreparingPayment(:final productId) => productId,
        PaymentFlowAwaitingPayment(:final productId) => productId,
        PaymentFlowProcessing(:final productId) => productId,
        PaymentFlowSuccess(:final productId) => productId,
        PaymentFlowFailed(:final productId) => productId,
        PaymentFlowCancelled(:final productId) => productId,
        PaymentFlowHasUnpaidOrder(:final productId) => productId.toString(),
        PaymentFlowTimeout(:final productId) => productId,
        _ => null,
      };

  /// 是否为超时状态
  bool get isTimeout => this is PaymentFlowTimeout;
}
