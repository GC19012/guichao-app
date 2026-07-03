import 'dart:async';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_store/gch_storage/gch_adapter.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_model/gch_payprovider_model.dart';

/// PayProvider专用存储适配器接口
///
/// 在通用GchStorageAdapter基础上，添加PayProvider特有的查询方法
abstract interface class PayProviderStorageAdapter implements GchStorageAdapter<PayProviderEntry, int> {

  /// 根据代码获取PayProvider
  Future<PayProviderEntry?> getByCode(String code);

  /// 根据支付方式类型获取PayProvider列表
  Future<List<PayProviderEntry>> getByMethod(PayMethod method);

  /// 根据支付类型获取PayProvider列表
  Future<List<PayProviderEntry>> getByPayType(PayType payType);

  /// 获取有效的PayProvider列表(status=1)
  Future<List<PayProviderEntry>> getActive();

  /// 监听有效PayProvider列表变化
  Stream<List<PayProviderEntry>> watchActive();

  /// 根据环境获取PayProvider列表
  Future<List<PayProviderEntry>> getByEnvironment(Environment environment);

  /// 根据客户端类型获取PayProvider列表
  Future<List<PayProviderEntry>> getByClientType(String clientType);

  /// 根据地区获取PayProvider列表
  Future<List<PayProviderEntry>> getByRegion(String region);

  /// 获取在线支付PayProvider列表
  Future<List<PayProviderEntry>> getOnlinePayProviders();

  /// 获取应用内购买PayProvider列表
  Future<List<PayProviderEntry>> getInAppPurchaseProviders();

  /// 获取卡密兑换PayProvider列表
  Future<List<PayProviderEntry>> getCardKeyProviders();

  /// 监听所有PayProvider变化
  Stream<List<PayProviderEntry>> watchAll();

  /// 监听特定支付方式类型变化
  Stream<List<PayProviderEntry>> watchByMethod(PayMethod method);

  /// 监听特定支付类型变化
  Stream<List<PayProviderEntry>> watchByPayType(PayType payType);

  /// 检查code是否存在
  Future<bool> existsByCode(String code);
}
