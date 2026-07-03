import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:guichao/gch_base/gch_flux/gch_flux_engine.dart';
import 'package:guichao/gch_base/gch_flux/gch_shield/gch_fixed_key.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_providers/gch_auth_providers.dart';
import 'package:guichao/gch_base/gch_biz/gch_api/gch_client/gch_api_client.dart';
import 'package:guichao/gch_base/gch_biz/gch_api/gch_client/gch_data_api_client_builder.dart';

part 'gch_api_client_providers.g.dart';

// ============================================================================
// API Client Providers - 基于现有架构的简化设计
// ============================================================================

// 注意：gchFluxProvider 统一使用 gch_flux_provider.dart 中的定义
// 不再在此处重复定义，避免职责混乱

/// 默认 API 配置
@riverpod
ApiClientConfig defaultApiConfig(DefaultApiConfigRef ref) {
  return ApiClientConfig(
    baseUrl: GchNucleus.defaultApiBaseUrl,
    timeout: const Duration(seconds: 30),
    enableEncryption: true,
    enableAuth: true,
    enableRetry: true,
    defaultHeaders: const {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  );
}

/// 主要的 API 客户端提供者 - 优化版：使用 keepAlive 防止自动销毁
///
/// ⚠️ 关键设计：
/// - 使用 ref.read() 初始化，避免依赖变化触发重建
/// - 使用 ref.listen() 响应用户/认证变化，动态更新 header 和密钥
/// - 客户端实例在整个应用生命周期内复用，避免 "adapter was closed" 错误
@Riverpod(keepAlive: true)
DataApiClient apiClient(ApiClientRef ref) {
  final config = ref.read(defaultApiConfigProvider);

  // 创建独立的HTTP客户端实例，避免与通用 gchFluxProvider 的拦截器冲突
  // 注意：apiClient 需要添加认证和加密拦截器，必须使用独立实例
  final independentHttp = GchFluxEngine(
    config: GchFluxConfig(
      timeout: config.timeout,
      debug: GchNucleus.isDevMode,
      enableProxy: false,  // VPN 连接时走代理（GchRouteMode.dual 自动回退直连）
    ),
  );

  // Note: proxy port listening disabled - gch_config module removed

  final builder = DataApiClientBuilder(independentHttp);

  // ⚠️ 使用 read 而非 watch，避免用户变化触发整个 Provider 重建
  final currentUser = ref.read(currentUserProvider);
  final userId = currentUser.whenOrNull(
    data: (user) => user?.userId,
  ) ?? GchNucleus.machineId ?? '00000000-0000-0000-0000-000000000000';

  // ⚠️ 使用 read 而非 watch，authManager 变化时通过 listen 处理
  final authManager = ref.read(authManagerProvider);
  authManager.whenData((auth) {
    builder.useAuth(auth);
  });

  // 根据配置选择加密方式
  FixedKeyInterceptor? fixedKeyInterceptor;
  if (GchNucleus.encryptMode == 'fixed') {
    // 使用userId作为固定密钥的key，确保与服务端一致
    fixedKeyInterceptor = builder.useFixedKey(
      key: userId,  // 使用实际的userId，而不是全局默认值
      debug: true,
    );
  } else {
    builder.useECDH(
      userId: userId,
      keyExchangeUrl: GchNucleus.defaultkeyExchangeUrl,
      debug: true,
    );
  }

  final client = builder.build(
    baseUrl: config.baseUrl,
    timeout: config.timeout,
    enableRetry: config.enableRetry,
    defaultHeaders: config.defaultHeaders,
  );

  // 监听用户认证状态变化，动态更新userid头部和加密密钥
  String? lastUserId = userId; // 记录上次设置的userId，避免重复设置

  // 初始设置
  client.setHeader('userid', userId);
  print('🔧 [API客户端] 初始设置userid: $userId');

  // 监听用户变化，动态更新 header 和密钥（不触发重建）
  ref.listen(currentUserProvider, (previous, next) {
    final deviceId = GchNucleus.machineId ?? '00000000-0000-0000-0000-000000000000';
    next.whenOrNull(
      data: (user) {
        final newUserId = user?.userId ?? deviceId;

        // 只有当userId真正变化时才设置请求头，避免重复设置
        if (lastUserId != newUserId) {
          final oldUserId = lastUserId;
          client.setHeader('userid', newUserId);
          lastUserId = newUserId;
          print('🔄 [API客户端] userID变化: $oldUserId -> $newUserId');

          // 如果是固定密钥模式，同时更新加密密钥
          if (GchNucleus.encryptMode == 'fixed' && fixedKeyInterceptor != null) {
            fixedKeyInterceptor.updateKey(newUserId);
          }
        }
      },
    );
  });

  // 监听认证管理器变化，更新认证拦截器
  ref.listen(authManagerProvider, (previous, next) {
    next.whenData((auth) {
      // AuthManager 变化时，更新认证信息
      // 注意：这里不需要重建客户端，认证拦截器会自动使用最新的 token
      print('🔄 [API客户端] 认证状态已更新');
    });
  });

  // 注意：由于使用了 keepAlive: true 且不 watch 任何会变化的依赖
  // onDispose 只会在应用退出时触发
  ref.onDispose(() {
    print('🔄 [API客户端] 正在释放资源...');
    client.dispose();
  });

  return client;
}


// ============================================================================
// API 管理器 - 简化接口
// ============================================================================

/// API 状态管理
@riverpod
class ApiState extends _$ApiState {
  @override
  bool build() => false; // false = 空闲, true = 请求中
}

/// API 管理器 - 提供简化的请求方法
@riverpod
class ApiManager extends _$ApiManager {
  // 活跃请求的 token 集合
  final Set<CancelToken> _activeTokens = {};

  @override
  void build() {
    // 统一注册一次清理逻辑
    ref.onDispose(() {
      for (final token in _activeTokens) {
        if (!token.isCancelled) {
          token.cancel('ApiManager disposed');
        }
      }
      _activeTokens.clear();
    });
  }

  DataApiClient get _client => ref.read(apiClientProvider);

  /// GET 请求
  Future<Response<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    // 极简自动取消：如果未提供 token，创建并加入集合管理
    final token = cancelToken ?? CancelToken();
    final needsCleanup = cancelToken == null;
    if (needsCleanup) {
      _activeTokens.add(token);
    }

    ref.read(apiStateProvider.notifier).state = true;
    try {
      final result = await _client.get<T>(
        endpoint,
        queryParameters: queryParameters,
        cancelToken: token,
      );
      return result;
    } finally {
      ref.read(apiStateProvider.notifier).state = false;
      // 请求完成后立即移除，避免长时间引用
      if (needsCleanup) {
        _activeTokens.remove(token);
      }
    }
  }
  
  /// POST 请求
  Future<Response<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    final token = cancelToken ?? CancelToken();
    final needsCleanup = cancelToken == null;
    if (needsCleanup) {
      _activeTokens.add(token);
    }

    ref.read(apiStateProvider.notifier).state = true;
    try {
      final result = await _client.post<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        cancelToken: token,
      );
      return result;
    } finally {
      ref.read(apiStateProvider.notifier).state = false;
      if (needsCleanup) {
        _activeTokens.remove(token);
      }
    }
  }
  
  /// PUT 请求
  Future<Response<T>> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    final token = cancelToken ?? CancelToken();
    final needsCleanup = cancelToken == null;
    if (needsCleanup) {
      _activeTokens.add(token);
    }

    ref.read(apiStateProvider.notifier).state = true;
    try {
      final result = await _client.put<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        cancelToken: token,
      );
      return result;
    } finally {
      ref.read(apiStateProvider.notifier).state = false;
      if (needsCleanup) {
        _activeTokens.remove(token);
      }
    }
  }
  
  /// DELETE 请求
  Future<Response<T>> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    final token = cancelToken ?? CancelToken();
    final needsCleanup = cancelToken == null;
    if (needsCleanup) {
      _activeTokens.add(token);
    }

    ref.read(apiStateProvider.notifier).state = true;
    try {
      final result = await _client.delete<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        cancelToken: token,
      );
      return result;
    } finally {
      ref.read(apiStateProvider.notifier).state = false;
      if (needsCleanup) {
        _activeTokens.remove(token);
      }
    }
  }
  
  // 认证相关方法
  bool get isAuthenticated => _client.isAuthenticated;
  String? get currentToken => _client.currentToken;
  Future<bool> refreshToken() => _client.refreshToken();
  void setAuthEnabled(bool enabled) => _client.setAuthEnabled(enabled);
  void setECDHEnabled(bool enabled) => _client.setECDHEnabled(enabled);
  void setFixedKeyEnabled(bool enabled) => _client.setFixedKeyEnabled(enabled);

  // 请求头管理方法
  void setHeader(String key, dynamic value) => _client.setHeader(key, value);
  void setHeaders(Map<String, dynamic> headers) => _client.setHeaders(headers);
  void removeHeader(String key) => _client.removeHeader(key);
  void clearHeaders() => _client.clearHeaders();
}

// ============================================================================
// 状态监听 Providers
// ============================================================================

/// API 认证状态
@riverpod
bool apiAuthStatus(Ref ref) {
  return ref.watch(apiClientProvider).isAuthenticated;
}

/// API 当前 Token
@riverpod
String? apiCurrentToken(Ref ref) {
  return ref.watch(apiClientProvider).currentToken;
}

/// API 请求状态
@riverpod
bool apiRequestState(Ref ref) {
  return ref.watch(apiStateProvider);
}

// ============================================================================
// 便捷扩展 - 超简单的API调用
// ============================================================================

/// WidgetRef/ConsumerWidget 扩展 - 极简API调用
extension WidgetRefApiExt on WidgetRef {
  /// GET 请求
  /// 
  /// 用法: final response = await ref.apiGet('/users');
  Future<Response<T>> apiGet<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return read(apiManagerProvider.notifier).get<T>(
      endpoint,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  /// POST 请求
  /// 
  /// 用法: final response = await ref.apiPost('/users', data: userData);
  Future<Response<T>> apiPost<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return read(apiManagerProvider.notifier).post<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  /// PUT 请求
  /// 
  /// 用法: final response = await ref.apiPut('/users/123', data: userData);
  Future<Response<T>> apiPut<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return read(apiManagerProvider.notifier).put<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  /// DELETE 请求
  /// 
  /// 用法: final response = await ref.apiDelete('/users/123');
  Future<Response<T>> apiDelete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return read(apiManagerProvider.notifier).delete<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  /// 认证状态
  bool get isApiAuthenticated => read(apiManagerProvider.notifier).isAuthenticated;
  
  /// 当前Token
  String? get apiToken => read(apiManagerProvider.notifier).currentToken;
  
  /// 刷新Token
  Future<bool> refreshApiToken() => read(apiManagerProvider.notifier).refreshToken();
  
  /// 设置认证状态
  void setAuthEnabled(bool enabled) => read(apiManagerProvider.notifier).setAuthEnabled(enabled);
  
  /// 设置ECDH状态
  void setECDHEnabled(bool enabled) => read(apiManagerProvider.notifier).setECDHEnabled(enabled);
  
  /// 设置固定密钥状态
  void setFixedKeyEnabled(bool enabled) => read(apiManagerProvider.notifier).setFixedKeyEnabled(enabled);

  /// 请求头管理方法
  void setHeader(String key, dynamic value) => read(apiManagerProvider.notifier).setHeader(key, value);
  void setHeaders(Map<String, dynamic> headers) => read(apiManagerProvider.notifier).setHeaders(headers);
  void removeHeader(String key) => read(apiManagerProvider.notifier).removeHeader(key);
  void clearHeaders() => read(apiManagerProvider.notifier).clearHeaders();

  /// API请求状态(loading)
  bool get isApiLoading => watch(apiStateProvider);
}

/// AutoDisposeRef 扩展 (用于 @riverpod 生成的 AutoDispose Provider)
extension AutoDisposeRefApiExt on AutoDisposeRef {
  /// GET 请求
  Future<Response<T>> apiGet<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return read(apiManagerProvider.notifier).get<T>(
      endpoint,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  /// POST 请求
  Future<Response<T>> apiPost<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return read(apiManagerProvider.notifier).post<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  /// PUT 请求
  Future<Response<T>> apiPut<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return read(apiManagerProvider.notifier).put<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  /// DELETE 请求
  Future<Response<T>> apiDelete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return read(apiManagerProvider.notifier).delete<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }
  
  /// 认证状态
  bool get isApiAuthenticated => read(apiManagerProvider.notifier).isAuthenticated;
  
  /// 当前Token
  String? get apiToken => read(apiManagerProvider.notifier).currentToken;
  
  /// 刷新Token
  Future<bool> refreshApiToken() => read(apiManagerProvider.notifier).refreshToken();
}

/// Ref 扩展 (用于非 AutoDispose 的 Provider)
extension RefApiExt on Ref {
  /// GET 请求
  Future<Response<T>> apiGet<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return read(apiManagerProvider.notifier).get<T>(
      endpoint,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  /// POST 请求
  Future<Response<T>> apiPost<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return read(apiManagerProvider.notifier).post<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  /// PUT 请求
  Future<Response<T>> apiPut<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return read(apiManagerProvider.notifier).put<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  /// DELETE 请求
  Future<Response<T>> apiDelete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return read(apiManagerProvider.notifier).delete<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }
  
  /// 认证状态
  bool get isApiAuthenticated => read(apiManagerProvider.notifier).isAuthenticated;
  
  /// 当前Token  
  String? get apiToken => read(apiManagerProvider.notifier).currentToken;
  
  /// 刷新Token
  Future<bool> refreshApiToken() => read(apiManagerProvider.notifier).refreshToken();
}

// ============================================================================
// 使用说明
// ============================================================================

/*
🚀 API Client Provider - 超简单用法

✅ 在 Widget 中使用:

1️⃣ GET: final response = await ref.apiGet('/users');
2️⃣ POST: final response = await ref.apiPost('/users', data: userData);
3️⃣ PUT: final response = await ref.apiPut('/users/123', data: userData);
4️⃣ DELETE: final response = await ref.apiDelete('/users/123');

✅ 认证相关:
- ref.isApiAuthenticated - 认证状态
- ref.apiToken - 当前Token
- ref.refreshApiToken() - 刷新Token
- ref.isApiLoading - 请求状态

✅ 在 StateNotifier/AsyncNotifier 中使用:
- ref.apiGet('/users')  
- ref.apiPost('/users', data: data)
- ref.apiPut('/users/123', data: data)
- ref.apiDelete('/users/123')

📦 核心 Providers:
- apiClientProvider - API客户端实例(自动配置认证和加密)
- apiManagerProvider - API管理器(状态管理)
- apiStateProvider - 请求状态(loading)
- apiAuthStatusProvider - 认证状态
- apiCurrentTokenProvider - 当前Token

🎯 特性:
- 基于现有DataApiClient和DataApiClientBuilder
- 自动配置认证和加密中间件
- 响应式状态管理
- 统一错误处理
- 资源自动释放
- 极简的对外接口

📋 架构:
- 完全基于现有的DataApiClient架构
- 使用DataApiClientBuilder构建客户端
- 返回标准的Dio Response<T>
- 与现有代码完全兼容
*/