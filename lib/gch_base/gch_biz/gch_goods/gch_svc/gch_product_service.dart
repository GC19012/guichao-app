import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:drift/drift.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_repo/gch_product_repository.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_model/gch_product_model.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';

/// 产品业务服务类 - 使用 ApiClient 和 ProductEntry
class ProductService {
  final ProductRepositoryInterface _repository;

  ProductService(this._repository);

  /// 初始化API客户端
  void initializeApiClient() {
    if (_repository is ProductRepository) {
      _repository.initializeApiClient();
    }
  }

  // ============================================================================
  // 基础产品操作
  // ============================================================================

  /// 获取所有产品
  Future<Either<String, List<ProductEntry>>> getProducts() async {
    return await _repository.getProducts();
  }

  /// 根据平台获取产品
  Future<Either<String, List<ProductEntry>>> getProductsByPlatform(ProductPlatform platform) async {
    return await _repository.getProductsByPlatform(platform);
  }

  /// 根据类型获取产品
  Future<Either<String, List<ProductEntry>>> getProductsByType(ProductType type) async {
    return await _repository.getProductsByType(type);
  }

  /// 获取所有产品的流
  Stream<List<ProductEntry>> watchProducts() {
    return _repository.watchAllProducts();
  }

  /// 按平台获取产品的流
  Stream<List<ProductEntry>> watchProductsByPlatform(ProductPlatform platform) {
    return _repository.watchProductsByPlatform(platform);
  }

  /// 按产品类型获取产品的流
  Stream<List<ProductEntry>> watchProductsByType(ProductType type) {
    return _repository.watchProductsByType(type);
  }

  // ============================================================================
  // 产品创建和更新
  // ============================================================================

  /// 创建新产品
  Future<Either<String, ProductEntry>> createProduct({
    required int id,
    required String productId,
    required String title,
    String? description,
    required double price,
    required String priceFormatted,
    String currency = 'USD',
    required ProductPlatform platform,
    required ProductType type,
    int? duration,
  }) async {
    // 创建产品对象
    final product = ProductEntriesCompanion.insert(
      id: Value(id),
      productId: productId,
      title: title,
      description: Value(description),
      price: price,
      priceFormatted: priceFormatted,
      currency: currency,
      platform: platform.value,
      type: type.value,
      duration: Value(duration),
    );

    // 执行业务规则验证
    final validationResult = _validateProduct(product);
    if (validationResult != null) {
      return Left(validationResult);
    }

    return await _repository.createProduct(product);
  }

  /// 更新产品
  Future<Either<String, bool>> updateProduct(ProductEntriesCompanion product) async {
    // 执行业务规则验证
    final validationResult = _validateProduct(product);
    if (validationResult != null) {
      return Left(validationResult);
    }

    return await _repository.updateProduct(product);
  }

  /// 删除产品
  Future<Either<String, bool>> deleteProduct(int id) async {
    return await _repository.deleteProduct(id);
  }


  // ============================================================================
  // 业务逻辑和验证
  // ============================================================================

  /// 验证产品数据
  String? _validateProduct(ProductEntriesCompanion product) {
    // 验证产品ID
    if (product.productId.value.isEmpty) {
      return '产品ID不能为空';
    }

    // 验证标题
    if (product.title.value.isEmpty) {
      return '产品标题不能为空';
    }

    // 验证价格
    if (product.price.value <= 0) {
      return '产品价格必须大于0';
    }

    // 验证价格格式
    if (product.priceFormatted.value.isEmpty) {
      return '价格格式不能为空';
    }

    // 验证货币
    if (product.currency.value.isEmpty) {
      return '货币代码不能为空';
    }

    // 验证平台
    if (product.platform.value.isEmpty) {
      return '平台不能为空';
    }

    // 验证类型
    if (product.type.value.isEmpty) {
      return '产品类型不能为空';
    }

    // 验证订阅时长（仅订阅类型需要）
    if (product.type.value == ProductType.subscription.value) {
      if (product.duration.value == null || product.duration.value! <= 0) {
        return '订阅产品必须设置有效的订阅时长';
      }
    }

    return null;
  }

  /// 获取产品统计信息
  Future<Map<String, dynamic>> getProductStats() async {
    final products = await getProducts();
    return products.fold(
      (error) => {'error': error},
      (products) {
        final totalProducts = products.length;
        final subscriptionProducts = products.where((p) => p.type == ProductType.subscription.value).length;
        final consumableProducts = products.where((p) => p.type == ProductType.consumable.value).length;
        final nonConsumableProducts = products.where((p) => p.type == ProductType.nonConsumable.value).length;
        final androidProducts = products.where((p) => p.platform == ProductPlatform.android.value).length;
        final iosProducts = products.where((p) => p.platform == ProductPlatform.ios.value).length;

        return {
          'totalProducts': totalProducts,
          'subscriptionProducts': subscriptionProducts,
          'consumableProducts': consumableProducts,
          'nonConsumableProducts': nonConsumableProducts,
          'androidProducts': androidProducts,
          'iosProducts': iosProducts,
        };
      },
    );
  }

  /// 搜索产品
  Future<Either<String, List<ProductEntry>>> searchProducts({
    required String searchTerm,
    ProductPlatform? platform,
    ProductType? type,
    double? minPrice,
    double? maxPrice,
  }) async {
    final products = await getProducts();
    return products.fold(
      (error) => Left(error),
      (products) {
        var filteredProducts = products.where((product) {
          // 搜索词匹配
          final matchesSearch = product.title.toLowerCase().contains(searchTerm.toLowerCase()) || (product.description?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false) || product.productId.toLowerCase().contains(searchTerm.toLowerCase());

          if (!matchesSearch) return false;

          // 平台过滤
          if (platform != null && product.platform != platform.value) return false;

          // 类型过滤
          if (type != null && product.type != type.value) return false;

          // 价格过滤
          if (minPrice != null && product.price < minPrice) return false;
          if (maxPrice != null && product.price > maxPrice) return false;

          return true;
        }).toList();

        return Right(filteredProducts);
      },
    );
  }

  // ============================================================================
  // 分页功能
  // ============================================================================

  /// 分页获取产品
  Future<Either<String, Map<String, dynamic>>> getProductsPaginated({
    String? platform,
    String? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (_repository is ProductRepository) {
      return await _repository.getProductsPaginated(
        platform: platform,
        type: type,
        page: page,
        pageSize: pageSize,
      );
    }
    return Left('仓库不支持分页功能');
  }

  /// 便捷方法：仅获取产品列表（分页）
  Future<Either<String, List<ProductEntry>>> getProductsListPaginated({
    String? platform,
    String? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await getProductsPaginated(
      platform: platform,
      type: type,
      page: page,
      pageSize: pageSize,
    );
    
    return result.fold(
      (error) => Left(error),
      (data) => Right(data['products'] as List<ProductEntry>),
    );
  }
}
