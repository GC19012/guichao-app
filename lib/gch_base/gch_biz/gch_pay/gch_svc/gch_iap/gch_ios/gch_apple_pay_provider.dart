// iOS App Store 支付实现
// 继承自 InAppPurchaseProviderBase，实现 iOS 特定逻辑

import 'package:flutter/foundation.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_interface.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import '../gch_common/gch_in_app_purchase_base.dart';
import '../gch_common/gch_in_app_purchase_models.dart';
import 'gch_storekit2_helper.dart';

/// iOS App Store 支付实现
///
/// 实现 iOS 特有的功能:
/// - StoreKit 2 代理设置
/// - 订阅组检查（升级/降级）
/// - 代码兑换界面
/// - 刷新购买验证数据
class ApplePayProvider extends InAppPurchaseProviderBase {
  ApplePayProvider({super.ref});

  // ==================== 抽象属性实现 ====================

  @override
  String get platformName => 'ios';

  @override
  String get gatewayDisplayName => 'App Store';

  // ==================== 平台特定初始化 ====================

  @override
  Future<void> initializePlatform() async {
    try {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          inAppPurchase!
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(PaymentQueueDelegate());
      debugPrint('iOS 支付队列代理设置成功');
    } catch (e) {
      debugPrint('iOS 支付队列代理设置失败: $e');
      // 不阻止初始化过程
    }
  }

  // ==================== 购买资格检查 ====================

  @override
  Future<PurchaseEligibility> checkPlatformEligibility(String productId) async {
    try {
      // 检查是否已订阅同一产品
      final existingSubscription = await checkiOSActiveSubscription(productId);
      if (existingSubscription != null) {
        debugPrint('⚠️ [iOS购买资格] 已订阅同一产品: $productId');
        return PurchaseEligibility.alreadySubscribed;
      }

      // 检查是否有同一订阅组的其他活跃订阅（升级/降级场景）
      final allActiveSubscriptions = await getiOSActiveSubscriptions();
      if (allActiveSubscriptions.isNotEmpty) {
        debugPrint('📊 [iOS购买资格] 发现其他活跃订阅: $allActiveSubscriptions');
        // 使用简化版检查（因为此时还没有 ProductDetails）
        final isSameGroup = await checkSameSubscriptionGroup(
          productId,
          allActiveSubscriptions,
        );
        if (isSameGroup) {
          debugPrint('✅ [iOS购买资格] 可以升级/降级，同一订阅组');
          return PurchaseEligibility.canUpgradeOrDowngrade;
        }
      }

      return PurchaseEligibility.canPurchase;
    } catch (e) {
      debugPrint('❌ [iOS购买资格] 检查失败: $e');
      return PurchaseEligibility.checkFailed;
    }
  }

  /// 快速检查是否可以购买
  @override
  Future<bool> canPurchaseProduct(String productId) async {
    final existing = await checkiOSActiveSubscription(productId);
    return existing == null;
  }

  // ==================== 构建购买参数 ====================

  @override
  Future<PurchaseParam> buildPurchaseParam({
    required ProductDetails productDetails,
    required String orderId,
    required InAppPurchaseParams inAppParams,
  }) async {
    // iOS 使用标准 PurchaseParam
    // applicationUserName 用于关联订单，但 StoreKit 不保证返回
    return PurchaseParam(
      productDetails: productDetails,
      applicationUserName: orderId,
    );
  }

  // ==================== 构建验证数据 ====================

  @override
  Future<Map<String, dynamic>> buildVerifyData(
      PurchaseDetails purchase, Map<String, dynamic> baseData) async {
    final verificationData = purchase.verificationData;

    // iOS 使用 receipt data 进行服务端验证
    final verifyData = Map<String, dynamic>.from(baseData);
    verifyData['receiptData'] = verificationData.serverVerificationData;
    verifyData['originalTransactionId'] = purchase.purchaseID;
    verifyData['status'] = purchase.status.name;
    verifyData['localVerificationData'] = verificationData.localVerificationData;

    // 构建 extend 字段
    final extend = <String, dynamic>{};
    final orderNum = baseData['orderNum']?.toString();
    if (orderNum != null && orderNum.isNotEmpty) {
      extend['order_num'] = orderNum;
      debugPrint('✅ iOS 验证数据已添加 orderNum: $orderNum');
    } else {
      debugPrint('⚠️ iOS 验证数据缺少 orderNum，后端可能无法关联订单');
    }
    extend['is_restored'] = baseData['isRestored'] ?? false;
    verifyData['extend'] = extend;

    debugPrint('✅ iOS 验证数据: status=${purchase.status.name}, '
        'isRestored=${extend['is_restored']}');

    return verifyData;
  }

  // ==================== 平台特定查询 ====================

  @override
  Future<IResponse<Map<String, dynamic>>> queryPlatform(
      Map<String, dynamic> params) async {
    // iOS 使用 StoreKit 2 的 transactions() 获取购买历史
    try {
      final activeSubscriptions = await getiOSActiveSubscriptions();

      return PaymentResponse.success(
        message: '查询成功',
        data: {
          'activeSubscriptions': activeSubscriptions,
          'platform': 'ios',
        },
      );
    } catch (e) {
      return PaymentResponse.failed(message: '查询失败: $e');
    }
  }

  // ==================== 订阅状态查询 ====================

  @override
  Future<IResponse<Map<String, dynamic>>> querySubscriptionStatusPlatform() async {
    // iOS 不建议在此方法中调用 restorePurchases()
    // 原因：会产生事件洪泛，且可能触发 Apple ID 认证弹窗
    // 建议：用户应使用"恢复购买"按钮主动触发，或通过后端 API 查询订阅状态
    debugPrint('🍎 [iOS] querySubscriptionStatus() 不支持，请使用后端 API 或恢复购买');
    return PaymentResponse.failed(
      message: 'iOS 请使用后端 API 或"恢复购买"功能查询订阅状态',
    );
  }

  // ==================== 待处理购买检查 ====================

  @override
  Future<void> checkPendingPurchasesPlatform() async {
    // iOS 初始化时不主动调用 restorePurchases()
    // 原因：
    // 1. restorePurchases() 会返回所有历史购买，产生大量事件洪泛
    // 2. 可能触发 Apple ID 认证弹窗，影响用户体验
    // 3. purchaseStream 已经会自动接收未完成的交易
    // 4. 真正未完成的交易会在 purchaseStream 中以 pending 状态出现
    //
    // iOS 未完成交易的处理策略：
    // - 依赖 purchaseStream 自动推送（StoreKit 会在适当时机重发）
    // - 用户可通过"恢复购买"按钮主动触发
    // - 支付成功但未验证的订单通过 OrderSyncService 恢复
    debugPrint('🍎 [iOS] 初始化时跳过 restorePurchases()，'
        '依赖 purchaseStream 自动处理未完成交易');
  }

  // ==================== 从数据库创建 ProductDetails ====================

  @override
  ProductDetails? createProductDetailsFromDb(ProductEntry productEntry) {
    // iOS 目前不支持从数据库创建 ProductDetails
    // 因为 iOS 的 ProductDetails 需要从 StoreKit 获取
    debugPrint('⚠️ [iOS] 不支持从数据库创建 ProductDetails');
    return null;
  }

  // ==================== 资源释放 ====================

  @override
  void disposePlatform() {
    try {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          inAppPurchase!
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      iosPlatformAddition.setDelegate(null);
      debugPrint('iOS 支付队列代理已清理');
    } catch (e) {
      debugPrint('清理iOS支付队列代理时发生异常: $e');
    }
  }

  // ==================== 验证失败处理 ====================

  @override
  Future<void> handleVerificationFailurePlatform(PurchaseDetails purchase) async {
    // iOS 专用：即使验证失败也必须完成交易，避免 StoreKit 无限循环返回
    // 不完成交易会导致 StoreKit 不断返回同一笔待处理交易
    try {
      if (purchase.pendingCompletePurchase) {
        await inAppPurchase!.completePurchase(purchase);
        debugPrint('⚠️ [iOS] 验证失败但已完成交易，避免重复返回: ${purchase.purchaseID}');
      }
    } catch (e) {
      debugPrint('⚠️ [iOS] 完成交易失败: $e');
    }
  }

  // ==================== iOS 专有方法 ====================

  /// 刷新购买验证数据
  Future<IResponse<Map<String, dynamic>>> refreshPurchaseVerificationData() async {
    if (!await isAvailable()) {
      return PaymentResponse.failed(message: 'App Store 不可用');
    }

    try {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          inAppPurchase!
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();

      final PurchaseVerificationData? verificationData =
          await iosPlatformAddition.refreshPurchaseVerificationData();

      if (verificationData != null) {
        return PaymentResponse.success(
          message: '购买验证数据刷新成功',
          data: {
            'source': verificationData.source,
            'localVerificationData': verificationData.localVerificationData,
            'serverVerificationData': verificationData.serverVerificationData,
          },
        );
      } else {
        return PaymentResponse.failed(message: '无法获取购买验证数据');
      }
    } catch (e, s) {
      debugPrint('刷新购买验证数据失败: $e\n$s');
      return PaymentResponse.failed(message: '刷新购买验证数据失败: $e');
    }
  }

  /// 显示代码兑换界面
  Future<IResponse<Map<String, dynamic>>> presentCodeRedemptionSheet() async {
    if (!await isAvailable()) {
      return PaymentResponse.failed(message: 'App Store 不可用');
    }

    try {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          inAppPurchase!
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();

      await iosPlatformAddition.presentCodeRedemptionSheet();

      return PaymentResponse.success(
        message: '代码兑换界面已显示',
      );
    } catch (e, s) {
      debugPrint('显示代码兑换界面失败: $e\n$s');
      return PaymentResponse.failed(message: '显示代码兑换界面失败: $e');
    }
  }
}
