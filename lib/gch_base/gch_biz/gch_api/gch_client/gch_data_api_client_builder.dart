import 'package:dio/dio.dart';
import 'package:guichao/gch_base/gch_flux/gch_flux_engine.dart';
import 'package:guichao/gch_base/gch_flux/gch_shield/gch_auth.dart';
import 'package:guichao/gch_base/gch_flux/gch_shield/gch_encrypt.dart';
import 'package:guichao/gch_base/gch_flux/gch_shield/gch_fixed_key.dart';
import 'package:guichao/gch_base/gch_flux/gch_shield/gch_supabase_auth_interceptor.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_manager.dart';
import 'gch_api_client.dart';

/// Builder 用于构建 [ApiClient] 并注入所需中间件
class DataApiClientBuilder {
  DataApiClientBuilder(this._http);

  final GchFluxEngine _http;
  final List<Interceptor> _middlewares = [];

  /// 使用 Supabase 认证
  DataApiClientBuilder useAuth(
      AuthManager authManager, {
        String? initialToken,
        SignatureGenerator? signatureGenerator,
        Map<String, String>? customHeaders,
      }) {
    _middlewares.add(
      SupabaseAuthInterceptor(
        authManager: authManager,
        initialToken: initialToken,
        signatureGenerator: signatureGenerator,
        customHeaders: customHeaders,
      ),
    );
    return this;
  }


  /// 使用ECDH加密
  DataApiClientBuilder useECDH({
    required String userId,
    required String keyExchangeUrl,
    bool debug = false,
  }) {
    _middlewares.add(
      ECDHCryptoInterceptor(
        userId: userId,
        keyExchangeUrl: keyExchangeUrl,
        debug: debug,
      ),
    );
    return this;
  }

  /// 使用固定密钥加密
  FixedKeyInterceptor useFixedKey({
    required String key,
    bool debug = false,
  }) {
    final interceptor = FixedKeyInterceptor(
      key: key,
      debug: debug,
    );
    _middlewares.add(interceptor);
    return interceptor;
  }

  /// 构建 [ApiClient]，并将所有中间件添加到 [DioHttpClient]
  DataApiClient build({
    required String baseUrl,
    Duration timeout = const Duration(seconds: 30),
    bool enableRetry = true,
    Map<String, String> defaultHeaders = const {},
  }) {
    // 优化：批量添加所有拦截器，只重建一次客户端
    if (_middlewares.isNotEmpty) {
      _http.mountShields(_middlewares);
    }

    final config = ApiClientConfig(
      baseUrl: baseUrl,
      timeout: timeout,
      enableEncryption: _middlewares.any((m) => 
        m is ECDHCryptoInterceptor || 
        m is FixedKeyInterceptor),
      enableAuth:
      _middlewares.any((m) => m is SupabaseAuthInterceptor || m is SignatureAuthInterceptor),
      enableRetry: enableRetry,
      defaultHeaders: defaultHeaders,
    );

    // 提取拦截器引用
    SupabaseAuthInterceptor? authInterceptor;
    ECDHCryptoInterceptor? ecdhInterceptor;
    FixedKeyInterceptor? fixedKeyInterceptor;
    
    for (final middleware in _middlewares) {
      if (middleware is ECDHCryptoInterceptor) {
        ecdhInterceptor = middleware;
      } else if (middleware is FixedKeyInterceptor) {
        fixedKeyInterceptor = middleware;
      } else if (middleware is SupabaseAuthInterceptor) {
        authInterceptor = middleware;
      }
    }
    
    return DataApiClient(
      httpClient: _http,
      config: config,
      authInterceptor: authInterceptor,
      ecdhInterceptor: ecdhInterceptor,
      fixedKeyInterceptor: fixedKeyInterceptor,
    );
  }
}
