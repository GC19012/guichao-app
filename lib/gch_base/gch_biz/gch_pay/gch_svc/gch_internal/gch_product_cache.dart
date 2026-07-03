import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_providers/gch_product_providers.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_svc/gch_product_service.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_model/gch_product_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 产品缓存服务
/// 职责：
/// 1. 缓存产品数据到内存
/// 2. 根据平台智能加载产品
/// 3. 提供快速的产品查询接口
class ProductCache {
  final Map<String, ProductEntry> _products = {};
  final Ref? ref;
  bool _loaded = false;
  Future<void>? _initializing;
  StreamSubscription<List<ProductEntry>>? _subscription;

  ProductCache({this.ref});

  /// 是否已加载
  bool get isLoaded => _loaded;

  /// 获取所有缓存的产品
  Map<String, ProductEntry> get all => Map.unmodifiable(_products);

  /// 初始化产品缓存
  Future<void> initialize() async {
    if (_loaded || ref == null) return;
    if (_initializing != null) return _initializing!;

    _initializing = _doInitialize();
    try {
      await _initializing;
    } finally {
      _initializing = null;
    }
  }
  
  Future<void> _doInitialize() async {
    try {
      final productService = ref!.read(productServiceProvider);
      _startWatching(productService);
      debugPrint('🔍 初始化产品缓存（服务端优先）');

      // 1) 服务端优先路径（ProductRepository._tryGetFromServer）
      var result = await productService.getProducts();

      // 2) 回退：保持旧有平台优先路径
      if (result.isLeft()) {
        final platform = _detectPlatform();
        debugPrint('⚠️ 服务端优先获取失败，回退平台路径: $platform');
        result = await _getProductsByPlatform(productService, platform);
      }

      result.fold(
        (error) => debugPrint('❌ 产品获取失败: $error'),
        (products) {
          _updateCache(products, reason: '初始化');
        },
      );
    } catch (e) {
      debugPrint('❌ 产品缓存初始化失败: $e');
    }
  }

  /// 根据平台获取产品
  Future<Either<String, List<ProductEntry>>> _getProductsByPlatform(
    ProductService productService,
    String platform,
  ) async {
    switch (platform) {
      case 'google':
        return await productService.getProductsByPlatform(ProductPlatform.android);
      case 'apple':
        return await productService.getProductsByPlatform(ProductPlatform.ios);
      default:
        return await productService.getProducts();
    }
  }

  String _detectPlatform() => 'apple';

  /// 获取单个产品
  ProductEntry? get(String productId) => _products[productId];

  /// 检查产品是否存在
  bool contains(String productId) => _products.containsKey(productId);

  /// 批量获取产品
  List<ProductEntry> getMultiple(List<String> productIds) {
    return productIds
        .where((id) => _products.containsKey(id))
        .map((id) => _products[id]!)
        .toList();
  }

  /// 按平台筛选产品
  List<ProductEntry> getByPlatform(ProductPlatform platform) {
    return _products.values
        .where((product) => product.platform == platform)
        .toList();
  }

  /// 订阅仓库数据变更，保持缓存一致
  void _startWatching(ProductService productService) {
    if (_subscription != null) return;

    _subscription = productService.watchProducts().listen(
      (products) {
        _updateCache(products, reason: '仓库同步');
      },
      onError: (error) {
        debugPrint('⚠️ 产品缓存同步失败: $error');
      },
    );
  }

  void _updateCache(List<ProductEntry> products, {required String reason}) {
    _products.clear();
    for (final product in products) {
      _products[product.productId] = product;
    }
    _loaded = true;
    debugPrint('✅ 产品缓存更新完成($reason): ${products.length}个');
  }

  /// 刷新缓存
  Future<void> refresh() async {
    _loaded = false;
    _products.clear();
    _subscription?.cancel();
    _subscription = null;
    _initializing = null;
    await initialize();
  }

  /// 清空缓存
  void clear() {
    _products.clear();
    _loaded = false;
    _subscription?.cancel();
    _subscription = null;
    _initializing = null;
    debugPrint('✅ 产品缓存已清空');
  }
}
