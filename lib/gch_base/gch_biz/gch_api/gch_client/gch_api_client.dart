import 'package:dio/dio.dart';
import 'package:guichao/gch_base/gch_flux/gch_flux_engine.dart';
import 'package:guichao/gch_base/gch_flux/gch_shield/gch_encrypt.dart';
import 'package:guichao/gch_base/gch_flux/gch_shield/gch_fixed_key.dart';
import 'package:guichao/gch_base/gch_flux/gch_shield/gch_supabase_auth_interceptor.dart';
import 'package:guichao/gch_base/gch_flux/gch_shield/gch_auth.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_manager.dart';
import 'package:guichao/gch_aux/gch_log_mix.dart';
/// API 客户端配置
class ApiClientConfig {
  final String baseUrl;
  final Duration timeout;
  final bool enableEncryption;
  final bool enableAuth;
  final bool enableRetry;
  final Map<String, String> defaultHeaders;

  const ApiClientConfig({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
    this.enableEncryption = true,
    this.enableAuth = true,
    this.enableRetry = true,
    this.defaultHeaders = const {},
  });
}
class DataApiClient with GchInfraLogger {
  final GchFluxEngine _http;
  final ApiClientConfig _config;

  SupabaseAuthInterceptor? _authInterceptor;
  ECDHCryptoInterceptor? _ecdhInterceptor;
  FixedKeyInterceptor? _fixedKeyInterceptor;

  DataApiClient({
    required GchFluxEngine httpClient,
    required ApiClientConfig config,
    SupabaseAuthInterceptor? authInterceptor,
    ECDHCryptoInterceptor? ecdhInterceptor,
    FixedKeyInterceptor? fixedKeyInterceptor,
  }) : _http = httpClient,
       _config = config,
       _authInterceptor = authInterceptor,
       _ecdhInterceptor = ecdhInterceptor,
       _fixedKeyInterceptor = fixedKeyInterceptor;

  void useAuth(AuthManager authManager, {Map<String, String>? headers}) {
    _authInterceptor = SupabaseAuthInterceptor(
      authManager: authManager,
      signatureGenerator: _generateSignature,
      customHeaders: headers,
    );
    _http.mountShield(_authInterceptor!);
    loggy.info('API 认证已启用');
  }


  void useECDH({
    required String userId,
    required String keyExchangeUrl,
    bool debug = false,
  }) {
    _ecdhInterceptor = ECDHCryptoInterceptor(
      userId: userId,
      keyExchangeUrl: keyExchangeUrl,
      debug: debug,
      logger: debug ? (message) => loggy.debug(message) : null,
    );
    _http.mountShield(_ecdhInterceptor!);
    loggy.info('API ECDH加密已启用 - 用户: $userId');
  }

  void useFixedKey({
    required String key,
    bool debug = false,
  }) {
    _fixedKeyInterceptor = FixedKeyInterceptor(
      key: key,
      debug: debug,
      logger: debug ? (message) => loggy.debug(message) : null,
    );
    _http.mountShield(_fixedKeyInterceptor!);
    loggy.info('API FixedKey加密已启用');
  }

  /// 智能URL解析：支持完整URL和相对路径
  String _resolveUrl(String urlOrPath) {
    // 如果是完整URL（包含http://或https://），直接使用
    if (urlOrPath.startsWith('http://') || urlOrPath.startsWith('https://')) {
      return urlOrPath;
    }
    
    // 如果是相对路径，与baseUrl组合
    final baseUrl = _config.baseUrl.endsWith('/') 
        ? _config.baseUrl.substring(0, _config.baseUrl.length - 1)
        : _config.baseUrl;
        
    final path = urlOrPath.startsWith('/') 
        ? urlOrPath 
        : '/$urlOrPath';
        
    return '$baseUrl$path';
  }

  String _generateSignature({
    required String method,
    required String url,
    required String timestamp,
    required String nonce,
    String? body,
    String? token,
  }) {
    return SignatureAlgorithms.hmacSha256(
      method: method,
      url: url,
      timestamp: timestamp,
      nonce: nonce,
      secretKey: 'your-secret-key',
      body: body,
      token: token,
    );
  }

  Future<Response<T>> get<T>(
      String urlOrPath, {
        Map<String, dynamic>? queryParameters,
        CancelToken? cancelToken,
      }) {
    final resolvedUrl = _resolveUrl(urlOrPath);
    final uri = Uri.parse(resolvedUrl);
    final finalUrl = queryParameters != null
        ? uri.replace(
            queryParameters: queryParameters.map((k, v) => MapEntry(k, v.toString())),
          ).toString()
        : uri.toString();
    return _http.get<T>(finalUrl, cancelToken: cancelToken);
  }

  Future<Response<T>> post<T>(
      String urlOrPath, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        CancelToken? cancelToken,
      }) {
    final resolvedUrl = _resolveUrl(urlOrPath);
    return _http.post<T>(
      resolvedUrl,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> put<T>(
      String urlOrPath, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        CancelToken? cancelToken,
      }) {
    final resolvedUrl = _resolveUrl(urlOrPath);
    return _http.put<T>(
      resolvedUrl,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> delete<T>(
      String urlOrPath, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        CancelToken? cancelToken,
      }) {
    final resolvedUrl = _resolveUrl(urlOrPath);
    return _http.delete<T>(
      resolvedUrl,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  GchFluxEngine get httpClient => _http;

  bool get isAuthenticated => _authInterceptor?.isAuthenticated ?? false;

  String? get currentToken => _authInterceptor?.token;

  Future<bool> refreshToken() async {
    return await _authInterceptor?.refreshToken() ?? false;
  }


  void setAuthEnabled(bool enabled) {
    _authInterceptor?.setEnabled(enabled);
  }

  void setECDHEnabled(bool enabled) {
    _ecdhInterceptor?.setEnabled(enabled);
    loggy.info('API ECDH加密已${enabled ? '启用' : '禁用'}');
  }

  void setFixedKeyEnabled(bool enabled) {
    _fixedKeyInterceptor?.setEnabled(enabled);
    loggy.info('API FixedKey加密已${enabled ? '启用' : '禁用'}');
  }

  /// 设置自定义请求头
  /// 会同时设置到ECDH和FixedKey拦截器（如果存在）
  void setHeader(String key, dynamic value) {
    _ecdhInterceptor?.setHeader(key, value);
    _fixedKeyInterceptor?.setHeader(key, value);
    loggy.debug('设置自定义请求头: $key = $value');
  }

  /// 批量设置请求头
  void setHeaders(Map<String, dynamic> headers) {
    _ecdhInterceptor?.setHeaders(headers);
    _fixedKeyInterceptor?.setHeaders(headers);
    loggy.debug('批量设置请求头: ${headers.keys.join(', ')}');
  }

  /// 移除指定请求头
  void removeHeader(String key) {
    _ecdhInterceptor?.removeHeader(key);
    _fixedKeyInterceptor?.removeHeader(key);
    loggy.debug('移除请求头: $key');
  }

  /// 清除所有自定义请求头
  void clearHeaders() {
    _ecdhInterceptor?.clearHeaders();
    _fixedKeyInterceptor?.clearHeaders();
    loggy.debug('清除所有自定义请求头');
  }

  /// 获取当前ECDH拦截器的自定义请求头
  Map<String, dynamic>? get ecdhHeaders => _ecdhInterceptor?.customHeaders;

  /// 获取当前FixedKey拦截器的自定义请求头
  Map<String, dynamic>? get fixedKeyHeaders => _fixedKeyInterceptor?.customHeaders;

  /// 释放资源
  ///
  /// 使用 force: false 优雅关闭，等待现有请求完成后再关闭连接，
  /// 避免 "Can't establish connection after adapter was closed" 错误
  void dispose() {
    _authInterceptor?.dispose();
    // 释放 HTTP 客户端资源 - 使用优雅关闭，等待现有请求完成
    _http.shutdown(force: false);
  }

  /// 强制关闭（仅在确定没有进行中的请求时使用）
  void forceDispose() {
    _authInterceptor?.dispose();
    _http.shutdown(force: true);
  }
}

// final apiClient = DataApiClient(/*...*/);
//
// // 启用ECDH加密
// apiClient.useECDH(
// userId: 'user-123',
// keyExchangeUrl: 'https://api.example.com/key-exchange',
// debug: true,
// );
//
// // 运行时动态控制
// apiClient.setECDHEnabled(false); // 禁用加密
// apiClient.setECDHEnabled(true);  // 重新启用加密
//
// // 检查状态
// final isEnabled = apiClient._ecdhInterceptor?.isEnabled ?? false;
