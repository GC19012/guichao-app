// lib/gch_base/gch_core/gch_nucleus.dart
//
// 全局应用管理器 - 包含静态配置、变量和方法

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:guichao/gch_base/gch_prefs/gch_store.dart';
import 'package:guichao/gch_base/gch_kit/gch_loggers.dart';
import 'package:uuid/uuid.dart';

/// 全局应用管理器
class GchNucleus with GchInfraLogger {
  GchNucleus._();

  static GchNucleus? _instance;
  static GchNucleus get instance => _instance ??= GchNucleus._();

  // ========== 静态常量配置 ==========

  /// 应用版本
  static const String version = '1.0.0';

  /// 【全局配置】应用启动时使用的默认数据库存储类型
  static const StorageType defaultStorageType = StorageType.sqlite;

  /// 【全局配置】Preferences 存储类型
  static const GchStoreType defaultPreferencesStorageType = GchStoreType.hive;

  static const String defaultInitDataUrl =
      'https://api.example.com/api/v1/users/getuserconfig';
  static const String defaultInitName = 'GUICHAO';
  static const String defaultkeyExchangeUrl =
      'https://api.example.com/api/v1/ecdh/key-exchange';
  static const String defaultApiBaseUrl = 'https://api.example.com';

  /// 加密模式选择：'ecdh'=动态密钥，'fixed'=固定密钥
  static const String encryptMode = 'fixed';

  // ========== 验证码配置 ==========

  /// 验证码配置
  static const GchCaptchaConfig captcha = GchCaptchaConfig();

  /// 强制开启 console 日志输出（即使在 release 模式下）
  static bool forceConsoleLog = false;

  /// 日志滚动触发大小（字节）- 2MB
  static const int logUploadSize = 2 * 1024 * 1024;

  // ========== Supabase / Auth 配置 ==========

  static String get authEndpoint => 'https://auth.example.com';

  static bool get isDevMode => kDebugMode;

  /// API 密钥
  static String get authApiKey {
    try {
      return const String.fromEnvironment('API_KEY', defaultValue: 'default_api_key');
    } catch (e) {
      instance.loggy.warning('获取 authApiKey 失败: $e');
      return 'default_api_key';
    }
  }

  // ========== 静态变量 ==========

  static bool isBootstrapped = false;

  /// 设备ID
  static String? machineId;

  /// GUICHAO号
  static String? gcSerial;

  /// 计数器
  static final Map<String, int> _counters = {};

  // ========== 静态方法 ==========

  static Future<String> buildGcSeq() async {
    String currentDeviceId = machineId ?? await fetchDeviceFingerprint();
    var bytes = utf8.encode(currentDeviceId);
    var hash = md5.convert(bytes);
    var hashStr = hash.toString();
    var number = int.parse(hashStr.substring(0, 8), radix: 16) % 100000000;
    return 'GC${number.toString().padLeft(8, '0')}';
  }

  /// 初始化全局管理器
  static Future<void> bootstrap({bool debugMode = false}) async {
    if (isBootstrapped) return;

    try {
      machineId = await fetchDeviceFingerprint();
      gcSerial = await buildGcSeq();
      isBootstrapped = true;
      instance.loggy.info('GchNucleus 初始化成功 - DeviceID: $machineId');
    } catch (e, stack) {
      instance.loggy.error('GchNucleus 初始化失败', e, stack);
      rethrow;
    }
  }

  // ========== 计数器管理 ==========

  static int readCounter(String key) => _counters[key] ?? 0;

  static int bumpCounter(String key, [int increment = 1]) {
    _counters[key] = (_counters[key] ?? 0) + increment;
    return _counters[key]!;
  }

  static void wipeCounter(String key) {
    _counters[key] = 0;
  }

  static void wipeAllCounters() {
    _counters.clear();
  }

  // ========== 工具方法 ==========

  /// 获取设备唯一ID
  static Future<String> fetchDeviceFingerprint() async {
    const platformChannelTimeout = Duration(seconds: 2);

    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = '';

      try {
        final iosInfo = await deviceInfo.iosInfo.timeout(platformChannelTimeout);
        deviceId =
            'ios_${iosInfo.name}_${iosInfo.model}_${iosInfo.identifierForVendor}';
      } catch (e) {
        instance.loggy.warning('iOS 设备信息获取失败: $e');
        deviceId =
            'ios_${Platform.operatingSystemVersion}_${Platform.numberOfProcessors}';
      }

      const uuid = Uuid();
      final uniqueId = uuid.v5(Namespace.url.value, deviceId);
      instance.loggy.info('设备唯一ID生成成功: $uniqueId (基于: $deviceId)');
      return uniqueId;
    } catch (e, stack) {
      instance.loggy.error('获取设备唯一ID失败', e, stack);
      final fallbackId =
          'fallback_${Platform.operatingSystem}_${Platform.operatingSystemVersion}_${Platform.numberOfProcessors}';
      const uuid = Uuid();
      final uniqueId = uuid.v5(Namespace.url.value, fallbackId);
      instance.loggy.info('备选设备唯一ID生成成功: $uniqueId');
      return uniqueId;
    }
  }
}

// ========== 数据库存储类型 ==========

enum StorageType {
  sqlite('SQLite');

  const StorageType(this.displayName);

  final String displayName;

  static StorageType fromString(String value) {
    return StorageType.values.firstWhere(
      (type) => type.name.toLowerCase() == value.toLowerCase(),
      orElse: () => StorageType.sqlite,
    );
  }
}

// ========== 验证码配置 ==========

enum GchCaptchaType {
  turnstile,
  aliyun,
}

class GchCaptchaConfig {
  final GchCaptchaType type;
  final bool isEnabled;
  final String turnstileSiteKey;
  final String turnstileBaseUrl;
  final String aliyunSceneId;
  final String aliyunPrefix;
  final String aliyunLang;

  const GchCaptchaConfig({
    this.type = GchCaptchaType.aliyun,
    this.isEnabled = true,
    this.turnstileSiteKey = 'YOUR_TURNSTILE_SITE_KEY',
    this.turnstileBaseUrl = 'https://auth.example.com',
    this.aliyunSceneId = 'YOUR_ALIYUN_SCENE_ID',
    this.aliyunPrefix = 'YOUR_ALIYUN_PREFIX',
    this.aliyunLang = 'cn',
  });
}
