// lib/core/gch_prefs/gch_store_factory.dart

import 'dart:async';
import 'gch_store.dart';
import 'gch_kv_backend.dart';
import 'gch_mem_store.dart';
import '../gch_kit/gch_loggers.dart';
import '../gch_core/gch_nucleus.dart';

/// 存储工厂 - 根据配置选择存储实现
class GchStoreFactory {
  static GchStore? _instance;
  static GchStoreType? _currentType;  // 改为可空，延迟初始化

  /// 设置存储类型
  static void setType(GchStoreType type) {
    _currentType = type;
    _instance = null; // 重置实例以便重新创建
  }

  /// 获取当前存储类型（动态读取配置）
  static GchStoreType get currentType {
    // 如果未手动设置，则从 GchNucleus 读取
    _currentType ??= GchNucleus.defaultPreferencesStorageType;
    return _currentType!;
  }

  /// 创建存储实例
  static Future<GchStore> create([GchStoreType? type]) async {
    final targetType = type ?? currentType;  // 使用 getter

    // 如果类型相同且实例存在，直接返回
    if (_instance != null && _instance!.type == targetType.toString()) {
      return _instance!;
    }

    // 创建新实例
    _instance = await _createStore(targetType);
    return _instance!;
  }
  
  /// 获取单例实例（支持降级）
  static Future<GchStore> getInstance() async {
    final targetType = currentType;  // 使用 getter 动态获取类型

    print('🔧 GchStoreFactory.getInstance() 开始');
    print('   目标类型: $targetType (${targetType.name})');
    print('   GchNucleus配置: ${GchNucleus.defaultPreferencesStorageType.name}');
    print('   实例状态: ${_instance != null ? "存在" : "不存在"}, ready: ${_instance?.ready}');

    if (_instance != null && _instance!.ready) {
      print('   返回现有实例: ${_instance!.type}');
      return _instance!;
    }

    // 尝试创建主存储，失败则降级
    try {
      print('   开始创建 $targetType 存储...');
      _instance = await _createStore(targetType).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('   ⏱️ 超时: $targetType 创建超过3秒');
          throw TimeoutException('Store creation timeout');
        },
      );
      print('   ✅ $targetType 存储创建成功');
      return _instance!;
    } catch (e, stackTrace) {
      print('   ❌ $targetType 存储创建失败: $e');
      print('   StackTrace: $stackTrace');
      InfraLoggerMixin('GchStoreFactory').loggy.error('主存储创建失败，尝试降级', e);

      // 降级到内存存储
      if (targetType != GchStoreType.memory) {
        print('   ⚠️ 降级到内存存储');
        InfraLoggerMixin('GchStoreFactory').loggy.warning('降级到内存存储');
        _instance = await _createStore(GchStoreType.memory);
        print('   ✅ 内存存储创建成功（降级）');
        return _instance!;
      }

      rethrow;
    }
  }
  
  static Future<GchStore> _createStore(GchStoreType type) async {
    switch (type) {
      case GchStoreType.hive:
        return await GchKvBackend.getInstance();

      case GchStoreType.shared:
        // TODO: 未来实现 SharedPreferencesStore
        throw UnimplementedError('SharedPreferences store not implemented yet');

      case GchStoreType.isar:
        // TODO: 未来实现 IsarStore
        throw UnimplementedError('Isar store not implemented yet');

      case GchStoreType.memory:
        final store = GchMemStore();
        await store.init();
        return store;

      case GchStoreType.custom:
        throw UnimplementedError('Custom store not implemented yet');
    }
  }
  
  /// 重置工厂(测试用)
  static void reset() {
    _instance = null;
    _currentType = null;  // 重置为 null，下次会重新读取 GchNucleus
  }
}

/// 存储配置
class GchStoreConfig {
  final GchStoreType type;
  final String? path;
  final bool secure;
  final Map<String, dynamic> extras;
  
  const GchStoreConfig({
    required this.type,
    this.path,
    this.secure = true,
    this.extras = const {},
  });
  
  /// Hive配置
  factory GchStoreConfig.hive({
    String? path,
    bool secure = true,
  }) => GchStoreConfig(
    type: GchStoreType.hive,
    path: path,
    secure: secure,
  );

  /// SharedPreferences配置
  factory GchStoreConfig.shared() => const GchStoreConfig(
    type: GchStoreType.shared,
    secure: false,
  );

  /// Isar配置
  factory GchStoreConfig.isar({
    String? path,
    bool secure = false,
  }) => GchStoreConfig(
    type: GchStoreType.isar,
    path: path,
    secure: secure,
  );
}

class InfraLoggerMixin with GchInfraLogger {
  final String name;
  InfraLoggerMixin(this.name);

  @override
  String toString() => name;
}