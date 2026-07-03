import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceUtils {
  static const String _storageKey = 'persistent_device_unique_id';
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// 获取持久唯一设备ID（仅用secure storage，不再用本地缓存）
  static Future<String> deviceId() async {
    // 1. 优先从flutter_secure_storage获取
    final secureId = await _getSecureId();
    if (secureId != null && secureId.isNotEmpty) {
      return secureId;
    }
    // 2. 获取系统原生唯一ID
    final sysId = await _getSystemUniqueId();
    if (sysId != null && sysId.isNotEmpty) {
      await _setSecureId(sysId);
      return sysId;
    }
    // 3. 生成软唯一ID
    final generatedId = await _generateSoftUniqueId();
    await _setSecureId(generatedId);
    return generatedId;
  }

  static Future<String?> _getSecureId() async {
    try {
      return await _secureStorage.read(key: _storageKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _setSecureId(String id) async {
    try {
      await _secureStorage.write(key: _storageKey, value: id);
    } catch (_) {}
  }

  static Future<String?> _getSystemUniqueId() async {
    try {
      final info = await _deviceInfoPlugin.iosInfo;
      return info.identifierForVendor;
    } catch (_) {}
    return null;
  }

  static Future<String> _generateSoftUniqueId() async {
    List<String> identifiers = [];
    try {
      final info = await _deviceInfoPlugin.iosInfo;
      identifiers = [
        info.name,
        info.systemName,
        info.systemVersion,
        info.model,
        info.localizedModel,
        info.isPhysicalDevice.toString(),
        info.utsname.sysname,
        info.utsname.nodename,
        info.utsname.release,
        info.utsname.version,
        info.utsname.machine,
      ];
    } catch (_) {}
    if (identifiers.isEmpty) {
      return _generateRandomId();
    }
    final combined = identifiers.where((e) => e.isNotEmpty).join('|');
    final digest = sha256.convert(utf8.encode(combined));
    return _formatAsUuid(digest.toString());
  }

  static String _generateRandomId() {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomBytes = List<int>.generate(12, (_) => random.nextInt(256));
    final combined = '$timestamp${randomBytes.join('')}';
    final digest = sha256.convert(utf8.encode(combined));
    return _formatAsUuid(digest.toString());
  }

  static String _formatAsUuid(String hex) {
    final h = hex.length < 32 ? hex.padRight(32, '0').substring(0, 32) : hex.substring(0, 32);
    return '${h.substring(0, 8)}-'
        '${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-'
        '${h.substring(20, 32)}';
  }
}

Future<void> writeFile(String path, dynamic content) async {
  final file = File(path);
  if (content is List<int>) {
    await file.writeAsBytes(content);
  } else if (content != null) {
    await file.writeAsString(content.toString());
  }
}
