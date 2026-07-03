import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authtype_model.dart';


class AuthServiceConfig {
  /// 基础URL
  final String baseUrl;

  /// API密钥
  final String apiKey;

  /// 认证类型映射 - 指定每种认证类型使用哪种服务实现
  final Map<AuthType, AuthServiceType> authTypeMapping;

  /// 各种服务实现的额外配置
  final Map<AuthServiceType, Map<String, dynamic>> serviceConfigs;

  const AuthServiceConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.authTypeMapping,
    this.serviceConfigs = const {},
  });

  /// 获取指定认证类型的服务实现类型
  AuthServiceType getServiceTypeForAuthType(AuthType authType) {
    return authTypeMapping[authType] ?? AuthServiceType.rest; // 默认使用REST
  }

  /// 获取指定服务类型的配置
  Map<String, dynamic> getConfigForServiceType(AuthServiceType serviceType) {
    return serviceConfigs[serviceType] ?? {};
  }
}
