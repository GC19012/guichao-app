import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:guichao/gch_base/gch_flux/gch_shield/gch_network_diagnostic_interceptor.dart';
import 'package:guichao/gch_aux/gch_log_mix.dart';

/// HTTP 客户端配置
class GchFluxConfig {
  final Duration timeout;
  final String userAgent;
  final bool debug;
  final List<Duration> retryDelays;
  final RetryEvaluator? retryEvaluator;
  final bool enableProxy;  // 新增：是否启用代理功能

  const GchFluxConfig({
    this.timeout = const Duration(seconds: 30),
    this.userAgent = 'GchFluxEngine/1.0',
    this.debug = false,
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 3),
    ],
    this.retryEvaluator,
    this.enableProxy = true,  // 默认启用代理
  });
}

/// 代理模式
enum GchRouteMode { bypass, tunnel, dual }

/// 请求上下文
class GchRequestCtx {
  final String url;
  final String? userAgent;
  final ({String username, String password})? credentials;
  final GchRouteMode proxyMode;
  final Map<String, dynamic> extra;

  GchRequestCtx({
    required this.url,
    this.userAgent,
    this.credentials,
    this.proxyMode = GchRouteMode.dual,
    this.extra = const {},
  });
}

/// 代理连接池
class GchPortProbe {
  final _checks = <String, Completer<bool>>{};
  final _cache = <String, (bool, DateTime)>{};
  final Duration cacheTimeout;

  GchPortProbe({this.cacheTimeout = const Duration(seconds: 30)});

  Future<bool> probePort(String host, int port, {Duration timeout = const Duration(seconds: 2)}) async {
    final key = '$host:$port';

    // 检查缓存
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.$2) < cacheTimeout) {
      return cached.$1;
    }

    // 防止并发检查
    final existing = _checks[key];
    if (existing != null) {
      return existing.future;
    }

    final completer = Completer<bool>();
    _checks[key] = completer;

    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      await socket.close();
      _cache[key] = (true, DateTime.now());
      completer.complete(true);
      return true;
    } catch (_) {
      _cache[key] = (false, DateTime.now());
      completer.complete(false);
      return false;
    } finally {
      _checks.remove(key);
    }
  }

  void flush() {
    _cache.clear();
    _checks.clear();
  }
}

/// 精简的 HTTP 客户端
class GchFluxEngine with GchInfraLogger {
  final GchFluxConfig config;
  final _clients = <GchRouteMode, Dio>{};
  final Map<Interceptor, Set<GchRouteMode>> _interceptorBindings = LinkedHashMap.identity();

  // 使用静态 GchPortProbe 实现多实例共享
  static final _sharedGchPortProbe = GchPortProbe();
  // 每个实例也可以选择使用自己的 GchPortProbe
  final GchPortProbe? _instanceGchPortProbe;

  GchPortProbe get _proxyPool => _instanceGchPortProbe ?? _sharedGchPortProbe;

  int _proxyPort = 0;

  GchFluxEngine({GchFluxConfig? config, bool useSharedGchPortProbe = true})
      : config = config ?? const GchFluxConfig(),
        _instanceGchPortProbe = useSharedGchPortProbe ? null : GchPortProbe() {
    _initClients();
  }

  /// 安全地关闭现有客户端
  void _closeExistingClients() {
    if (_clients.isNotEmpty) {
      loggy.debug('释放 ${_clients.length} 个旧的 Dio 客户端实例');
      for (final client in _clients.values) {
        try {
          client.close(force: true);
        } catch (e) {
          loggy.warning('关闭客户端时出错: $e');
        }
      }
      _clients.clear();
    }
  }

  void _initClients() {
    // 释放旧的客户端实例，避免资源泄漏
    _closeExistingClients();

    // 如果不启用代理，只创建 direct 客户端
    final modes = config.enableProxy
        ? [GchRouteMode.bypass, GchRouteMode.tunnel, GchRouteMode.dual]
        : [GchRouteMode.bypass];

    for (final mode in modes) {
      final dio = Dio(
        BaseOptions(
          connectTimeout: config.timeout,
          sendTimeout: config.timeout,
          receiveTimeout: config.timeout,
          headers: {'User-Agent': config.userAgent},
        ),
      );

      // 配置重试策略
      final retryDelays = mode == GchRouteMode.tunnel
          ? [const Duration(seconds: 1)]
          : config.retryDelays;

      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          retryDelays: retryDelays,
          retryEvaluator: config.retryEvaluator,
        ),
      );

      // 网络诊断拦截器（在所有拦截器之前，以便捕获原始错误）
      dio.interceptors.add(NetworkDiagnosticInterceptor());

      // 调试日志
      if (config.debug) {
        dio.interceptors.add(LogInterceptor(
          requestHeader: true,
          responseHeader: true,
          error: true,
        ));
      }

      // 配置代理 + TLS 诊断
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.findProxy = (uri) => _getProxyString(mode);
          // 记录证书错误（不跳过验证，仅用于诊断日志）
          client.badCertificateCallback = (X509Certificate cert, String host, int port) {
            loggy.error('[TLS-Adapter] badCertificate: host=$host:$port, '
                'subject=${cert.subject}, issuer=${cert.issuer}, '
                'validFrom=${cert.startValidity}, validTo=${cert.endValidity}');
            return false; // 保持安全，不跳过证书验证
          };
          return client;
        },
      );

      _clients[mode] = dio;
    }
    _replayInterceptors();
  }
  Future<bool> probePort({
    String host = '127.0.0.1',
    int? port,
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final targetPort = port ?? _proxyPort;

    if (targetPort <= 0) {
      loggy.warning("端口号无效: [$targetPort]");
      return false;
    }

    try {
      final result = await _proxyPool.probePort(host, targetPort, timeout: timeout);
      loggy.debug("端口检查 [$host:$targetPort] -> $result");
      return result;
    } catch (e) {
      loggy.error("端口检查异常 [$host:$targetPort]: $e");
      return false;
    }
  }
  String _getProxyString(GchRouteMode mode) {
    switch (mode) {
      case GchRouteMode.tunnel:
        return 'PROXY localhost:$_proxyPort';
      case GchRouteMode.dual:
        return 'PROXY localhost:$_proxyPort; DIRECT';
      default:
        return 'DIRECT';
    }
  }

  void bindPort(int port) {
    _proxyPort = port;
    _proxyPool.flush();
    loggy.debug("设置代理端口: [$port]");
  }

  void mountShield(
    Interceptor interceptor, {
    Set<GchRouteMode>? modes,
  }) {
    final resolvedModes = _resolveModes(modes);
    final existingModes = _interceptorBindings[interceptor];
    if (existingModes != null) {
      _removeInterceptorFromModes(interceptor, existingModes);
    }
    _interceptorBindings[interceptor] = resolvedModes;
    _applyInterceptorToModes(interceptor, resolvedModes);
  }

  void dropShield(Interceptor interceptor) {
    final modes = _interceptorBindings.remove(interceptor);
    if (modes == null) {
      return;
    }
    _removeInterceptorFromModes(interceptor, modes);
  }

  /// 批量添加拦截器（推荐用于初始化阶段）
  /// 只重建一次客户端，减少资源开销
  void mountShields(
    List<Interceptor> interceptors, {
    Set<GchRouteMode>? modes,
  }) {
    for (final interceptor in interceptors) {
      mountShield(interceptor, modes: modes);
    }
  }

  /// 批量移除拦截器
  void dropShields(List<Interceptor> interceptors) {
    for (final interceptor in interceptors) {
      dropShield(interceptor);
    }
  }

  Future<Response<T>> get<T>(
      String url, {
        CancelToken? cancelToken,
        String? userAgent,
        ({String username, String password})? credentials,
        bool proxyOnly = false,
      }) async {
    final mode = !config.enableProxy
        ? GchRouteMode.bypass  // 如果禁用代理，始终使用直连
        : proxyOnly
        ? GchRouteMode.tunnel
        : await _proxyPool.probePort('127.0.0.1', _proxyPort)
        ? GchRouteMode.dual
        : GchRouteMode.bypass;

    final dio = await _selectClient(mode);
    final options = _buildOptions(
      GchRequestCtx(
        url: url,
        userAgent: userAgent,
        credentials: credentials,
        proxyMode: mode,
      ),
    );

    return dio.get<T>(url, cancelToken: cancelToken, options: options);
  }

  Future<Response<T>> post<T>(
      String url, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        CancelToken? cancelToken,
        String? userAgent,
        ({String username, String password})? credentials,
        bool proxyOnly = false,
      }) async {
    final mode = !config.enableProxy
        ? GchRouteMode.bypass  // 如果禁用代理，始终使用直连
        : proxyOnly
        ? GchRouteMode.tunnel
        : await _proxyPool.probePort('127.0.0.1', _proxyPort)
        ? GchRouteMode.dual
        : GchRouteMode.bypass;

    final dio = await _selectClient(mode);
    final options = _buildOptions(
      GchRequestCtx(
        url: url,
        userAgent: userAgent,
        credentials: credentials,
        proxyMode: mode,
      ),
    );

    return dio.post<T>(
      url,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
      String url, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        CancelToken? cancelToken,
        String? userAgent,
        ({String username, String password})? credentials,
        bool proxyOnly = false,
      }) async {
    final mode = !config.enableProxy
        ? GchRouteMode.bypass  // 如果禁用代理，始终使用直连
        : proxyOnly
        ? GchRouteMode.tunnel
        : await _proxyPool.probePort('127.0.0.1', _proxyPort)
        ? GchRouteMode.dual
        : GchRouteMode.bypass;

    final dio = await _selectClient(mode);
    final options = _buildOptions(
      GchRequestCtx(
        url: url,
        userAgent: userAgent,
        credentials: credentials,
        proxyMode: mode,
      ),
    );

    return dio.put<T>(
      url,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
      String url, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        CancelToken? cancelToken,
        String? userAgent,
        ({String username, String password})? credentials,
        bool proxyOnly = false,
      }) async {
    final mode = !config.enableProxy
        ? GchRouteMode.bypass  // 如果禁用代理，始终使用直连
        : proxyOnly
        ? GchRouteMode.tunnel
        : await _proxyPool.probePort('127.0.0.1', _proxyPort)
        ? GchRouteMode.dual
        : GchRouteMode.bypass;

    final dio = await _selectClient(mode);
    final options = _buildOptions(
      GchRequestCtx(
        url: url,
        userAgent: userAgent,
        credentials: credentials,
        proxyMode: mode,
      ),
    );

    return dio.delete<T>(
      url,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
    );
  }

  Future<Response> download(
      String url,
      String savePath, {
        CancelToken? cancelToken,
        String? userAgent,
        ({String username, String password})? credentials,
        bool proxyOnly = false,
        bool skipInterceptors = false,
      }) async {
    // 跳过拦截器：用于外部URL（如S3），避免自定义header导致400错误
    if (skipInterceptors) {
      final cleanDio = Dio(BaseOptions(
        connectTimeout: config.timeout,
        receiveTimeout: config.timeout,
        headers: {if (userAgent != null) 'User-Agent': userAgent},
      ));
      try {
        return await cleanDio.download(url, savePath, cancelToken: cancelToken);
      } finally {
        cleanDio.close(force: true);
      }
    }

    final mode = !config.enableProxy
        ? GchRouteMode.bypass  // 如果禁用代理，始终使用直连
        : proxyOnly
        ? GchRouteMode.tunnel
        : await _proxyPool.probePort('127.0.0.1', _proxyPort)
        ? GchRouteMode.dual
        : GchRouteMode.bypass;

    final dio = await _selectClient(mode);
    final options = _buildOptions(
      GchRequestCtx(
        url: url,
        userAgent: userAgent,
        credentials: credentials,
        proxyMode: mode,
      ),
    );

    return dio.download(url, savePath, cancelToken: cancelToken, options: options);
  }

  Future<Dio> _selectClient(GchRouteMode mode) async {
    final client = _clients[mode];
    if (client == null) {
      throw StateError('客户端未初始化: ${mode.name}');
    }
    return client;
  }

  Options _buildOptions(GchRequestCtx context, [Options? baseOptions]) {
    final uri = Uri.parse(context.url);

    String? auth;
    if (context.credentials != null) {
      final userInfo = '${context.credentials!.username}:${context.credentials!.password}';
      auth = 'Basic ${base64.encode(utf8.encode(userInfo))}';
    } else if (uri.userInfo.isNotEmpty) {
      auth = 'Basic ${base64.encode(utf8.encode(uri.userInfo))}';
    }

    final headers = <String, dynamic>{
      if (context.userAgent != null) 'User-Agent': context.userAgent,
      if (auth != null) 'Authorization': auth,
    };

    if (baseOptions != null) {
      headers.addAll(baseOptions.headers ?? {});
      return baseOptions.copyWith(
        headers: headers,
        extra: {...baseOptions.extra ?? {}, ...context.extra},
      );
    }

    return Options(headers: headers, extra: context.extra);
  }

  void shutdown({bool force = false}) {
    for (final client in _clients.values) {
      client.close(force: force);
    }
    _clients.clear();
    _proxyPool.flush();
    _interceptorBindings.clear();
  }

  /// 释放资源的别名，与 DataApiClient 保持一致
  void teardown() => shutdown(force: true);

  Set<GchRouteMode> _resolveModes(Set<GchRouteMode>? modes) {
    final availableModes = _clients.isEmpty
        ? _defaultModes()
        : _clients.keys.toSet();
    if (modes == null || modes.isEmpty) {
      return availableModes;
    }
    final filtered = modes.where((mode) => availableModes.contains(mode)).toSet();
    return filtered.isEmpty ? availableModes : filtered;
  }

  Set<GchRouteMode> _defaultModes() {
    return config.enableProxy
        ? {GchRouteMode.bypass, GchRouteMode.tunnel, GchRouteMode.dual}
        : {GchRouteMode.bypass};
  }

  void _applyInterceptorToModes(Interceptor interceptor, Set<GchRouteMode> modes) {
    for (final mode in modes) {
      final client = _clients[mode];
      if (client == null) continue;
      if (!client.interceptors.contains(interceptor)) {
        client.interceptors.add(interceptor);
      }
    }
  }

  void _removeInterceptorFromModes(Interceptor interceptor, Set<GchRouteMode> modes) {
    for (final mode in modes) {
      final client = _clients[mode];
      client?.interceptors.remove(interceptor);
    }
  }

  void _replayInterceptors() {
    for (final entry in _interceptorBindings.entries) {
      _applyInterceptorToModes(entry.key, entry.value);
    }
  }
}
