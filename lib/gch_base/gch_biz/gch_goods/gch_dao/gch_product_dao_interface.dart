import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_model/gch_product_model.dart';

/// Product DAO 统一接口 - 类型安全的产品数据访问抽象
abstract interface class ProductDaoInterface {
  // 基础查询
  Future<List<ProductEntry>> getAllProducts();
  Future<ProductEntry?> getProductById(int id);
  Future<ProductEntry?> getProductByProductId(String productId);

  // 条件查询
  Future<List<ProductEntry>> getProductsByPlatform(ProductPlatform platform);
  Future<List<ProductEntry>> getProductsByType(ProductType type);
  Future<List<ProductEntry>> getProductsByCurrency(String currency);

  // 创建和更新
  Future<int> createProduct(ProductEntriesCompanion product);
  Future<int> upsertProduct(ProductEntriesCompanion product);
  Future<void> upsertProducts(List<ProductEntriesCompanion> products);
  Future<bool> updateProduct(ProductEntriesCompanion product);

  // 删除
  Future<int> deleteProduct(int id);
  Future<int> deleteProductByProductId(String productId);

  // 验证
  Future<bool> productIdExists(String productId);
  Future<int> getProductCount();

  // 快捷方法
  Future<List<ProductEntry>> getSubscriptionProducts();
  Future<List<ProductEntry>> getConsumableProducts();
  Future<List<ProductEntry>> getNonConsumableProducts();

  // 响应式
  Stream<List<ProductEntry>> watchAllProducts();
  Stream<ProductEntry?> watchProductById(int id);
  Stream<List<ProductEntry>> watchProductsByPlatform(ProductPlatform platform);
  Stream<List<ProductEntry>> watchProductsByType(ProductType type);
}
