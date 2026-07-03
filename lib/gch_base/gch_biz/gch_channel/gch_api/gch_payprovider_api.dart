import 'package:dio/dio.dart';

import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_api/gch_client/gch_api_client.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_model/gch_payprovider_model.dart';

/// 支付渠道API接口
class PayProviderApi {
  final DataApiClient _apiClient;

  PayProviderApi({required DataApiClient apiClient}) : _apiClient = apiClient;

  /// 初始化API客户端
  void initializeApiClient() {
    // 这里可以添加支付渠道相关的API初始化逻辑
  }

  /// 从 JSON 创建 PayProviderEntry
  PayProviderEntry _payProviderFromJson(Map<String, dynamic> json) {
    return PayProviderEntry(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      method: json['method'] as int,
      payType: json['payType'] as int,
      iconUrl: json['iconUrl'] as String?,
      status: json['status'] as int,
      config: json['config'] as String?,
      regions: json['regions'] as String?,
      environment: json['environment'] as String,
      clientTypes: json['clientTypes'] as String?,
      extra1: json['extra1'] as int?,
      extra2: json['extra2'] as int?,
      extra3: json['extra3'] as String?,
      extra4: json['extra4'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),
    );
  }

  /// 从服务器获取所有支付渠道
  Future<Response<List<PayProviderEntry>>> getPayProviders() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/pay-providers');
    final providersJson = response.data?['data'] as List<dynamic>? ?? [];
    final providers = providersJson.map((json) => _payProviderFromJson(json as Map<String, dynamic>)).toList();
    return Response(
      data: providers,
      requestOptions: response.requestOptions,
      statusCode: response.statusCode,
    );
  }



  /// 根据代码从服务器获取支付渠道
  Future<Response<PayProviderEntry?>> getPayProviderByCode(String code) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/payproviders/bycode/$code');
    final data = response.data?['data'];
    final provider = data != null ? _payProviderFromJson(data as Map<String, dynamic>) : null;
    return Response(
      data: provider,
      requestOptions: response.requestOptions,
      statusCode: response.statusCode,
    );
  }

  /// 根据支付方式类型从服务器获取支付渠道
  Future<Response<List<PayProviderEntry>>> getPayProvidersByMethod(PayMethod method) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/payproviders/bymethod/${method.value}');
    final providersJson = response.data?['data'] as List<dynamic>? ?? [];
    final providers = providersJson.map((json) => _payProviderFromJson(json as Map<String, dynamic>)).toList();
    return Response(
      data: providers,
      requestOptions: response.requestOptions,
      statusCode: response.statusCode,
    );
  }

  /// 根据支付类型从服务器获取支付渠道
  Future<Response<List<PayProviderEntry>>> getPayProvidersByPayType(PayType payType) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/payproviders/bypaytype/${payType.value}');
    final providersJson = response.data?['data'] as List<dynamic>? ?? [];
    final providers = providersJson.map((json) => _payProviderFromJson(json as Map<String, dynamic>)).toList();
    return Response(
      data: providers,
      requestOptions: response.requestOptions,
      statusCode: response.statusCode,
    );
  }



  /// 根据客户端类型从服务器获取支付渠道
  Future<Response<List<PayProviderEntry>>> getPayProvidersByClientType(String clientType) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/payproviders/byclienttype/$clientType');
    final providersJson = response.data?['data'] as List<dynamic>? ?? [];
    final providers = providersJson.map((json) => _payProviderFromJson(json as Map<String, dynamic>)).toList();
    return Response(
      data: providers,
      requestOptions: response.requestOptions,
      statusCode: response.statusCode,
    );
  }

  /// 根据地区从服务器获取支付渠道
  Future<Response<List<PayProviderEntry>>> getPayProvidersByRegion(String region) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/payproviders/byregion/$region');
    final providersJson = response.data?['data'] as List<dynamic>? ?? [];
    final providers = providersJson.map((json) => _payProviderFromJson(json as Map<String, dynamic>)).toList();
    return Response(
      data: providers,
      requestOptions: response.requestOptions,
      statusCode: response.statusCode,
    );
  }

  /// 获取有效的支付渠道
  Future<Response<List<PayProviderEntry>>> getActivePayProviders() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/payproviders/active');
    final providersJson = response.data?['data'] as List<dynamic>? ?? [];
    final providers = providersJson.map((json) => _payProviderFromJson(json as Map<String, dynamic>)).toList();
    return Response(
      data: providers,
      requestOptions: response.requestOptions,
      statusCode: response.statusCode,
    );
  }

}
