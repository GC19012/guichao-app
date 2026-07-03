// apple_auth_interface.dart
// Apple 认证接口定义

/// Apple 认证结果
class AppleAuthResult {
  final bool isSuccess;
  final bool isCancelled;
  final bool isUnsupported;
  final String? idToken;
  final String? accessToken;
  final String? authorizationCode;
  final String? rawNonce; // 原始 nonce，用于 Supabase 验证
  final String? errorMessage;

  const AppleAuthResult._({
    required this.isSuccess,
    required this.isCancelled,
    required this.isUnsupported,
    this.idToken,
    this.accessToken,
    this.authorizationCode,
    this.rawNonce,
    this.errorMessage,
  });

  /// 成功结果
  factory AppleAuthResult.success({
    required String idToken,
    String? accessToken,
    String? authorizationCode,
    String? rawNonce,
  }) {
    return AppleAuthResult._(
      isSuccess: true,
      isCancelled: false,
      isUnsupported: false,
      idToken: idToken,
      accessToken: accessToken,
      authorizationCode: authorizationCode,
      rawNonce: rawNonce,
    );
  }
  
  /// 用户取消
  factory AppleAuthResult.cancelled() {
    return const AppleAuthResult._(
      isSuccess: false,
      isCancelled: true,
      isUnsupported: false,
    );
  }
  
  /// 平台不支持
  factory AppleAuthResult.unsupported() {
    return const AppleAuthResult._(
      isSuccess: false,
      isCancelled: false,
      isUnsupported: true,
      errorMessage: '当前平台不支持 Apple Sign-In',
    );
  }
  
  /// 错误结果
  factory AppleAuthResult.error(String message) {
    return AppleAuthResult._(
      isSuccess: false,
      isCancelled: false,
      isUnsupported: false,
      errorMessage: message,
    );
  }
}

/// Apple 认证接口
abstract class AppleAuthInterface {
  /// 是否支持当前平台
  bool get isSupported;
  
  /// 执行 Apple 登录
  Future<AppleAuthResult> signIn();
  
  /// 登出
  Future<void> signOut();
}
