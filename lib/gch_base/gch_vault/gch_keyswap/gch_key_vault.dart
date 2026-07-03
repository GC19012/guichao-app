// gch_key_vault.dart
// 密钥存储 - 精简版，手机优化

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:guichao/gch_base/gch_vault/gch_keyswap/gch_keyswap_model.dart';

/// 密钥存储服务
class GchKeyVault {
  static const String _keyPrefix = 'ecdh_';
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// 保存用户密钥
  static Future<bool> saveUserKeys(GchUserKeys keys) async {
    try {
      final jsonData = jsonEncode(keys.toJson());
      await _storage.write(key: '$_keyPrefix${keys.userId}', value: jsonData);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取用户密钥
  static Future<GchUserKeys?> getUserKeys(String userId) async {
    try {
      final jsonData = await _storage.read(key: '$_keyPrefix$userId');
      if (jsonData == null) return null;

      final jsonMap = jsonDecode(jsonData) as Map<String, dynamic>;
      return GchUserKeys.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  /// 检查用户是否有密钥
  static Future<bool> hasUserKeys(String userId) async {
    try {
      final data = await _storage.read(key: '$_keyPrefix$userId');
      return data != null;
    } catch (e) {
      return false;
    }
  }

  /// 删除用户密钥
  static Future<bool> removeUserKeys(String userId) async {
    try {
      await _storage.delete(key: '$_keyPrefix$userId');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 清除所有密钥
  static Future<bool> clearAllKeys() async {
    try {
      final allKeys = await _storage.readAll();
      for (final key in allKeys.keys) {
        if (key.startsWith(_keyPrefix)) {
          await _storage.delete(key: key);
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取所有用户ID
  static Future<List<String>> getAllUserIds() async {
    try {
      final allKeys = await _storage.readAll();
      return allKeys.keys
          .where((key) => key.startsWith(_keyPrefix))
          .map((key) => key.substring(_keyPrefix.length))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 清理过期密钥
  static Future<int> cleanExpiredKeys() async {
    int cleaned = 0;
    try {
      final userIds = await getAllUserIds();
      for (final userId in userIds) {
        final keys = await getUserKeys(userId);
        if (keys != null && !keys.isValid) {
          if (await removeUserKeys(userId)) {
            cleaned++;
          }
        }
      }
    } catch (e) {
      // 静默处理错误
    }
    return cleaned;
  }
}
