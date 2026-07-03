import 'package:guichao/gch_base/gch_biz/gch_channel/gch_repo/gch_payprovider_repository.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_model/gch_payprovider_model.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:drift/drift.dart';

/// 支付渠道服务类
class PayProviderService {
  final PayProviderRepositoryInterface _repository;

  PayProviderService(this._repository);

  /// 获取所有支付渠道
  Future<List<PayProviderEntry>> getAllPayProviders() async {
    final result = await _repository.getPayProviders();
    return result.fold(
      (error) => throw Exception(error),
      (providers) => providers,
    );
  }


  /// 根据代码获取支付渠道
  Future<PayProviderEntry?> getPayProviderByCode(String code) async {
    final result = await _repository.getPayProviderByCode(code);
    return result.fold(
      (error) => throw Exception(error),
      (provider) => provider,
    );
  }

  /// 根据支付方式类型获取支付渠道
  Future<List<PayProviderEntry>> getPayProvidersByMethod(PayMethod method) async {
    final result = await _repository.getPayProvidersByMethod(method);
    return result.fold(
      (error) => throw Exception(error),
      (providers) => providers,
    );
  }

  /// 根据支付类型获取支付渠道
  Future<List<PayProviderEntry>> getPayProvidersByPayType(PayType payType) async {
    final result = await _repository.getPayProvidersByPayType(payType);
    return result.fold(
      (error) => throw Exception(error),
      (providers) => providers,
    );
  }

  /// 根据环境获取支付渠道
  Future<List<PayProviderEntry>> getPayProvidersByEnvironment(Environment environment) async {
    final result = await _repository.getPayProvidersByEnvironment(environment);
    return result.fold(
      (error) => throw Exception(error),
      (providers) => providers,
    );
  }

  /// 根据客户端类型获取支付渠道
  Future<List<PayProviderEntry>> getPayProvidersByClientType(String clientType) async {
    final result = await _repository.getPayProvidersByClientType(clientType);
    return result.fold(
      (error) => throw Exception(error),
      (providers) => providers,
    );
  }

  /// 根据地区获取支付渠道
  Future<List<PayProviderEntry>> getPayProvidersByRegion(String region) async {
    final result = await _repository.getPayProvidersByRegion(region);
    return result.fold(
      (error) => throw Exception(error),
      (providers) => providers,
    );
  }

  /// 获取有效的支付渠道
  Future<List<PayProviderEntry>> getActivePayProviders() async {
    final result = await _repository.getActivePayProviders();
    return result.fold(
      (error) => throw Exception(error),
      (providers) => providers,
    );
  }

  /// 创建支付渠道
  Future<PayProviderEntry> createPayProvider({
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
    final result = await _repository.createPayProvider(
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
    return result.fold(
      (error) => throw Exception(error),
      (provider) => provider,
    );
  }

  /// 更新支付渠道
  Future<bool> updatePayProvider({
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
    final result = await _repository.updatePayProvider(
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
    return result.fold(
      (error) => throw Exception(error),
      (success) => success,
    );
  }

  /// 删除支付渠道
  Future<bool> deletePayProvider(int id) async {
    final result = await _repository.deletePayProvider(id);
    return result.fold(
      (error) => throw Exception(error),
      (success) => success,
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
    final allProviders = await getAllPayProviders();
    return allProviders.where((provider) {
      final method = PayMethod.fromValue(provider.method);
      return method == PayMethod.wap || method == PayMethod.h5 || method == PayMethod.appStore;
    }).toList();
  }

  String getPlatform() => 'ios';

  /// 获取当前可用支付方式
  Future<List<PayProviderEntry>> getCurrent() async {
    final platform = getPlatform();
    final providers = await getActivePayProviders();
    
    // 调试信息
    print('PayProviderService.getCurrent() - 平台: $platform');
    print('PayProviderService.getCurrent() - 活跃提供商数量: ${providers.length}');
    for (final p in providers) {
      print('  - ${p.code}: ${p.name} (clientTypes: ${p.clientTypes})');
    }
    
    // 按平台过滤
    final filtered = providers.where((p) {
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
    
    print('PayProviderService.getCurrent() - 过滤后提供商数量: ${filtered.length}');
    return filtered;
  }

  /// 同步支付渠道数据
  Future<List<PayProviderEntry>> syncPayProviders() async {
    if (_repository is PayProviderRepository) {
      final repository = _repository;
      final result = await repository.syncPayProvidersFromServer();
      return result.fold(
        (error) => throw Exception(error),
        (providers) => providers,
      );
    }
    throw Exception('Repository does not support sync operation');
  }

  /// 监听所有支付渠道变化
  Stream<List<PayProviderEntry>> watchAllPayProviders() {
    return _repository.watchAllPayProviders();
  }

  /// 监听特定支付渠道变化
  Stream<PayProviderEntry?> watchPayProviderById(int id) {
    return _repository.watchPayProviderById(id);
  }

  /// 监听有效支付渠道变化
  Stream<List<PayProviderEntry>> watchActivePayProviders() {
    return _repository.watchActivePayProviders();
  }

  /// 监听特定支付方式类型变化
  Stream<List<PayProviderEntry>> watchPayProvidersByMethod(PayMethod method) {
    return _repository.watchPayProvidersByMethod(method);
  }

  /// 监听特定支付类型变化
  Stream<List<PayProviderEntry>> watchPayProvidersByPayType(PayType payType) {
    return _repository.watchPayProvidersByPayType(payType);
  }
}
