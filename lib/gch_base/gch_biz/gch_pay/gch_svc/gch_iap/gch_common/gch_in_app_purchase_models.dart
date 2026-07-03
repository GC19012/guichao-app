// 应用内购买共享数据模型
// 从 google_apple_pay_provider.dart 提取，保持所有逻辑不变

import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_interface.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart'
    as billing;

// ============================================================================
// 购买资格枚举
// ============================================================================

/// 购买资格状态
///
/// 用于判断用户是否可以购买指定商品
enum PurchaseEligibility {
  /// 可以正常购买
  canPurchase,

  /// 可以升级或降级（同一订阅组内有其他活跃订阅）
  canUpgradeOrDowngrade,

  /// 已订阅同一产品，不能重复购买
  alreadySubscribed,

  /// 产品未找到（未在 App Store Connect 配置）
  productNotFound,

  /// 商店不可用（设备不支持或网络问题）
  storeUnavailable,

  /// 检查失败（发生异常）
  checkFailed,
}

/// PurchaseEligibility 扩展方法
extension PurchaseEligibilityX on PurchaseEligibility {
  /// 是否可以发起购买（包括正常购买和升级/降级）
  bool get canInitiatePurchase =>
      this == PurchaseEligibility.canPurchase ||
      this == PurchaseEligibility.canUpgradeOrDowngrade;

  /// 是否是升级/降级场景
  bool get isUpgradeOrDowngrade => this == PurchaseEligibility.canUpgradeOrDowngrade;

  /// 是否已订阅
  bool get isAlreadySubscribed => this == PurchaseEligibility.alreadySubscribed;

  /// 获取用户友好的消息
  String get message {
    switch (this) {
      case PurchaseEligibility.canPurchase:
        return '可以购买';
      case PurchaseEligibility.canUpgradeOrDowngrade:
        return '可以升级或降级订阅';
      case PurchaseEligibility.alreadySubscribed:
        return '您已订阅此商品';
      case PurchaseEligibility.productNotFound:
        return '商品未找到';
      case PurchaseEligibility.storeUnavailable:
        return '应用商店不可用';
      case PurchaseEligibility.checkFailed:
        return '检查失败，请重试';
    }
  }
}

// ============================================================================

/// 应用内购买参数
class InAppPurchaseParams implements IParams<Map<String, dynamic>> {
  /// 产品ID（应用商店产品ID）
  final String productId;

  /// 购买类型 (consumable, non-consumable, subscription)
  final String purchaseType;

  /// 额外参数（包含用户信息、订单信息等）
  /// - userId: 用户ID（必需）
  /// - productNumericId: 产品数字ID（后端产品ID）
  /// - orderId: 订单ID（可选，用于关联已有订单）
  /// - appId: 应用ID
  /// - clientIp: 客户端IP
  /// - notifyUrl: 支付结果通知URL
  /// - returnUrl: 支付完成返回URL
  /// - timeoutSeconds: 超时时间（秒）
  final Map<String, dynamic>? extraParams;

  /// 是否自动消耗(仅消耗品有效)
  final bool autoConsume;

  /// 升级/降级订阅时的旧订阅ID(仅Android)
  final String? oldSubscriptionId;

  /// 替换模式(仅Android)
  final billing.ReplacementMode? prorationMode;

  InAppPurchaseParams({
    required this.productId,
    required this.purchaseType,
    this.extraParams,
    this.autoConsume = true,
    this.oldSubscriptionId,
    this.prorationMode,
  });

  /// 获取用户ID（必需参数）
  String get userId => extraParams?['userId']?.toString() ?? 'USER_DEFAULT';

  /// 获取产品数字ID（后端产品ID）
  int get productNumericId => extraParams?['productNumericId'] as int? ?? 0;

  @override
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'purchaseType': purchaseType,
      'extraParams': extraParams,
      'autoConsume': autoConsume,
      'oldSubscriptionId': oldSubscriptionId,
      'prorationMode': prorationMode?.index,
    };
  }
}

/// PrePay 结果
class PrepayResult {
  const PrepayResult({
    required this.productId,
    this.orderId,
  });

  final String productId;
  final String? orderId;
}

/// PrePay 载荷
class PrepayPayload {
  const PrepayPayload({
    required this.amount,
    required this.currency,
    required this.subject,
    required this.description,
    required this.notifyUrl,
    required this.returnUrl,
    required this.clientIp,
    required this.timeoutSeconds,
    required this.productNumericId,
    required this.extendParams,
    this.userId,
    this.productCode,
    this.appId,
  });

  final double amount;
  final String currency;
  final String subject;
  final String description;
  final String notifyUrl;
  final String returnUrl;
  final String clientIp;
  final int timeoutSeconds;
  final int productNumericId;
  final Map<String, dynamic> extendParams;
  final String? userId;
  final String? productCode;
  final String? appId;
}

/// PrePay 验证异常
class PrepayValidationException implements Exception {
  final String message;

  const PrepayValidationException(this.message);

  @override
  String toString() => 'PrepayValidationException($message)';
}

/// 支付异常
class PaymentException implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic>? data;

  const PaymentException(this.code, this.message, [this.data]);

  @override
  String toString() => 'PaymentException($code, $message)';
}

/// 产品加载结果
class ProductLoadResult {
  final bool success;
  final bool isNetworkError;
  final String? errorMessage;
  final int productCount;

  const ProductLoadResult._({
    required this.success,
    this.isNetworkError = false,
    this.errorMessage,
    this.productCount = 0,
  });

  factory ProductLoadResult.success(int count) => ProductLoadResult._(
        success: true,
        productCount: count,
      );

  factory ProductLoadResult.empty() => const ProductLoadResult._(
        success: true,
        productCount: 0,
      );

  factory ProductLoadResult.networkError(String message) => ProductLoadResult._(
        success: false,
        isNetworkError: true,
        errorMessage: message,
      );

  factory ProductLoadResult.fallback(int count) => ProductLoadResult._(
        success: count > 0,
        productCount: count,
      );
}

/// 验证参数类
class VerifyParams implements IParams<Map<String, dynamic>> {
  final Map<String, dynamic> data;

  VerifyParams(this.data);

  @override
  Map<String, dynamic> toMap() => data;
}
