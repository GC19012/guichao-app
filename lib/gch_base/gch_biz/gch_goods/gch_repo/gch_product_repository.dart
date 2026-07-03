import 'package:fpdart/fpdart.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_api/gch_product_api.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_dao/gch_product_dao_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_model/gch_product_model.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
/// 产品仓库接口 - 极简化设计
abstract class ProductRepositoryInterface {
  // 基础获取接口
  Future<Either<String, List<ProductEntry>>> getProducts();
  Future<Either<String, List<ProductEntry>>> getProductsByPlatform(ProductPlatform platform);
  Future<Either<String, List<ProductEntry>>> getProductsByType(ProductType type);
  
  // 数据监听
  Stream<List<ProductEntry>> watchAllProducts();
  Stream<List<ProductEntry>> watchProductsByPlatform(ProductPlatform platform);
  Stream<List<ProductEntry>> watchProductsByType(ProductType type);
  
  // 本地CRUD操作
  Future<Either<String, ProductEntry>> createProduct(ProductEntriesCompanion product);
  Future<Either<String, ProductEntry>> upsertProduct(ProductEntriesCompanion product);
  Future<Either<String, bool>> updateProduct(ProductEntriesCompanion product);
  Future<Either<String, bool>> deleteProduct(int id);
  
  // 分页接口
  Future<Either<String, Map<String, dynamic>>> getProductsPaginated({
    String? platform,
    String? type,
    int page = 1,
    int pageSize = 20,
  });
}

/// 产品仓库实现
class ProductRepository implements ProductRepositoryInterface {
  final ProductApi _api;
  final ProductDaoInterface _dao; // ✅ 类型安全：支持任何实现 ProductDaoInterface 的 DAO
  final InAppPurchase? _inAppPurchase;

  // 内存缓存
  final Map<String, ProductDetails> _iapCache = {};
  final Map<String, ProductEntry> _productCache = {};
  
  // 缓存时间戳（1小时过期）
  DateTime? _lastCacheTime;
  static const Duration _cacheExpiration = Duration(hours: 1);

  ProductRepository(this._api, this._dao, [this._inAppPurchase]);

  /// 初始化API客户端
  void initializeApiClient() {
    _api.initializeApiClient();
  }

  /// 清除产品缓存（用于强制刷新）
  void clearCache() {
    debugPrint('🧹 [ProductRepository] 清除产品缓存');
    _productCache.clear();
    _iapCache.clear();
    _lastCacheTime = null;
  }

  @override
  Future<Either<String, List<ProductEntry>>> getProducts() async {
    debugPrint('📦 [ProductRepository] getProducts() 调用');
    try {
      //🚀 快速路径：缓存命中立即返回 + 后台同步（不改变原逻辑）
      final cacheResult = _tryGetFromCache();
      if (cacheResult.isRight()) {
        debugPrint('✅ 从缓存快速返回，后台同步服务端');
        _backgroundSync(); // 异步后台同步，不阻塞返回
        return cacheResult;
      }

      debugPrint('🔍 缓存未命中，执行完整获取流程');

      // 🥇 第一优先级：从服务端获取最新数据
      final serverResult = await _tryGetFromServer();
      if (serverResult.isRight()) {
        debugPrint('✅ 从服务端获取产品列表');
        return serverResult;
      }

      // 🥈 第二优先级：服务端失败，尝试从应用商店获取
      final iapResult = await _tryGetFromInAppPurchase();
      if (iapResult.isRight()) {
        debugPrint('✅ 服务端失败，从应用商店获取产品列表');
        return iapResult;
      }

      // 🥉 第三优先级：从本地数据库获取（兜底方案）
      // 注意：缓存检查已在开头执行，这里不再重复
      final localResult = await _tryGetFromDatabase();
      if (localResult.isRight()) {
        debugPrint('✅ 降级到本地数据库获取产品列表');
        return localResult;
      }

      debugPrint('❌ 所有数据源都不可用');
      return const Left('所有数据源都不可用');

    } catch (e) {
      debugPrint('❌ 获取产品列表异常: $e');
      return Left('获取产品列表失败: $e');
    }
  }

  /// 🥇 从 IAP 获取
  Future<Either<String, List<ProductEntry>>> _tryGetFromInAppPurchase() async {
    try {
      if (_inAppPurchase == null) {
        debugPrint('⚠️ InAppPurchase 实例为 null，跳过 IAP 获取');
        return const Left('IAP实例不可用');
      }
      
      if (!await _inAppPurchase.isAvailable()) {
        debugPrint('⚠️ InAppPurchase 服务不可用');
        return const Left('IAP服务不可用');
      }
      final ids = await _getStoreProductIds();
      if (ids.isEmpty) return const Left('无可用商品ID，需先从服务端同步');

      final response = await _inAppPurchase.queryProductDetails(ids);
      if (response.error != null) {
        return Left('IAP查询失败: ${response.error!.message}');
      }

      if (response.productDetails.isEmpty) {
        return const Left('IAP无商品');
      }

      final products = <ProductEntry>[];
      for (final pd in response.productDetails) {
        _iapCache[pd.id] = pd;
        final entry = _toProductEntry(pd);
        if (entry != null) {
          products.add(entry);
          _productCache[pd.id] = entry;
        }
      }

      _lastCacheTime = DateTime.now();
      _saveToDb(products);
      return Right(products);
    } catch (e) {
      return Left('IAP异常: $e');
    }
  }

  /// 🥈 从缓存获取
  Either<String, List<ProductEntry>> _tryGetFromCache() {
    if (_lastCacheTime == null ||
        DateTime.now().difference(_lastCacheTime!) > _cacheExpiration ||
        _productCache.isEmpty) {
      return const Left('缓存无效');
    }
    return Right(_productCache.values.where((p) => p.visible).toList());
  }

  /// 🥉 从数据库获取
  Future<Either<String, List<ProductEntry>>> _tryGetFromDatabase() async {
    try {
      final products = await _dao.getAllProducts();
      if (products.isEmpty) return const Left('数据库为空');

      for (final p in products) {
        _productCache[p.productId] = p;
      }
      _lastCacheTime = DateTime.now();
      // 仅返回 visible=true 的产品给 UI 层
      final visible = products.where((p) => p.visible).toList();
      if (visible.isEmpty) return const Left('数据库为空');
      return Right(visible);
    } catch (e) {
      return Left('数据库失败: $e');
    }
  }

  /// 🏆 从服务器获取 - 极简化设计
  Future<Either<String, List<ProductEntry>>> _tryGetFromServer() async {
    try {
      // 根据当前平台确定 platform 参数
      // Android 传入 'google'，iOS 传入 'apple'
      final platform = _getCurrentPlatform();
      debugPrint('📡 从服务器获取产品列表，platform: $platform');

      final products = await _api.getProductsList(platform: platform);

      if (products.isEmpty) {
        return const Left('服务器无数据');
      }

      await _saveToDb(products); // 保存全量（含 visible=false）
      for (final p in products) {
        _productCache[p.productId] = p;
      }
      _lastCacheTime = DateTime.now();
      // 仅返回 visible=true 的产品给 UI 层
      return Right(products.where((p) => p.visible).toList());
    } catch (e) {
      return Left('服务器失败: $e');
    }
  }

  String? _getCurrentPlatform() => ProductPlatform.ios.value;

  /// 从缓存或数据库获取已知商品的应用商店 ID
  ///
  /// 这些 ID 来源于服务端同步，避免硬编码，商品变更时自动跟随服务端更新。
  Future<Set<String>> _getStoreProductIds() async {
    // 优先从内存缓存
    if (_productCache.isNotEmpty) {
      return _productCache.values.map((p) => p.productId).toSet();
    }
    // 降级：从本地数据库
    final products = await _dao.getAllProducts();
    return products.map((p) => p.productId).toSet();
  }

  /// 转换为ProductEntry
  /// 当服务端缓存存在时使用服务端 ID；否则生成确定性负数 ID 用于 IAP-only 降级路径。
  /// 负数 ID 表示"未经服务端确认"，前端在 PrePay 时会将其转为 0 并依赖 product_code 让后端解析。
  ProductEntry? _toProductEntry(ProductDetails pd) {
    // 从缓存中查找对应的服务端产品以获取正确的 ID
    final serverProduct = _productCache[pd.id];
    if (serverProduct != null) {
      // 服务端标记 visible=false 的产品不展示
      if (!serverProduct.visible) return null;
      return ProductEntry(
        id: serverProduct.id, // 使用服务端的 ID
        productId: pd.id,
        title: pd.title,
        description: pd.description.isNotEmpty ? pd.description : null,
        price: pd.rawPrice,
        priceFormatted: pd.price,
        currency: pd.currencyCode,
        platform: ProductPlatform.ios.value,
        type: _getType(pd.id).value,
        duration: _getDuration(pd.id),
        priceId: serverProduct.priceId,
        title2: serverProduct.title2,
        title3: serverProduct.title3,
        description2: serverProduct.description2,
        description3: serverProduct.description3,
        promoinfo1: serverProduct.promoinfo1,
        promoinfo2: serverProduct.promoinfo2,
        visible: serverProduct.visible,
      );
    }

    // IAP-only 降级路径：生成确定性负数 ID 避免 Drift PK 冲突
    final syntheticId = -(pd.id.hashCode.abs() + 1);
    debugPrint('⚠️ IAP-only 产品 ${pd.id}，使用合成 ID: $syntheticId');
    return ProductEntry(
      id: syntheticId,
      productId: pd.id,
      title: pd.title,
      description: pd.description.isNotEmpty ? pd.description : null,
      price: pd.rawPrice,
      priceFormatted: pd.price,
      currency: pd.currencyCode,
      platform: ProductPlatform.ios.value,
      type: _getType(pd.id).value,
      duration: _getDuration(pd.id),
      visible: true,
    );
  }

  ProductType _getType(String id) {
    if (id.contains('monthly') || id.contains('yearly')) return ProductType.subscription;
    if (id.contains('lifetime')) return ProductType.nonConsumable;
    return ProductType.consumable;
  }

  int? _getDuration(String id) {
    if (id.contains('monthly')) return 30;
    if (id.contains('yearly')) return 365;
    return null;
  }

  /// 保存到数据库（批量写入，单事务只触发一次 watch stream）
  Future<void> _saveToDb(List<ProductEntry> products) async {
    try {
      await _dao.upsertProducts(
        products.map((p) => ProductEntriesCompanion.insert(
          id: Value(p.id),
          productId: p.productId,
          title: p.title,
          description: Value(p.description),
          price: p.price,
          priceFormatted: p.priceFormatted,
          currency: p.currency,
          platform: p.platform,
          type: p.type,
          duration: Value(p.duration),
          title2: Value(p.title2),
          title3: Value(p.title3),
          description2: Value(p.description2),
          description3: Value(p.description3),
          promoinfo1: Value(p.promoinfo1),
          promoinfo2: Value(p.promoinfo2),
          visible: Value(p.visible),
        )).toList(),
      );
    } catch (e) {
      debugPrint('保存失败: $e');
    }
  }

  /// 后台同步服务端数据（不阻塞UI）
  void _backgroundSync() {
    Future.microtask(() async {
      try {
        final serverResult = await _tryGetFromServer();
        serverResult.fold(
          (error) => debugPrint('后台同步失败: $error'),
          (products) => debugPrint('✅ 后台同步完成: ${products.length}个产品'),
        );
      } catch (e) {
        debugPrint('后台同步异常: $e');
      }
    });
  }

  // ============================================================================
  // 本地CRUD操作
  // ============================================================================

  @override
  Future<Either<String, ProductEntry>> createProduct(ProductEntriesCompanion product) async {
    try {
      final createdId = await _dao.createProduct(product);
      // 根据ID获取完整的ProductEntry
      final createdProduct = await _dao.getProductById(createdId);
      if (createdProduct != null) {
        return Right(createdProduct);
      } else {
        return const Left('创建产品后无法获取产品信息');
      }
    } catch (e) {
      return Left('创建产品失败: $e');
    }
  }

  @override
  Future<Either<String, ProductEntry>> upsertProduct(ProductEntriesCompanion product) async {
    try {
      final upsertedId = await _dao.upsertProduct(product);
      // 根据ID获取完整的ProductEntry
      final upsertedProduct = await _dao.getProductById(upsertedId);
      if (upsertedProduct != null) {
        return Right(upsertedProduct);
      } else {
        // 如果通过ID找不到，尝试通过product_id获取
        final productId = product.productId.value;
        final productByProductId = await _dao.getProductByProductId(productId);
        if (productByProductId != null) {
          return Right(productByProductId);
        }
        return const Left('创建或更新产品后无法获取产品信息');
      }
    } catch (e) {
      return Left('创建或更新产品失败: $e');
    }
  }

  @override
  Future<Either<String, bool>> updateProduct(ProductEntriesCompanion product) async {
    try {
      await _dao.updateProduct(product);
      return const Right(true);
    } catch (e) {
      return Left('更新产品失败: $e');
    }
  }

  @override
  Future<Either<String, bool>> deleteProduct(int id) async {
    try {
      await _dao.deleteProduct(id);
      return const Right(true);
    } catch (e) {
      return Left('删除产品失败: $e');
    }
  }

  @override
  Future<Either<String, List<ProductEntry>>> getProductsByPlatform(ProductPlatform platform) async {
    try {
      debugPrint('🔍 按平台获取产品: ${platform.value}，服务端优先策略');

      // 🥇 优先从服务端获取最新数据
      try {
        final apiProducts = await _api.getAllProductsByPlatform(platform.value);
        if (apiProducts.isNotEmpty) {
          debugPrint('✅ 从服务端获取平台产品并同步到本地');
          await _saveToDb(apiProducts);
          final visible = apiProducts.where((p) => p.visible).toList();
          return Right(visible);
        }
      } catch (e) {
        debugPrint('⚠️ 服务端获取平台产品失败: $e');
      }

      // 🥈 降级：从本地数据库获取
      final localProducts = await _dao.getProductsByPlatform(platform);
      if (localProducts.isNotEmpty) {
        debugPrint('✅ 降级到本地数据库获取平台产品');
        return Right(localProducts.where((p) => p.visible).toList());
      }

      return const Left('无法获取平台产品数据');
    } catch (e) {
      return Left('获取平台产品失败: $e');
    }
  }

  @override
  Future<Either<String, List<ProductEntry>>> getProductsByType(ProductType type) async {
    try {
      debugPrint('🔍 按类型获取产品: ${type.value}，服务端优先策略');

      // 🥇 优先从服务端获取最新数据
      try {
        final apiProducts = await _api.getProductsByTypeList(type);
        if (apiProducts.isNotEmpty) {
          debugPrint('✅ 从服务端获取类型产品并同步到本地');
          await _saveToDb(apiProducts);
          final visible = apiProducts.where((p) => p.visible).toList();
          return Right(visible);
        }
      } catch (e) {
        debugPrint('⚠️ 服务端获取类型产品失败: $e');
      }

      // 🥈 降级：从本地数据库获取
      final localProducts = await _dao.getProductsByType(type);
      if (localProducts.isNotEmpty) {
        debugPrint('✅ 降级到本地数据库获取类型产品');
        return Right(localProducts.where((p) => p.visible).toList());
      }

      return const Left('无法获取类型产品数据');
    } catch (e) {
      return Left('获取类型产品失败: $e');
    }
  }

  @override
  Stream<List<ProductEntry>> watchAllProducts() {
    return _dao.watchAllProducts().map((list) => list.where((p) => p.visible).toList());
  }


  @override
  Stream<List<ProductEntry>> watchProductsByPlatform(ProductPlatform platform) {
    return _dao.watchProductsByPlatform(platform);
  }

  @override
  Stream<List<ProductEntry>> watchProductsByType(ProductType type) {
    return _dao.watchProductsByType(type);
  }




  @override
  Future<Either<String, Map<String, dynamic>>> getProductsPaginated({
    String? platform,
    String? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _api.getProducts(
        platform: platform,
        type: type,
        page: page,
        pageSize: pageSize,
      );
      
      if (response.data == null) {
        return const Left('API返回空数据');
      }
      
      // 检查响应格式
      final responseData = response.data!;
      final code = responseData['code'] as int?;
      final msg = responseData['msg'] as String?;
      
      if (code != 0) {
        return Left('API错误: ${msg ?? '未知错误'}');
      }
      
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        return const Left('响应数据格式错误');
      }
      
      // 解析产品列表
      final productsJson = data['products'] as List<dynamic>? ?? [];
      final products = productsJson
          .map((json) => _productFromJsonWithPriceid(json as Map<String, dynamic>))
          .toList();
      
      // 缓存产品数据
      for (final product in products) {
        _productCache[product.productId] = product;
      }
      _lastCacheTime = DateTime.now();
      
      // 保存到本地数据库
      await _saveToDb(products);
      
      // 返回完整的分页信息
      return Right({
        'products': products,
        'total': data['total'] ?? 0,
        'page': data['page'] ?? page,
        'page_size': data['page_size'] ?? pageSize,
      });
    } catch (e) {
      return Left('获取分页产品失败: $e');
    }
  }

  /// 从JSON创建ProductEntry的辅助方法（包含priceid字段）
  ProductEntry _productFromJsonWithPriceid(Map<String, dynamic> json) {
    final productId = json['productId'] ?? json['productid'];
    final priceId = json['priceid'] ?? json['priceId'];
    final promoInfo1 = json['promoinfo1'] ?? json['promoInfo1'];
    final promoInfo2 = json['promoinfo2'] ?? json['promoInfo2'];
    return ProductEntry(
      id: json['id'] as int,
      productId: productId as String,
      priceId: priceId as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      priceFormatted: json['priceFormatted'] as String,
      currency: json['currency'] as String,
      platform: json['platform'] as String,
      type: json['type'] as String,
      duration: json['duration'] as int?,
      title2: json['title2'] as String?,
      title3: json['title3'] as String?,
      description2: json['description2'] as String?,
      description3: json['description3'] as String?,
      promoinfo1: promoInfo1 as String?,
      promoinfo2: promoInfo2 as String?,
      visible: json['visible'] as bool? ?? true,
    );
  }
}
