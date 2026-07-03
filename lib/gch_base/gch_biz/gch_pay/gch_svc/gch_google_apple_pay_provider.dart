/// 应用内购买提供者 - 统一入口（代理模式）
///
/// 使用 ApplePayProvider 处理 App Store 内购
/// 保持向后兼容性，所有公开 API 不变


import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_interface.dart';

// 导入模块化组件
import 'gch_iap/gch_common/gch_in_app_purchase_base.dart';
import 'gch_iap/gch_common/gch_in_app_purchase_models.dart';
import 'gch_iap/gch_common/gch_purchase_error_handler.dart';
import 'gch_iap/gch_ios/gch_apple_pay_provider.dart';
// 导出所有模块以保持向后兼容
export 'gch_iap/gch_common/gch_in_app_purchase_base.dart'
    show InAppPurchaseProviderBase;
export 'gch_iap/gch_common/gch_in_app_purchase_models.dart';
export 'gch_iap/gch_common/gch_purchase_error_handler.dart'
    show StoreInitError, StoreInitResult;
export 'gch_iap/gch_common/gch_in_app_purchase_callback.dart';
export 'gch_iap/gch_ios/gch_apple_pay_provider.dart';
export 'gch_iap/gch_ios/gch_storekit2_helper.dart';

/// 应用内购买提供者 - 统一入口（代理模式）
///
/// 使用 ApplePayProvider 处理 App Store 内购
/// 实现 PaymentProvider 接口，代理所有调用到平台特定实现
class InAppPurchaseProvider
    implements PaymentProvider<Map<String, dynamic>, Map<String, dynamic>> {
  late final InAppPurchaseProviderBase _platformProvider;

  InAppPurchaseProvider({Ref? ref}) {
    _platformProvider = ApplePayProvider(ref: ref);
    debugPrint('InAppPurchaseProvider: 使用 ApplePayProvider');
  }

  // ==================== 代理 PaymentProvider 接口 ====================

  @override
  PayProvider get method => _platformProvider.method;

  @override
  bool get requiresSdk => _platformProvider.requiresSdk;

  @override
  Set<CallbackType> getSupportedCallbackTypes() =>
      _platformProvider.getSupportedCallbackTypes();

  @override
  Stream<IResponse>? resultStream(CallbackType type) =>
      _platformProvider.resultStream(type);

  @override
  Future<bool> initialize(Map<String, dynamic> config) =>
      _platformProvider.initialize(config);

  @override
  Future<bool> isAvailable() => _platformProvider.isAvailable();

  @override
  Future<String?> checkGatewayReachability() =>
      _platformProvider.checkGatewayReachability();

  @override
  String get gatewayDisplayName => _platformProvider.gatewayDisplayName;

  @override
  Future<IResponse<Map<String, dynamic>>> PrePay(
          IParams<Map<String, dynamic>> params) =>
      _platformProvider.PrePay(params);

  @override
  Future<IResponse<Map<String, dynamic>>> pay(
          IParams<Map<String, dynamic>> params) =>
      _platformProvider.pay(params);

  @override
  Future<IResponse<Map<String, dynamic>>> verifypay(
          IParams<Map<String, dynamic>> params) =>
      _platformProvider.verifypay(params);

  @override
  Future<IResponse<Map<String, dynamic>>> query(
          IParams<Map<String, dynamic>> params) =>
      _platformProvider.query(params);

  @override
  Future<IResponse<Map<String, dynamic>>> getPayResult(
          IParams<Map<String, dynamic>> params) =>
      _platformProvider.getPayResult(params);

  @override
  Future<IResponse<Map<String, dynamic>>> refund(
          IParams<Map<String, dynamic>> params) =>
      _platformProvider.refund(params);

  @override
  Future<IResponse<Map<String, dynamic>>> cancelorder(
          IParams<Map<String, dynamic>> params) =>
      _platformProvider.cancelorder(params);

  @override
  Future<IResponse<List<Map<String, dynamic>>>> getProducts(
          [List<String>? productIds]) =>
      _platformProvider.getProducts(productIds);

  @override
  void dispose() => _platformProvider.dispose();

  // ==================== 扩展方法代理 ====================

  /// 获取应用商店支付是否可用
  bool get isStoreAvailable => _platformProvider.isStoreAvailable;

  /// 获取最后一次初始化结果
  StoreInitResult get lastInitResult => _platformProvider.lastInitResult;

  /// 检查商品购买资格
  Future<PurchaseEligibility> checkPurchaseEligibility(String productId) =>
      _platformProvider.checkPurchaseEligibility(productId);

  /// 快速检查是否可以购买商品
  Future<bool> canPurchaseProduct(String productId) =>
      _platformProvider.canPurchaseProduct(productId);

  /// 获取详细的可用性状态
  Future<IResponse<Map<String, dynamic>>> getAvailabilityStatus() =>
      _platformProvider.getAvailabilityStatus();

  /// 恢复购买
  Future<IResponse<Map<String, dynamic>>> restorePurchases() =>
      _platformProvider.restorePurchases();

  /// 查询订阅状态
  Future<IResponse<Map<String, dynamic>>> querySubscriptionStatus() =>
      _platformProvider.querySubscriptionStatus();

  /// 获取产品详情缓存
  Map<String, dynamic> get productDetailsCache =>
      _platformProvider.productDetailsCache.map(
        (key, value) => MapEntry(key, {
          'id': value.id,
          'title': value.title,
          'description': value.description,
          'price': value.price,
          'rawPrice': value.rawPrice,
          'currencyCode': value.currencyCode,
          'currencySymbol': value.currencySymbol,
        }),
      );

  /// 预取商店商品详情到平台缓存。
  Future<void> prefetchProducts(Iterable<String> productIds) =>
      _platformProvider.prefetchProducts(productIds);

  /// 是否处于初始化恢复阶段
  bool get isInitRestorePhase => _platformProvider.isInitRestorePhase;

  // ==================== iOS 专有方法 ====================

  /// 刷新购买验证数据（仅 iOS）
  Future<IResponse<Map<String, dynamic>>> refreshPurchaseVerificationData() {
    if (_platformProvider is ApplePayProvider) {
      return _platformProvider.refreshPurchaseVerificationData();
    }
    return Future.value(PaymentResponse.failed(message: '仅 iOS 支持此功能'));
  }

  /// 显示代码兑换界面（仅 iOS）
  Future<IResponse<Map<String, dynamic>>> presentCodeRedemptionSheet() {
    if (_platformProvider is ApplePayProvider) {
      return _platformProvider.presentCodeRedemptionSheet();
    }
    return Future.value(PaymentResponse.failed(message: '仅 iOS 支持此功能'));
  }

}

/// InAppPurchaseProvider 的 Riverpod Provider
final inAppPurchaseProvider = Provider<InAppPurchaseProvider>((ref) {
  return InAppPurchaseProvider(ref: ref);
});

/// InAppPurchaseProvider 工厂函数，支持依赖注入
InAppPurchaseProvider createInAppPurchaseProvider({Ref? ref}) {
  return InAppPurchaseProvider(ref: ref);
}
