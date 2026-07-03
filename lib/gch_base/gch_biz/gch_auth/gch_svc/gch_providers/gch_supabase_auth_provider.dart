// providers/supabase_auth_provider.dart

import 'dart:async';
import 'package:guichao/gch_base/gch_cuowu/gch_cuowu_fanyi.dart';
import 'package:guichao/gch_base/gch_ink/gch_ink.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_config/gch_oauth_config.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authtype_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authuser_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_provider_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_providers/gch_apple_auth_native.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase
    hide AuthUser;
import 'package:guichao/gch_base/gch_biz/gch_common/gch_enums.dart';

/// Supabase认证提供者 - 精简版
class SupabaseAuthProvider extends AuthProvider
    implements CredentialAuthProvider, OtpAuthProvider, OAuthProvider {
  late final supabase.SupabaseClient _client;
  bool _initialized = false;

  @override
  String get providerId => 'supabase';

  @override
  String get providerName => 'Supabase Authentication';

  @override
  Set<AuthType> get supportedAuthTypes => {
        AuthType.email,
        AuthType.phone,
        AuthType.emailOtp,
        AuthType.phoneOtp,
        AuthType.apple,
        AuthType.verifycode, // 向后兼容
      };

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    if (_initialized) return;

    try {
      _client = supabase.Supabase.instance.client;
    } catch (_) {
      throw StateError('supabase_not_initialized');
    }
    _initialized = true;
  }

  @override
  Future<bool> isAvailable() async {
    return _initialized;
  }

  @override
  Future<void> dispose() async {
    _initialized = false;
  }

  // CredentialAuthProvider 实现
  @override
  Future<AuthResult> signInWithCredential(AuthRequest request) async {
    try {
      if (request.email != null && request.password != null) {
        return await _signInWithEmail(request.email!, request.password!);
      } else if (request.phone != null && request.password != null) {
        return await _signInWithPhone(request.phone!, request.password!);
      } else {
        return AuthResultImpl.failure(
          'invalid_credentials',
          errorCode: AuthErrorCode.invalidCredentials,
        );
      }
    } catch (e) {
      final errorMessage = e.toString();
      return AuthResultImpl.failure(
        errorMessage,
        errorCode: _detectErrorCode(errorMessage),
      );
    }
  }

  @override
  Future<AuthResult> signUpWithCredential(AuthRequest request) async {
    try {
      if (request.email != null && request.password != null) {
        return await _signUpWithEmail(request);
      } else if (request.phone != null && request.password != null) {
        return await _signUpWithPhone(request);
      } else {
        return AuthResultImpl.failure(
          'validation_failed',
          errorCode: AuthErrorCode.invalidInput,
        );
      }
    } catch (e) {
      final errorMessage = e.toString();
      return AuthResultImpl.failure(
        errorMessage,
        errorCode: _detectErrorCode(errorMessage),
      );
    }
  }

  @override
  Future<bool> resetPassword(String identifier) async {
    try {
      await _client.auth.resetPasswordForEmail(
        identifier,
        redirectTo: 'guichao://reset-callback/',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      // 确保用户已登录
      if (_client.auth.currentUser == null) {
        return false;
      }

      final response = await _client.auth.updateUser(
        supabase.UserAttributes(password: newPassword),
      );

      return response.user != null;
    } catch (e) {
      return false;
    }
  }

  // OtpAuthProvider 实现
  @override
  Future<bool> sendOtp(
    String identifier, {
    OtpType type = OtpType.email,
    String? captchaToken,
    bool shouldCreateUser = true,
  }) async {
    try {
      if (type == OtpType.email) {
        // 发送邮箱 OTP (同时包含验证码和 Magic Link)
        await _client.auth.signInWithOtp(
          email: identifier,
          emailRedirectTo: OAuthConfig.getRedirectUrl('email'),
          shouldCreateUser: shouldCreateUser, // 注册时true，密码重置时false
          captchaToken: captchaToken,
        );
      } else if (type == OtpType.sms) {
        // 发送手机 OTP
        await _client.auth.signInWithOtp(
          phone: identifier,
          shouldCreateUser: shouldCreateUser, // 注册时true，密码重置时false
          captchaToken: captchaToken,
        );
      } else {
        return false;
      }
      return true;
    } catch (e) {
      GchInk.app.error('发送 OTP 失败', e);
      rethrow;
    }
  }

  @override
  Future<AuthResult> verifyOtp(String identifier, String code,
      {OtpType type = OtpType.email}) async {
    try {
      final otpType =
          type == OtpType.email ? supabase.OtpType.email : supabase.OtpType.sms;

      final response = await _client.auth.verifyOTP(
        email: type == OtpType.email ? identifier : null,
        phone: type == OtpType.sms ? identifier : null,
        token: code,
        type: otpType,
      );

      return _convertSupabaseAuthResponse(response);
    } catch (e) {
      final errorMessage = e.toString();
      return AuthResultImpl.failure(
        errorMessage,
        errorCode: _detectErrorCode(errorMessage),
      );
    }
  }

  // OAuthProvider 实现
  @override
  Future<AuthResult> signInWithOAuth({
    String? authCode,
    String? idToken,
    String? accessToken,
    String? redirectUrl,
    Map<String, dynamic>? extraParams,
  }) async {
    try {
      final provider = extraParams?['provider'] as String?;
      if (provider == null) {
        return AuthResultImpl.failure(
          'oauth_provider_not_supported',
          errorCode: AuthErrorCode.oauthFailed,
        );
      }

      supabase.AuthResponse response;

      final providerLower = provider.toLowerCase();
      if (providerLower == 'apple') {
        response = await _signInWithApple();
      } else {
        return AuthResultImpl.failure(
          'oauth_provider_not_supported',
          errorCode: AuthErrorCode.oauthFailed,
        );
      }

      return _convertSupabaseAuthResponse(response);
    } catch (e) {
      final errorMessage = e.toString();
      return AuthResultImpl.failure(
        errorMessage,
        errorCode: _detectErrorCode(errorMessage),
      );
    }
  }

  @override
  Future<String?> getAuthorizationUrl({
    required String redirectUrl,
    List<String>? scopes,
    Map<String, String>? extraParams,
  }) async {
    try {
      final provider = extraParams?['provider'];
      if (provider == null) return null;

      // 根据最新的 Supabase Flutter API，signInWithOAuth 返回 void
      // 对于 Supabase，我们直接返回重定向 URL，因为 OAuth 流程会通过重定向处理
      GchInk.app
          .debug('OAuth authorization URL requested for provider: $provider');
      return redirectUrl;
    } catch (e) {
      GchInk.app.debug('Failed to get authorization URL: $e');
      return null;
    }
  }

  // 私有辅助方法
  Future<AuthResult> _signInWithEmail(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return _convertSupabaseAuthResponse(response);
  }

  Future<AuthResult> _signInWithPhone(String phone, String password) async {
    final response = await _client.auth.signInWithPassword(
      phone: phone,
      password: password,
    );
    return _convertSupabaseAuthResponse(response);
  }

  Future<AuthResult> _signUpWithEmail(AuthRequest request) async {
    final response = await _client.auth.signUp(
      email: request.email ?? '',
      password: request.password ?? '',
      data: request.metadata,
    );
    return _convertSupabaseSignupResponse(response);
  }

  Future<AuthResult> _signUpWithPhone(AuthRequest request) async {
    try {
      // 检查是否提供了验证码
      if (request.code == null) {
        // 如果没有验证码，发送 OTP 并提示用户
        await _client.auth.signInWithOtp(phone: request.phone);
        return AuthResultImpl.failure(
          'otp_required: ${request.phone}',
          errorCode: AuthErrorCode.invalidInput,
        );
      }

      // 如果有验证码，验证 OTP 并创建用户
      final response = await _client.auth.verifyOTP(
        phone: request.phone,
        token: request.code!,
        type: supabase.OtpType.sms,
      );

      if (response.user != null && response.session != null) {
        // 如果用户创建成功，更新用户元数据
        if (request.metadata?.isNotEmpty ?? false) {
          await _client.auth.updateUser(
            supabase.UserAttributes(data: request.metadata!),
          );
        }

        return _convertSupabaseSignupResponse(response);
      } else {
        return AuthResultImpl.failure(
          'otp_expired',
          errorCode: AuthErrorCode.invalidVerificationCode,
        );
      }
    } catch (e) {
      final errorMessage = e.toString();
      return AuthResultImpl.failure(
        errorMessage,
        errorCode: _detectErrorCode(errorMessage),
      );
    }
  }

  /// 转换Supabase认证响应 - 用于登录验证
  /// 返回错误码而非本地化消息，UI层通过GchCuowuFanyi转换为当前语言
  AuthResult _convertSupabaseAuthResponse(supabase.AuthResponse response) {
    if (response.user != null) {
      final user = response.user!;

      // 有用户但没有session的情况：登录失败
      if (response.session == null) {
        if (user.email != null && user.emailConfirmedAt == null) {
          return AuthResultImpl.failure(
            'email_not_confirmed',
            errorCode: AuthErrorCode.emailNotVerified,
          );
        }

        if (user.phone != null && user.phoneConfirmedAt == null) {
          return AuthResultImpl.failure(
            'phone_not_confirmed',
            errorCode: AuthErrorCode.phoneNotVerified,
          );
        }

        return AuthResultImpl.failure(
          'email_not_confirmed',
          errorCode: AuthErrorCode.emailNotVerified,
        );
      }

      // 有用户和session的情况：检查验证状态
      if (user.email?.toLowerCase() != "".toLowerCase() &&
          user.emailConfirmedAt == null) {
        return AuthResultImpl.failure(
          'email_not_confirmed',
          errorCode: AuthErrorCode.emailNotVerified,
        );
      }

      if (user.phone?.toLowerCase() != "".toLowerCase() &&
          user.phoneConfirmedAt == null) {
        return AuthResultImpl.failure(
          'phone_not_confirmed',
          errorCode: AuthErrorCode.phoneNotVerified,
        );
      }

      // 验证通过，返回成功结果
      final convertedUser = _convertSupabaseUser(user);
      return AuthResultImpl.success(
        user: convertedUser,
        token: response.session!.accessToken,
        refreshToken: response.session!.refreshToken,
        expiresAt: response.session!.expiresIn != null
            ? DateTime.now()
                .add(Duration(seconds: response.session!.expiresIn!))
            : null,
      );
    } else {
      return AuthResultImpl.failure(
        'invalid_credentials',
        errorCode: AuthErrorCode.invalidCredentials,
      );
    }
  }

  /// 转换Supabase注册响应 - 专门用于注册流程
  /// 返回错误码而非本地化消息，UI层通过GchCuowuFanyi转换为当前语言
  AuthResult _convertSupabaseSignupResponse(supabase.AuthResponse response) {
    if (response.user != null) {
      final user = response.user!;

      // 注册成功，无论有没有session都返回成功消息（通过failure传递消息）
      if (user.email != null && user.emailConfirmedAt == null) {
        return AuthResultImpl.failure(
          'signup_success_email_verify',
          errorCode: AuthErrorCode.signupSuccess,
        );
      }

      if (user.phone != null && user.phoneConfirmedAt == null) {
        return AuthResultImpl.failure(
          'signup_success_phone_verify',
          errorCode: AuthErrorCode.signupSuccess,
        );
      }

      return AuthResultImpl.failure(
        'signup_success_verify',
        errorCode: AuthErrorCode.signupSuccess,
      );
    } else {
      return AuthResultImpl.failure(
        'unexpected_failure',
        errorCode: AuthErrorCode.serverError,
      );
    }
  }

  /// 检测并转换Supabase错误到标准错误码
  /// 复用 GchCuowuFanyi.tiquCuowuma 的匹配逻辑
  AuthErrorCode _detectErrorCode(String errorMessage) {
    final errorCode = GchCuowuFanyi.tiquCuowuma(errorMessage);
    return _mapErrorCodeToAuthErrorCode(errorCode);
  }

  /// 将字符串错误码映射到 AuthErrorCode 枚举
  static AuthErrorCode _mapErrorCodeToAuthErrorCode(String code) {
    return switch (code) {
      // 凭证类
      'invalid_credentials' || 'user_not_found' => AuthErrorCode.invalidCredentials,
      'weak_password' || 'same_password' => AuthErrorCode.weakPassword,
      'bad_jwt' => AuthErrorCode.invalidToken,
      // 账号存在性
      'user_already_exists' || 'email_exists' || 'phone_exists' ||
      'identity_already_exists' => AuthErrorCode.userAlreadyExists,
      // 验证状态
      'email_not_confirmed' || 'provider_email_needs_verification' ||
      'email_address_not_authorized' || 'email_address_invalid' => AuthErrorCode.emailNotVerified,
      'phone_not_confirmed' => AuthErrorCode.phoneNotVerified,
      // OTP/验证码
      'otp_expired' || 'otp_disabled' || 'captcha_failed' => AuthErrorCode.invalidVerificationCode,
      // 会话
      'session_expired' || 'session_not_found' || 'refresh_token_not_found' ||
      'refresh_token_already_used' || 'reauthentication_needed' => AuthErrorCode.sessionExpired,
      // 账号状态
      'signup_disabled' => AuthErrorCode.signupDisabled,
      'user_banned' => AuthErrorCode.userBanned,
      // 频率限制
      'over_request_rate_limit' || 'over_email_send_rate_limit' ||
      'over_sms_send_rate_limit' => AuthErrorCode.tooManyRequests,
      // 发送失败
      'sms_send_failed' => AuthErrorCode.smsSendFailed,
      // OAuth
      'bad_oauth_state' || 'bad_oauth_callback' || 'oauth_provider_not_supported' ||
      'provider_disabled' || 'oauth_cancelled' || 'oauth_config_error' => AuthErrorCode.oauthFailed,
      // 网络
      'network_error' || 'request_timeout' => AuthErrorCode.networkError,
      // 默认
      _ => AuthErrorCode.unknown,
    };
  }

  AuthUser _convertSupabaseUser(supabase.User user) {
    final data = user.userMetadata ?? {};
    return AuthUser(
      userId: user.id,
      code: data['code']?.toString() ??
          (DateTime.now().millisecondsSinceEpoch % 1000000).toString(),
      email: user.email,
      phone: user.phone,
      name: data['name']?.toString() ?? 'New User',
      nickname: data['nickname']?.toString(),
      password: '',
      vipType: VipType.fromValue(_parseInt(data['viptype'] ?? data['vip_type'])),
      country: data['country']?.toString() ?? 'CN',
      createdAt: DateTime.parse(user.createdAt),
      updatedAt: user.updatedAt != null
          ? DateTime.parse(user.updatedAt!)
          : DateTime.now(),
      expiredAt: _parseExpiredAt(data['expiredat'] ?? data['expired_at']),
    );
  }

  /// 解析过期时间字段
  /// 服务端存储的是 UTC 时间，确保解析后统一为 UTC
  DateTime _parseExpiredAt(dynamic value) {
    if (value == null) return DateTime.now().toUtc();
    if (value is DateTime) return value.toUtc();
    if (value is String) {
      try {
        // 如果字符串不含时区信息，视为 UTC
        final hasTimezone = value.contains('Z') ||
            RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(value);
        final parsed = DateTime.parse(hasTimezone ? value : '${value}Z');
        return parsed.toUtc();
      } catch (_) {
        return DateTime.now().toUtc();
      }
    }
    if (value is int) {
      // Unix timestamp (seconds or milliseconds)
      if (value > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
      } else {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
      }
    }
    return DateTime.now().toUtc();
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// 原生 Apple 登录（iOS/Android/macOS/Web）
  Future<supabase.AuthResponse> _signInWithApple() async {
    GchInk.app.debug('[Apple OAuth] 开始 Apple 登录流程');

    final appleAuth = AppleAuthNative.instance;

    if (!appleAuth.isSupported) {
      GchInk.app.debug('[Apple OAuth] 平台不支持原生 Apple 登录，使用 OAuth 流程');
      return await _supabaseOAuthSignIn('apple');
    }

    try {
      GchInk.app.debug('[Apple OAuth] 调用 appleAuth.signIn()...');
      final result = await appleAuth.signIn();

      GchInk.app.debug('[Apple OAuth] signIn 结果:'
          '\n  - isSuccess: ${result.isSuccess}'
          '\n  - isCancelled: ${result.isCancelled}'
          '\n  - hasIdToken: ${result.idToken != null && result.idToken!.isNotEmpty}'
          '\n  - hasRawNonce: ${result.rawNonce != null}'
          '\n  - errorMessage: ${result.errorMessage}');

      if (result.isCancelled) {
        GchInk.app.info('[Apple OAuth] 用户取消了 Apple 登录');
        throw Exception('oauth_cancelled');
      }

      if (!result.isSuccess) {
        GchInk.app.error('[Apple OAuth] Apple 登录失败: ${result.errorMessage}');
        throw Exception('apple_auth_failed: ${result.errorMessage}');
      }

      if (result.idToken == null || result.idToken!.isEmpty) {
        GchInk.app.error('[Apple OAuth] Apple 返回的 idToken 为空');
        throw Exception('apple_token_missing');
      }

      GchInk.app.debug('[Apple OAuth] 开始调用 Supabase signInWithIdToken...'
          '\n  - idToken 长度: ${result.idToken!.length}'
          '\n  - rawNonce: ${result.rawNonce != null ? "已提供" : "未提供"}');

      // 传递 nonce 给 Supabase 用于验证
      // Apple 收到的是 SHA256(rawNonce)，Supabase 需要 rawNonce 来验证
      final response = await _client.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.apple,
        idToken: result.idToken!,
        nonce: result.rawNonce, // 原始 nonce，Supabase 会验证与 idToken 中的 nonce 声明匹配
      );

      GchInk.app.info('[Apple OAuth] Supabase 登录成功'
          '\n  - userId: ${response.user?.id}'
          '\n  - email: ${response.user?.email}'
          '\n  - hasSession: ${response.session != null}');

      return response;
    } catch (e, stackTrace) {
      GchInk.app.error('[Apple OAuth] Apple 登录异常', e, stackTrace);
      rethrow;
    }
  }

  /// Supabase OAuth 登录
  Future<supabase.AuthResponse> _supabaseOAuthSignIn(String provider) async {
    try {
      final callbackUrl = OAuthConfig.getRedirectUrl(provider);
      final oauthProvider = _getSupabaseOAuthProvider(provider);

      final success = await _client.auth.signInWithOAuth(
        oauthProvider,
        redirectTo: callbackUrl,
        authScreenLaunchMode: supabase.LaunchMode.externalApplication,
      );

      if (!success) {
        throw Exception('oauth_provider_not_supported');
      }

      // 等待认证完成
      return await _waitForAuthState();
    } catch (e) {
      GchInk.app.error('$provider OAuth 登录失败', e);
      rethrow;
    }
  }

  /// 等待认证状态变化
  Future<supabase.AuthResponse> _waitForAuthState() async {
    final completer = Completer<supabase.AuthResponse>();
    late StreamSubscription subscription;

    subscription = _client.auth.onAuthStateChange.listen((authState) {
      if (authState.event == supabase.AuthChangeEvent.signedIn &&
          authState.session != null) {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete(supabase.AuthResponse(
              session: authState.session!, user: authState.session!.user));
        }
      }
    });

    return await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        subscription.cancel();
        final session = _client.auth.currentSession;
        if (session != null) {
          return supabase.AuthResponse(session: session, user: session.user);
        }
        throw TimeoutException('OAuth 认证超时', const Duration(seconds: 30));
      },
    );
  }

  /// 获取 Supabase OAuth 提供者
  supabase.OAuthProvider _getSupabaseOAuthProvider(String provider) {
    switch (provider) {
      case 'apple':
        return supabase.OAuthProvider.apple;
      default:
        throw ArgumentError('oauth_provider_not_supported');
    }
  }
}
