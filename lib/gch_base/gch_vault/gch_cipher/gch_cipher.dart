import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

/// AES-256 加密工具类
class GchCipher {
  final Uint8List _key;
  late final GCMBlockCipher _cipher;

  GchCipher._(this._key) {
    final aesEngine = AESEngine();
    _cipher = GCMBlockCipher(aesEngine);
  }

  /// 创建 AES 加密实例
  factory GchCipher.create(Uint8List key) {
    if (key.length != 32) {
      throw ArgumentError('AES-256 key must be 32 bytes, got ${key.length}');
    }
    return GchCipher._(key);
  }

  /// 从字符串创建 AES 实例
  factory GchCipher.fromString(String keyString) {
    var keyBytes = utf8.encode(keyString);
    var key = Uint8List(32);
    if (keyBytes.length >= 32) {
      key.setAll(0, keyBytes.take(32));
    } else {
      key.setAll(0, keyBytes);
      for (int i = keyBytes.length; i < 32; i++) {
        key[i] = 0;
      }
    }
    return GchCipher._(key);
  }

  /// 从字符串创建 AES 实例 - 使用HKDF派生增强安全性（与服务端一致）
  factory GchCipher.fromStringWithKDF(String keyString) {
    // 使用与服务端相同的参数进行密钥派生
    final salt = base64Decode('WU9VUl9BUFBfU0FMVA=='); // 应用特定的盐值（占位符，运行时解码）
    final info = utf8.encode('fixed-key-encryption'); // 上下文信息

    // 使用SHA-256对userID进行初步处理，作为HKDF的输入密钥材料(IKM)
    final sha256 = SHA256Digest();
    sha256.update(utf8.encode(keyString), 0, utf8.encode(keyString).length);
    final _kdfCtx = base64Decode('WU9VUl9LREZfQ09OVEVYVA==');
    sha256.update(_kdfCtx, 0, _kdfCtx.length);
    final ikm = Uint8List(sha256.digestSize);
    sha256.doFinal(ikm, 0);

    // 使用HKDF派生32字节的AES-256密钥
    final hkdf = HKDFKeyDerivator(SHA256Digest());
    final params = HkdfParameters(
      ikm,           // IKM (Input Keying Material)
      32,            // 期望的密钥长度（32字节）
      salt,          // Salt（盐值）
      info,          // Info（上下文信息）
      false,         // 不跳过Extract阶段
    );

    hkdf.init(params);

    // 生成派生密钥
    final derivedKey = Uint8List(32);
    hkdf.deriveKey(null, 0, derivedKey, 0);

    // 打印派生密钥的Base64编码（可通过GchNucleus控制）

    return GchCipher._(derivedKey);
  }

  /// 生成 32 字节随机密钥
  static Uint8List generateRandomKey() {
    final random = Random.secure();
    final key = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      key[i] = random.nextInt(256);
    }
    return key;
  }

  /// AES-256-GCM 加密
  String seal(dynamic data) {
    try {
      final jsonData = jsonEncode(data);
      final plaintext = utf8.encode(jsonData);

      // 生成 12 字节随机 nonce
      final random = Random.secure();
      final nonce = Uint8List(12);
      for (int i = 0; i < 12; i++) {
        nonce[i] = random.nextInt(256);
      }

      // 初始化 GCM 加密
      final params = AEADParameters(
        KeyParameter(_key),
        128, // 128位MAC
        nonce,
        Uint8List(0), // 无附加数据
      );

      _cipher.init(true, params);

      // 加密数据
      final output = Uint8List(plaintext.length + _cipher.macSize);
      final len = _cipher.processBytes(plaintext, 0, plaintext.length, output, 0);
      _cipher.doFinal(output, len);

      // 拼接 nonce 和密文
      final combined = Uint8List(nonce.length + output.length);
      combined.setAll(0, nonce);
      combined.setAll(nonce.length, output);

      return base64.encode(combined);
    } catch (e) {
      throw GchCipherException('Failed to encrypt data: $e');
    }
  }

  /// AES-256-GCM 解密
  dynamic unseal(String data) {
    try {
      final encrypted = base64.decode(data);

      const nonceSize = 12;
      if (encrypted.length < nonceSize + 16) { // nonce + minimum MAC
        throw GchCipherException('Ciphertext too short');
      }

      final nonce = encrypted.sublist(0, nonceSize);
      final ciphertext = encrypted.sublist(nonceSize);

      // 初始化 GCM 解密
      final params = AEADParameters(
        KeyParameter(_key),
        128, // 128位MAC
        nonce,
        Uint8List(0), // 无附加数据
      );

      _cipher.init(false, params);

      // 解密数据
      final output = Uint8List(ciphertext.length - _cipher.macSize);
      final len = _cipher.processBytes(ciphertext, 0, ciphertext.length, output, 0);
      _cipher.doFinal(output, len);

      final jsonString = utf8.decode(output);
      return jsonDecode(jsonString);
    } catch (e) {
      throw GchCipherException('Failed to decrypt data: $e');
    }
  }

  /// 解密为 Map
  Map<String, dynamic> unsealMap(String data) {
    final result = unseal(data);
    if (result is! Map<String, dynamic>) {
      throw GchCipherException('Decrypted data is not a map');
    }
    return result;
  }

  /// 解密为 List
  List<dynamic> unsealList(String data) {
    final result = unseal(data);
    if (result is! List<dynamic>) {
      throw GchCipherException('Decrypted data is not a list');
    }
    return result;
  }

  /// 解密为指定类型
  T unsealAs<T>(String data, T Function(Map<String, dynamic>) fromJson) {
    final map = unsealMap(data);
    return fromJson(map);
  }
}

/// AES 加密异常
class GchCipherException implements Exception {
  final String message;
  const GchCipherException(this.message);
  @override
  String toString() => 'GchCipherException: $message';
}
