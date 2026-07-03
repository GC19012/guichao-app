// iOS StoreKit 2 辅助函数
// 从 google_apple_pay_provider.dart 提取，保持所有逻辑不变

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

/// 获取 iOS 上当前所有有效订阅的产品ID列表
///
/// 用于判断用户是否有任何活跃订阅，以及具体是哪些产品
/// 会排除已被升级的订阅（isUpgraded=true）
Future<List<String>> getiOSActiveSubscriptions() async {
  try {
    final transactions = await SK2Transaction.transactions();
    final now = DateTime.now();

    return transactions
        .where((tx) {
          // 检查是否已被升级
          bool isUpgraded = false;
          try {
            if (tx.jsonRepresentation != null && tx.jsonRepresentation!.isNotEmpty) {
              final jsonData = json.decode(tx.jsonRepresentation!) as Map<String, dynamic>;
              isUpgraded = jsonData['isUpgraded'] == true;
            }
          } catch (e) {
            // JSON 解析失败不影响主逻辑
          }
          if (isUpgraded) return false; // 排除已升级的订阅

          final expStr = tx.expirationDate;
          if (expStr == null) return false;
          final exp = DateTime.tryParse(expStr);
          return exp != null && exp.isAfter(now);
        })
        .map((tx) => tx.productId)
        .toList();
  } catch (e) {
    debugPrint('⚠️ [iOS] 获取活跃订阅列表失败: $e');
    return [];
  }
}

/// 检查 iOS 上用户是否已订阅指定产品
///
/// 返回值：
/// - `null`: 未订阅该产品，可以继续购买
/// - `String`: 已订阅的产品ID（如果与请求的productId相同，说明重复订阅）
///
/// 使用 StoreKit 2 的 `SK2Transaction.transactions()` 获取所有当前有效交易
///
/// 根据 Apple StoreKit 2 文档：
/// - `transactions()` 返回用户所有有权限的交易
/// - `isUpgraded=true` 表示该订阅已被升级到更高等级
/// - 升级立即生效，降级在下次续订日期生效
Future<String?> checkiOSActiveSubscription(String productId) async {
  try {
    debugPrint('🍎 [iOS] 检查订阅状态，目标产品: $productId');

    // 获取所有当前有效的交易（StoreKit 2）
    final transactions = await SK2Transaction.transactions();
    debugPrint('🍎 [iOS] 获取到 ${transactions.length} 个有效交易');

    for (final tx in transactions) {
      // 解析 jsonRepresentation 获取更多信息（包括 isUpgraded）
      bool isUpgraded = false;
      String? subscriptionGroupId;
      try {
        if (tx.jsonRepresentation != null && tx.jsonRepresentation!.isNotEmpty) {
          final jsonData = json.decode(tx.jsonRepresentation!) as Map<String, dynamic>;
          isUpgraded = jsonData['isUpgraded'] == true;
          subscriptionGroupId = jsonData['subscriptionGroupID']?.toString() ?? tx.subscriptionGroupID;
        }
      } catch (e) {
        // JSON 解析失败不影响主逻辑
      }

      debugPrint('   - 产品: ${tx.productId}, 过期: ${tx.expirationDate}, '
          'isUpgraded: $isUpgraded, subscriptionGroup: ${subscriptionGroupId ?? tx.subscriptionGroupID}');

      // 如果交易已被升级，跳过（用户已升级到其他订阅）
      if (isUpgraded) {
        debugPrint('   ⏭️ 跳过已升级的交易: ${tx.productId}');
        continue;
      }

      // 检查是否是同一产品的有效订阅
      if (tx.productId == productId) {
        // 检查是否未过期
        final expirationDateStr = tx.expirationDate;
        if (expirationDateStr != null) {
          final expirationDate = DateTime.tryParse(expirationDateStr);
          if (expirationDate != null && expirationDate.isAfter(DateTime.now())) {
            debugPrint('🔔 [iOS] 发现已订阅同一产品: $productId, 过期时间: $expirationDate');
            return productId; // 返回已订阅的产品ID
          }
        }
      }
    }

    debugPrint('✅ [iOS] 未发现对 $productId 的有效订阅，可以继续购买');
    return null;
  } catch (e) {
    debugPrint('⚠️ [iOS] 检查订阅状态失败: $e');
    // 检查失败时不阻止购买，让 StoreKit 自己处理
    return null;
  }
}

/// 从 ProductDetails 获取订阅组ID（StoreKit 2）
///
/// 返回值：
/// - `String`: 订阅组ID
/// - `null`: 非订阅产品或无法获取
String? getSubscriptionGroupIdFromProduct(ProductDetails productDetails) {
  try {
    // StoreKit 2: 使用 AppStoreProduct2Details
    if (productDetails is AppStoreProduct2Details) {
      final sk2Product = productDetails.sk2Product;
      final groupId = sk2Product.subscription?.subscriptionGroupID;
      debugPrint('📦 [StoreKit2] 产品 ${productDetails.id} 的订阅组: $groupId');
      return groupId;
    }

    // StoreKit 1 回退: 使用 AppStoreProductDetails
    if (productDetails is AppStoreProductDetails) {
      final skProduct = productDetails.skProduct;
      final groupId = skProduct.subscriptionGroupIdentifier;
      debugPrint('📦 [StoreKit1] 产品 ${productDetails.id} 的订阅组: $groupId');
      return groupId;
    }

    debugPrint('⚠️ [订阅组] 产品类型不支持: ${productDetails.runtimeType}');
    return null;
  } catch (e) {
    debugPrint('⚠️ [订阅组] 获取订阅组ID失败: $e');
    return null;
  }
}

/// 检查目标产品是否与现有订阅在同一订阅组
///
/// 返回值：
/// - `SubscriptionGroupCheckResult` 包含详细信息
///
/// 这是生产可靠的实现：
/// 1. 从 ProductDetails 获取目标产品的 subscriptionGroupID
/// 2. 从已购交易获取现有订阅的 subscriptionGroupID
/// 3. 精确比较两者
class SubscriptionGroupCheckResult {
  final bool isSameGroup;
  final String? targetGroupId;
  final String? existingGroupId;
  final String? existingProductId;

  const SubscriptionGroupCheckResult({
    required this.isSameGroup,
    this.targetGroupId,
    this.existingGroupId,
    this.existingProductId,
  });
}

/// 检查目标产品是否与现有订阅在同一订阅组（精确版本）
///
/// 参数：
/// - `targetProductDetails`: 目标产品的详情（用于获取 subscriptionGroupID）
/// - `existingProductIds`: 现有活跃订阅的产品ID列表
///
/// 返回：检查结果，包含是否同组及详细信息
Future<SubscriptionGroupCheckResult> checkSameSubscriptionGroupPrecise(
  ProductDetails targetProductDetails,
  List<String> existingProductIds,
) async {
  try {
    // 1. 获取目标产品的订阅组ID
    final targetGroupId = getSubscriptionGroupIdFromProduct(targetProductDetails);
    if (targetGroupId == null) {
      debugPrint('⚠️ [订阅组检查] 目标产品无订阅组ID，可能不是订阅产品');
      return const SubscriptionGroupCheckResult(isSameGroup: false);
    }

    // 2. 从现有交易中获取订阅组ID
    final transactions = await SK2Transaction.transactions();

    for (final tx in transactions) {
      if (existingProductIds.contains(tx.productId)) {
        // 检查是否已被升级
        bool isUpgraded = false;
        String? groupId = tx.subscriptionGroupID;

        try {
          if (tx.jsonRepresentation != null && tx.jsonRepresentation!.isNotEmpty) {
            final jsonData = json.decode(tx.jsonRepresentation!) as Map<String, dynamic>;
            isUpgraded = jsonData['isUpgraded'] == true;
            groupId ??= jsonData['subscriptionGroupID']?.toString();
          }
        } catch (_) {}

        // 跳过已升级的订阅
        if (isUpgraded) continue;

        // 检查过期时间
        final expStr = tx.expirationDate;
        if (expStr == null) continue;
        final exp = DateTime.tryParse(expStr);
        if (exp == null || !exp.isAfter(DateTime.now())) continue;

        // 3. 精确比较订阅组ID
        if (groupId == targetGroupId) {
          debugPrint('✅ [订阅组检查] 同一订阅组: 目标=$targetGroupId, 现有=${tx.productId}');
          return SubscriptionGroupCheckResult(
            isSameGroup: true,
            targetGroupId: targetGroupId,
            existingGroupId: groupId,
            existingProductId: tx.productId,
          );
        }
      }
    }

    debugPrint('📊 [订阅组检查] 不在同一订阅组: 目标组=$targetGroupId');
    return SubscriptionGroupCheckResult(
      isSameGroup: false,
      targetGroupId: targetGroupId,
    );
  } catch (e) {
    debugPrint('⚠️ [订阅组检查] 检查失败: $e');
    return const SubscriptionGroupCheckResult(isSameGroup: false);
  }
}

/// 检查两个产品是否属于同一订阅组（简化版本 - 向后兼容）
///
/// 注意：此方法不够可靠，建议使用 checkSameSubscriptionGroupPrecise
/// 保留此方法是为了向后兼容
Future<bool> checkSameSubscriptionGroup(
  String targetProductId,
  List<String> existingProductIds,
) async {
  debugPrint('🔍 [订阅组检查-简化] 开始检查: target=$targetProductId, existing=$existingProductIds');

  try {
    // 从现有交易中获取订阅组ID
    final transactions = await SK2Transaction.transactions();
    debugPrint('🔍 [订阅组检查-简化] 获取到 ${transactions.length} 个交易');

    final existingGroupIds = <String>{};

    for (final tx in transactions) {
      debugPrint('   交易: productId=${tx.productId}, subscriptionGroupID=${tx.subscriptionGroupID}');

      if (existingProductIds.contains(tx.productId)) {
        String? groupId = tx.subscriptionGroupID;
        // 尝试从 jsonRepresentation 获取
        if (groupId == null && tx.jsonRepresentation != null) {
          try {
            final jsonData = json.decode(tx.jsonRepresentation!) as Map<String, dynamic>;
            groupId = jsonData['subscriptionGroupID']?.toString();
            debugPrint('   从JSON获取subscriptionGroupID: $groupId');
          } catch (e) {
            debugPrint('   JSON解析失败: $e');
          }
        }
        if (groupId != null) {
          existingGroupIds.add(groupId);
          debugPrint('   ✅ 添加订阅组ID: $groupId');
        } else {
          debugPrint('   ⚠️ 未能获取subscriptionGroupID');
        }
      }
    }

    // ⚠️ 注意：此处无法获取目标产品的订阅组ID，只能假设
    // 如果有任何活跃订阅，返回 true（保守策略）
    if (existingGroupIds.isNotEmpty) {
      debugPrint('📊 [订阅组检查-简化] 现有订阅组: $existingGroupIds');
      debugPrint('⚠️ [订阅组检查-简化] 无法确定目标产品订阅组，假设可能同组');
      return true;
    }

    debugPrint('⚠️ [订阅组检查-简化] 未找到任何订阅组ID，返回 false');
    return false;
  } catch (e) {
    debugPrint('⚠️ [订阅组检查] 检查失败: $e');
    return false;
  }
}

/// iOS 支付队列代理
class PaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
