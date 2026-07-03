import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:guichao/gch_base/gch_app_xinxi/gch_yingyong_xinxi.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_store/gch_db_provider.dart';
import 'package:guichao/gch_base/gch_biz/gch_api/gch_providers/gch_api_client_providers.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_api/gch_payprovider_api.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_dao/gch_payprovider_dao.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_repo/gch_payprovider_repository.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_model/gch_payprovider_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_svc/gch_payprovider_service.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_storage/gch_payprovider_storage_adapter.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_storage/gch_sqlite_payprovider_adapter.dart';

part 'gch_payprovider_providers.g.dart';

/// PayProvider API Provider
@riverpod
PayProviderApi payProviderApi(PayProviderApiRef ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PayProviderApi(apiClient: apiClient);
}

/// PayProvider Storage Adapter Provider - SQLite 实现
@riverpod
Future<PayProviderStorageAdapter> payProviderStorageAdapter(PayProviderStorageAdapterRef ref) async {
  final database = ref.watch(gchDatabaseProvider);
  final dao = PayProviderDao(database);
  return SQLitePayProviderAdapter(dao);
}

/// PayProvider DAO Provider (SQLite-only, kept for backward compatibility)
@riverpod
PayProviderDao payProviderDao(PayProviderDaoRef ref) {
  final database = ref.watch(gchDatabaseProvider);
  return PayProviderDao(database);
}

/// PayProvider Repository Provider
@riverpod
Future<PayProviderRepository> payProviderRepository(PayProviderRepositoryRef ref) async {
  final api = ref.watch(payProviderApiProvider);
  final adapter = await ref.watch(payProviderStorageAdapterProvider.future);

  // Wrap adapter to maintain compatibility with existing DAO interface
  final dao = _PayProviderDaoAdapter(adapter);

  return PayProviderRepository(api, dao);
}

/// 适配器包装类 - 将 StorageAdapter 包装为 DAO 接口
///
/// 这样可以保持 Repository 层不变，只需替换底层存储实现
class _PayProviderDaoAdapter implements PayProviderDao {
  final PayProviderStorageAdapter _adapter;

  _PayProviderDaoAdapter(this._adapter);

  @override
  Future<List<PayProviderEntry>> getAllPayProviders() {
    return _adapter.gchFetchAll();
  }

  @override
  Future<PayProviderEntry?> getPayProviderById(int id) {
    return _adapter.gchFetchOne(id);
  }

  @override
  Future<PayProviderEntry?> getPayProviderByCode(String code) {
    return _adapter.getByCode(code);
  }

  @override
  Future<List<PayProviderEntry>> getPayProvidersByMethod(PayMethod method) {
    return _adapter.getByMethod(method);
  }

  @override
  Future<List<PayProviderEntry>> getPayProvidersByPayType(PayType payType) {
    return _adapter.getByPayType(payType);
  }

  @override
  Future<List<PayProviderEntry>> getPayProvidersByStatus(int status) async {
    if (status == 1) {
      return _adapter.getActive();
    }
    return _adapter.gchFetchAll(where: {'status': status});
  }

  @override
  Future<List<PayProviderEntry>> getPayProvidersByEnvironment(Environment environment) {
    return _adapter.getByEnvironment(environment);
  }

  @override
  Future<List<PayProviderEntry>> getPayProvidersByClientType(String clientType) {
    return _adapter.getByClientType(clientType);
  }

  @override
  Future<List<PayProviderEntry>> getPayProvidersByRegion(String region) {
    return _adapter.getByRegion(region);
  }

  @override
  Future<List<PayProviderEntry>> getActivePayProviders() {
    return _adapter.getActive();
  }

  @override
  Future<int> createPayProvider(PayProviderEntriesCompanion payProvider) async {
    // Convert companion to entry
    final now = DateTime.now();
    final entry = PayProviderEntry(
      id: payProvider.id.present ? payProvider.id.value : 0,
      code: payProvider.code.value,
      name: payProvider.name.value,
      method: payProvider.method.present ? payProvider.method.value : 0,
      payType: payProvider.payType.present ? payProvider.payType.value : 0,
      iconUrl: payProvider.iconUrl.present ? payProvider.iconUrl.value : null,
      status: payProvider.status.present ? payProvider.status.value : 1,
      config: payProvider.config.present ? payProvider.config.value : null,
      regions: payProvider.regions.present ? payProvider.regions.value : null,
      environment: payProvider.environment.present ? payProvider.environment.value : 'production',
      clientTypes: payProvider.clientTypes.present ? payProvider.clientTypes.value : null,
      extra1: payProvider.extra1.present ? payProvider.extra1.value : null,
      extra2: payProvider.extra2.present ? payProvider.extra2.value : null,
      extra3: payProvider.extra3.present ? payProvider.extra3.value : null,
      extra4: payProvider.extra4.present ? payProvider.extra4.value : null,
      createdAt: payProvider.createdAt.present ? payProvider.createdAt.value : now,
      updatedAt: payProvider.updatedAt.present ? payProvider.updatedAt.value : now,
    );

    await _adapter.gchPut(entry);
    return entry.id;
  }

  @override
  Future<bool> updatePayProvider(PayProviderEntriesCompanion payProvider) async {
    if (!payProvider.id.present) return false;

    final updates = <String, dynamic>{};
    if (payProvider.code.present) updates['code'] = payProvider.code.value;
    if (payProvider.name.present) updates['name'] = payProvider.name.value;
    if (payProvider.method.present) updates['method'] = payProvider.method.value;
    if (payProvider.payType.present) updates['payType'] = payProvider.payType.value;
    if (payProvider.iconUrl.present) updates['iconUrl'] = payProvider.iconUrl.value;
    if (payProvider.status.present) updates['status'] = payProvider.status.value;
    if (payProvider.config.present) updates['config'] = payProvider.config.value;
    if (payProvider.regions.present) updates['regions'] = payProvider.regions.value;
    if (payProvider.environment.present) updates['environment'] = payProvider.environment.value;
    if (payProvider.clientTypes.present) updates['clientTypes'] = payProvider.clientTypes.value;
    if (payProvider.extra1.present) updates['extra1'] = payProvider.extra1.value;
    if (payProvider.extra2.present) updates['extra2'] = payProvider.extra2.value;
    if (payProvider.extra3.present) updates['extra3'] = payProvider.extra3.value;
    if (payProvider.extra4.present) updates['extra4'] = payProvider.extra4.value;

    await _adapter.gchPatch(payProvider.id.value, updates);
    return true;
  }

  @override
  Future<int> deletePayProvider(int id) async {
    await _adapter.gchRemove(id);
    return 1;
  }

  @override
  Future<int> deletePayProviderByCode(String code) async {
    await _adapter.gchRemoveWhere({'code': code});
    return 1;
  }

  @override
  Future<bool> payProviderCodeExists(String code) {
    return _adapter.existsByCode(code);
  }

  @override
  Future<int> getPayProviderCount() {
    return _adapter.gchCount();
  }

  @override
  Future<List<PayProviderEntry>> getOnlinePayProviders() {
    return _adapter.getOnlinePayProviders();
  }

  @override
  Future<List<PayProviderEntry>> getCardKeyPayProviders() {
    return _adapter.getCardKeyProviders();
  }

  @override
  Future<List<PayProviderEntry>> getInAppPurchasePayProviders() {
    return _adapter.getInAppPurchaseProviders();
  }

  @override
  Future<List<PayProviderEntry>> getPcPayProviders() {
    return _adapter.getByMethod(PayMethod.pc);
  }

  @override
  Future<List<PayProviderEntry>> getMobilePayProviders() async {
    final results = await Future.wait([
      _adapter.getByMethod(PayMethod.wap),
      _adapter.getByMethod(PayMethod.h5),
      _adapter.getByMethod(PayMethod.appStore),
    ]);

    return results.expand((list) => list).toList();
  }

  @override
  Stream<List<PayProviderEntry>> watchAllPayProviders() {
    return _adapter.watchAll();
  }

  @override
  Stream<PayProviderEntry?> watchPayProviderById(int id) {
    return _adapter.gchObserveOne(id);
  }

  @override
  Stream<List<PayProviderEntry>> watchActivePayProviders() {
    return _adapter.watchActive();
  }

  @override
  Stream<List<PayProviderEntry>> watchPayProvidersByMethod(PayMethod method) {
    return _adapter.watchByMethod(method);
  }

  @override
  Stream<List<PayProviderEntry>> watchPayProvidersByPayType(PayType payType) {
    return _adapter.watchByPayType(payType);
  }

  // Implement missing members from PayProviderDao
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// PayProvider Service Provider
@riverpod
Future<PayProviderService> payProviderService(PayProviderServiceRef ref) async {
  final repository = await ref.watch(payProviderRepositoryProvider.future);
  return PayProviderService(repository);
}

/// 所有支付渠道 Provider
@riverpod
Future<List<PayProviderEntry>> payProviders(PayProvidersRef ref) async {
  final service = await ref.watch(payProviderServiceProvider.future);
  return await service.getAllPayProviders();
}

/// 有效支付渠道 Provider
@riverpod
Future<List<PayProviderEntry>> activePayProviders(ActivePayProvidersRef ref) async {
  final service = await ref.watch(payProviderServiceProvider.future);
  return await service.getActivePayProviders();
}

/// 在线支付渠道 Provider
@riverpod
Future<List<PayProviderEntry>> onlinePayProviders(OnlinePayProvidersRef ref) async {
  final service = await ref.watch(payProviderServiceProvider.future);
  return await service.getOnlinePayProviders();
}

/// 卡密兑换渠道 Provider
@riverpod
Future<List<PayProviderEntry>> cardKeyPayProviders(CardKeyPayProvidersRef ref) async {
  final service = await ref.watch(payProviderServiceProvider.future);
  return await service.getCardKeyPayProviders();
}

/// 应用内购买渠道 Provider
@riverpod
Future<List<PayProviderEntry>> inAppPurchasePayProviders(InAppPurchasePayProvidersRef ref) async {
  final service = await ref.watch(payProviderServiceProvider.future);
  return await service.getInAppPurchasePayProviders();
}

/// PC端支付渠道 Provider
@riverpod
Future<List<PayProviderEntry>> pcPayProviders(PcPayProvidersRef ref) async {
  final service = await ref.watch(payProviderServiceProvider.future);
  return await service.getPcPayProviders();
}

/// 移动端支付渠道 Provider
@riverpod
Future<List<PayProviderEntry>> mobilePayProviders(MobilePayProvidersRef ref) async {
  final service = await ref.watch(payProviderServiceProvider.future);
  return await service.getMobilePayProviders();
}

/// 支付渠道流 Provider
@riverpod
Stream<List<PayProviderEntry>> payProvidersStream(PayProvidersStreamRef ref) async* {
  final service = await ref.watch(payProviderServiceProvider.future);
  yield* service.watchAllPayProviders();
}

/// 有效支付渠道流 Provider
@riverpod
Stream<List<PayProviderEntry>> activePayProvidersStream(ActivePayProvidersStreamRef ref) async* {
  final service = await ref.watch(payProviderServiceProvider.future);
  yield* service.watchActivePayProviders();
}

/// 当前环境可用支付方式 Provider
///
/// 根据安装来源过滤支付方式：
/// - App Store 安装: 只显示 Apple Pay
/// - 其他来源: 显示所有支付方式
@riverpod
Future<List<PayProviderEntry>> currentPayProviders(CurrentPayProvidersRef ref) async {
  final service = await ref.watch(payProviderServiceProvider.future);
  final installSource = await ref.watch(anzhuangLaiyuanProvider.future);

  debugPrint('📱 currentPayProviders - 安装来源: $installSource');

  // 获取所有活跃的支付方式
  final allProviders = await service.getActivePayProviders();

  debugPrint('📱 currentPayProviders - 活跃提供商数量: ${allProviders.length}');
  for (final p in allProviders) {
    debugPrint('  - ${p.code}: ${p.name}');
  }

  // iOS 平台保底：无论 installSource 检测结果如何，一律只加载 Apple Pay
  // （installSource 依赖 PackageInfo，异常时可能返回 unknown，此处用 Platform.isIOS 兜底）
  if (Platform.isIOS) {
    final applePayProviders = allProviders.where((p) =>
      p.code.toLowerCase() == 'apple_pay' ||
      p.code.toLowerCase() == 'applepay'
    ).toList();

    debugPrint('📱 iOS 平台，只加载 Apple Pay: ${applePayProviders.length} 个');
    return applePayProviders;
  }

  // 非 iOS 平台：根据安装来源过滤
  switch (installSource) {
    case AnzhuangLaiyuan.appStore:
      // App Store 安装：只显示 Apple Pay
      final applePayProviders = allProviders.where((p) =>
        p.code.toLowerCase() == 'apple_pay' ||
        p.code.toLowerCase() == 'applepay'
      ).toList();

      if (applePayProviders.isNotEmpty) {
        debugPrint('📱 App Store 安装，只显示 Apple Pay: ${applePayProviders.length} 个');
        return applePayProviders;
      }

      // 如果没有找到 Apple Pay，记录警告但返回空列表
      debugPrint('⚠️ App Store 安装但未找到 Apple Pay 支付方式');
      return [];

    case AnzhuangLaiyuan.weizhi:
      // 其他来源：返回所有支持当前平台的支付方式
      final platform = _getCurrentPlatform();
      final filtered = allProviders.where((p) {
        final types = p.clientTypes;
        // 如果没有指定客户端类型，认为支持所有平台
        if (types == null || types.isEmpty) return true;

        // 将逗号分隔的字符串转换为列表，并去除空格
        final supportedPlatforms = types
            .split(',')
            .map((t) => t.trim().toLowerCase())
            .toList();

        // 检查是否包含当前平台（不区分大小写）
        return supportedPlatforms.contains(platform.toLowerCase());
      }).toList();

      debugPrint('📱 非商店安装，显示所有支付方式: ${filtered.length} 个');
      return filtered;
  }
}

String _getCurrentPlatform() => 'ios';

/// 当前环境可用支付方式 Provider
///
/// 基于安装来源过滤后的支付方式
@riverpod
Future<List<PayProviderEntry>> availablePayProviders(AvailablePayProvidersRef ref) async {
  final filteredProviders = await ref.watch(currentPayProvidersProvider.future);

  debugPrint('📱 最终可用支付方式: ${filteredProviders.length} 个');
  for (final p in filteredProviders) {
    debugPrint('  - ${p.code}: ${p.name}');
  }

  return filteredProviders;
}
