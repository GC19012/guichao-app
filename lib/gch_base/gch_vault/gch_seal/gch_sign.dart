import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// 签名生成和验证工具类
///
/// 与Python版本保持完全兼容的HMAC-SHA256签名实现
class GchSigner {
  // 运行时解码，避免明文嵌入二进制
  static final String _defaultSecret = String.fromCharCodes(base64Decode('WU9VUl9ITUFDX1NJR05JTkdfU0VDUkVU'));

  /// 生成请求签名
  ///
  /// [method] HTTP方法
  /// [path] 请求路径
  /// [body] 请求体，可选
  /// 返回包含签名、时间戳和随机数的GchSignResult对象
  static GchSignResult forge(
    String method,
    String path, {
    String? body,
    String? secret,
  }) {
    final effectiveSecret = secret ?? _defaultSecret;
    // 生成时间戳和随机数
    final ts = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final random = Random.secure();
    final nonce = (100000 + random.nextInt(900000)).toString();

    // 创建HMAC对象
    final secretBytes = utf8.encode(effectiveSecret);
    final hmacSha256 = Hmac(sha256, secretBytes);

    // 准备签名数据
    final signatureData = <int>[];
    signatureData.addAll(utf8.encode(method));
    signatureData.addAll(utf8.encode(path));
    signatureData.addAll(utf8.encode(ts));
    signatureData.addAll(utf8.encode(nonce));

    // 注意：根据Python代码，body部分被注释掉了，所以这里也不包含body
    // if (body != null && body.isNotEmpty) {
    //   signatureData.addAll(utf8.encode(body));
    // }

    // 生成签名
    final digest = hmacSha256.convert(signatureData);
    final signature = digest.toString();

    return GchSignResult(
      signature: signature,
      timestamp: ts,
      nonce: nonce,
    );
  }

  /// 验证签名
  /// 对应Python代码中的verifySignature方法
  ///
  /// [method] HTTP方法
  /// [path] 请求路径
  /// [timestamp] 时间戳
  /// [nonce] 随机数
  /// [body] 请求体
  /// [signature] 待验证的签名
  /// 返回签名是否有效
  static bool check(
    String method,
    String path,
    String timestamp,
    String nonce,
    String? body,
    String signature, {
    String? secret,
    bool enableDebug = false,
  }) {
    final effectiveSecret = secret ?? _defaultSecret;

    // 创建HMAC对象
    final secretBytes = utf8.encode(effectiveSecret);
    final hmacSha256 = Hmac(sha256, secretBytes);

    // 准备签名数据
    final signatureData = <int>[];
    signatureData.addAll(utf8.encode(method));
    signatureData.addAll(utf8.encode(path));
    signatureData.addAll(utf8.encode(timestamp));
    signatureData.addAll(utf8.encode(nonce));

    // 如果body存在，则添加到HMAC
    if (body != null && body.isNotEmpty) {
      signatureData.addAll(utf8.encode(body));
    }

    // 生成期望的签名
    final digest = hmacSha256.convert(signatureData);
    final expectedSignature = digest.toString();

    if (enableDebug) {
      print('expected signature: $expectedSignature');
    }

    // 使用constant time compare来比较签名
    return _constantTimeCompare(signature, expectedSignature);
  }

  /// 常量时间比较，防止时序攻击
  ///
  /// [a] 第一个字符串
  /// [b] 第二个字符串
  ///
  /// 返回两个字符串是否相等
  static bool _constantTimeCompare(String a, String b) {
    if (a.length != b.length) {
      return false;
    }

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }

    return result == 0;
  }

  /// 验证签名的便捷方法，使用GchSignResult对象
  ///
  /// [method] HTTP方法
  /// [path] 请求路径
  /// [body] 请求体
  /// [signatureResult] 包含签名信息的对象
  /// [secret] 签名密钥
  /// [enableDebug] 是否启用调试输出
  ///
  /// 返回签名是否有效
  static bool checkWithResult(
    String method,
    String path,
    String? body,
    GchSignResult signatureResult, {
    String? secret,
    bool enableDebug = false,
  }) {
    return check(
      method,
      path,
      signatureResult.timestamp,
      signatureResult.nonce,
      body,
      signatureResult.signature,
      secret: secret,
      enableDebug: enableDebug,
    );
  }

  /// 从HTTP头部提取签名信息
  ///
  /// [headers] HTTP头部Map
  ///
  /// 返回GchSignResult对象，如果头部信息不完整则返回null
  static GchSignResult? extractSignatureFromHeaders(Map<String, String> headers) {
    final signature = headers['X-Signature'];
    final timestamp = headers['X-Timestamp'];
    final nonce = headers['X-Nonce'];

    if (signature == null || timestamp == null || nonce == null) {
      return null;
    }

    return GchSignResult(
      signature: signature,
      timestamp: timestamp,
      nonce: nonce,
    );
  }

  /// 将签名信息添加到HTTP头部
  ///
  /// [headers] 要修改的HTTP头部Map
  /// [signatureResult] 签名结果对象
  static void addSignatureToHeaders(
    Map<String, String> headers,
    GchSignResult signatureResult,
  ) {
    headers['X-Signature'] = signatureResult.signature;
    headers['X-Timestamp'] = signatureResult.timestamp;
    headers['X-Nonce'] = signatureResult.nonce;
  }
}

/// 签名结果数据类
class GchSignResult {
  /// 生成的签名
  final String signature;

  /// 时间戳
  final String timestamp;

  /// 随机数
  final String nonce;

  const GchSignResult({
    required this.signature,
    required this.timestamp,
    required this.nonce,
  });

  /// 转换为Map
  Map<String, String> toMap() {
    return {
      'signature': signature,
      'timestamp': timestamp,
      'nonce': nonce,
    };
  }

  /// 从Map创建
  factory GchSignResult.fromMap(Map<String, String> map) {
    return GchSignResult(
      signature: map['signature']!,
      timestamp: map['timestamp']!,
      nonce: map['nonce']!,
    );
  }

  /// 转换为JSON字符串
  String toJson() => jsonEncode(toMap());

  /// 从JSON字符串创建
  factory GchSignResult.fromJson(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    return GchSignResult.fromMap(map.cast<String, String>());
  }

  @override
  String toString() {
    return 'GchSignResult(signature: $signature, timestamp: $timestamp, nonce: $nonce)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GchSignResult &&
        other.signature == signature &&
        other.timestamp == timestamp &&
        other.nonce == nonce;
  }

  @override
  int get hashCode => signature.hashCode ^ timestamp.hashCode ^ nonce.hashCode;
}

/// 签名验证异常
class GchSignException implements Exception {
  final String message;

  const GchSignException(this.message);

  @override
  String toString() => 'GchSignException: $message';
}

/// 扩展方法，为HTTP客户端添加签名功能
extension GchSignExt on Map<String, String> {
  /// 为HTTP请求添加签名头部
  ///
  /// [method] HTTP方法
  /// [path] 请求路径
  /// [body] 请求体
  /// [secret] 签名密钥
  void addSignature(
    String method,
    String path, {
    String? body,
    String? secret,
  }) {
    final result = GchSigner.forge(
      method,
      path,
      body: body,
      secret: secret,
    );
    GchSigner.addSignatureToHeaders(this, result);
  }
}
