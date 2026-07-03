import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_dao/gch_product_dao.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_dao/gch_product_dao_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_model/gch_product_model.dart';

/// SQLite ProductDao 适配器 - 零开销包装
final class SQLiteProductDaoAdapter implements ProductDaoInterface {
  SQLiteProductDaoAdapter(this._dao);
  final ProductDao _dao;

  @override
  Future<List<ProductEntry>> getAllProducts() => _dao.getAllProducts();

  @override
  Future<ProductEntry?> getProductById(int id) => _dao.getProductById(id);

  @override
  Future<ProductEntry?> getProductByProductId(String productId) => _dao.getProductByProductId(productId);

  @override
  Future<List<ProductEntry>> getProductsByPlatform(ProductPlatform platform) => _dao.getProductsByPlatform(platform);

  @override
  Future<List<ProductEntry>> getProductsByType(ProductType type) => _dao.getProductsByType(type);

  @override
  Future<List<ProductEntry>> getProductsByCurrency(String currency) => _dao.getProductsByCurrency(currency);

  @override
  Future<int> createProduct(ProductEntriesCompanion product) => _dao.createProduct(product);

  @override
  Future<int> upsertProduct(ProductEntriesCompanion product) => _dao.upsertProduct(product);

  @override
  Future<void> upsertProducts(List<ProductEntriesCompanion> products) => _dao.upsertProducts(products);

  @override
  Future<bool> updateProduct(ProductEntriesCompanion product) => _dao.updateProduct(product);

  @override
  Future<int> deleteProduct(int id) => _dao.deleteProduct(id);

  @override
  Future<int> deleteProductByProductId(String productId) => _dao.deleteProductByProductId(productId);

  @override
  Future<bool> productIdExists(String productId) => _dao.productIdExists(productId);

  @override
  Future<int> getProductCount() => _dao.getProductCount();

  @override
  Future<List<ProductEntry>> getSubscriptionProducts() => _dao.getSubscriptionProducts();

  @override
  Future<List<ProductEntry>> getConsumableProducts() => _dao.getConsumableProducts();

  @override
  Future<List<ProductEntry>> getNonConsumableProducts() => _dao.getNonConsumableProducts();

  @override
  Stream<List<ProductEntry>> watchAllProducts() => _dao.watchAllProducts();

  @override
  Stream<ProductEntry?> watchProductById(int id) => _dao.watchProductById(id);

  @override
  Stream<List<ProductEntry>> watchProductsByPlatform(ProductPlatform platform) => _dao.watchProductsByPlatform(platform);

  @override
  Stream<List<ProductEntry>> watchProductsByType(ProductType type) => _dao.watchProductsByType(type);
}
