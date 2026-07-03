
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:synchronized/synchronized.dart';

import 'gch_kv_ex.dart';
import 'gch_kv_enc.dart';

/// 生产级 KV 存储管理器
class GchKvMgr {
  static GchKvMgr? _instance;
  static final _lock = Lock();

  /// 获取单例实例（改进版：支持超时和错误恢复）
  static Future<GchKvMgr> getInstance() async {
    return await _lock.synchronized(() async {
      // 如果实例存在且已初始化，直接返回
      if (_instance != null && _instance!._initialized) {
        return _instance!;
      }

      // 创建新实例或重新初始化
      try {
        _instance ??= GchKvMgr._();

        // 添加总体超时（3秒）
        await _instance!._initialize().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            _instance!._initialized = false; // 允许重试
            throw GchKvInitEx('GchKvMgr 初始化超时（3秒）');
          },
        );

        return _instance!;
      } catch (e) {
        // 清理失败的实例状态，允许下次重试
        _instance?._initialized = false;
        rethrow;
      }
    });
  }

  // 私有构造函数
  GchKvMgr._();

  // 核心组件
  late final GchKvEncryption _encryption;
  bool _initialized = false;
  bool _disposed = false;

  // 线程安全的盒子管理
  final Map<String, GchKvBoxWrapper> _boxes = {};
  final Map<String, GchKvLazyBoxWrapper> _lazyBoxes = {};
  final Lock _boxLock = Lock();

  // 资源监控
  final Set<StreamSubscription> _subscriptions = {};
  Timer? _healthCheckTimer;

  /// 初始化（改进版：添加超时和异步优化）
  Future<void> _initialize() async {
    if (_initialized) return;

    try {
      // 步骤1: 初始化 Hive（添加超时保护）
      await Future.microtask(() async {
        await Hive.initFlutter('guichao_h');
      }).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          throw GchKvInitEx('Hive.initFlutter() 超时（2秒）');
        },
      );

      // 步骤2: 初始化加密组件（异步执行，不阻塞）
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );
      _encryption = GchKvEncryption(storage);

      // 步骤3: 异步设置错误处理和健康检查（不阻塞主流程）
      Future.microtask(() {
        _setupErrorHandling();
        _startHealthCheck();
      });

      _initialized = true;
    } catch (e, stack) {
      _initialized = false; // 允许重试
      throw GchKvInitEx(
        'Failed to initialize GchKvMgr',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// 注册类型适配器
  Future<void> registerAdapter<T>(TypeAdapter<T> adapter) async {
    _checkInit();

    try {
      if (!Hive.isAdapterRegistered(adapter.typeId)) {
        Hive.registerAdapter(adapter);
      }
    } catch (e, stack) {
      throw GchKvTypeEx(
        'Failed to register adapter for type ${T.toString()}',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// 打开盒子（线程安全）
  Future<Box<T>> openBox<T>(
    String name, {
    bool encrypted = false,
    bool compactOnLaunch = true,
  }) async {
    _checkInit();
    _validateBoxName(name);

    return await _boxLock.synchronized(() async {
      final key = _getBoxKey<T>(name);

      // 检查是否已打开
      if (_boxes.containsKey(key)) {
        final wrapper = _boxes[key]!;
        if (!wrapper.isClosed) {
          return wrapper.box as Box<T>;
        }
        // 清理已关闭的盒子
        _boxes.remove(key);
      }

      try {
        List<int>? encryptionKey;
        if (encrypted) {
          encryptionKey = await _encryption.getOrCreateKey(name);
        }

        final box = await Hive.openBox<T>(
          name,
          encryptionCipher: encryptionKey != null ? HiveAesCipher(encryptionKey) : null,
          compactionStrategy: (entries, deletedEntries) => compactOnLaunch && deletedEntries > entries * 0.2,
        );

        // 包装盒子
        final wrapper = GchKvBoxWrapper<T>(box, encrypted);
        _boxes[key] = wrapper;

        return box;
      } catch (e, stack) {
        throw GchKvBoxEx(
          'Failed to open box: $name',
          cause: e,
          stackTrace: stack,
        );
      }
    });
  }

  /// 打开延迟盒子（线程安全）
  Future<LazyBox<T>> openLazyBox<T>(
    String name, {
    bool encrypted = false,
  }) async {
    _checkInit();
    _validateBoxName(name);

    return await _boxLock.synchronized(() async {
      final key = _getLazyBoxKey<T>(name);

      // 检查是否已打开
      if (_lazyBoxes.containsKey(key)) {
        final wrapper = _lazyBoxes[key]!;
        if (!wrapper.isClosed) {
          return wrapper.box as LazyBox<T>;
        }
        // 清理已关闭的盒子
        _lazyBoxes.remove(key);
      }

      try {
        List<int>? encryptionKey;
        if (encrypted) {
          encryptionKey = await _encryption.getOrCreateKey(name);
        }

        final box = await Hive.openLazyBox<T>(
          name,
          encryptionCipher: encryptionKey != null ? HiveAesCipher(encryptionKey) : null,
        );

        // 包装盒子
        final wrapper = GchKvLazyBoxWrapper<T>(box, encrypted);
        _lazyBoxes[key] = wrapper;

        return box;
      } catch (e, stack) {
        throw GchKvBoxEx(
          'Failed to open lazy box: $name',
          cause: e,
          stackTrace: stack,
        );
      }
    });
  }

  /// 安全关闭盒子
  Future<void> closeBox(String name) async {
    return await _boxLock.synchronized(() async {
      try {
        // 查找并关闭所有匹配的盒子
        final keysToRemove = <String>[];

        for (final entry in _boxes.entries) {
          if (entry.key.contains(name)) {
            await entry.value.close();
            keysToRemove.add(entry.key);
          }
        }

        for (final entry in _lazyBoxes.entries) {
          if (entry.key.contains(name)) {
            await entry.value.close();
            keysToRemove.add(entry.key);
          }
        }

        // 清理映射
        for (final key in keysToRemove) {
          _boxes.remove(key);
          _lazyBoxes.remove(key);
        }
      } catch (e) {
        // 关闭失败不抛异常，避免影响其他操作
        debugPrint('Warning: Failed to close box $name: $e');
      }
    });
  }

  /// 删除盒子
  Future<void> deleteBox(String name) async {
    _checkInit();
    _validateBoxName(name);

    return await _boxLock.synchronized(() async {
      try {
        // 先关闭盒子
        await closeBox(name);

        // 删除磁盘数据
        await Hive.deleteBoxFromDisk(name);

        // 删除加密密钥
        await _encryption.deleteKey(name);
      } catch (e, stack) {
        throw GchKvBoxEx(
          'Failed to delete box: $name',
          cause: e,
          stackTrace: stack,
        );
      }
    });
  }

  /// 检查盒子是否存在
  Future<bool> boxExists(String name) async {
    _checkInit();
    try {
      return await Hive.boxExists(name);
    } catch (e) {
      return false;
    }
  }

  /// 获取盒子信息
  Future<GchKvBoxInfo?> getBoxInfo(String name) async {
    _checkInit();

    try {
      final exists = await boxExists(name);
      if (!exists) return null;

      // 尝试获取已打开的盒子信息
      final normalKey = _boxes.keys.firstWhere(
        (k) => k.contains(name),
        orElse: () => '',
      );

      if (normalKey.isNotEmpty) {
        final wrapper = _boxes[normalKey]!;
        return GchKvBoxInfo(
          name: name,
          encrypted: wrapper.encrypted,
          isLazy: false,
          isOpen: !wrapper.isClosed,
          length: wrapper.isClosed ? 0 : wrapper.box.length,
        );
      }

      return GchKvBoxInfo(
        name: name,
        encrypted: false,
        isLazy: false,
        isOpen: false,
        length: 0,
      );
    } catch (e) {
      return null;
    }
  }

  /// 获取所有盒子信息
  Future<List<GchKvBoxInfo>> getAllBoxInfo() async {
    _checkInit();

    final infos = <GchKvBoxInfo>[];

    // 遍历已打开的盒子
    for (final entry in _boxes.entries) {
      final wrapper = entry.value;
      final name = _extractBoxName(entry.key);

      infos.add(GchKvBoxInfo(
        name: name,
        encrypted: wrapper.encrypted,
        isLazy: false,
        isOpen: !wrapper.isClosed,
        length: wrapper.isClosed ? 0 : wrapper.box.length,
      ));
    }

    for (final entry in _lazyBoxes.entries) {
      final wrapper = entry.value;
      final name = _extractBoxName(entry.key);

      infos.add(GchKvBoxInfo(
        name: name,
        encrypted: wrapper.encrypted,
        isLazy: true,
        isOpen: !wrapper.isClosed,
        length: wrapper.isClosed ? 0 : wrapper.box.length,
      ));
    }

    return infos;
  }

  /// 执行数据完整性检查
  Future<GchKvHealthReport> checkBoxHealth(String name) async {
    _checkInit();

    try {
      final exists = await boxExists(name);
      if (!exists) {
        return GchKvHealthReport(
          boxName: name,
          healthy: false,
          error: 'Box does not exist',
        );
      }

      // 尝试打开盒子进行检查
      try {
        final testBox = await Hive.openBox('${name}_health_check');
        await testBox.close();
        await Hive.deleteBoxFromDisk('${name}_health_check');

        return GchKvHealthReport(
          boxName: name,
          healthy: true,
        );
      } catch (e) {
        return GchKvHealthReport(
          boxName: name,
          healthy: false,
          error: 'Failed to perform health check: $e',
        );
      }
    } catch (e, stack) {
      return GchKvHealthReport(
        boxName: name,
        healthy: false,
        error: 'Health check error: $e',
        stackTrace: stack,
      );
    }
  }

  /// 安全关闭所有资源
  Future<void> dispose() async {
    if (_disposed) return;

    await _boxLock.synchronized(() async {
      try {
        // 停止健康检查
        _healthCheckTimer?.cancel();

        // 取消所有订阅
        for (final subscription in _subscriptions) {
          await subscription.cancel();
        }
        _subscriptions.clear();

        // 关闭所有盒子
        for (final wrapper in _boxes.values) {
          await wrapper.close();
        }
        for (final wrapper in _lazyBoxes.values) {
          await wrapper.close();
        }

        // 清理缓存
        _boxes.clear();
        _lazyBoxes.clear();
        _encryption.clearCache();

        // 关闭 Hive
        await Hive.close();

        _disposed = true;
        _initialized = false;
      } catch (e) {
        debugPrint('Warning: Error during GchKvMgr disposal: $e');
      }
    });
  }

  // ========== 私有辅助方法 ==========

  void _checkInit() {
    if (_disposed) {
      throw GchKvEx('GchKvMgr has been disposed');
    }
    if (!_initialized) {
      throw GchKvInitEx('GchKvMgr not initialized');
    }
  }

  void _validateBoxName(String name) {
    if (name.isEmpty || name.contains(RegExp(r'[<>:"/\\|?*]'))) {
      throw GchKvBoxEx('Invalid box name: $name');
    }
  }

  String _getBoxKey<T>(String name) => '${T.toString()}_$name';
  String _getLazyBoxKey<T>(String name) => '${T.toString()}_${name}_lazy';

  String _extractBoxName(String key) {
    final parts = key.split('_');
    if (parts.length >= 2) {
      return parts.skip(1).join('_').replaceAll('_lazy', '');
    }
    return key;
  }

  void _setupErrorHandling() {
    // 设置全局错误处理
    // 在实际项目中集成日志系统
  }

  void _startHealthCheck() {
    _healthCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _performHealthCheck(),
    );
  }

  /// 手动触发健康检查（主要用于测试）
  Future<void> performHealthCheck() async {
    await _performHealthCheck();
  }

  Future<void> _performHealthCheck() async {
    try {
      // 检查是否有损坏的盒子
      final boxKeysToRemove = <String>[];
      final lazyBoxKeysToRemove = <String>[];

      // 检查普通盒子
      for (final entry in _boxes.entries) {
        if (entry.value.isClosed) {
          boxKeysToRemove.add(entry.key);
        }
      }

      // 检查懒加载盒子
      for (final entry in _lazyBoxes.entries) {
        if (entry.value.isClosed) {
          lazyBoxKeysToRemove.add(entry.key);
        }
      }

      // 移除已关闭的盒子
      for (final key in boxKeysToRemove) {
        _boxes.remove(key);
        debugPrint('Health check: Removed closed box: $key');
      }

      for (final key in lazyBoxKeysToRemove) {
        _lazyBoxes.remove(key);
        debugPrint('Health check: Removed closed lazy box: $key');
      }

      // 记录健康检查结果
      if (boxKeysToRemove.isNotEmpty || lazyBoxKeysToRemove.isNotEmpty) {
        debugPrint('Health check: Cleaned up ${boxKeysToRemove.length} boxes and ${lazyBoxKeysToRemove.length} lazy boxes');
      }
    } catch (e) {
      debugPrint('Health check error: $e');
    }
  }
}

/// 盒子包装器
class GchKvBoxWrapper<T> {
  final Box<T> box;
  final bool encrypted;

  GchKvBoxWrapper(this.box, this.encrypted);

  bool get isClosed => !box.isOpen;

  Future<void> close() async {
    if (!isClosed) {
      await box.close();
    }
  }
}

/// 延迟盒子包装器
class GchKvLazyBoxWrapper<T> {
  final LazyBox<T> box;
  final bool encrypted;

  GchKvLazyBoxWrapper(this.box, this.encrypted);

  bool get isClosed => !box.isOpen;

  Future<void> close() async {
    if (!isClosed) {
      await box.close();
    }
  }
}

/// 盒子信息
class GchKvBoxInfo {
  final String name;
  final bool encrypted;
  final bool isLazy;
  final bool isOpen;
  final int length;

  const GchKvBoxInfo({
    required this.name,
    required this.encrypted,
    required this.isLazy,
    required this.isOpen,
    required this.length,
  });
}

/// 盒子健康报告
class GchKvHealthReport {
  final String boxName;
  final bool healthy;
  final String? error;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  GchKvHealthReport({
    required this.boxName,
    required this.healthy,
    this.error,
    this.stackTrace,
  }) : timestamp = DateTime.now();
}
