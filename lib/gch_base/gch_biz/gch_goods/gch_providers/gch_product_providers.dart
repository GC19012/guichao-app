import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_store/gch_db_provider.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_api/gch_product_api.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_dao/gch_product_dao_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_dao/gch_sqlite_product_dao_adapter.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_repo/gch_product_repository.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_svc/gch_product_service.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_internal/gch_product_cache.dart';

part 'gch_product_providers.g.dart';

/// Product DAO Provider - SQLite 实现
@Riverpod(keepAlive: true)
ProductDaoInterface productDao(ProductDaoRef ref) {
  final db = ref.watch(gchDatabaseProvider);
  return SQLiteProductDaoAdapter(db.productDao);
}

/// 产品API Provider
@riverpod
ProductApi productApi(Ref ref) {
  return ProductApi(ref: ref);
}

/// InAppPurchase Provider - 后台异步初始化，不阻塞UI
/// 安全地获取 InAppPurchase 实例，处理可能的初始化错误
@riverpod
InAppPurchase? inAppPurchase(Ref ref) {

  try {
    // 🚀 使用后台任务异步初始化，立即返回
    Future.microtask(() {
      try {
        InAppPurchase.instance.isAvailable();
        debugPrint('✅ InAppPurchase 后台初始化完成');
      } catch (e) {
        debugPrint('⚠️ InAppPurchase 后台初始化失败: $e');
      }
    });
    return InAppPurchase.instance;
  } catch (e) {
    debugPrint('⚠️ InAppPurchase 不可用: $e');
    return null;
  }
}

/// 产品仓库 Provider
/// ⚠️ 使用 keepAlive: true 保持单例，避免内存缓存被重置
@Riverpod(keepAlive: true)
ProductRepositoryInterface productRepository(ProductRepositoryRef ref) {
  final dao = ref.watch(productDaoProvider);
  final api = ref.watch(productApiProvider);
  final iap = ref.watch(inAppPurchaseProvider);
  return ProductRepository(api, dao, iap);
}

/// 产品服务 Provider
@riverpod
ProductService productService(Ref ref) {
  final repository = ref.watch(productRepositoryProvider);
  return ProductService(repository);
}

/// 产品列表 Provider
@riverpod
Future<List<ProductEntry>> products(Ref ref) async {
  final service = ref.watch(productServiceProvider);
  final result = await service.getProducts();
  return result.fold(
    (error) => throw Exception(error),
    (products) => products,
  );
}

/// 产品缓存 Provider（应用级单例）
///
/// ✅ 优势：
/// - 实例级缓存，每个PaymentManager实例独立
/// - 支持清空操作，解决切账号/地区后数据污染问题
/// - 通过Provider管理生命周期，支持自动清理
///
/// 使用场景：
/// - 获取产品：`productCache.get(productId)`
/// - 检查存在：`productCache.contains(productId)`
/// - 刷新缓存：`productCache.refresh()`
/// - 清空缓存：`productCache.clear()` （切账号/地区时）
///
/// @Deprecated: 不要使用 PaymentManager.getProduct() 静态方法
@Riverpod(keepAlive: true)
ProductCache productCache(ProductCacheRef ref) {
  final cache = ProductCache(ref: ref);

  // 应用启动时自动初始化产品缓存
  Future.microtask(() async {
    await cache.initialize();
  });

  // Provider销毁时清空缓存
  ref.onDispose(() {
    cache.clear();
    debugPrint('✅ ProductCache 已清空（Provider销毁）');
  });

  return cache;
}
