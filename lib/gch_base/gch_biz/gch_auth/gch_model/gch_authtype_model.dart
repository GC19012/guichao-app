import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authuser_model.dart';

enum AuthServiceType {
  rest,
  supabase,
  grpc,
  websocket,
}

/// 认证类型枚举
enum AuthType {
  email,    // 邮箱密码登录
  phone,    // 手机号密码登录
  emailOtp, // 邮箱验证码登录
  phoneOtp, // 手机号验证码登录
  apple,    // Apple OAuth登录
  verifycode,    // 验证码登录（向后兼容）
}
enum OAuthProviderType {
  apple,
}
class OAuthResult {
  final bool success;
  final String? accessToken;
  final String? idToken;
  final String? authCode;
  final Map<String, dynamic>? userData;
  final String? errorMessage;

  OAuthResult({
    required this.success,
    this.accessToken,
    this.idToken,
    this.authCode,
    this.userData,
    this.errorMessage,
  });
}
class AuthResponse {
  final AuthUser? user;
  final String? token;
  final String? refreshToken;
  final DateTime? expiresAt;
  final String? errorMessage;

  AuthResponse({
    this.user,
    this.token,
    this.refreshToken,
    this.expiresAt,
    this.errorMessage,
  });

  bool get isSuccess => errorMessage == null;
}

// 登录/注册/重置密码请求参数
class AuthRequest {
  /// 邮箱
  final String? email;

  /// 密码
  final String? password;

  /// 手机号
  final String? phone;

  /// 验证码
  final String? code;

  /// 认证类型，例如 'email', 'phone', 'apple' 等
  final String? authType;

  /// 额外元数据
  final Map<String, dynamic>? metadata;

  AuthRequest({
    this.email,
    this.password,
    this.phone,
    this.code,
    this.authType,
    this.metadata,
  });

  /// 创建邮箱密码登录请求
  factory AuthRequest.withEmail({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) {
    return AuthRequest(
      email: email,
      password: password,
      authType: 'email',
      metadata: metadata,
    );
  }

  /// 创建手机号验密码登录请求
  factory AuthRequest.withPhone({
    required String phone,
    required String password,
    Map<String, dynamic>? metadata,
  }) {
    return AuthRequest(
      phone: phone,
      password: password,
      authType: 'phone',
      metadata: metadata,
    );
  }

  /// 创建社交登录请求
  factory AuthRequest.withOAuth({
    required String provider,
    String? accessToken,
    String? idToken,
    Map<String, dynamic>? userData,
    Map<String, dynamic>? metadata,
  }) {
    return AuthRequest(
      authType: provider,
      metadata: {
        'accessToken': accessToken,
        'idToken': idToken,
        'userData': userData,
        ...?metadata,
      },
    );
  }

  /// 创建手机号验证码登录请求
  factory AuthRequest.withPhoneVerifyCode({
    required String phone,
    required String code,
    Map<String, dynamic>? metadata,
  }) {
    return AuthRequest(
      phone: phone,
      code: code,
      authType: 'phoneOtp',
      metadata: metadata,
    );
  }

  /// 创建邮箱验证码登录请求
  factory AuthRequest.withEmailVerifyCode({
    required String email,
    required String code,
    Map<String, dynamic>? metadata,
  }) {
    return AuthRequest(
      email: email,
      code: code,
      authType: 'emailOtp',
      metadata: metadata,
    );
  }

  /// 创建用于注册的请求
  factory AuthRequest.forSignUp({
    String? email,
    String? password,
    String? phone,
    String? name,
    String? nickname,
    String? country,
    Map<String, dynamic>? metadata,
  }) {
    final combinedMetadata = {
      if (name != null) 'name': name,
      if (nickname != null) 'nickname': nickname,
      if (country != null) 'country': country,
      ...?metadata,
    };

    return AuthRequest(
      email: email,
      password: password,
      phone: phone,
      metadata: combinedMetadata,
      authType: email != null ? 'email' : 'phone',
    );
  }
}

