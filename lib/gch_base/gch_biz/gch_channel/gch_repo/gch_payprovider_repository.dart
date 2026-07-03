import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';

import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_api/gch_payprovider_api.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_dao/gch_payprovider_dao.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_model/gch_payprovider_model.dart';

/// 支付渠道仓库接口
abstract class PayProviderRepositoryInterface {
  Future<Either<String, List<PayProviderEntry>>> getPayProviders();
  Future<Either<String, PayProviderEntry?>> getPayProviderByCode(String code);
  Future<Either<String, List<PayProviderEntry>>> getPayProvidersByMethod(PayMethod method);
  Future<Either<String, List<PayProviderEntry>>> getPayProvidersByPayType(PayType payType);
  Future<Either<String, List<PayProviderEntry>>> getPayProvidersByEnvironment(Environment environment);
  Future<Either<String, List<PayProviderEntry>>> getPayProvidersByClientType(String clientType);
  Future<Either<String, List<PayProviderEntry>>> getPayProvidersByRegion(String region);
  Future<Either<String, List<PayProviderEntry>>> getActivePayProviders();
  Future<Either<String, PayProviderEntry>> createPayProvider(PayProviderEntriesCompanion payProvider);
  Future<Either<String, bool>> updatePayProvider(PayProviderEntriesCompanion payProvider);
  Future<Either<String, bool>> deletePayProvider(int id);
  Stream<List<PayProviderEntry>> watchAllPayProviders();
  Stream<PayProviderEntry?> watchPayProviderById(int id);
  Stream<List<PayProviderEntry>> watchActivePayProviders();
  Stream<List<PayProviderEntry>> watchPayProvidersByMethod(PayMethod method);
  Stream<List<PayProviderEntry>> watchPayProvidersByPayType(PayType payType);
}

/// 支付渠道仓库实现
class PayProviderRepository implements PayProviderRepositoryInterface {
  final PayProviderApi _api;
  final PayProviderDao _dao;

  PayProviderRepository(this._api, this._dao);

  /// 初始化API客户端
  void initializeApiClient() {
    _api.initializeApiClient();
  }

  @override
  Future<Either<String, List<PayProviderEntry>>> getPayProviders() async {
    try {
      // 首先尝试从本地数据库获取
      final localProviders = await _dao.getAllPayProviders();

      // 如果本地有数据，返回本地数据
      if (localProviders.isNotEmpty) {
        return Right(localProviders);
      }

      // 如果本地没有数据，从API获取
      final apiResponse = await _api.getPayProviders();
      final providers = apiResponse.data;

      if (providers != null) {
        // 将API数据保存到本地数据库
        for (final provider in providers) {
          await _dao.createPayProvider(PayProviderEntriesCompanion.insert(
            code: provider.code,
            name: provider.name,
            method: Value(provider.method),
            payType: Value(provider.payType),
            iconUrl: Value(provider.iconUrl),
            status: Value(provider.status),
            config: Value(provider.config),
            regions: Value(provider.regions),
            environment: Value(provider.environment),
            clientTypes: Value(provider.clientTypes),
            extra1: Value(provider.extra1),
            extra2: Value(provider.extra2),
            extra3: Value(provider.extra3),
            extra4: Value(provider.extra4),
          ));
        }
        return Right(providers);
      } else {
        return const Left('API返回空数据');
      }
    } catch (e) {
      return Left('获取支付渠道列表失败: $e');
    }
  }


  @override
  Future<Either<String, PayProviderEntry?>> getPayProviderByCode(String code) async {
    try {
      final provider = await _dao.getPayProviderByCode(code);
      if (provider != null) {
        return Right(provider);
      }

      // 如果本地没有，尝试从API获取
      final apiResponse = await _api.getPayProviderByCode(code);
      final apiProvider = apiResponse.data;
      
      if (apiProvider != null) {
        // 保存到本地数据库
        await _dao.createPayProvider(PayProviderEntriesCompanion.insert(
          code: apiProvider.code,
          name: apiProvider.name,
          method: Value(apiProvider.method),
          payType: Value(apiProvider.payType),
          iconUrl: Value(apiProvider.iconUrl),
          status: Value(apiProvider.status),
          config: Value(apiProvider.config),
          regions: Value(apiProvider.regions),
          environment: Value(apiProvider.environment),
          clientTypes: Value(apiProvider.clientTypes),
          extra1: Value(apiProvider.extra1),
          extra2: Value(apiProvider.extra2),
          extra3: Value(apiProvider.extra3),
          extra4: Value(apiProvider.extra4),
        ));
      }
      return Right(apiProvider);
    } catch (e) {
      return Left('获取支付渠道失败: $e');
    }
  }

  @override
  Future<Either<String, List<PayProviderEntry>>> getPayProvidersByMethod(PayMethod method) async {
    try {
      final providers = await _dao.getPayProvidersByMethod(method);
      return Right(providers);
    } catch (e) {
      return Left('获取支付渠道失败: $e');
    }
  }

  @override
  Future<Either<String, List<PayProviderEntry>>> getPayProvidersByPayType(PayType payType) async {
    try {
      final providers = await _dao.getPayProvidersByPayType(payType);
      return Right(providers);
    } catch (e) {
      return Left('获取支付渠道失败: $e');
    }
  }

  @override
  Future<Either<String, List<PayProviderEntry>>> getPayProvidersByEnvironment(Environment environment) async {
    try {
      final providers = await _dao.getPayProvidersByEnvironment(environment);
      return Right(providers);
    } catch (e) {
      return Left('获取支付渠道失败: $e');
    }
  }

  @override
  Future<Either<String, List<PayProviderEntry>>> getPayProvidersByClientType(String clientType) async {
    try {
      final providers = await _dao.getPayProvidersByClientType(clientType);
      return Right(providers);
    } catch (e) {
      return Left('获取支付渠道失败: $e');
    }
  }

  @override
  Future<Either<String, List<PayProviderEntry>>> getPayProvidersByRegion(String region) async {
    try {
      final providers = await _dao.getPayProvidersByRegion(region);
      return Right(providers);
    } catch (e) {
      return Left('获取支付渠道失败: $e');
    }
  }

  @override
  Future<Either<String, List<PayProviderEntry>>> getActivePayProviders() async {
    try {
      final providers = await _dao.getActivePayProviders();
      return Right(providers);
    } catch (e) {
      return Left('获取有效支付渠道失败: $e');
    }
  }

  @override
  Future<Either<String, PayProviderEntry>> createPayProvider(PayProviderEntriesCompanion payProvider) async {
    try {
      final id = await _dao.createPayProvider(payProvider);

      // 注意：API暂无创建接口，仅本地创建
      final createdProvider = await _dao.getPayProviderById(id);

      return Right(createdProvider!);
    } catch (e) {
      return Left('创建支付渠道失败: $e');
    }
  }

  @override
  Future<Either<String, bool>> updatePayProvider(PayProviderEntriesCompanion payProvider) async {
    try {
      final success = await _dao.updatePayProvider(payProvider);

      // 注意：API暂无更新接口，仅本地更新

      return Right(success);
    } catch (e) {
      return Left('更新支付渠道失败: $e');
    }
  }

  @override
  Future<Either<String, bool>> deletePayProvider(int id) async {
    try {
      final deletedCount = await _dao.deletePayProvider(id);

      // 注意：API暂无删除接口，仅本地删除

      return Right(deletedCount > 0);
    } catch (e) {
      return Left('删除支付渠道失败: $e');
    }
  }

  @override
  Stream<List<PayProviderEntry>> watchAllPayProviders() {
    return _dao.watchAllPayProviders();
  }

  @override
  Stream<PayProviderEntry?> watchPayProviderById(int id) {
    return _dao.watchPayProviderById(id);
  }

  @override
  Stream<List<PayProviderEntry>> watchActivePayProviders() {
    return _dao.watchActivePayProviders();
  }

  @override
  Stream<List<PayProviderEntry>> watchPayProvidersByMethod(PayMethod method) {
    return _dao.watchPayProvidersByMethod(method);
  }

  @override
  Stream<List<PayProviderEntry>> watchPayProvidersByPayType(PayType payType) {
    return _dao.watchPayProvidersByPayType(payType);
  }

  /// 从服务器同步支付渠道数据
  Future<Either<String, List<PayProviderEntry>>> syncPayProvidersFromServer() async {
    try {
      final apiResponse = await _api.getPayProviders();
      final providers = apiResponse.data;

      if (providers != null) {
        // 清空本地数据
        final existingProviders = await _dao.getAllPayProviders();
        for (final provider in existingProviders) {
          await _dao.deletePayProvider(provider.id);
        }

        // 保存新数据
        for (final provider in providers) {
          await _dao.createPayProvider(PayProviderEntriesCompanion.insert(
            code: provider.code,
            name: provider.name,
            method: Value(provider.method),
            payType: Value(provider.payType),
            iconUrl: Value(provider.iconUrl),
            status: Value(provider.status),
            config: Value(provider.config),
            regions: Value(provider.regions),
            environment: Value(provider.environment),
            clientTypes: Value(provider.clientTypes),
            extra1: Value(provider.extra1),
            extra2: Value(provider.extra2),
            extra3: Value(provider.extra3),
            extra4: Value(provider.extra4),
          ));
        }

        return Right(providers);
      } else {
        return const Left('API返回空数据');
      }
    } catch (e) {
      return Left('同步支付渠道数据失败: $e');
    }
  }

}
