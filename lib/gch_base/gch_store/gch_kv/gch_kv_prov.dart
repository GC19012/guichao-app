
import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../gch_kit/gch_loggers.dart';
import 'gch_kv_api.dart';
import 'gch_kv_box.dart';
import 'gch_kv_mgr.dart';
import 'gch_kv_ex.dart';

part 'gch_kv_prov.g.dart';

/// KV存储核心状态管理 - 精简注解版本

// ========== 基础Provider ==========

/// GchKvMgr Provider - 核心管理器
@Riverpod(keepAlive: true)
Future<GchKvMgr> kvManager(KvManagerRef ref) async {
  final logger = KvLoggerMixin("GchKvMgr");

  try {
    logger.loggy.debug("初始化GchKvMgr");
    final manager = await GchKvMgr.getInstance();

    ref.onDispose(() async {
      logger.loggy.debug("销毁GchKvMgr");
      await manager.dispose();
    });

    return manager;
  } catch (e, stack) {
    logger.loggy.error("GchKvMgr初始化失败", e, stack);
    throw GchKvInitEx('GchKvMgr initialization failed', cause: e, stackTrace: stack);
  }
}

/// GchKvApi Provider - 高级API接口
@Riverpod(keepAlive: true)
Future<GchKvApi> kvAPI(KvAPIRef ref) async {
  final logger = KvLoggerMixin("GchKvApi");

  try {
    logger.loggy.debug("初始化GchKvApi");
    await gchKv.init();

    ref.onDispose(() async {
      logger.loggy.debug("销毁GchKvApi");
      await gchKv.dispose();
    });

    return gchKv;
  } catch (e, stack) {
    logger.loggy.error("GchKvApi初始化失败", e, stack);
    throw GchKvInitEx('GchKvApi initialization failed', cause: e, stackTrace: stack);
  }
}

// ========== 盒子Provider ==========

/// 通用盒子Provider
@riverpod
Future<GchKvBox<dynamic>> kvBox(KvBoxRef ref, String name, {
  bool secure = false,
  bool lazy = false,
}) async {
  await ref.watch(kvAPIProvider.future);

  final logger = KvLoggerMixin("GchKvBox[$name]");

  try {
    logger.loggy.debug("创建盒子: secure=$secure, lazy=$lazy");
    final box = await gchOpenKvBox<dynamic>(name, secure: secure, lazy: lazy);

    ref.onDispose(() async {
      logger.loggy.debug("销毁盒子");
      await box.dispose();
    });

    return box;
  } catch (e, stack) {
    logger.loggy.error("盒子创建失败", e, stack);
    throw GchKvBoxEx('GchKvBox creation failed: $name', cause: e, stackTrace: stack);
  }
}

// ========== 响应式状态Provider ==========

/// 盒子值的响应式Provider
@riverpod
class KvValue extends _$KvValue {
  StreamSubscription? _subscription;

  @override
  Future<dynamic> build(String boxName, String key, {
    bool secure = false,
    dynamic defaultValue,
  }) async {
    final logger = KvLoggerMixin("KvValue[$boxName:$key]");

    try {
      final box = await ref.watch(kvBoxProvider(boxName, secure: secure).future);

      // 设置变化监听
      try {
        _subscription = box.watch(key: key).listen((event) {
          if (event.key == key) {
            logger.loggy.debug("值变化: ${event.deleted ? 'deleted' : 'updated'}");
            ref.invalidateSelf();
          }
        });
      } catch (e) {
        logger.loggy.debug("盒子不支持监听: $e");
      }

      ref.onDispose(() {
        _subscription?.cancel();
      });

      return await box.get(key, defaultValue: defaultValue);
    } catch (e, stack) {
      logger.loggy.error("获取值失败", e, stack);
      return defaultValue;
    }
  }
}

/// 盒子键列表的响应式Provider
@riverpod
class KvKeys extends _$KvKeys {
  StreamSubscription? _subscription;

  @override
  Future<Set<String>> build(String boxName, {bool secure = false}) async {
    final logger = KvLoggerMixin("KvKeys[$boxName]");

    try {
      final box = await ref.watch(kvBoxProvider(boxName, secure: secure).future);

      try {
        _subscription = box.watch().listen((event) {
          logger.loggy.debug("键变化: ${event.key}");
          ref.invalidateSelf();
        });
      } catch (e) {
        logger.loggy.debug("盒子不支持监听: $e");
      }

      ref.onDispose(() {
        _subscription?.cancel();
      });

      final keys = await box.getKeys();
      return keys.cast<String>().toSet();
    } catch (e, stack) {
      logger.loggy.error("获取键失败", e, stack);
      return <String>{};
    }
  }
}

/// 批量写入Provider
@riverpod
class KvBatchWriter extends _$KvBatchWriter {
  @override
  Future<void> build() async {
    // 无状态Provider
  }

  /// 批量写入多个盒子
  Future<bool> writeToBoxes(Map<String, Map<String, dynamic>> data, {bool secure = false}) async {
    final logger = KvLoggerMixin("KvBatchWriter");

    try {
      logger.loggy.debug("批量写入${data.length}个盒子");

      for (final entry in data.entries) {
        final boxName = entry.key;
        final boxData = entry.value;

        final box = await ref.read(kvBoxProvider(boxName, secure: secure).future);
        await box.putAll(boxData);
      }

      logger.loggy.debug("批量写入完成");
      return true;
    } catch (e, stack) {
      logger.loggy.error("批量写入失败", e, stack);
      return false;
    }
  }
}

/// 数据库健康状态Provider
@riverpod
class KvHealth extends _$KvHealth {
  Timer? _timer;

  @override
  Future<List<GchKvHealthReport>> build() async {
    final manager = await ref.watch(kvManagerProvider.future);

    // 定期健康检查
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      ref.invalidateSelf();
    });

    ref.onDispose(() {
      _timer?.cancel();
    });

    // 获取所有盒子信息并检查健康状态
    final allBoxes = await manager.getAllBoxInfo();
    final reports = <GchKvHealthReport>[];

    for (final boxInfo in allBoxes) {
      final report = await manager.checkBoxHealth(boxInfo.name);
      reports.add(report);
    }

    return reports;
  }
}

// ========== 工具类 ==========

/// 日志混入类
class KvLoggerMixin with GchInfraLogger {
  final String name;
  KvLoggerMixin(this.name);

  @override
  String toString() => name;
}

/// 便捷访问扩展
extension KvProviderExtensions on WidgetRef {
  /// 获取盒子值
  AsyncValue<dynamic> kvValue(String boxName, String key, {
    bool secure = false,
    dynamic defaultValue,
  }) {
    return watch(kvValueProvider(boxName, key, secure: secure, defaultValue: defaultValue));
  }

  /// 获取盒子键列表
  AsyncValue<Set<String>> kvKeys(String boxName, {bool secure = false}) {
    return watch(kvKeysProvider(boxName, secure: secure));
  }

  /// 写入盒子值
  Future<bool> setKvValue(String boxName, String key, dynamic value, {bool secure = false}) async {
    try {
      final box = await read(kvBoxProvider(boxName, secure: secure).future);
      await box.put(key, value);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 删除盒子值
  Future<bool> deleteKvValue(String boxName, String key, {bool secure = false}) async {
    try {
      final box = await read(kvBoxProvider(boxName, secure: secure).future);
      await box.delete(key);
      return true;
    } catch (e) {
      return false;
    }
  }
}
