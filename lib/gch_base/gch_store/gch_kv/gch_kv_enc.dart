
import 'dart:typed_data';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'gch_kv_ex.dart';

/// 安全的加密密钥管理器
class GchKvEncryption {
  static const String _keyPrefix = 'hive_enc_';
  static const int _keyLength = 32; // AES-256
  static const int _maxRetries = 3;

  final FlutterSecureStorage _storage;
  final Map<String, List<int>> _keyCache = {};
  final _random = Random.secure();

  GchKvEncryption(this._storage);

  /// 获取或创建加密密钥
  Future<List<int>> getOrCreateKey(String boxName) async {
    if (boxName.isEmpty) {
      throw GchKvEncEx('Box name cannot be empty');
    }

    // 检查缓存
    if (_keyCache.containsKey(boxName)) {
      return _keyCache[boxName]!;
    }

    final keyName = '$_keyPrefix$boxName';

    try {
      // 尝试读取现有密钥
      final storedKey = await _readKeyWithRetry(keyName);
      if (storedKey != null) {
        _keyCache[boxName] = storedKey;
        return storedKey;
      }

      // 生成新密钥
      final newKey = _generateSecureKey();
      await _storeKeyWithRetry(keyName, newKey);

      _keyCache[boxName] = newKey;
      return newKey;

    } catch (e, stack) {
      throw GchKvEncEx(
        'Failed to get/create encryption key for box: $boxName',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// 删除加密密钥
  Future<void> deleteKey(String boxName) async {
    if (boxName.isEmpty) return;

    final keyName = '$_keyPrefix$boxName';

    try {
      await _storage.delete(key: keyName);
      _keyCache.remove(boxName);
    } catch (e) {
      // 删除失败不抛异常，只记录
      // Logger 在实际使用时添加
    }
  }

  /// 验证密钥有效性
  Future<bool> validateKey(String boxName) async {
    try {
      final key = await getOrCreateKey(boxName);
      return key.length == _keyLength && key.every((b) => b >= 0 && b <= 255);
    } catch (e) {
      return false;
    }
  }

  /// 重新生成密钥（危险操作，会导致现有数据无法解密）
  Future<List<int>> regenerateKey(String boxName) async {
    if (boxName.isEmpty) {
      throw GchKvEncEx('Box name cannot be empty');
    }

    final newKey = _generateSecureKey();
    final keyName = '$_keyPrefix$boxName';

    try {
      await _storeKeyWithRetry(keyName, newKey);
      _keyCache[boxName] = newKey;
      return newKey;
    } catch (e, stack) {
      throw GchKvEncEx(
        'Failed to regenerate encryption key for box: $boxName',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// 清理所有缓存的密钥
  void clearCache() {
    _keyCache.clear();
  }

  /// 生成安全的随机密钥
  List<int> _generateSecureKey() {
    try {
      // 使用 Hive 提供的安全密钥生成
      final hiveKey = Hive.generateSecureKey();
      if (hiveKey.length == _keyLength) {
        return hiveKey;
      }

      // 备用方案：手动生成
      final bytes = Uint8List(_keyLength);
      for (int i = 0; i < _keyLength; i++) {
        bytes[i] = _random.nextInt(256);
      }

      return bytes.toList();
    } catch (e) {
      throw GchKvEncEx('Failed to generate secure key', cause: e);
    }
  }

  /// 带重试的密钥读取
  Future<List<int>?> _readKeyWithRetry(String keyName) async {
    for (int i = 0; i < _maxRetries; i++) {
      try {
        final keyStr = await _storage.read(key: keyName);
        if (keyStr == null) return null;

        return _parseKeyString(keyStr);
      } catch (e) {
        if (i == _maxRetries - 1) rethrow;
        await Future.delayed(Duration(milliseconds: 100 * (i + 1)));
      }
    }
    return null;
  }

  /// 带重试的密钥存储
  Future<void> _storeKeyWithRetry(String keyName, List<int> key) async {
    final keyStr = key.join(',');
    final checksum = _calculateChecksum(key);
    final data = '$keyStr:$checksum';

    for (int i = 0; i < _maxRetries; i++) {
      try {
        await _storage.write(key: keyName, value: data);

        // 验证写入
        final verification = await _storage.read(key: keyName);
        if (verification == data) return;

        throw GchKvStorageEx('Key verification failed');
      } catch (e) {
        if (i == _maxRetries - 1) rethrow;
        await Future.delayed(Duration(milliseconds: 100 * (i + 1)));
      }
    }
  }

  /// 解析密钥字符串
  List<int> _parseKeyString(String keyStr) {
    try {
      final parts = keyStr.split(':');
      if (parts.length != 2) {
        throw GchKvCorruptEx('Invalid key format');
      }

      final keyBytes = parts[0].split(',').map(int.parse).toList();
      final storedChecksum = parts[1];
      final calculatedChecksum = _calculateChecksum(keyBytes);

      if (storedChecksum != calculatedChecksum) {
        throw GchKvCorruptEx('Key checksum mismatch');
      }

      if (keyBytes.length != _keyLength) {
        throw GchKvCorruptEx('Invalid key length: ${keyBytes.length}');
      }

      return keyBytes;
    } catch (e) {
      if (e is GchKvEx) rethrow;
      throw GchKvCorruptEx('Failed to parse key string', cause: e);
    }
  }

  /// 计算密钥校验和
  String _calculateChecksum(List<int> key) {
    final bytes = Uint8List.fromList(key);
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 8); // 取前8位
  }
}
