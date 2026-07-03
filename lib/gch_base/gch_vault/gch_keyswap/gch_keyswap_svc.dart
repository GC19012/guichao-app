// gch_keyswap_svc.dart
// KeySwap服务 - 使用PointyCastle实现

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import 'package:guichao/gch_base/gch_vault/gch_keyswap/gch_key_vault.dart';
import 'package:guichao/gch_base/gch_vault/gch_keyswap/gch_keyswap_model.dart';

/// 极简KeySwap服务 - PointyCastle实现
///
/// 基于P-256曲线和AES-GCM的安全加密服务
class GchKeySwapSvc {
  // P-256椭圆曲线参数
  static final _domainParams = ECDomainParameters('secp256r1');

  // 密钥生成器
  static final _keyGenerator = ECKeyGenerator()
    ..init(ParametersWithRandom(
      ECKeyGeneratorParameters(_domainParams),
      SecureRandom('Fortuna')..seed(KeyParameter(_generateSeed())),
    ));

  // ECDH密钥交换
  static final _ecdh = ECDHBasicAgreement();

  // AES-GCM加密器
  static final _aesGcm = GCMBlockCipher(AESEngine());

  /// 生成随机种子
  static Uint8List _generateSeed() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(32, (i) => random.nextInt(256))
    );
  }

  /// 生成密钥对
  static Future<GchKeyPair> _genKeys() async {
    final keyPair = _keyGenerator.generateKeyPair();
    final publicKey = keyPair.publicKey;
    final privateKey = keyPair.privateKey;

    // 提取密钥字节 - P-256公钥为65字节(未压缩格式)
    final publicBytes = _encodePublicKey(publicKey);
    final privateBytes = _encodePrivateKey(privateKey);

    return GchKeyPair(
      privateKey: privateBytes,
      publicKey: publicBytes,
    );
  }

  /// 编码公钥为字节数组
  static Uint8List _encodePublicKey(ECPublicKey publicKey) {
    final point = publicKey.Q!;
    final x = point.x!.toBigInteger()!;
    final y = point.y!.toBigInteger()!;

    // 未压缩格式：0x04 + x(32字节) + y(32字节)
    final encoded = Uint8List(65);
    encoded[0] = 0x04; // 未压缩标识

    final xBytes = _bigIntToBytes(x, 32);
    final yBytes = _bigIntToBytes(y, 32);

    encoded.setRange(1, 33, xBytes);
    encoded.setRange(33, 65, yBytes);

    return encoded;
  }

  /// 编码私钥为字节数组
  static Uint8List _encodePrivateKey(ECPrivateKey privateKey) {
    return _bigIntToBytes(privateKey.d!, 32);
  }

  /// BigInt转换为固定长度字节数组
  static Uint8List _bigIntToBytes(BigInt value, int length) {
    final bytes = Uint8List(length);
    final valueBytes = value.toRadixString(16).padLeft(length * 2, '0');

    for (int i = 0; i < length; i++) {
      final hex = valueBytes.substring(i * 2, i * 2 + 2);
      bytes[i] = int.parse(hex, radix: 16);
    }

    return bytes;
  }

  /// 从字节数组重建公钥
  static ECPublicKey _decodePublicKey(Uint8List publicBytes) {
    if (publicBytes.length != 65 || publicBytes[0] != 0x04) {
      throw ArgumentError('Invalid public key format');
    }

    final xBytes = publicBytes.sublist(1, 33);
    final yBytes = publicBytes.sublist(33, 65);

    final x = _bytesToBigInt(xBytes);
    final y = _bytesToBigInt(yBytes);

    final point = _domainParams.curve.createPoint(x, y);
    return ECPublicKey(point, _domainParams);
  }

  /// 从字节数组重建私钥
  static ECPrivateKey _decodePrivateKey(Uint8List privateBytes) {
    final d = _bytesToBigInt(privateBytes);
    return ECPrivateKey(d, _domainParams);
  }

  /// 字节数组转换为BigInt
  static BigInt _bytesToBigInt(Uint8List bytes) {
    var result = BigInt.zero;
    for (final byte in bytes) {
      result = (result << 8) + BigInt.from(byte);
    }
    return result;
  }

  /// 计算共享密钥
  static Future<Uint8List?> _computeSecret(
    Uint8List privateBytes,
    Uint8List publicBytes
  ) async {
    try {
      final privateKey = _decodePrivateKey(privateBytes);
      final publicKey = _decodePublicKey(publicBytes);

      _ecdh.init(privateKey);
      final sharedSecret = _ecdh.calculateAgreement(publicKey);

      return _bigIntToBytes(sharedSecret, 32);
    } catch (e) {
      return null;
    }
  }

  /// 派生用户密钥 - 使用PointyCastle的标准HKDF实现，与Go服务端完全兼容
  static Future<Uint8List> _deriveKey(Uint8List sharedSecret, String userId) async {
    // 与Go服务端严格一致: hkdf.New(sha256.New, sharedSecret, []byte(userid), nil)
    // Go代码参数顺序: hash, secret(IKM), salt, info
    // Go中: secret=sharedSecret, salt=[]byte(userid), info=nil

    // 使用PointyCastle的HKDFKeyDerivator
    final hkdf = HKDFKeyDerivator(SHA256Digest());

    // 初始化HKDF参数 - 与Go端完全一致
    // HkdfParameters构造函数参数顺序: (ikm, desiredKeyLength, salt, info, skipExtract)
    // Go的HKDF: hkdf.New(sha256.New, sharedSecret, []byte(userid), nil)
    //   - sharedSecret作为IKM
    //   - []byte(userid)作为salt
    //   - nil作为info（空）
    final params = HkdfParameters(
      sharedSecret,         // IKM (Input Keying Material) - 对应Go的sharedSecret
      32,                   // 期望的密钥长度（32字节）
      utf8.encode(userId),  // Salt（盐值）- 对应Go的[]byte(userid)
      Uint8List(0),         // Info（空）- 对应Go的nil
      false,                // 不跳过Extract阶段
    );

    hkdf.init(params);

    // 生成派生密钥
    final derivedKey = Uint8List(32);
    hkdf.deriveKey(null, 0, derivedKey, 0);

    return derivedKey;
  }

  /// 为用户生成密钥对
  static Future<GchUserKeys?> generateUserKeys(String userId, {Duration? ttl}) async {
    try {
      final keyPair = await _genKeys();
      final expiresAt = ttl != null ? DateTime.now().add(ttl) : null;

      final userKeys = GchUserKeys(
        userId: userId,
        privateKey: keyPair.privateKey,
        publicKey: keyPair.publicKey,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
      );

      if (await GchKeyVault.saveUserKeys(userKeys)) {
        return userKeys;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 获取用户密钥
  static Future<GchUserKeys?> getUserKeys(String userId) async {
    try {
      final keys = await GchKeyVault.getUserKeys(userId);
      if (keys != null && keys.isValid) {
        return keys;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 密钥交换 - 客户端接收服务端公钥，计算共享密钥
  static Future<GchUserKeys?> performKeyExchange(
    String userId,
    Uint8List serverPublicKey
  ) async {
    try {
      // 获取用户密钥
      var userKeys = await getUserKeys(userId);
      if (userKeys == null) {
        // 如果没有密钥，先生成
        userKeys = await generateUserKeys(userId);
        if (userKeys == null) return null;
      } else if (userKeys.serverPublicKey != null &&
                 _areKeysEqual(userKeys.serverPublicKey!, serverPublicKey)) {
        // 服务器公钥没有变化，直接返回缓存
        return userKeys;
      }

      // 计算共享密钥
      final sharedSecret = await _computeSecret(userKeys.privateKey, serverPublicKey);
      if (sharedSecret == null) return null;

      // 派生最终密钥
      final derivedKey = await _deriveKey(sharedSecret, userId);

      // 更新用户密钥
      final updatedKeys = userKeys.withServerKeyAndSharedKey(serverPublicKey, derivedKey);

      if (await GchKeyVault.saveUserKeys(updatedKeys)) {
        return updatedKeys;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 获取用户的共享密钥
  static Future<Uint8List?> getSharedKey(String userId) async {
    try {
      final keys = await getUserKeys(userId);
      return keys?.sharedKey;
    } catch (e) {
      return null;
    }
  }

  /// AES-GCM加密
  static Future<Uint8List?> encrypt(Uint8List key, Uint8List data) async {
    try {
      // 生成随机nonce
      final nonce = _generateSeed().sublist(0, 12);

      // 初始化AES-GCM
      final params = AEADParameters(
        KeyParameter(key),
        128, // 128位MAC
        nonce,
        Uint8List(0), // 无附加数据
      );

      _aesGcm.init(true, params);

      final output = Uint8List(data.length + _aesGcm.macSize);
      final len = _aesGcm.processBytes(data, 0, data.length, output, 0);
      _aesGcm.doFinal(output, len);

      // 格式: nonce + ciphertext（与后端Go标准GCM格式一致）
      final result = Uint8List(nonce.length + output.length);
      result.setRange(0, nonce.length, nonce);
      result.setRange(nonce.length, result.length, output);

      return result;
    } catch (e) {
      return null;
    }
  }

  /// AES-GCM解密
  static Future<Uint8List?> decrypt(Uint8List key, Uint8List data) async {
    try {
      if (data.length < 12 + 16) return null; // nonce + mac minimum

      // 分离组件
      final nonce = data.sublist(0, 12);
      final ciphertext = data.sublist(12);

      // 初始化AES-GCM
      final params = AEADParameters(
        KeyParameter(key),
        128, // 128位MAC
        nonce,
        Uint8List(0), // 无附加数据
      );

      _aesGcm.init(false, params);

      final output = Uint8List(ciphertext.length - _aesGcm.macSize);
      final len = _aesGcm.processBytes(ciphertext, 0, ciphertext.length, output, 0);
      _aesGcm.doFinal(output, len);

      return output;
    } catch (e) {
      return null;
    }
  }

  /// 使用用户共享密钥加密
  static Future<Uint8List?> encryptForUser(String userId, Uint8List plaintext) async {
    final sharedKey = await getSharedKey(userId);
    if (sharedKey == null) return null;
    return await encrypt(sharedKey, plaintext);
  }

  /// 使用用户共享密钥解密
  static Future<Uint8List?> decryptForUser(String userId, Uint8List ciphertext) async {
    final sharedKey = await getSharedKey(userId);
    if (sharedKey == null) return null;
    return await decrypt(sharedKey, ciphertext);
  }

  /// 从服务端公钥获取密钥并加密 - 匹配服务端KeyExchange流程
  static Future<String?> encryptWithServerKey(String userId, String plaintext, Uint8List serverPublicKey) async {
    try {
      // 执行密钥交换
      final userKeys = await performKeyExchange(userId, serverPublicKey);
      if (userKeys?.sharedKey == null) return null;
      // Debug: 打印sharedKey的hex表示
      print('SharedKey (hex): ${userKeys!.sharedKey!.map((e) => e.toRadixString(16).padLeft(2, '0')).join()}');

      // 使用派生密钥加密
      final encrypted = await encrypt(userKeys.sharedKey!, utf8.encode(plaintext));
      return encrypted != null ? base64.encode(encrypted) : null;
    } catch (e) {
      return null;
    }
  }

  /// 使用现有密钥解密 - 匹配服务端Decrypt流程
  static Future<String?> decryptWithUserKey(String userId, String ciphertextBase64) async {
    try {
      final ciphertext = base64.decode(ciphertextBase64);
      final decrypted = await decryptForUser(userId, ciphertext);
      return decrypted != null ? utf8.decode(decrypted) : null;
    } catch (e) {
      return null;
    }
  }

  /// 文本加密（Base64输出）
  static Future<String?> encryptText(String userId, String plaintext) async {
    final data = Uint8List.fromList(utf8.encode(plaintext));
    final encrypted = await encryptForUser(userId, data);
    return encrypted != null ? base64.encode(encrypted) : null;
  }

  /// 文本解密
  static Future<String?> decryptText(String userId, String ciphertext) async {
    try {
      final data = base64.decode(ciphertext);
      final decrypted = await decryptForUser(userId, data);
      return decrypted != null ? utf8.decode(decrypted) : null;
    } catch (e) {
      return null;
    }
  }

  /// 生成安全的随机盐值
  static Future<Uint8List> generateSalt({int length = 32}) async {
    return _generateSeed().sublist(0, length);
  }

  /// 验证公钥格式
  static bool isValidPublicKey(Uint8List publicKeyBytes) {
    // P-256公钥标准长度：65字节(未压缩)
    return publicKeyBytes.length == 65 && publicKeyBytes[0] == 0x04;
  }

  /// 清理过期密钥
  static Future<int> cleanExpiredKeys() async {
    return await GchKeyVault.cleanExpiredKeys();
  }

  /// 删除用户密钥
  static Future<bool> removeUserKeys(String userId) async {
    return await GchKeyVault.removeUserKeys(userId);
  }

  /// 比较两个密钥是否相同
  static bool _areKeysEqual(Uint8List key1, Uint8List key2) {
    if (key1.length != key2.length) return false;
    for (int i = 0; i < key1.length; i++) {
      if (key1[i] != key2[i]) return false;
    }
    return true;
  }

  /// 获取密钥信息（调试用）
  static Future<Map<String, dynamic>?> getKeyInfo(String userId) async {
    final keys = await getUserKeys(userId);
    if (keys == null) return null;

    return {
      'userId': keys.userId,
      'publicKeyLength': keys.publicKey.length,
      'hasSharedKey': keys.sharedKey != null,
      'sharedKeyLength': keys.sharedKey?.length,
      'createdAt': keys.createdAt.toIso8601String(),
      'expiresAt': keys.expiresAt?.toIso8601String(),
      'isValid': keys.isValid,
    };
  }

  /// 密钥轮换 - 为用户生成新的密钥对
  static Future<GchUserKeys?> rotateUserKeys(String userId, {Duration? ttl}) async {
    try {
      // 删除旧密钥
      await removeUserKeys(userId);

      // 生成新密钥
      return await generateUserKeys(userId, ttl: ttl);
    } catch (e) {
      return null;
    }
  }

  /// 批量清理用户密钥
  static Future<int> bulkCleanUserKeys(List<String> userIds) async {
    int cleanedCount = 0;
    for (final userId in userIds) {
      if (await removeUserKeys(userId)) {
        cleanedCount++;
      }
    }
    return cleanedCount;
  }
}

/// 密钥对数据类
class GchKeyPair {
  final Uint8List privateKey;
  final Uint8List publicKey;

  const GchKeyPair({
    required this.privateKey,
    required this.publicKey,
  });

  /// 验证密钥对有效性
  bool get isValid {
    return privateKey.isNotEmpty &&
           publicKey.isNotEmpty &&
           GchKeySwapSvc.isValidPublicKey(publicKey);
  }

  @override
  String toString() {
    return 'GchKeyPair(privateKeyLength: ${privateKey.length}, publicKeyLength: ${publicKey.length})';
  }
}
