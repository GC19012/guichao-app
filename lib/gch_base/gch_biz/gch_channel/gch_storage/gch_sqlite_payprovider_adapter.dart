import 'dart:async';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_dao/gch_payprovider_dao.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_model/gch_payprovider_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_storage/gch_payprovider_storage_adapter.dart';
import 'package:drift/drift.dart' as drift;

/// SQLite存储适配器实现 - PayProvider
///
/// 包装现有的PayProviderDao，使其符合StorageAdapter接口
class SQLitePayProviderAdapter implements PayProviderStorageAdapter {
  final PayProviderDao _dao;

  SQLitePayProviderAdapter(this._dao);

  @override
  Future<void> gchInit() async {
    // DAO is already initialized through database
  }

  @override
  Future<void> gchShutdown() async {
    // Database handles closing
  }

  @override
  Future<PayProviderEntry?> gchFetchOne(int id) {
    return _dao.getPayProviderById(id);
  }

  @override
  Future<PayProviderEntry?> getByCode(String code) {
    return _dao.getPayProviderByCode(code);
  }

  @override
  Future<List<PayProviderEntry>> getByMethod(PayMethod method) {
    return _dao.getPayProvidersByMethod(method);
  }

  @override
  Future<List<PayProviderEntry>> getByPayType(PayType payType) {
    return _dao.getPayProvidersByPayType(payType);
  }

  @override
  Future<List<PayProviderEntry>> getActive() {
    return _dao.getActivePayProviders();
  }

  @override
  Stream<List<PayProviderEntry>> watchActive() {
    return _dao.watchActivePayProviders();
  }

  @override
  Future<List<PayProviderEntry>> getByEnvironment(Environment environment) {
    return _dao.getPayProvidersByEnvironment(environment);
  }

  @override
  Future<List<PayProviderEntry>> getByClientType(String clientType) {
    return _dao.getPayProvidersByClientType(clientType);
  }

  @override
  Future<List<PayProviderEntry>> getByRegion(String region) {
    return _dao.getPayProvidersByRegion(region);
  }

  @override
  Future<List<PayProviderEntry>> getOnlinePayProviders() {
    return _dao.getOnlinePayProviders();
  }

  @override
  Future<List<PayProviderEntry>> getInAppPurchaseProviders() {
    return _dao.getInAppPurchasePayProviders();
  }

  @override
  Future<List<PayProviderEntry>> getCardKeyProviders() {
    return _dao.getCardKeyPayProviders();
  }

  @override
  Stream<List<PayProviderEntry>> watchAll() {
    return _dao.watchAllPayProviders();
  }

  @override
  Stream<List<PayProviderEntry>> watchByMethod(PayMethod method) {
    return _dao.watchPayProvidersByMethod(method);
  }

  @override
  Stream<List<PayProviderEntry>> watchByPayType(PayType payType) {
    return _dao.watchPayProvidersByPayType(payType);
  }

  @override
  Future<bool> existsByCode(String code) {
    return _dao.payProviderCodeExists(code);
  }

  @override
  Future<List<PayProviderEntry>> gchFetchAll({
    Map<String, dynamic>? where,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
  }) async {
    // For SQLite/Drift, we use the existing DAO methods
    // This is a simplified implementation - full query builder would be more complex
    return _dao.getAllPayProviders();
  }

  @override
  Stream<List<PayProviderEntry>> gchObserveAll({
    Map<String, dynamic>? where,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
  }) {
    // Simplified implementation using watchAll
    return watchAll();
  }

  @override
  Stream<PayProviderEntry?> gchObserveOne(int id) {
    return _dao.watchPayProviderById(id);
  }

  @override
  Future<void> gchPut(PayProviderEntry entity) async {
    await _dao.createPayProvider(
      PayProviderEntriesCompanion(
        id: drift.Value(entity.id),
        code: drift.Value(entity.code),
        name: drift.Value(entity.name),
        method: drift.Value(entity.method),
        payType: drift.Value(entity.payType),
        iconUrl: drift.Value(entity.iconUrl),
        status: drift.Value(entity.status),
        config: drift.Value(entity.config),
        regions: drift.Value(entity.regions),
        environment: drift.Value(entity.environment),
        clientTypes: drift.Value(entity.clientTypes),
        extra1: drift.Value(entity.extra1),
        extra2: drift.Value(entity.extra2),
        extra3: drift.Value(entity.extra3),
        extra4: drift.Value(entity.extra4),
      ),
    );
  }

  @override
  Future<void> gchPutBatch(List<PayProviderEntry> entities) async {
    for (final entity in entities) {
      await gchPut(entity);
    }
  }

  @override
  Future<void> gchPatch(int id, Map<String, dynamic> updates) async {
    final companion = PayProviderEntriesCompanion(
      id: drift.Value(id),
      code: updates.containsKey('code')
          ? drift.Value(updates['code'] as String)
          : const drift.Value.absent(),
      name: updates.containsKey('name')
          ? drift.Value(updates['name'] as String)
          : const drift.Value.absent(),
      method: updates.containsKey('method')
          ? drift.Value(updates['method'] as int)
          : const drift.Value.absent(),
      payType: updates.containsKey('payType')
          ? drift.Value(updates['payType'] as int)
          : const drift.Value.absent(),
      iconUrl: updates.containsKey('iconUrl')
          ? drift.Value(updates['iconUrl'] as String?)
          : const drift.Value.absent(),
      status: updates.containsKey('status')
          ? drift.Value(updates['status'] as int)
          : const drift.Value.absent(),
      config: updates.containsKey('config')
          ? drift.Value(updates['config'] as String?)
          : const drift.Value.absent(),
      regions: updates.containsKey('regions')
          ? drift.Value(updates['regions'] as String?)
          : const drift.Value.absent(),
      environment: updates.containsKey('environment')
          ? drift.Value(updates['environment'] as String)
          : const drift.Value.absent(),
      clientTypes: updates.containsKey('clientTypes')
          ? drift.Value(updates['clientTypes'] as String?)
          : const drift.Value.absent(),
      extra1: updates.containsKey('extra1')
          ? drift.Value(updates['extra1'] as int?)
          : const drift.Value.absent(),
      extra2: updates.containsKey('extra2')
          ? drift.Value(updates['extra2'] as int?)
          : const drift.Value.absent(),
      extra3: updates.containsKey('extra3')
          ? drift.Value(updates['extra3'] as String?)
          : const drift.Value.absent(),
      extra4: updates.containsKey('extra4')
          ? drift.Value(updates['extra4'] as String?)
          : const drift.Value.absent(),
    );

    await _dao.updatePayProvider(companion);
  }

  @override
  Future<void> gchRemove(int id) async {
    await _dao.deletePayProvider(id);
  }

  @override
  Future<void> gchRemoveWhere(Map<String, dynamic> where) async {
    // Simplified: delete by code if provided
    if (where.containsKey('code')) {
      await _dao.deletePayProviderByCode(where['code'] as String);
    }
  }

  @override
  Future<void> gchPurge() async {
    final all = await _dao.getAllPayProviders();
    for (final provider in all) {
      await _dao.deletePayProvider(provider.id);
    }
  }

  @override
  Future<int> gchCount({Map<String, dynamic>? where}) {
    return _dao.getPayProviderCount();
  }

  @override
  Future<T> gchTransact<T>(Future<T> Function() action) async {
    // Drift handles transactions through database instance
    return await action();
  }
}
