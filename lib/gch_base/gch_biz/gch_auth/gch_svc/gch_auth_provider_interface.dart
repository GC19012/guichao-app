// auth_provider_interface.dart

import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authtype_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authuser_model.dart';

/// 认证事件类型
enum AuthEventType {
  signedIn,
  signedOut,
  tokenRefreshed,
  tokenExpired,
  userUpdated,
  passwordRecovery,
  error,
}

/// 认证事件
class AuthEvent {
  final AuthEventType type;
  final AuthUser? user;
  final AuthSession? session;
  final String? message;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const AuthEvent({
    required this.type,
    this.user,
    this.session,
    this.message,
    required this.timestamp,
    this.data = const {},
  });

  factory AuthEvent.signedIn(AuthUser user, AuthSession session) => AuthEvent(
    type: AuthEventType.signedIn,
    user: user,
    session: session,
    timestamp: DateTime.now(),
  );

  factory AuthEvent.signedOut([String? reason]) => AuthEvent(
    type: AuthEventType.signedOut,
    message: reason,
    timestamp: DateTime.now(),
  );

  factory AuthEvent.tokenRefreshed(AuthSession session) => AuthEvent(
    type: AuthEventType.tokenRefreshed,
    session: session,
    timestamp: DateTime.now(),
  );

  factory AuthEvent.tokenExpired([String? sessionId]) => AuthEvent(
    type: AuthEventType.tokenExpired,
    message: sessionId,
    timestamp: DateTime.now(),
  );

  factory AuthEvent.userUpdated(AuthUser user) => AuthEvent(
    type: AuthEventType.userUpdated,
    user: user,
    timestamp: DateTime.now(),
  );

  factory AuthEvent.passwordRecovery(String email) => AuthEvent(
    type: AuthEventType.passwordRecovery,
    message: email,
    timestamp: DateTime.now(),
  );

  factory AuthEvent.error(String message, [Map<String, dynamic>? data]) => AuthEvent(
    type: AuthEventType.error,
    message: message,
    timestamp: DateTime.now(),
    data: data ?? {},
  );
}

/// 认证提供者状态
class AuthProviderState {
  final bool isAuthenticated;
  final AuthUser? user;
  final AuthSession? session;
  final DateTime? lastActivity;

  const AuthProviderState({
    required this.isAuthenticated,
    this.user,
    this.session,
    this.lastActivity,
  });

  AuthProviderState copyWith({
    bool? isAuthenticated,
    AuthUser? user,
    AuthSession? session,
    DateTime? lastActivity,
  }) {
    return AuthProviderState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      session: session ?? this.session,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }
}

/// 标准错误码
enum AuthErrorCode {
  unknown('UNKNOWN'),
  networkError('NETWORK_ERROR'),
  serverError('SERVER_ERROR'),
  invalidInput('INVALID_INPUT'),
  // 凭证类
  invalidCredentials('INVALID_CREDENTIALS'),
  userNotFound('USER_NOT_FOUND'),
  weakPassword('WEAK_PASSWORD'),
  invalidToken('INVALID_TOKEN'),
  // 账号存在性
  userAlreadyExists('USER_ALREADY_EXISTS'),
  // 验证状态
  emailNotVerified('EMAIL_NOT_VERIFIED'),
  phoneNotVerified('PHONE_NOT_VERIFIED'),
  invalidVerificationCode('INVALID_VERIFICATION_CODE'),
  // 会话
  sessionExpired('SESSION_EXPIRED'),
  // 账号状态
  signupDisabled('SIGNUP_DISABLED'),
  userBanned('USER_BANNED'),
  // 频率限制
  tooManyRequests('TOO_MANY_REQUESTS'),
  // 发送失败
  smsSendFailed('SMS_SEND_FAILED'),
  // OAuth
  oauthFailed('OAUTH_FAILED'),
  // 注册成功（特殊）
  signupSuccess('SIGNUP_SUCCESS'),
  ;

  const AuthErrorCode(this.code);
  final String code;
}

/// 认证结果
abstract class AuthResult {
  bool get isSuccess;
  String? get errorMessage;
  AuthErrorCode? get errorCode;
  AuthUser? get user;
  String? get token;
  String? get refreshToken;
  DateTime? get expiresAt;
}

/// 基础认证提供者接口
abstract class AuthProvider {
  /// 提供者标识符
  String get providerId;
  
  /// 提供者名称
  String get providerName;
  
  /// 支持的认证类型
  Set<AuthType> get supportedAuthTypes;
  
  /// 是否已初始化
  bool get isInitialized;
  
  /// 初始化提供者
  Future<void> initialize(Map<String, dynamic> config);
  
  /// 检查提供者是否可用
  Future<bool> isAvailable();
  
  /// 销毁提供者
  Future<void> dispose();
}

/// 凭据认证提供者（邮箱/密码、手机/验证码）
abstract class CredentialAuthProvider extends AuthProvider {
  /// 使用凭据登录
  Future<AuthResult> signInWithCredential(AuthRequest request);
  
  /// 使用凭据注册
  Future<AuthResult> signUpWithCredential(AuthRequest request); 
  
  /// 重置密码
  Future<bool> resetPassword(String identifier);
  
  /// 修改密码
  Future<bool> changePassword(String oldPassword, String newPassword);
}

/// OTP认证提供者（验证码）
abstract class OtpAuthProvider extends AuthProvider {
  /// 发送OTP
  ///
  /// [identifier] 邮箱或手机号
  /// [type] OTP类型（email/sms）
  /// [captchaToken] 人机验证token
  /// [shouldCreateUser] 是否自动创建用户（注册时true，密码重置时false）
  Future<bool> sendOtp(
    String identifier, {
    OtpType type = OtpType.email,
    String? captchaToken,
    bool shouldCreateUser = true,
  });

  /// 验证OTP
  Future<AuthResult> verifyOtp(String identifier, String code, {OtpType type = OtpType.email});
}

/// OAuth认证提供者（第三方登录）
abstract class OAuthProvider extends AuthProvider {
  /// OAuth登录
  Future<AuthResult> signInWithOAuth({
    String? authCode,
    String? idToken,
    String? accessToken,
    String? redirectUrl,
    Map<String, dynamic>? extraParams,
  });
  
  /// 获取授权URL
  Future<String?> getAuthorizationUrl({
    required String redirectUrl,
    List<String>? scopes,
    Map<String, String>? extraParams,
  });
}

/// 安全存储认证提供者 - 替代生物识别
abstract class SecureStorageAuthProvider extends AuthProvider {
  /// 检查安全存储是否可用
  Future<bool> isSecureStorageAvailable();
  
  /// 使用存储的凭据登录
  Future<AuthResult> signInWithStoredCredentials();
  
  /// 启用安全存储
  Future<bool> enableSecureStorage(String userId, Map<String, String> credentials);
  
  /// 禁用安全存储
  Future<bool> disableSecureStorage();
}

/// 会话管理提供者（扩展事件支持）
abstract class SessionProvider {
  /// 获取当前会话
  Future<AuthSession?> getCurrentSession();
  
  /// 从认证服务获取当前用户信息
  Future<AuthUser?> getUser({String? accessToken});
  
  /// 刷新会话
  Future<bool> refreshSession();
  
  /// 清除会话
  Future<void> clearSession();
  
  /// 会话状态变化流
  Stream<AuthSession?> get sessionStream;
  
  /// 认证事件流（新增）
  Stream<AuthEvent> get authEvents;
  
  /// 认证状态流（新增）
  Stream<AuthProviderState> get authStateChanges;
  
  /// 当前认证状态（新增）
  AuthProviderState get currentState;

  /// 手动触发用户信息更新事件
  /// 用于本地检测到状态变化（如 VIP 过期）时主动通知监听者
  void handleUserUpdate(AuthUser user);
}

/// 用户配置文件提供者
abstract class UserProfileProvider {
  /// 获取用户配置文件
  Future<AuthUser?> getUserProfile(String userId);
  
  /// 更新用户配置文件
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> updates);
  
  /// 删除用户配置文件
  Future<bool> deleteUserProfile(String userId);
}

/// OTP类型枚举
enum OtpType {
  email,
  sms,
  voice,
}

/// 认证会话
class AuthSession {
  final String userId;
  final String token;
  final String? refreshToken;
  final DateTime expiresAt;
  final Map<String, dynamic> metadata;
  
  const AuthSession({
    required this.userId,
    required this.token,
    this.refreshToken,
    required this.expiresAt,
    this.metadata = const {},
  });
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isExpired;
}

/// 认证结果实现
class AuthResultImpl implements AuthResult {
  final bool _isSuccess;
  final String? _errorMessage;
  final AuthErrorCode? _errorCode;
  final AuthUser? _user;
  final String? _token;
  final String? _refreshToken;
  final DateTime? _expiresAt;
  
  const AuthResultImpl({
    required bool isSuccess,
    String? errorMessage,
    AuthErrorCode? errorCode,
    AuthUser? user,
    String? token,
    String? refreshToken,
    DateTime? expiresAt,
  }) : _isSuccess = isSuccess,
       _errorMessage = errorMessage,
       _errorCode = errorCode,
       _user = user,
       _token = token,
       _refreshToken = refreshToken,
       _expiresAt = expiresAt;
  
  @override
  bool get isSuccess => _isSuccess;
  
  @override
  String? get errorMessage => _errorMessage;
  
  @override
  AuthErrorCode? get errorCode => _errorCode;
  
  @override
  AuthUser? get user => _user;
  
  @override
  String? get token => _token;
  
  @override
  String? get refreshToken => _refreshToken;
  
  @override
  DateTime? get expiresAt => _expiresAt;
  
  /// 成功结果工厂方法
  factory AuthResultImpl.success({
    AuthUser? user,
    String? token,
    String? refreshToken,
    DateTime? expiresAt,
  }) {
    return AuthResultImpl(
      isSuccess: true,
      user: user,
      token: token,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }
  
  /// 失败结果工厂方法
  factory AuthResultImpl.failure(String errorMessage, {AuthErrorCode? errorCode}) {
    return AuthResultImpl(
      isSuccess: false,
      errorMessage: errorMessage,
      errorCode: errorCode ?? AuthErrorCode.unknown,
    );
  }
}
