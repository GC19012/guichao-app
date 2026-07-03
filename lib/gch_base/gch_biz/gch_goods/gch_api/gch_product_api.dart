import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_api/gch_providers/gch_api_client_providers.dart';
import 'package:guichao/gch_base/gch_biz/gch_api/gch_client/gch_api_client.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_model/gch_product_model.dart';

/// 产品API接口
class ProductApi {
  final Ref _ref;

  ProductApi({required Ref ref}) : _ref = ref;

  /// 获取API客户端
  DataApiClient get _apiClient => _ref.read(apiClientProvider);

  /// 初始化API客户端
  void initializeApiClient() {
    // 这里可以添加产品相关的API初始化逻辑
  }

  /// 从 JSON 创建 ProductEntry
  ProductEntry _productFromJson(Map<String, dynamic> json) {
    // 验证必需字段
    final id = json['id'];
    final productId = json['productid'];
    final title = json['title'];
    final price = json['price'];
    final priceFormatted = json['priceFormatted'];
    final currency = json['currency'];
    final platform = json['platform'];
    final type = json['type'];
    final priceId = json['priceId'] ?? json['priceid'];
    final promoInfo1 = json['promoinfo1'] ?? json['promoInfo1'];
    final promoInfo2 = json['promoinfo2'] ?? json['promoInfo2'];

    return ProductEntry(
      id: id is int ? id : int.parse(id.toString()),
      productId: productId.toString(),
      // priceId 可以为 null
      priceId: priceId?.toString(),
      title: title.toString(),
      // description 可以为 null
      description: json['description']?.toString(),
      price: price is num ? price.toDouble() : double.parse(price.toString()),
      priceFormatted: priceFormatted.toString(),
      currency: currency.toString(),
      platform: platform.toString(),
      type: type.toString(),
      // duration 可以为 null
      duration: json['duration'] is int
          ? json['duration'] as int
          : json['duration'] != null
              ? int.tryParse(json['duration'].toString())
              : null,
      title2: json['title2']?.toString(),
      title3: json['title3']?.toString(),
      description2: json['description2']?.toString(),
      description3: json['description3']?.toString(),
      promoinfo1: promoInfo1?.toString(),
      promoinfo2: promoInfo2?.toString(),
      visible: json['visible'] as bool? ?? true,
    );
  }
  
  /// 解析新的API响应格式
  List<ProductEntry> _parseProductsFromApiResponse(Map<String, dynamic> response) {
    try {
      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) return [];
      
      final productsJson = data['products'] as List<dynamic>? ?? [];
      return productsJson
          .whereType<Map<String, dynamic>>() // 过滤出有效的Map类型
          .map((json) {
            try {
              return _productFromJson(json);
            } catch (e) {
              // 记录单个产品解析失败，但不中断整个列表的处理
              print('Failed to parse product: $json, error: $e');
              return null;
            }
          })
          .whereType<ProductEntry>() // 过滤掉null值
          .toList();
    } catch (e) {
      print('Failed to parse products response: $response, error: $e');
      return [];
    }
  }

  void _logApiProducts(
    List<dynamic> productsJson,
    List<ProductEntry> products, {
    String? platform,
    String? type,
    required int page,
    required int pageSize,
  }) {
    debugPrint(
      '📦 [ProductApi] API products platform=$platform type=$type page=$page pageSize=$pageSize rawCount=${productsJson.length} parsedCount=${products.length}',
    );

    for (var i = 0; i < productsJson.length; i++) {
      final raw = productsJson[i];
      debugPrint('📦 [ProductApi] raw product[$i]: $raw');
    }

    for (var i = 0; i < products.length; i++) {
      final product = products[i];
      debugPrint('''
📦 [ProductApi] parsed product[$i]
  id=${product.id}
  productId=${product.productId}
  title=${product.title}
  description=${product.description}
  price=${product.price}
  priceFormatted=${product.priceFormatted}
  currency=${product.currency}
  platform=${product.platform}
  type=${product.type}
  duration=${product.duration}
  priceId=${product.priceId}
  title2=${product.title2}
  title3=${product.title3}
  description2=${product.description2}
  description3=${product.description3}
  promoinfo1=${product.promoinfo1}
  promoinfo2=${product.promoinfo2}
  visible=${product.visible}
''');
    }
  }
  

  /// 获取所有产品 - 使用新的POST接口
  Future<Response<Map<String, dynamic>>> getProducts({
    String? platform,
    String? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    final requestData = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };

    if (platform != null) requestData['platform'] = platform;
    if (type != null) requestData['type'] = type;

    debugPrint('📤 [ProductApi] getProducts 请求参数:');
    debugPrint('   - platform: $platform');
    debugPrint('   - type: $type');
    debugPrint('   - page: $page');
    debugPrint('   - pageSize: $pageSize');
    debugPrint('   - requestData: $requestData');

    return await _apiClient.post<Map<String, dynamic>>(
      '/api/v1/client-products/getproducts',
      data: requestData,
    );
  }




  /// 根据类型获取产品 - 极简化设计
  Future<List<ProductEntry>> getProductsByTypeList(ProductType type) async {
    return await getProductsList(
      type: type.value,
      pageSize: 1000, // 使用大的page_size获取所有产品
    );
  }





  /// 分页获取产品 - 更新为新的POST接口
  Future<Response<Map<String, dynamic>>> getProductsPaginated({
    int page = 1,
    int pageSize = 20,
    String? platform,
    String? type,
  }) async {
    return await getProducts(
      page: page,
      pageSize: pageSize,
      platform: platform,
      type: type,
    );
  }
  
  /// 便捷方法：直接获取产品列表
  Future<List<ProductEntry>> getProductsList({
    String? platform,
    String? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await getProducts(
      platform: platform,
      type: type,
      page: page,
      pageSize: pageSize,
    );
    
    if (response.data == null) return [];
    final data = response.data!['data'] as Map<String, dynamic>?;
    final productsJson = data?['products'] as List<dynamic>? ?? const [];
    final products = _parseProductsFromApiResponse(response.data!);
    _logApiProducts(
      productsJson,
      products,
      platform: platform,
      type: type,
      page: page,
      pageSize: pageSize,
    );
    return products;
  }
  
  /// 获取指定平台的所有产品（不分页）
  Future<List<ProductEntry>> getAllProductsByPlatform(String platform) async {
    return await getProductsList(
      platform: platform,
      pageSize: 1000, // 使用大的page_size获取所有产品
    );
  }
  
  /// 便捷方法：根据平台获取产品列表
  Future<List<ProductEntry>> getProductsByPlatformList(ProductPlatform platform) async {
    // 直接使用所有产品接口，极简化设计
    return await getAllProductsByPlatform(platform.value);
  }

  // 保留原有的本地模拟方法作为备用
  /// 获取所有产品（本地模拟）
  Future<Either<String, List<ProductEntry>>> getProductsLocal() async {
    // 模拟API调用
    await Future.delayed(const Duration(milliseconds: 500));

    return Right([
      ProductEntry(
        id: 1,
        productId: 'premium_monthly',
        title: '高级会员月卡',
        description: '享受高级功能，每月自动续费',
        price: 9.99,
        priceFormatted: '\$9.99',
        currency: 'USD',
        platform: ProductPlatform.android.value,
        type: ProductType.subscription.value,
        duration: 30,
        visible: true,
      ),
      ProductEntry(
        id: 2,
        productId: 'premium_yearly',
        title: '高级会员年卡',
        description: '享受高级功能，每年自动续费，更优惠',
        price: 99.99,
        priceFormatted: '\$99.99',
        currency: 'USD',
        platform: ProductPlatform.android.value,
        type: ProductType.subscription.value,
        duration: 365,
        visible: true,
      ),
      ProductEntry(
        id: 3,
        productId: 'coins_100',
        title: '100金币',
        description: '购买100个金币用于应用内消费',
        price: 0.99,
        priceFormatted: '\$0.99',
        currency: 'USD',
        platform: ProductPlatform.android.value,
        type: ProductType.consumable.value,
        duration: null,
        visible: true,
      ),
      ProductEntry(
        id: 4,
        productId: 'remove_ads',
        title: '移除广告',
        description: '永久移除应用内所有广告',
        price: 4.99,
        priceFormatted: '\$4.99',
        currency: 'USD',
        platform: ProductPlatform.android.value,
        type: ProductType.nonConsumable.value,
        duration: null,
        visible: true,
      ),
    ]);
  }

  /// 根据ID获取产品（本地模拟）
  Future<Either<String, ProductEntry?>> getProductByIdLocal(int id) async {
    final products = await getProductsLocal();
    return products.fold(
      (error) => Left(error),
      (products) => Right(products.where((p) => p.id == id).firstOrNull),
    );
  }

  /// 根据产品ID获取产品（本地模拟）
  Future<Either<String, ProductEntry?>> getProductByProductIdLocal(String productId) async {
    final products = await getProductsLocal();
    return products.fold(
      (error) => Left(error),
      (products) => Right(products.where((p) => p.productId == productId).firstOrNull),
    );
  }

  /// 根据平台获取产品（本地模拟）
  Future<Either<String, List<ProductEntry>>> getProductsByPlatformLocal(ProductPlatform platform) async {
    final products = await getProductsLocal();
    return products.fold(
      (error) => Left(error),
      (products) => Right(products.where((p) => p.platform == platform.value).toList()),
    );
  }

  /// 根据类型获取产品（本地模拟）
  Future<Either<String, List<ProductEntry>>> getProductsByTypeLocal(ProductType type) async {
    final products = await getProductsLocal();
    return products.fold(
      (error) => Left(error),
      (products) => Right(products.where((p) => p.type == type.value).toList()),
    );
  }

  /// 创建产品（本地模拟）
  Future<Either<String, ProductEntry>> createProductLocal(ProductEntriesCompanion product) async {
    // 模拟API调用
    await Future.delayed(const Duration(milliseconds: 300));

    // 这里应该调用真实的API
    return Left('创建产品功能暂未实现');
  }

  /// 更新产品（本地模拟）
  Future<Either<String, bool>> updateProductLocal(ProductEntriesCompanion product) async {
    // 模拟API调用
    await Future.delayed(const Duration(milliseconds: 300));

    // 这里应该调用真实的API
    return Left('更新产品功能暂未实现');
  }

  /// 删除产品（本地模拟）
  Future<Either<String, bool>> deleteProductLocal(int id) async {
    // 模拟API调用
    await Future.delayed(const Duration(milliseconds: 300));

    // 这里应该调用真实的API
    return Left('删除产品功能暂未实现');
  }
}
