// crypto_utils.dart
// 认证加密相关的工具函数

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// 认证加密工具类
class AuthCryptoHelper {
  AuthCryptoHelper._();

  /// 生成安全的随机 nonce 字符串
  ///
  /// 用于 OAuth 认证流程（如 Apple Sign-In）中防止重放攻击
  /// [length] nonce 长度，默认 32 字符
  static String createNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// 计算字符串的 SHA256 哈希值
  ///
  /// [input] 要哈希的字符串
  /// 返回十六进制格式的哈希值
  static String computeSha256(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 生成 nonce 及其 SHA256 哈希值
  ///
  /// 返回一个包含原始 nonce 和哈希值的记录
  /// - `rawNonce`: 原始 nonce，用于服务端验证
  /// - `hashedNonce`: SHA256 哈希后的 nonce，用于传给第三方认证服务
  static ({String rawNonce, String hashedNonce}) createNonceWithHash([
    int length = 32,
  ]) {
    final rawNonce = createNonce(length);
    final hashedNonce = computeSha256(rawNonce);
    return (rawNonce: rawNonce, hashedNonce: hashedNonce);
  }
}
