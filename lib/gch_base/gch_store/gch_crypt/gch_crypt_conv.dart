import 'dart:convert';
import 'dart:math' ;
import 'package:drift/drift.dart';
import 'package:hive_flutter/hive_flutter.dart';
// 字段加密工具类
class FieldEncryptor {
  static String? _key;
  static const String _boxName = 'crypto_keys';
  static const String _keyName = 'crypto_key';

  // 初始化加密密钥 - 增强容错性和重试机制
  static Future<void> setup() async {
    if (_key != null) {
      print('[FieldEncryptor] 已经初始化，跳过');
      return;
    }

    // 确保 Hive 已初始化（防止 preferences 降级到内存存储时 Hive 未被初始化）
    await Hive.initFlutter('guichao_h');

    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        print('[FieldEncryptor] 正在初始化... (尝试 ${attempt + 1}/3)');
        final box = await Hive.openBox(_boxName);
        _key = box.get(_keyName) as String?;

        if (_key == null) {
          print('[FieldEncryptor] 生成新的加密密钥');
          final random = Random.secure();
          final bytes = List<int>.generate(32, (i) => random.nextInt(256));
          _key = base64Encode(bytes);
          await box.put(_keyName, _key);
        }

        await box.close();
        print('[FieldEncryptor] ✅ 初始化成功');
        return;
      } catch (e, stackTrace) {
        print('[FieldEncryptor] ❌ 初始化失败，尝试 ${attempt + 1}/3: $e');

        if (attempt == 2) {
          print('[FieldEncryptor] 所有重试都失败，抛出异常');
          print('StackTrace: $stackTrace');
          rethrow;
        }

        // 渐进式延迟重试
        final delayMs = 500 * (attempt + 1);
        print('[FieldEncryptor] 等待 ${delayMs}ms 后重试...');
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  // 检查是否已初始化
  static bool get isReady => _key != null;

  // 简单XOR加密
  static String encryptValue(String text) {
    if (_key == null) throw Exception('FieldEncryptor not initialized');

    final keyBytes = base64Decode(_key!);
    final textBytes = utf8.encode(text);
    final encryptedBytes = <int>[];

    for (int i = 0; i < textBytes.length; i++) {
      encryptedBytes.add(textBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return base64Encode(encryptedBytes);
  }

  // 解密
  static String decryptValue(String encrypted) {
    if (_key == null) {
      print('[FieldEncryptor] 警告: FieldEncryptor未初始化，返回原始数据');
      return encrypted; // 兼容处理，避免抛出异常
    }

    try {
      final keyBytes = base64Decode(_key!);
      final encryptedBytes = base64Decode(encrypted);
      final decryptedBytes = <int>[];

      for (int i = 0; i < encryptedBytes.length; i++) {
        decryptedBytes.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return utf8.decode(decryptedBytes);
    } catch (e) {
      print('[FieldEncryptor] 解密失败: $e，返回原始数据');
      // 兼容未加密数据
      return encrypted;
    }
  }
}

// 通用加密文本转换器
abstract class CryptoText {
  // 用于非空字段
  static const TypeConverter<String, String> nonNull = _CryptoTextNonNull();

  // 用于可空字段
  static const TypeConverter<String?, String?> nullable = _CryptoTextNullable();

  // 默认构造函数返回非空版本
  factory CryptoText() => const _CryptoTextNonNull();
}

// 内部实现 - 非空版本
class _CryptoTextNonNull extends TypeConverter<String, String> implements CryptoText {
  const _CryptoTextNonNull();

  @override
  String fromSql(String fromDb) => FieldEncryptor.decryptValue(fromDb);

  @override
  String toSql(String value) => FieldEncryptor.encryptValue(value);
}

// 内部实现 - 可空版本
class _CryptoTextNullable extends TypeConverter<String?, String?> {
  const _CryptoTextNullable();

  @override
  String? fromSql(String? fromDb) {
    if (fromDb == null) return null;
    final decrypted = FieldEncryptor.decryptValue(fromDb);

    return decrypted;
  }

  @override
  String? toSql(String? value) {
    if (value == null) return null;
    return FieldEncryptor.encryptValue(value);
  }
}
