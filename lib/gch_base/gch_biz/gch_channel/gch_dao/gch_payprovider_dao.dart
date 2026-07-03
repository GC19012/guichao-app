import 'package:drift/drift.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_model/gch_payprovider_model.dart';

part 'gch_payprovider_dao.g.dart';

/// 支付渠道数据访问对象
@DriftAccessor(tables: [PayProviderEntries])
class PayProviderDao extends DatabaseAccessor<GchDatabase> with _$PayProviderDaoMixin {
  PayProviderDao(GchDatabase db) : super(db);

  /// 获取所有支付渠道
  Future<List<PayProviderEntry>> getAllPayProviders() {
    return select(payProviderEntries).get();
  }

  /// 根据ID获取支付渠道
  Future<PayProviderEntry?> getPayProviderById(int id) {
    return (select(payProviderEntries)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  /// 根据代码获取支付渠道
  Future<PayProviderEntry?> getPayProviderByCode(String code) {
    return (select(payProviderEntries)..where((p) => p.code.equals(code))).getSingleOrNull();
  }

  /// 根据支付方式类型获取支付渠道
  Future<List<PayProviderEntry>> getPayProvidersByMethod(PayMethod method) {
    return (select(payProviderEntries)..where((p) => p.method.equals(method.value))).get();
  }

  /// 根据支付类型获取支付渠道
  Future<List<PayProviderEntry>> getPayProvidersByPayType(PayType payType) {
    return (select(payProviderEntries)..where((p) => p.payType.equals(payType.value))).get();
  }

  /// 根据状态获取支付渠道
  Future<List<PayProviderEntry>> getPayProvidersByStatus(int status) {
    return (select(payProviderEntries)..where((p) => p.status.equals(status))).get();
  }

  /// 根据环境获取支付渠道
  Future<List<PayProviderEntry>> getPayProvidersByEnvironment(Environment environment) {
    return (select(payProviderEntries)..where((p) => p.environment.equals(environment.value))).get();
  }

  /// 根据客户端类型获取支付渠道
  Future<List<PayProviderEntry>> getPayProvidersByClientType(String clientType) {
    return (select(payProviderEntries)..where((p) => p.clientTypes.like('%$clientType%'))).get();
  }

  /// 根据地区获取支付渠道
  Future<List<PayProviderEntry>> getPayProvidersByRegion(String region) {
    return (select(payProviderEntries)..where((p) => p.regions.like('%$region%'))).get();
  }

  /// 获取有效的支付渠道
  Future<List<PayProviderEntry>> getActivePayProviders() {
    return getPayProvidersByStatus(1);
  }

  /// 创建支付渠道
  Future<int> createPayProvider(PayProviderEntriesCompanion payProvider) {
    return into(payProviderEntries).insert(payProvider);
  }

  /// 更新支付渠道
  Future<bool> updatePayProvider(PayProviderEntriesCompanion payProvider) {
    return update(payProviderEntries).replace(payProvider);
  }

  /// 删除支付渠道
  Future<int> deletePayProvider(int id) {
    return (delete(payProviderEntries)..where((p) => p.id.equals(id))).go();
  }

  /// 删除支付渠道（根据代码）
  Future<int> deletePayProviderByCode(String code) {
    return (delete(payProviderEntries)..where((p) => p.code.equals(code))).go();
  }

  /// 检查支付渠道代码是否存在
  Future<bool> payProviderCodeExists(String code) {
    return (select(payProviderEntries)..where((p) => p.code.equals(code))).getSingleOrNull().then((provider) => provider != null);
  }

  /// 获取支付渠道数量
  Future<int> getPayProviderCount() {
    return (select(payProviderEntries)..where((p) => p.id.isNotNull())).get().then((providers) => providers.length);
  }

  /// 获取在线支付渠道
  Future<List<PayProviderEntry>> getOnlinePayProviders() {
    return getPayProvidersByPayType(PayType.online);
  }

  /// 获取卡密兑换渠道
  Future<List<PayProviderEntry>> getCardKeyPayProviders() {
    return getPayProvidersByPayType(PayType.cardKey);
  }

  /// 获取应用内购买渠道
  Future<List<PayProviderEntry>> getInAppPurchasePayProviders() {
    return getPayProvidersByPayType(PayType.inAppPurchase);
  }

  /// 获取PC端支付渠道
  Future<List<PayProviderEntry>> getPcPayProviders() {
    return getPayProvidersByMethod(PayMethod.pc);
  }

  /// 获取移动端支付渠道
  Future<List<PayProviderEntry>> getMobilePayProviders() {
    return (select(payProviderEntries)..where((p) => p.method.isIn([PayMethod.wap.value, PayMethod.h5.value, PayMethod.appStore.value]))).get();
  }

  /// 监听所有支付渠道变化
  Stream<List<PayProviderEntry>> watchAllPayProviders() {
    return select(payProviderEntries).watch();
  }

  /// 监听特定支付渠道变化
  Stream<PayProviderEntry?> watchPayProviderById(int id) {
    return (select(payProviderEntries)..where((p) => p.id.equals(id))).watchSingleOrNull();
  }

  /// 监听有效支付渠道变化
  Stream<List<PayProviderEntry>> watchActivePayProviders() {
    return (select(payProviderEntries)..where((p) => p.status.equals(1))).watch();
  }

  /// 监听特定支付方式类型变化
  Stream<List<PayProviderEntry>> watchPayProvidersByMethod(PayMethod method) {
    return (select(payProviderEntries)..where((p) => p.method.equals(method.value))).watch();
  }

  /// 监听特定支付类型变化
  Stream<List<PayProviderEntry>> watchPayProvidersByPayType(PayType payType) {
    return (select(payProviderEntries)..where((p) => p.payType.equals(payType.value))).watch();
  }
}
