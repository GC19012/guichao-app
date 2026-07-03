import 'package:drift/drift.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_model/gch_product_model.dart';
part 'gch_product_dao.g.dart';

/// 产品数据访问对象
@DriftAccessor(tables: [ProductEntries])
class ProductDao extends DatabaseAccessor<GchDatabase> with _$ProductDaoMixin {
  ProductDao(GchDatabase db) : super(db);

  /// 获取所有产品
  Future<List<ProductEntry>> getAllProducts() {
    return select(productEntries).get();
  }

  /// 根据ID获取产品
  Future<ProductEntry?> getProductById(int id) {
    return (select(productEntries)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  /// 根据产品ID获取产品
  Future<ProductEntry?> getProductByProductId(String productId) {
    return (select(productEntries)..where((p) => p.productId.equals(productId))).getSingleOrNull();
  }

  /// 根据平台获取产品
  Future<List<ProductEntry>> getProductsByPlatform(ProductPlatform platform) {
    return (select(productEntries)..where((p) => p.platform.equals(platform.value))).get();
  }

  /// 根据类型获取产品
  Future<List<ProductEntry>> getProductsByType(ProductType type) {
    return (select(productEntries)..where((p) => p.type.equals(type.value))).get();
  }

  /// 根据货币获取产品
  Future<List<ProductEntry>> getProductsByCurrency(String currency) {
    return (select(productEntries)..where((p) => p.currency.equals(currency))).get();
  }

  /// 创建产品
  Future<int> createProduct(ProductEntriesCompanion product) {
    return into(productEntries).insert(product);
  }

  /// 创建或更新产品（upsert）
  /// 如果 product_id 已存在，则更新现有记录
  Future<int> upsertProduct(ProductEntriesCompanion product) {
    return into(productEntries).insertOnConflictUpdate(product);
  }

  /// 批量创建或更新产品
  Future<void> upsertProducts(List<ProductEntriesCompanion> products) async {
    await batch((batch) {
      for (final product in products) {
        batch.insert(
          productEntries,
          product,
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// 更新产品
  Future<bool> updateProduct(ProductEntriesCompanion product) {
    return update(productEntries).replace(product);
  }

  /// 删除产品
  Future<int> deleteProduct(int id) {
    return (delete(productEntries)..where((p) => p.id.equals(id))).go();
  }

  /// 删除产品（根据产品ID）
  Future<int> deleteProductByProductId(String productId) {
    return (delete(productEntries)..where((p) => p.productId.equals(productId))).go();
  }

  /// 检查产品ID是否存在
  Future<bool> productIdExists(String productId) {
    return (select(productEntries)..where((p) => p.productId.equals(productId))).getSingleOrNull().then((product) => product != null);
  }

  /// 获取产品数量
  Future<int> getProductCount() {
    return (select(productEntries)..where((p) => p.id.isNotNull())).get().then((products) => products.length);
  }

  /// 获取订阅产品
  Future<List<ProductEntry>> getSubscriptionProducts() {
    return getProductsByType(ProductType.subscription);
  }

  /// 获取消耗品
  Future<List<ProductEntry>> getConsumableProducts() {
    return getProductsByType(ProductType.consumable);
  }

  /// 获取非消耗品
  Future<List<ProductEntry>> getNonConsumableProducts() {
    return getProductsByType(ProductType.nonConsumable);
  }

  /// 监听所有产品变化
  Stream<List<ProductEntry>> watchAllProducts() {
    return select(productEntries).watch();
  }

  /// 监听特定产品变化
  Stream<ProductEntry?> watchProductById(int id) {
    return (select(productEntries)..where((p) => p.id.equals(id))).watchSingleOrNull();
  }

  /// 监听特定平台产品变化
  Stream<List<ProductEntry>> watchProductsByPlatform(ProductPlatform platform) {
    return (select(productEntries)..where((p) => p.platform.equals(platform.value))).watch();
  }

  /// 监听特定类型产品变化
  Stream<List<ProductEntry>> watchProductsByType(ProductType type) {
    return (select(productEntries)..where((p) => p.type.equals(type.value))).watch();
  }
}
