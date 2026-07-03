import 'package:dio/dio.dart';
import 'package:guichao/gch_base/gch_vault/gch_cipher/gch_cipher.dart';

/// 固定密钥加密拦截器 - 使用AES-256-GCM与服务端共享密钥
class FixedKeyInterceptor extends Interceptor {
  String _key;  // 改为可变，以支持动态更新
  late GchCipher _aes;  // 移除final，以支持重新初始化
  bool _enabled = true;
  final bool _debug;
  final void Function(String message)? _logger;
  final Map<String, dynamic> _customHeaders = {};

  FixedKeyInterceptor({
    required String key,
    bool enabled = true,
    bool debug = false,
    void Function(String message)? logger,
  }) : _key = key, _enabled = enabled, _debug = debug, _logger = logger {
    _initCrypto();
  }

  /// 初始化AES加密组件
  void _initCrypto() {
    // 使用KDF派生密钥，与服务端保持一致
    _aes = GchCipher.fromStringWithKDF(_key);
  }
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// 获取启用状态
  bool get isEnabled => _enabled;
  void updateKey(String newKey) {
    _key = newKey;
    _initCrypto(); // 重新初始化加密组件
  }
  String get currentKey => _key;
  void setHeader(String key, dynamic value) {
    _customHeaders[key] = value;
  }

  /// 批量设置请求头
  void setHeaders(Map<String, dynamic> headers) {
    _customHeaders.addAll(headers);
  }

  /// 移除指定请求头
  void removeHeader(String key) {
    _customHeaders.remove(key);
  }

  /// 清除所有自定义请求头
  void clearHeaders() {
    _customHeaders.clear();
  }

  /// 获取所有自定义请求头
  Map<String, dynamic> get customHeaders => Map.unmodifiable(_customHeaders);

  /// 日志输出
  void _log(String message) {
    if (_debug) {
      _logger?.call(message);
    }
  }




  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 始终应用自定义请求头（无论是否加密）
    if (_customHeaders.isNotEmpty) {
      options.headers.addAll(_customHeaders);
      _log('已应用 ${_customHeaders.length} 个自定义请求头');
    }

    if (!_enabled || options.data == null ||
        !['POST', 'PUT', 'PATCH'].contains(options.method.toUpperCase())) {
      handler.next(options);
      return;
    }

    try {
      // 设置加密模式header，告诉服务端使用固定密钥模式
      options.headers['X-Crypto-Mode'] = 'fixed';
      final data = options.data;
      final encrypted = _aes.seal(data);
      options.data = {'data': encrypted};
      options.headers['Content-Type'] = 'application/json';
    } catch (e) {
      _log('[ERROR] 加密失败: $e');
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!_enabled || response.data is! Map<String, dynamic>) {
      handler.next(response);
      return;
    }

    try {
      final responseMap = response.data as Map<String, dynamic>;
      if (responseMap.containsKey('data') && responseMap['data'] is String) {
        final encryptedData = responseMap['data'] as String;
        final decryptedData = _aes.unseal(encryptedData);
        responseMap['data'] = decryptedData;
        response.data = responseMap;
      }
    } catch (e) {
      _log('[ERROR] 解密失败: $e');
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_enabled && err.response?.data is Map<String, dynamic>) {
      try {
        final responseMap = err.response!.data as Map<String, dynamic>;
        if (responseMap.containsKey('data') && responseMap['data'] is String) {
          final encryptedData = responseMap['data'] as String;
          // 调试模式下显示错误响应的加密数据
          final decryptedData = _aes.unseal(encryptedData);
          responseMap['data'] = decryptedData;
          err.response!.data = responseMap;
        }
      } catch (e) {
        _log('[ERROR] 错误响应解密失败: $e');
      }
    }

    handler.next(err);
  }
}
