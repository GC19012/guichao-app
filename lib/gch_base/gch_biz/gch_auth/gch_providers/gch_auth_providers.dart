// providers/auth_providers.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:guichao/gch_base/gch_core/gch_net_guard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_config/gch_auth_config.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authtype_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authuser_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_manager.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_provider_interface.dart';

import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_providers/gch_local_session_provider.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_providers/gch_local_user_profile_provider.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_providers/gch_supabase_auth_provider.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_providers/gch_supabase_session_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser, OtpType;
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_resilient_auth_wrapper.dart';
import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';
import 'package:guichao/gch_base/gch_biz/gch_common/gch_enums.dart';
import 'package:guichao/gch_base/gch_prefs/gch_store_provider.dart';
// ============================================================================
// 基础设施提供者
// ============================================================================

/// Flutter Secure Storage提供者
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
});


// ============================================================================
// 认证配置提供者
// ============================================================================

/// 认证配置提供者
final authConfigProvider = FutureProvider<AuthServiceConfig>((ref) {
  // 使用AppConfig统一配置
  return Future.value(AuthServiceConfig(
    baseUrl: '${GchNucleus.authEndpoint}/',
    apiKey: GchNucleus.authApiKey,
    authTypeMapping: const {
      AuthType.email: AuthServiceType.supabase,
      AuthType.phone: AuthServiceType.supabase,
      AuthType.emailOtp: AuthServiceType.supabase,
      AuthType.phoneOtp: AuthServiceType.supabase,
      AuthType.apple: AuthServiceType.supabase,
      AuthType.verifycode: AuthServiceType.supabase, // 向后兼容
    },
    serviceConfigs: {
      AuthServiceType.supabase: {
        'supabaseUrl': GchNucleus.authEndpoint,
        'supabaseKey': GchNucleus.authApiKey,
      },
    },
  ));
});

// ============================================================================
// 核心提供者实现
// ============================================================================

/// 会话管理提供者（支持 Supabase）
final sessionProviderProvider = FutureProvider<SessionProvider>((ref) async {
  try {
    // 获取认证配置
    final config = await ref.read(authConfigProvider.future);
    final supabaseConfig = config.serviceConfigs[AuthServiceType.supabase];
    
    // 如果存在 Supabase 配置，创建 SupabaseSessionProvider
    if (supabaseConfig != null && 
        supabaseConfig['supabaseUrl'] != null && 
        supabaseConfig['supabaseKey'] != null) {
      
      // 全局初始化Supabase（如果未初始化）
      final supabaseUrl = supabaseConfig['supabaseUrl'] as String;
      final supabaseKey = supabaseConfig['supabaseKey'] as String;
      
      // 检查是否已全局初始化
      SupabaseClient supabaseClient;
      try {
        supabaseClient = Supabase.instance.client;
      } catch (_) {
        // 如果未初始化，则进行全局初始化
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseKey,
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
            // 禁用 supabase_flutter 内部的 deep link 自动监听：
            // 微信回调 UL 含 code= 会被误判为 Supabase OAuth 回调，
            // 触发 exchangeCodeForSession 报 Code verifier not found。
            // 项目使用 DeepLinkNotifier 统一路由，精准区分微信 / Supabase 回调，
            // 再显式调用 getSessionFromUrl 完成 Supabase exchange。
            detectSessionInUri: false,
          ),
        );
        supabaseClient = Supabase.instance.client;
      }
      
      // 返回 SupabaseSessionProvider
      return SupabaseSessionProvider(supabaseClient);
    }
  } catch (e) {
    debugPrint('创建 SupabaseSessionProvider 失败: $e');
  }
  
  // 回退到本地会话管理器
  final storage = ref.watch(secureStorageProvider);
  return SessionManager(storage: storage);
});

/// 用户配置文件提供者
final userProfileProviderProvider = Provider<UserProfileProvider>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return LocalUserProfile(storage: storage);
});

// ============================================================================
// 认证提供者实例
// ============================================================================

/// Supabase认证提供者
final supabaseAuthProviderProvider = Provider<SupabaseAuthProvider>((ref) {
  return SupabaseAuthProvider();
});



// ============================================================================
// 弹性包装提供者
// ============================================================================

/// 弹性Supabase认证提供者
final resilientSupabaseProvider = Provider<ResilientProvider>((ref) {
  final innerProvider = ref.watch(supabaseAuthProviderProvider);
  return ResilientProvider(
    provider: innerProvider,
    retryConfig: const RetryConfig(
      maxAttempts: 3,
      baseDelay: Duration(seconds: 1),
      backoffStrategy: BackoffStrategy.exponentialWithJitter,
    ),
    circuitBreakerConfig: const CircuitBreakerConfig(
      failureThreshold: 5,
      timeout: Duration(minutes: 2),
    ),
  );
});


// ============================================================================
// 认证管理器
// ============================================================================

/// 认证管理器提供者 - 性能优化版本
final authManagerProvider = FutureProvider<AuthManager>((ref) async {
  try {
    // 初始化网络工具类（设置全局容器）
    GchNetGuard.setup(ref.container);

    final sessionProvider = await ref.watch(sessionProviderProvider.future);
    final userProfileProvider = ref.watch(userProfileProviderProvider);
    final store = await ref.watch(gchStoreProvider.future);

    // 快速创建AuthManager实例
    final authManager = AuthManager(
      sessionProvider: sessionProvider,
      userProfileProvider: userProfileProvider,
      store: store,
    );
    ref.onDispose(() {
      unawaited(authManager.dispose());
    });

    // ✅ 修复：等待注册完成，确保消费者获取时认证提供者已就绪
    // 注册过程内部已有错误处理，不会阻塞太久
    await _registerAuthProvidersAsync(ref, authManager);

    return authManager;
  } catch (e) {
    debugPrint('认证管理器初始化失败: $e');
    rethrow;
  }
});

/// 异步注册认证提供者 - 性能优化版本
Future<void> _registerAuthProvidersAsync(
  Ref ref,
  AuthManager authManager,
) async {
  try {
    // 获取配置，但不阻塞主流程
    final config = await ref.read(authConfigProvider.future);
    await _registerAuthProviders(ref, authManager, config);
  } catch (e) {
    debugPrint('异步注册认证提供者失败: $e');
  }
}

/// 注册认证提供者
Future<void> _registerAuthProviders(
  Ref ref,
  AuthManager authManager,
  AuthServiceConfig config,
) async {
  // 注册Supabase提供者（带弹性包装）
  final supabaseProvider = ref.read(resilientSupabaseProvider);
  await supabaseProvider.initialize(config.serviceConfigs[AuthServiceType.supabase] ?? {});
  await authManager.registerProvider(supabaseProvider, setAsDefault: true);
  
  // 设置认证类型映射
  authManager.setAuthTypeMapping(AuthType.email, supabaseProvider.providerId);
  authManager.setAuthTypeMapping(AuthType.phone, supabaseProvider.providerId);
  authManager.setAuthTypeMapping(AuthType.emailOtp, supabaseProvider.providerId);
  authManager.setAuthTypeMapping(AuthType.phoneOtp, supabaseProvider.providerId);
  authManager.setAuthTypeMapping(AuthType.apple, supabaseProvider.providerId);
  authManager.setAuthTypeMapping(AuthType.verifycode, supabaseProvider.providerId); // 向后兼容
}


/// 当前用户提供者 - 响应认证状态变化
final currentUserProvider = FutureProvider<AuthUser?>((ref) async {
  // 监听认证状态变化来触发重建
  ref.watch(authStateChangesProvider);

  final authManager = await ref.watch(authManagerProvider.future);
  final cachedUser = authManager.currentAuthState.user;
  if (cachedUser != null) {
    return cachedUser;
  }
  return await authManager.getCurrentUser();
});

// authStateStreamProvider 已移除，请使用 authStateChangesProvider

/// 新的认证事件流提供者
final authEventsProvider = StreamProvider<AuthEvent>((ref) async* {
  final authManager = await ref.watch(authManagerProvider.future);
  yield* authManager.authEvents;
});

/// 新的认证状态流提供者
final authStateChangesProvider = StreamProvider<AuthProviderState>((ref) async* {
  final authManager = await ref.watch(authManagerProvider.future);
  yield* authManager.authStateChanges;
});

/// 当前令牌提供者
final currentTokenProvider = FutureProvider<String?>((ref) async {
  final authManager = await ref.watch(authManagerProvider.future);
  return await authManager.getCurrentToken();
});


// ============================================================================
// 会话和用户配置文件事件提供者
// ============================================================================

/// 会话事件流提供者
/// ✅ 修复：正确获取 SessionProvider 后直接 yield，而非在 whenData 回调中
final sessionEventsProvider = StreamProvider<SessionEvent>((ref) async* {
  final sessionProvider = await ref.watch(sessionProviderProvider.future);

  if (sessionProvider is SessionManager) {
    yield* sessionProvider.sessionEvents;
  }
});

/// 用户配置文件事件流提供者
final userProfileEventsProvider = StreamProvider<UserProfileEvent>((ref) async* {
  final userProfileProvider = ref.watch(userProfileProviderProvider);
  if (userProfileProvider is LocalUserProfile) {
    yield* userProfileProvider.profileChanges;
  }
});

// ============================================================================
// 辅助提供者
// ============================================================================

/// 用户统计信息提供者
final userStatsProvider = FutureProvider<UserStats>((ref) async {
  final userProfileProvider = ref.watch(userProfileProviderProvider);
  if (userProfileProvider is LocalUserProfile) {
    return await userProfileProvider.getUserStats();
  }
  return const UserStats(
    totalUsers: 0,
    activeUsers: 0,
    expiredUsers: 0,
    vipUsers: 0,
  );
});

/// 所有用户列表提供者
final allUsersProvider = FutureProvider<List<AuthUser>>((ref) async {
  final userProfileProvider = ref.watch(userProfileProviderProvider);
  if (userProfileProvider is LocalUserProfile) {
    return await userProfileProvider.getAllUsers();
  }
  return [];
});

// ============================================================================
// 认证操作提供者
// ============================================================================

/// 认证操作提供者 - 提供便捷的认证方法
final authActionsProvider = Provider<AuthActions>((ref) {
  return AuthActions(ref);
});

// ============================================================================
// 用户信息缓存提供者 - 性能优化
// ============================================================================

/// 用户信息提供者 - 自动响应认证状态变化并缓存数据
final userInfoProvider = FutureProvider<({
  bool isAuthenticated,
  String? email,
  String? phone,
  String gcSeq,
  VipType vipType,
  DateTime? expiredAt,
  String? authType,
  String? name,
  String? nickname,
})>((ref) async {
  // 监听认证状态变化自动刷新
  ref.watch(authStateChangesProvider);

  try {
    final authManager = await ref.watch(authManagerProvider.future);
    final currentUser = await authManager.getCurrentUser();

    // 获取GUICHAO
    String gcSeq = GchNucleus.gcSerial ?? await GchNucleus.buildGcSeq();
    GchNucleus.gcSerial ??= gcSeq;

    return (
      isAuthenticated: currentUser != null,
      email: currentUser?.email,
      phone: currentUser?.phone,
      gcSeq: gcSeq,
      vipType: currentUser?.currentVip ?? VipType.free,
      expiredAt: currentUser?.expiredAt,
      authType: currentUser?.authType,
      name: currentUser?.name,
      nickname: currentUser?.nickname,
    );
  } catch (e) {
    debugPrint('获取用户信息失败: $e');
    return (
      isAuthenticated: false,
      email: null,
      phone: null,
      gcSeq: 'GC00000000',
      vipType: VipType.free,
      expiredAt: null,
      authType: null,
      name: null,
      nickname: null,
    );
  }
});

/// 认证操作类
class AuthActions {
  final Ref _ref;

  AuthActions(this._ref);
  
  /// 邮箱密码登录
  Future<AuthResult> signInWithEmail(String email, String password) async {
    final authManager = await _ref.read(authManagerProvider.future);
    return await authManager.signIn(AuthRequest(
      email: email,
      password: password,
      authType: 'email',
    ));
  }
  
  /// 手机验证码登录
  Future<AuthResult> signInWithPhone(String phone, String code) async {
    final authManager = await _ref.read(authManagerProvider.future);
    return await authManager.signIn(AuthRequest(
      phone: phone,
      code: code,
      authType: 'phoneOtp',
    ));
  }
  
  /// 邮箱验证码登录
  Future<AuthResult> signInWithEmailCode(String email, String code) async {
    final authManager = await _ref.read(authManagerProvider.future);
    return await authManager.signIn(AuthRequest(
      email: email,
      code: code,
      authType: 'emailOtp',
    ));
  }
  
  /// Apple登录
  Future<AuthResult> signInWithApple({required String idToken, String? accessToken}) async {
    final authManager = await _ref.read(authManagerProvider.future);
    return await authManager.signInWithOAuth(
      providerId: 'supabase',
      idToken: idToken,
      accessToken: accessToken,
      extraParams: {'provider': 'apple'},
    );
  }
  
  /// 注册用户
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? name,
    String? phone,
  }) async {
    final authManager = await _ref.read(authManagerProvider.future);
    return await authManager.signUp(AuthRequest.forSignUp(
      email: email,
      password: password,
      name: name,
      phone: phone,
    ));
  }
  
  /// 登出
  Future<bool> signOut() async {
    final authManager = await _ref.read(authManagerProvider.future);
    return await authManager.signOut();
  }
  
  /// 发送短信验证码
  Future<bool> sendSmsCode(String phone) async {
    final authManager = await _ref.read(authManagerProvider.future);
    return await authManager.sendOtp(phone, type: OtpType.sms);
  }
  
  /// 发送邮箱验证码
  Future<bool> sendEmailCode(String email) async {
    final authManager = await _ref.read(authManagerProvider.future);
    return await authManager.sendOtp(email, type: OtpType.email);
  }
  
  /// 重置密码
  Future<bool> resetPassword(String email) async {
    final authManager = await _ref.read(authManagerProvider.future);
    return await authManager.resetPassword(email);
  }
  
  /// 修改密码
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    final authManager = await _ref.read(authManagerProvider.future);
    return await authManager.changePassword(oldPassword, newPassword);
  }
  
}
