import 'dart:async';
import 'package:dio/dio.dart';
import 'package:guichao/gch_base/gch_flux/gch_shield/gch_auth.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_manager.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_provider_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_provider_interface.dart' as provider;
import 'package:guichao/gch_aux/gch_log_mix.dart';

/// Supabase 认证拦截器
/// 
/// 扩展基础认证拦截器，增加 Supabase token 管理和自动刷新功能
class SupabaseAuthInterceptor extends SignatureAuthInterceptor with GchInfraLogger {
  final AuthManager _authManager;
  StreamSubscription<AuthEvent>? _eventSubscription;
  StreamSubscription<provider.AuthProviderState>? _stateSubscription;
  
  bool _autoRefreshEnabled = true;
  Timer? _refreshTimer;
  static const Duration _refreshCheckInterval = Duration(minutes: 5);

  SupabaseAuthInterceptor({
    required AuthManager authManager,
    String? initialToken,
    SignatureGenerator? signatureGenerator,
    Map<String, String>? customHeaders,
  }) : _authManager = authManager,
       super(
         token: initialToken,
         signatureGenerator: signatureGenerator,
         customHeaders: customHeaders,
       ) {
    // 延迟初始化，避免阻塞构造函数
    Future.microtask(() {
      _initializeAuth();
      _startEventListening();
      _startPeriodicRefresh();
    });
  }

  /// 初始化认证状态
  void _initializeAuth() async {
    try {
      final currentToken = await _authManager.getCurrentToken();
      if (currentToken != null) {
        setToken(currentToken);
        loggy.info('已初始化 Supabase token');
      }
    } catch (e) {
      loggy.error('初始化认证状态失败', e);
    }
  }

  /// 开始监听认证事件
  void _startEventListening() {
    // 监听认证事件
    _eventSubscription = _authManager.authEvents.listen(
      _handleAuthEvent,
      onError: (error) => loggy.error('认证事件监听错误', error),
    );

    // 监听认证状态变化
    _stateSubscription = _authManager.authStateChanges.listen(
      _handleAuthStateChange,
      onError: (error) => loggy.error('认证状态监听错误', error),
    );

    loggy.debug('Supabase 认证事件监听已启动');
  }

  /// 处理认证事件
  void _handleAuthEvent(AuthEvent event) {
    switch (event.type) {
      case AuthEventType.signedIn:
        _updateTokenFromEvent(event);
        loggy.info('登录成功，自动更新 token');
        break;
      case AuthEventType.signedOut:
        setToken(null);
        loggy.info('登出成功，清除 token');
        break;
      case AuthEventType.tokenRefreshed:
        _updateTokenFromEvent(event);
        loggy.debug('Token 刷新成功，已自动更新');
        break;
      case AuthEventType.tokenExpired:
        setToken(null);
        loggy.warning('Token 已过期，清除 token');
        break;
      case AuthEventType.error:
        loggy.warning('认证错误: ${event.message}');
        break;
      default:
        break;
    }
  }

  /// 处理认证状态变化
  void _handleAuthStateChange(provider.AuthProviderState state) {
    if (state.isAuthenticated) {
      _refreshCurrentToken();
    } else {
      setToken(null);
    }
  }

  /// 从事件中更新 token
  void _updateTokenFromEvent(AuthEvent event) {
    final token = event.data['token'] as String?;
    if (token != null) {
      setToken(token);
    } else {
      _refreshCurrentToken();
    }
  }

  /// 刷新当前 token
  void _refreshCurrentToken() async {
    try {
      final currentToken = await _authManager.getCurrentToken();
      setToken(currentToken);
    } catch (e) {
      loggy.error('刷新当前 token 失败', e);
    }
  }

  /// 开始定期检查 token 有效性
  void _startPeriodicRefresh() {
    if (!_autoRefreshEnabled) return;

    // 先取消已存在的定时器，避免重复创建
    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(_refreshCheckInterval, (_) async {
      if (token != null) {
        try {
          await _authManager.refreshToken();
        } catch (e) {
          loggy.error('定期 token 刷新失败', e);
        }
      }
    });

    loggy.debug('已启动 token 定期刷新检查');
  }

  /// 启用/禁用自动刷新
  void setAutoRefreshEnabled(bool enabled) {
    _autoRefreshEnabled = enabled;

    if (enabled) {
      // 只在定时器未运行时才启动，避免重复
      if (_refreshTimer == null || !_refreshTimer!.isActive) {
        _startPeriodicRefresh();
      }
    } else {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    }

    loggy.debug('Token 自动刷新: ${enabled ? '启用' : '禁用'}');
  }

  /// 手动刷新 token
  Future<bool> refreshToken() async {
    try {
      final success = await _authManager.refreshToken();
      if (success) {
        _refreshCurrentToken();
        loggy.info('手动刷新 token 成功');
      }
      return success;
    } catch (e) {
      loggy.error('手动刷新 token 失败', e);
      return false;
    }
  }

  /// 检查 token 是否有效
  Future<bool> isTokenValid() async {
    try {
      final currentToken = await _authManager.getCurrentToken();
      if (currentToken == null || currentToken.isEmpty) {
        return false;
      }
      
      // 检查认证状态
      final authState = _authManager.currentAuthState;
      return authState.isAuthenticated && authState.session != null && authState.session!.isValid;
    } catch (e) {
      loggy.error('检查 token 有效性失败', e);
      return false;
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 在请求前检查并刷新 token（如果需要）
    if (_autoRefreshEnabled && token != null) {
      try {
        final isValid = await isTokenValid();
        if (!isValid) {
          await refreshToken();
        }
      } catch (e) {
        loggy.warning('请求前检查 token 失败', e);
      }
    }

    // 调用父类的请求处理逻辑
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 处理 401 未授权错误
    if (err.response?.statusCode == 401) {
      loggy.warning('收到 401 错误，可能需要刷新 token');
      
      // 尝试刷新 token 并重试请求
      _handleUnauthorizedError(err, handler);
      return;
    }

    handler.next(err);
  }

  /// 处理未授权错误
  void _handleUnauthorizedError(DioException err, ErrorInterceptorHandler handler) async {
    try {
      // 尝试刷新 token
      final refreshSuccess = await refreshToken();
      
      if (refreshSuccess && token != null) {
        // Token 刷新成功，重试原始请求
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $token';
        
        // 使用临时 Dio 实例重试，确保在 finally 中释放
        Dio? dio;
        try {
          dio = Dio();
          final response = await dio.fetch(options);
          handler.resolve(response);
          loggy.info('Token 刷新成功，请求已重试');
          return;
        } catch (retryError) {
          loggy.error('重试请求失败', retryError);
        } finally {
          // 确保释放临时 Dio 实例，避免连接池泄漏
          dio?.close(force: true);
          loggy.debug('临时 Dio 实例已释放');
        }
      }
    } catch (e) {
      loggy.error('处理 401 错误时异常', e);
    }

    // 如果刷新失败或重试失败，传递原始错误
    handler.next(err);
  }

  /// 获取认证管理器
  AuthManager get authManager => _authManager;

  /// 是否已认证
  bool get isAuthenticated => token != null && token!.isNotEmpty;

  /// 清理资源
  void dispose() {
    _eventSubscription?.cancel();
    _stateSubscription?.cancel();
    _refreshTimer?.cancel();
    clear();
    loggy.debug('Supabase 认证拦截器已释放');
  }
}