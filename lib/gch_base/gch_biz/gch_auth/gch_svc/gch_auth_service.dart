// auth_service.dart

import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authtype_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authuser_model.dart';
/// 第三方服务接口
abstract class ThirdPartyService {
  /// 服务名称
  String get serviceName;

  /// 检查服务是否可用
  Future<bool> isAvailable();

  /// 初始化服务
  Future<void> initialize(Map<String, dynamic> config);

  /// 获取响应流
  Stream<dynamic> respStream();
}

/// 第三方登录服务接口
abstract class ThirdPartyAuthService extends ThirdPartyService {
  /// 发起认证请求
  Future<void> auth(Map<String, dynamic> params);
}

/// 第三方支付服务接口
abstract class ThirdPartyPaymentService extends ThirdPartyService {
  /// 发起支付请求
  Future<void> pay(Map<String, dynamic> params);
}

// 身份验证服务接口
abstract class AuthService {
  // 获取指定的第三方服务
  T getThirdPartyService<T extends ThirdPartyService>(String serviceName);

  // 帐户管理
  Future<AuthResponse> signIn({required AuthRequest request});
  Future<AuthResponse> signUp({required AuthRequest request});
  Future<AuthResponse> signOut();
  // 密码管理
  Future<bool> resetPassword({required String email});
  Future<bool> confirmPasswordReset({required String code, required String newPassword});
  Future<bool> changePassword({required String oldPassword, required String newPassword});

  // 手机验证
  Future<bool> sendSmsCode({required String phone});
  Future<bool> verifySmsCode({required String phone, required String code});

  // OTP 验证
  Future<AuthResponse> verifyOtp({required String email, required String code});
  Future<AuthResponse> signInWithOtp({required String email});

  // OAuth2登录
  Future<AuthResponse> signInWithOAuth2({
    required String provider,
    String? accessToken,
    String? idToken,
    String? authCode,
    String? redirectUrl,
    Map<String, dynamic>? extraParams,
  });
  // 会话管理
  Future<AuthUser?> getCurrentUser();
  Future<String?> getToken();
  Future<bool> refreshToken();
  // 用户状态监听
  Stream<AuthUser?> get onAuthStateChanged;
}
