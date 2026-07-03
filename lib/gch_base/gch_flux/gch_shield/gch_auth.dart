import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';

/// 签名生成器函数类型
typedef SignatureGenerator = String Function({
required String method,
required String url,
required String timestamp,
required String nonce,
String? body,
String? token,
});

/// 签名认证拦截器
class SignatureAuthInterceptor extends Interceptor {
  String? _token;
  SignatureGenerator? _signatureGenerator;
  bool _enabled = true;
  final Map<String, String> _customHeaders = {};

  SignatureAuthInterceptor({
    String? token,
    SignatureGenerator? signatureGenerator,
    Map<String, String>? customHeaders,
  }) : _token = token,
        _signatureGenerator = signatureGenerator {
    if (customHeaders != null) {
      _customHeaders.addAll(customHeaders);
    }
  }

  /// 设置 Bearer Token
  void setToken(String? token) {
    _token = token;
  }

  /// 获取当前 Token
  String? get token => _token;

  /// 设置签名生成器
  void setSignatureGenerator(SignatureGenerator? generator) {
    _signatureGenerator = generator;
  }

  /// 启用/禁用拦截器
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// 是否启用
  bool get isEnabled => _enabled;

  /// 添加自定义 header
  void addHeader(String key, String value) {
    _customHeaders[key] = value;
  }

  /// 移除自定义 header
  void removeHeader(String key) {
    _customHeaders.remove(key);
  }

  /// 批量设置自定义 headers
  void setHeaders(Map<String, String> headers) {
    _customHeaders.clear();
    _customHeaders.addAll(headers);
  }

  /// 获取所有自定义 headers
  Map<String, String> get customHeaders => Map.unmodifiable(_customHeaders);

  /// 清除自定义 headers
  void clearHeaders() {
    _customHeaders.clear();
  }

  /// 清除所有配置
  void clear() {
    _token = null;
    _signatureGenerator = null;
    _customHeaders.clear();
  }

  /// 生成随机 nonce
  String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// 生成时间戳
  String _generateTimestamp() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_enabled) {
      handler.next(options);
      return;
    }

    // 添加自定义 headers（优先级最高，可以覆盖默认值）
    options.headers.addAll(_customHeaders);

    // 添加 Bearer Token
    if (_token != null && _token!.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $_token';
    }

    // 如果有签名生成器，添加签名相关 headers
    if (_signatureGenerator != null) {
      final timestamp = _generateTimestamp();
      final nonce = _generateNonce();

      // 获取请求体（如果有）
      String? body;
      if (options.data != null) {
        if (options.data is String) {
          body = options.data as String;
        } else if (options.data is Map) {
          body = jsonEncode(options.data);
        } else {
          body = options.data.toString();
        }
      }

      // 生成签名
      final signature = _signatureGenerator!(
        method: options.method,
        url: options.uri.toString(),
        timestamp: timestamp,
        nonce: nonce,
        body: body,
        token: _token,
      );

      // 添加签名 headers
      options.headers['X-Signature'] = signature;
      options.headers['X-Timestamp'] = timestamp;
      options.headers['X-Nonce'] = nonce;
    }

    handler.next(options);
  }
}

/// 常用签名算法
class SignatureAlgorithms {
  /// HMAC-SHA256 签名
  static String hmacSha256({
    required String method,
    required String url,
    required String timestamp,
    required String nonce,
    required String secretKey,
    String? body,
    String? token,
  }) {
    // 构建签名字符串
    final parts = [
      method.toUpperCase(),
      url,
      timestamp,
      nonce,
      if (body != null && body.isNotEmpty) body,
      if (token != null && token.isNotEmpty) token,
    ];

    final signString = parts.join('|');
    final key = utf8.encode(secretKey);
    final bytes = utf8.encode(signString);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);

    return base64.encode(digest.bytes);
  }

  /// MD5 签名（简单示例）
  static String md5Sign({
    required String method,
    required String url,
    required String timestamp,
    required String nonce,
    required String secretKey,
    String? body,
    String? token,
  }) {
    final parts = [
      method.toUpperCase(),
      url,
      timestamp,
      nonce,
      if (body != null && body.isNotEmpty) body,
      secretKey,
    ];

    final signString = parts.join('');
    return md5.convert(utf8.encode(signString)).toString();
  }
}