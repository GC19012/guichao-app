// auth_manager.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:guichao/gch_base/gch_core/gch_net_guard.dart';
import 'package:guichao/gch_base/gch_prefs/gch_store.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authtype_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authuser_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_provider_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_common/gch_enums.dart';

/// 认证管理器 - 统一管理所有认证提供者
class AuthManager {
  final Map<String, AuthProvider> _providers = {};
  final Map<AuthType, String> _authTypeMapping = {};
  final SessionProvider _sessionProvider;
  final UserProfileProvider _userProfileProvider;
  final GchStore _store;

  // 响应式网络状态管理
  bool _online = true;
  StreamSubscription<bool>? _networkSub;

  // 用户状态追踪（内存缓存，启动时从 Store 加载）
  String? _lastUserId;
  VipType? _lastVipType;
  DateTime? _lastRemoteUserFetch;
  DateTime? _skipRemoteFetchUntil;
  int _remoteFetchErrorStreak = 0;
  DateTime? _lastUserRefreshRequest;
  
  static const Duration _remoteFetchCooldown = Duration(seconds: 5);
  static const Duration _remoteBackoffDuration = Duration(seconds: 30);
  static const int _maxRemoteErrorsBeforeBackoff = 3;

  AuthManager({
    required SessionProvider sessionProvider,
    required UserProfileProvider userProfileProvider,
    required GchStore store,
  })  : _sessionProvider = sessionProvider,
        _userProfileProvider = userProfileProvider,
        _store = store {
    _initNetworkListener();
    _loadTracking();
  }

  /// 从 Store 加载用户追踪状态
  void _loadTracking() {
    _lastUserId = _store.getStringSync('last_uid');
    final vip = _store.getIntSync('last_vip');
    _lastVipType = vip != null ? VipType.fromValue(vip) : null;
  }

  /// 保存用户追踪状态到 Store
  Future<void> _saveTracking() async {
    if (_lastUserId != null) {
      await _store.setString('last_uid', _lastUserId!);
    }
    if (_lastVipType != null) {
      await _store.setInt('last_vip', _lastVipType!.value);
    }
  }
  
  /// 初始化网络状态监听 - 响应式设计
  void _initNetworkListener() {
    // 获取初始状态
    _online = GchNetGuard.isReachable;

    // 监听网络状态变化流
    _networkSub = GchNetGuard.reachabilityStream.listen(
      (online) {
        if (_online != online) {
          print('AuthManager 网络状态变化: $_online -> $online');
          _online = online;
        }
      },
      onError: (error) {
        print('AuthManager 网络监听异常: $error');
        _online = true; // 容错处理
      },
    );
  }

  /// 认证事件流 - 统一的事件通知
  Stream<AuthEvent> get authEvents => _sessionProvider.authEvents;

  /// 认证状态变化流 - 统一的状态管理
  Stream<AuthProviderState> get authStateChanges => _sessionProvider.authStateChanges;

  /// 当前认证状态
  AuthProviderState get currentAuthState => _sessionProvider.currentState;
  
  /// 在线状态 - 本地缓存，实时同步
  bool get online => _online;

  /// 注册认证提供者
  Future<void> registerProvider(
    AuthProvider provider, {
    bool setAsDefault = false,
  }) async {
    await provider.initialize({});
    _providers[provider.providerId] = provider;

    // 为支持的认证类型建立映射
    for (final authType in provider.supportedAuthTypes) {
      if (setAsDefault || !_authTypeMapping.containsKey(authType)) {
        _authTypeMapping[authType] = provider.providerId;
      }
    }
  }

  /// 设置认证类型映射
  void setAuthTypeMapping(AuthType authType, String providerId) {
    if (!_providers.containsKey(providerId)) {
      throw ArgumentError('Provider $providerId not registered');
    }
    _authTypeMapping[authType] = providerId;
  }

  /// 获取指定类型的提供者
  T? getProvider<T extends AuthProvider>(String providerId) {
    final provider = _providers[providerId];
    return provider is T ? provider : null;
  }

  /// 根据认证类型获取提供者
  AuthProvider? getProviderByAuthType(AuthType authType) {
    final providerId = _authTypeMapping[authType];
    return providerId != null ? _providers[providerId] : null;
  }

  /// 获取所有支持指定认证类型的提供者
  List<AuthProvider> getProvidersByAuthType(AuthType authType) {
    return _providers.values.where((provider) => provider.supportedAuthTypes.contains(authType)).toList();
  }

  /// 登录
  Future<AuthResult> signIn(AuthRequest request) async {
    final authType = _determineAuthType(request);
    final provider = getProviderByAuthType(authType);

    if (provider == null) {
      return AuthResultImpl.failure('No provider available for auth type: $authType');
    }

    try {
      AuthResult result;

      if (provider is CredentialAuthProvider) {
        result = await provider.signInWithCredential(request);
      } else if (provider is OtpAuthProvider && request.code != null) {
        final identifier = request.email ?? request.phone ?? '';
        result = await provider.verifyOtp(identifier, request.code!);
      } else {
        return AuthResultImpl.failure('Unsupported authentication method');
      }

      return result;
    } catch (e) {
      return AuthResultImpl.failure('Authentication failed: $e');
    }
  }

  /// 注册
  Future<AuthResult> signUp(AuthRequest request) async {
    final authType = _determineAuthType(request);
    final provider = getProviderByAuthType(authType);

    if (provider is! CredentialAuthProvider) {
      return AuthResultImpl.failure('Provider does not support registration');
    }

    try {
      return await provider.signUpWithCredential(request);
    } catch (e) {
      return AuthResultImpl.failure('Registration failed: $e');
    }
  }

  /// OAuth登录
  Future<AuthResult> signInWithOAuth({
    required String providerId,
    String? authCode,
    String? idToken,
    String? accessToken,
    String? redirectUrl,
    Map<String, dynamic>? extraParams,
  }) async {
    final provider = getProvider<OAuthProvider>(providerId);

    if (provider == null) {
      return AuthResultImpl.failure('OAuth provider not found: $providerId');
    }

    try {
      return await provider.signInWithOAuth(
        authCode: authCode,
        idToken: idToken,
        accessToken: accessToken,
        redirectUrl: redirectUrl,
        extraParams: extraParams,
      );
    } catch (e) {
      return AuthResultImpl.failure('OAuth authentication failed: $e');
    }
  }

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
  }) async {
    final authType = type == OtpType.email ? AuthType.emailOtp : AuthType.phoneOtp;
    final provider = getProviderByAuthType(authType);

    if (provider is! OtpAuthProvider) {
      return false;
    }

    try {
      return await provider.sendOtp(
        identifier,
        type: type,
        captchaToken: captchaToken,
        shouldCreateUser: shouldCreateUser,
      );
    } catch (e) {
      return false;
    }
  }

  /// 验证OTP
  Future<AuthResult> verifyOtp(String identifier, String code, {OtpType type = OtpType.email}) async {
    final authType = type == OtpType.email ? AuthType.emailOtp : AuthType.phoneOtp;
    final provider = getProviderByAuthType(authType);

    if (provider is! OtpAuthProvider) {
      return AuthResultImpl.failure('OTP provider not available');
    }

    try {
      return await provider.verifyOtp(identifier, code, type: type);
    } catch (e) {
      return AuthResultImpl.failure('OTP verification failed: $e');
    }
  }

  /// 使用存储的凭据登录（替代生物识别）
  Future<AuthResult> signInWithStoredCredentials() async {
    try {
      final refreshed = await _sessionProvider.refreshSession();
      if (refreshed) {
        final currentUser = await getCurrentUser();
        if (currentUser != null) {
          return AuthResultImpl.success(user: currentUser);
        }
      }
      return AuthResultImpl.failure('Stored credentials authentication not available');
    } catch (e) {
      return AuthResultImpl.failure('Stored credentials authentication failed: $e');
    }
  }

  /// 登出
  Future<bool> signOut() async {
    try {
      await _sessionProvider.clearSession();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 删除账号
  Future<bool> deleteAccount() async {
    try {
      // 调用后端API删除账号
      // TODO: 实际API调用需要在 user_setting_notifier 中使用 apiDelete
      await _sessionProvider.clearSession();
      return true;
    } catch (e) {
      debugPrint('删除账号失败: $e');
      return false;
    }
  }

  /// 获取当前用户 - 默认使用缓存，可通过 forceRemote 控制服务端刷新
  Future<AuthUser?> getCurrentUser({bool forceRemote = false}) async {
    print('AuthManager getCurrentUser - 在线状态: $_online, forceRemote: $forceRemote'); // 调试日志
    
    // 获取当前有效会话
    final session = await _sessionProvider.getCurrentSession();
    if (session == null || !session.isValid) {
      print('AuthManager getCurrentUser - 无有效会话'); // 调试日志
      return null;
    }
    
    if (forceRemote) {
      print('AuthManager getCurrentUser - 强制刷新用户信息'); // 调试日志
      final refreshed = await refreshCurrentUser(force: true, session: session);
      if (refreshed != null) {
        return refreshed;
      }
      print('AuthManager getCurrentUser - 强制刷新失败，回退到缓存'); // 调试日志
    }

    // 使用当前状态（缓存的用户信息）
    final currentState = _sessionProvider.currentState;
    print('AuthManager getCurrentUser - 当前状态: isAuthenticated=${currentState.isAuthenticated}, hasUser=${currentState.user != null}'); // 调试日志
    
    if (currentState.isAuthenticated && currentState.user != null) {
      unawaited(_userProfileProvider.updateUserProfile(
        currentState.user!.userId,
        currentState.user!.toJson(),
      ));
      print('AuthManager getCurrentUser - 从状态返回用户: ${currentState.user!.email}'); // 调试日志
      return currentState.user;
    }

    print('AuthManager getCurrentUser - 状态中无用户数据，回退到本地缓存'); // 调试日志

    // 状态中无用户数据：从本地缓存获取
    final cachedUser = await _userProfileProvider.getUserProfile(session.userId);
    print('AuthManager getCurrentUser - 本地缓存用户: ${cachedUser?.email ?? "未找到"}'); // 调试日志
    return cachedUser;
  }

  /// 统一刷新入口：可选刷新会话 + 远端用户，附带节流和回退
  ///
  /// [force] 为 true 时跳过 5 秒节流窗口，强制从远端拉取。
  /// 典型场景：支付成功后需要立即获取最新 VIP 状态。
  Future<AuthUser?> refreshUserData({
    bool refreshSession = true,
    bool force = false,
  }) async {
    final now = DateTime.now();
    if (!force &&
        _lastUserRefreshRequest != null &&
        now.difference(_lastUserRefreshRequest!) < _remoteFetchCooldown) {
      print('AuthManager refreshUserData - 距离上次刷新过近，直接返回缓存');
      return currentAuthState.user;
    }
    _lastUserRefreshRequest = now;

    if (refreshSession) {
      print('AuthManager refreshUserData - 刷新 Supabase 会话');
      final refreshed = await _sessionProvider.refreshSession();
      if (!refreshed) {
        print('AuthManager refreshUserData - 刷新会话失败');
        _trackRemoteError();
      } else {
        print('AuthManager refreshUserData - 会话刷新成功');
        _remoteFetchErrorStreak = 0;
      }
    }

    print('AuthManager refreshUserData - 准备刷新远端用户信息');
    return await refreshCurrentUser(force: true);
  }

  /// 通过 Supabase 获取最新用户信息，并更新缓存（带节流与回退）
  Future<AuthUser?> refreshCurrentUser({bool force = false, AuthSession? session}) async {
    final effectiveSession = session ?? await _sessionProvider.getCurrentSession();
    if (effectiveSession == null || !effectiveSession.isValid) {
      print('AuthManager refreshCurrentUser - 无有效会话');
      return null;
    }

    final now = DateTime.now();
    if (!force &&
        _lastRemoteUserFetch != null &&
        now.difference(_lastRemoteUserFetch!) < _remoteFetchCooldown) {
      print('AuthManager refreshCurrentUser - 命中远端节流，返回缓存');
      return currentAuthState.user ?? await _userProfileProvider.getUserProfile(effectiveSession.userId);
    }

    if (_skipRemoteFetchUntil != null && now.isBefore(_skipRemoteFetchUntil!)) {
      print('AuthManager refreshCurrentUser - 远端回退窗口内，返回缓存');
      return currentAuthState.user ?? await _userProfileProvider.getUserProfile(effectiveSession.userId);
    }

    try {
      print('AuthManager refreshCurrentUser - 调用 SessionProvider.getUser');
      final remoteUser = await _sessionProvider.getUser(accessToken: effectiveSession.token);
      if (remoteUser != null) {
        _lastRemoteUserFetch = now;
        _remoteFetchErrorStreak = 0;
        _skipRemoteFetchUntil = null;
        unawaited(_userProfileProvider.updateUserProfile(
          remoteUser.userId,
          remoteUser.toJson(),
        ));
        print('AuthManager refreshCurrentUser - 成功获取远端用户: ${remoteUser.email}');

        // 检测本地过期但服务端未降级：主动触发 authStateChanges
        // 这样监听者可以通过 user.currentVip 获取正确的 free 状态
        if (remoteUser.isExpired && remoteUser.vipType != VipType.free) {
          print('AuthManager refreshCurrentUser - 检测到本地过期但服务端未降级，主动触发状态更新');
          _sessionProvider.handleUserUpdate(remoteUser);
        }

        return remoteUser;
      }
      print('AuthManager refreshCurrentUser - 远端返回为空，回退本地');
      return currentAuthState.user ?? await _userProfileProvider.getUserProfile(effectiveSession.userId);
    } catch (e) {
      print('AuthManager refreshCurrentUser - 获取远端用户异常: $e');
      _trackRemoteError();
      return currentAuthState.user ?? await _userProfileProvider.getUserProfile(effectiveSession.userId);
    }
  }

  void _trackRemoteError() {
    _remoteFetchErrorStreak++;
    if (_remoteFetchErrorStreak >= _maxRemoteErrorsBeforeBackoff) {
      _skipRemoteFetchUntil = DateTime.now().add(_remoteBackoffDuration);
      _remoteFetchErrorStreak = 0;
      print('AuthManager refreshCurrentUser - 进入远端回退窗口');
    }
  }

  /// 获取当前令牌
  Future<String?> getCurrentToken() async {
    final session = await _sessionProvider.getCurrentSession();
    return session?.token;
  }

  /// 刷新令牌
  Future<bool> refreshToken() async {
    return await _sessionProvider.refreshSession();
  }

  /// 重置密码
  Future<bool> resetPassword(String identifier) async {
    final provider = _providers.values.whereType<CredentialAuthProvider>().firstOrNull;

    if (provider == null) {
      return false;
    }

    try {
      return await provider.resetPassword(identifier);
    } catch (e) {
      return false;
    }
  }

  /// 修改密码
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    final provider = _providers.values.whereType<CredentialAuthProvider>().firstOrNull;

    if (provider == null) {
      return false;
    }

    try {
      return await provider.changePassword(oldPassword, newPassword);
    } catch (e) {
      return false;
    }
  }

  /// 更新用户密码（用于注册流程，不需要旧密码）
  Future<bool> updateUserPassword(String newPassword) async {
    // 优先使用Supabase provider，因为它支持直接更新密码
    final provider = _providers.values.whereType<CredentialAuthProvider>().firstOrNull;
    
    if (provider == null) {
      return false;
    }

    try {
      // 尝试使用空的旧密码或特殊标记来更新
      // 对于Supabase，在已验证OTP的情况下，可以直接更新密码
      return await provider.changePassword('', newPassword);
    } catch (e) {
      return false;
    }
  }

  /// 根据请求确定认证类型
  AuthType _determineAuthType(AuthRequest request) {
    if (request.authType != null) {
      switch (request.authType) {
        case 'apple':
          return AuthType.apple;
        case 'phone':
          return AuthType.phone;
        case 'email':
          return AuthType.email;
        case 'phoneOtp':
          return AuthType.phoneOtp;
        case 'emailOtp':
          return AuthType.emailOtp;
        case 'verifycode':
          return AuthType.verifycode;
        default:
          return AuthType.email;
      }
    }

    // 自动判断认证类型
    if (request.phone != null && request.code != null) {
      return AuthType.phoneOtp; // 手机号+验证码 -> phoneOtp
    } else if (request.email != null && request.code != null) {
      return AuthType.emailOtp; // 邮箱+验证码 -> emailOtp  
    } else if (request.phone != null && request.password != null) {
      return AuthType.phone; // 手机号+密码 -> phone
    } else if (request.email != null) {
      return AuthType.email; // 邮箱+密码 -> email
    }

    return AuthType.email;
  }

  /// 检测用户或VIP等级是否发生变化
  ///
  /// 用于连接前判断是否需要强制更新配置文件
  /// @return (changed, reason) - changed=是否变化, reason=变化原因
  (bool, String?) checkUserChange() {
    final (changed, reason, _) = checkUserChangeWithVipStatus();
    return (changed, reason);
  }

  /// 检测用户或VIP等级是否发生变化（带VIP降级状态）
  ///
  /// 用于连接前判断是否需要强制更新配置文件
  /// 使用 currentVip 而非 vipType，以检测本地过期导致的降级
  /// @return (changed, reason, vipDowngraded) - changed=是否变化, reason=变化原因, vipDowngraded=是否VIP降级
  (bool, String?, bool) checkUserChangeWithVipStatus() {
    final authState = currentAuthState;

    if (!authState.isAuthenticated || authState.user == null) {
      return (false, null, false);
    }

    final user = authState.user!;
    final currentUserId = user.userId;
    final currentVipType = user.currentVip;

    // 场景1: 切换用户
    if (_lastUserId != null && _lastUserId != currentUserId) {
      _lastUserId = currentUserId;
      _lastVipType = currentVipType;
      unawaited(_saveTracking());
      return (true, '用户切换', false);
    }

    // 场景2: VIP等级变化
    if (_lastVipType != null && _lastVipType != currentVipType) {
      final isDowngraded = currentVipType.index < _lastVipType!.index;
      _lastVipType = currentVipType;
      unawaited(_saveTracking());
      final reason = user.isExpired && user.vipType != VipType.free
          ? 'VIP过期'
          : (isDowngraded ? 'VIP降级' : 'VIP升级');
      return (true, reason, isDowngraded);
    }

    // 首次检查，记录状态
    if (_lastUserId == null) {
      _lastUserId = currentUserId;
      _lastVipType = currentVipType;
      unawaited(_saveTracking());
    }

    return (false, null, false);
  }

  /// 重置用户状态追踪（用于登出）
  void resetUserTracking() {
    _lastUserId = null;
    _lastVipType = null;
  }

  /// 销毁管理器
  Future<void> dispose() async {
    await _networkSub?.cancel();
    for (final provider in _providers.values) {
      await provider.dispose();
    }
    _providers.clear();
    _authTypeMapping.clear();
    resetUserTracking();
  }
}

/// 扩展方法
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
