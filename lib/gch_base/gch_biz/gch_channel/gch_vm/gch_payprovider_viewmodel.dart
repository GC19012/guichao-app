import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_repo/gch_payprovider_repository.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_model/gch_payprovider_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_providers/gch_payprovider_providers.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:drift/drift.dart';

part 'gch_payprovider_viewmodel.g.dart';

/// PayProvider ViewModel
@riverpod
class PayProviderViewModel extends _$PayProviderViewModel {
  @override
  Future<List<PayProviderEntry>> build() async {
    final repository = await ref.watch(payProviderRepositoryProvider.future);
    return await _getPayProviders(repository);
  }

  Future<List<PayProviderEntry>> _getPayProviders(PayProviderRepositoryInterface repository) async {
    final result = await repository.getPayProviders();
    return result.fold(
      (error) => throw Exception(error),
      (providers) => providers,
    );
  }

  /// 刷新支付渠道列表
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final repository = await ref.read(payProviderRepositoryProvider.future);
    state = await AsyncValue.guard(() => _getPayProviders(repository));
  }

  /// 创建支付渠道
  Future<void> createPayProvider({
    required String code,
    required String name,
    required PayMethod method,
    required PayType payType,
    String? iconUrl,
    int status = 1,
    String? config,
    String? regions,
    Environment environment = Environment.production,
    String? clientTypes,
    int? extra1,
    int? extra2,
    String? extra3,
    String? extra4,
  }) async {
    final repository = await ref.read(payProviderRepositoryProvider.future);

    final result = await repository.createPayProvider(
      PayProviderEntriesCompanion.insert(
        code: code,
        name: name,
        method: Value(method.value),
        payType: Value(payType.value),
        iconUrl: Value(iconUrl),
        status: Value(status),
        config: Value(config),
        regions: Value(regions),
        environment: Value(environment.value),
        clientTypes: Value(clientTypes),
        extra1: Value(extra1),
        extra2: Value(extra2),
        extra3: Value(extra3),
        extra4: Value(extra4),
      ),
    );

    result.fold(
      (error) => throw Exception(error),
      (provider) {
        // 刷新列表
        refresh();
      },
    );
  }

  /// 更新支付渠道
  Future<void> updatePayProvider({
    required int id,
    String? code,
    String? name,
    PayMethod? method,
    PayType? payType,
    String? iconUrl,
    int? status,
    String? config,
    String? regions,
    Environment? environment,
    String? clientTypes,
    int? extra1,
    int? extra2,
    String? extra3,
    String? extra4,
  }) async {
    final repository = await ref.read(payProviderRepositoryProvider.future);

    final result = await repository.updatePayProvider(
      PayProviderEntriesCompanion(
        id: Value(id),
        code: code != null ? Value(code) : const Value.absent(),
        name: name != null ? Value(name) : const Value.absent(),
        method: method != null ? Value(method.value) : const Value.absent(),
        payType: payType != null ? Value(payType.value) : const Value.absent(),
        iconUrl: iconUrl != null ? Value(iconUrl) : const Value.absent(),
        status: status != null ? Value(status) : const Value.absent(),
        config: config != null ? Value(config) : const Value.absent(),
        regions: regions != null ? Value(regions) : const Value.absent(),
        environment: environment != null ? Value(environment.value) : const Value.absent(),
        clientTypes: clientTypes != null ? Value(clientTypes) : const Value.absent(),
        extra1: extra1 != null ? Value(extra1) : const Value.absent(),
        extra2: extra2 != null ? Value(extra2) : const Value.absent(),
        extra3: extra3 != null ? Value(extra3) : const Value.absent(),
        extra4: extra4 != null ? Value(extra4) : const Value.absent(),
      ),
    );

    result.fold(
      (error) => throw Exception(error),
      (success) {
        if (success) {
          // 刷新列表
          refresh();
        }
      },
    );
  }

  /// 删除支付渠道
  Future<void> deletePayProvider(int id) async {
    final repository = await ref.read(payProviderRepositoryProvider.future);

    final result = await repository.deletePayProvider(id);

    result.fold(
      (error) => throw Exception(error),
      (success) {
        if (success) {
          // 刷新列表
          refresh();
        }
      },
    );
  }


  /// 根据代码获取支付渠道
  Future<PayProviderEntry?> getPayProviderByCode(String code) async {
    final repository = await ref.read(payProviderRepositoryProvider.future);

    final result = await repository.getPayProviderByCode(code);
    return result.fold(
      (error) => throw Exception(error),
      (provider) => provider,
    );
  }

  /// 根据支付方式类型获取支付渠道
  Future<List<PayProviderEntry>> getPayProvidersByMethod(PayMethod method) async {
    final repository = await ref.read(payProviderRepositoryProvider.future);

    final result = await repository.getPayProvidersByMethod(method);
    return result.fold(
      (error) => throw Exception(error),
      (providers) => providers,
    );
  }

  /// 根据支付类型获取支付渠道
  Future<List<PayProviderEntry>> getPayProvidersByPayType(PayType payType) async {
    final repository = await ref.read(payProviderRepositoryProvider.future);

    final result = await repository.getPayProvidersByPayType(payType);
    return result.fold(
      (error) => throw Exception(error),
      (providers) => providers,
    );
  }

  /// 根据环境获取支付渠道
  Future<List<PayProviderEntry>> getPayProvidersByEnvironment(Environment environment) async {
    final repository = await ref.read(payProviderRepositoryProvider.future);

    final result = await repository.getPayProvidersByEnvironment(environment);
    return result.fold(
      (error) => throw Exception(error),
      (providers) => providers,
    );
  }

  /// 根据客户端类型获取支付渠道
  Future<List<PayProviderEntry>> getPayProvidersByClientType(String clientType) async {
    final repository = await ref.read(payProviderRepositoryProvider.future);

    final result = await repository.getPayProvidersByClientType(clientType);
    return result.fold(
      (error) => throw Exception(error),
      (providers) => providers,
    );
  }

  /// 根据地区获取支付渠道
  Future<List<PayProviderEntry>> getPayProvidersByRegion(String region) async {
    final repository = await ref.read(payProviderRepositoryProvider.future);

    final result = await repository.getPayProvidersByRegion(region);
    return result.fold(
      (error) => throw Exception(error),
      (providers) => providers,
    );
  }

  /// 获取有效的支付渠道
  Future<List<PayProviderEntry>> getActivePayProviders() async {
    final repository = await ref.read(payProviderRepositoryProvider.future);

    final result = await repository.getActivePayProviders();
    return result.fold(
      (error) => throw Exception(error),
      (providers) => providers,
    );
  }

  /// 获取在线支付渠道
  Future<List<PayProviderEntry>> getOnlinePayProviders() async {
    return await getPayProvidersByPayType(PayType.online);
  }

  /// 获取卡密兑换渠道
  Future<List<PayProviderEntry>> getCardKeyPayProviders() async {
    return await getPayProvidersByPayType(PayType.cardKey);
  }

  /// 获取应用内购买渠道
  Future<List<PayProviderEntry>> getInAppPurchasePayProviders() async {
    return await getPayProvidersByPayType(PayType.inAppPurchase);
  }

  /// 获取PC端支付渠道
  Future<List<PayProviderEntry>> getPcPayProviders() async {
    return await getPayProvidersByMethod(PayMethod.pc);
  }

  /// 获取移动端支付渠道
  Future<List<PayProviderEntry>> getMobilePayProviders() async {
    final allProviders = await future;
    return allProviders.where((provider) {
      final method = PayMethod.fromValue(provider.method);
      return method == PayMethod.wap || method == PayMethod.h5 || method == PayMethod.appStore;
    }).toList();
  }

  /// 同步支付渠道数据
  Future<void> syncPayProviders() async {
    final repository = await ref.read(payProviderRepositoryProvider.future);

    final result = await repository.syncPayProvidersFromServer();
    result.fold(
      (error) => throw Exception(error),
      (providers) {
        // 刷新列表
        refresh();
      },
    );
  }

  /// 监听所有支付渠道变化
  Stream<List<PayProviderEntry>> watchAllPayProviders() async* {
    final repository = await ref.read(payProviderRepositoryProvider.future);
    yield* repository.watchAllPayProviders();
  }

  /// 监听有效支付渠道变化
  Stream<List<PayProviderEntry>> watchActivePayProviders() async* {
    final repository = await ref.read(payProviderRepositoryProvider.future);
    yield* repository.watchActivePayProviders();
  }

  /// 监听特定支付方式类型变化
  Stream<List<PayProviderEntry>> watchPayProvidersByMethod(PayMethod method) async* {
    final repository = await ref.read(payProviderRepositoryProvider.future);
    yield* repository.watchPayProvidersByMethod(method);
  }

  /// 监听特定支付类型变化
  Stream<List<PayProviderEntry>> watchPayProvidersByPayType(PayType payType) async* {
    final repository = await ref.read(payProviderRepositoryProvider.future);
    yield* repository.watchPayProvidersByPayType(payType);
  }
}
