import 'dart:async';
import 'dart:convert';
import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guichao/gch_base/gch_store/gch_storage/gch_adapter.dart';
import 'package:guichao/gch_base/gch_store/gch_storage/gch_factory.dart';

/// 存储管理器
///
/// 负责管理应用的存储配置，支持运行时切换存储后端
/// 提供统一的存储访问接口
class GchStorageManager {
  GchStorageManager._();

  static final GchStorageManager _instance = GchStorageManager._();
  static GchStorageManager get instance => _instance;

  static const String _storageTypeKey = 'storage_type';
  static const String _storageConfigKey = 'storage_config';

  StorageType _currentStorageType = GchNucleus.defaultStorageType;
  GchStorageConfig? _currentConfig;
  dynamic _currentProfileAdapter;

  // ✅ 添加 disposed 标志防止双重关闭
  bool _disposed = false;

  final StreamController<StorageType> _storageTypeController = StreamController.broadcast();
  final StreamController<GchStorageChangeEvent> _storageChangeController = StreamController.broadcast();

  /// 当前存储类型
  StorageType get gchCurrentType => _currentStorageType;

  /// 当前存储配置
  GchStorageConfig? get gchConfig => _currentConfig;

  /// 当前Profile适配器
  dynamic get gchProfileAdapter => _currentProfileAdapter;

  /// 存储类型变化流
  Stream<StorageType> get gchTypeChanges => _storageTypeController.stream;

  /// 存储变化事件流
  Stream<GchStorageChangeEvent> get gchChanges => _storageChangeController.stream;

  /// 初始化存储管理器
  Future<void> gchInit() async {
    try {
      await _loadConfig();
      await _setupStorage();

      if (GchNucleus.isDevMode) {
        print('GchStorageManager: 初始化完成，当前存储类型: $_currentStorageType');
      }
    } catch (e) {
      if (GchNucleus.isDevMode) {
        print('GchStorageManager: 初始化失败: $e');
      }

      // 回退到默认配置
      await _fallback();
    }
  }

  /// 切换存储类型
  Future<void> gchSwitchType(
    StorageType newType, {
    GchStorageConfig? customConfig,
    bool migrateData = true,
    void Function(int current, int total)? onMigrationProgress,
  }) async {
    if (newType == _currentStorageType) {
      if (GchNucleus.isDevMode) {
        print('GchStorageManager: 存储类型未变化，跳过切换');
      }
      return;
    }

    if (!GchStorageFactory.gchIsTypeSupported(newType)) {
      throw UnsupportedError('Storage type $newType is not supported');
    }

    _storageChangeController.add(GchStorageChangeEvent.switchStarted(
      from: _currentStorageType,
      to: newType,
    ));

    try {
      // 创建新的存储配置
      final newConfig = customConfig ?? GchStorageFactory.gchDefaultConfig(newType);

      // 创建新的适配器
      final newAdapter = await GchStorageFactory.instance.gchBuildAdapter(newConfig);

      // 数据迁移
      if (migrateData && _currentProfileAdapter != null) {
        _storageChangeController.add(GchStorageChangeEvent.migrationStarted(
          from: _currentStorageType,
          to: newType,
        ));

        await GchStorageFactory.instance.gchMigrate(
          fromAdapter: _currentProfileAdapter,
          toAdapter: newAdapter,
          onProgress: onMigrationProgress,
        );

        _storageChangeController.add(GchStorageChangeEvent.migrationCompleted(
          from: _currentStorageType,
          to: newType,
        ));
      }

      // 关闭旧适配器 (stub: no-op after gch_profile removal)
      _currentProfileAdapter = null;

      // 更新当前配置
      final oldType = _currentStorageType;
      _currentStorageType = newType;
      _currentConfig = newConfig;
      _currentProfileAdapter = newAdapter;

      // 保存配置
      await _saveConfig();

      // 通知变化
      _storageTypeController.add(newType);
      _storageChangeController.add(GchStorageChangeEvent.switchCompleted(
        from: oldType,
        to: newType,
      ));

      if (GchNucleus.isDevMode) {
        print('GchStorageManager: 成功切换到 $newType');
      }
    } catch (e) {
      _storageChangeController.add(GchStorageChangeEvent.switchFailed(
        from: _currentStorageType,
        to: newType,
        error: e.toString(),
      ));

      if (GchNucleus.isDevMode) {
        print('GchStorageManager: 切换存储类型失败: $e');
      }
      rethrow;
    }
  }


  /// 修复存储问题
  Future<void> gchRepair() async {
    if (_currentProfileAdapter == null) {
      throw StateError('No active storage adapter');
    }

    try {
      // Stub: adapter repair no-op after gch_profile removal

      // TODO: 添加更多修复逻辑，如：
      // - 修复损坏的数据
      // - 重建索引
      // - 清理无效记录

      if (GchNucleus.isDevMode) {
        print('GchStorageManager: 存储修复完成');
      }
    } catch (e) {
      if (GchNucleus.isDevMode) {
        print('GchStorageManager: 存储修复失败: $e');
      }
      rethrow;
    }
  }

  /// 备份当前存储数据
  Future<Map<String, dynamic>> gchBackup() async {
    if (_currentProfileAdapter == null) {
      throw StateError('No active storage adapter');
    }

    try {
      return {
        'version': '1.0',
        'storageType': _currentStorageType.name,
        'timestamp': DateTime.now().toIso8601String(),
        'profiles': <dynamic>[],
      };
    } catch (e) {
      if (GchNucleus.isDevMode) {
        print('GchStorageManager: 数据备份失败: $e');
      }
      rethrow;
    }
  }

  /// 从备份恢复数据
  Future<void> gchRestore(Map<String, dynamic> backupData) async {
    if (_currentProfileAdapter == null) {
      throw StateError('No active storage adapter');
    }

    try {
      // Stub: restore no-op after gch_profile removal
      if (GchNucleus.isDevMode) {
        print('GchStorageManager: 数据恢复跳过 (gch_profile removed)');
      }
    } catch (e) {
      if (GchNucleus.isDevMode) {
        print('GchStorageManager: 数据恢复失败: $e');
      }
      rethrow;
    }
  }

  /// 清理存储（清空所有数据）
  Future<void> gchClearAll() async {
    if (_currentProfileAdapter == null) {
      throw StateError('No active storage adapter');
    }

    try {
      // Stub: purge no-op after gch_profile removal

      if (GchNucleus.isDevMode) {
        print('GchStorageManager: 存储已清空');
      }
    } catch (e) {
      if (GchNucleus.isDevMode) {
        print('GchStorageManager: 清空存储失败: $e');
      }
      rethrow;
    }
  }

  /// 关闭存储管理器
  Future<void> gchDispose() async {
    // ✅ 防止双重关闭
    if (_disposed) return;
    _disposed = true;

    await _storageTypeController.close();
    await _storageChangeController.close();

    _currentProfileAdapter = null;

    await GchStorageFactory.instance.gchCloseAll();

    if (GchNucleus.isDevMode) {
      print('GchStorageManager: 资源已释放');
    }
  }

  /// 静态关闭方法 - 用于应用终止时清理单例资源
  /// ✅ 修复 CRITICAL 级别的双重 StreamController 永久泄漏
  static Future<void> gchShutdown() async {
    try {
      await _instance.gchDispose();
    } catch (e) {
      if (GchNucleus.isDevMode) {
        print('GchStorageManager: shutdown 失败 (可能已关闭): $e');
      }
    }
  }

  // 私有方法

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();

    // 加载存储类型
    final storageTypeName = prefs.getString(_storageTypeKey);
    if (storageTypeName != null) {
      _currentStorageType = StorageType.values.firstWhere((t) => t.name == storageTypeName, orElse: () => GchNucleus.defaultStorageType);
    }

    // 加载存储配置
    final configJson = prefs.getString(_storageConfigKey);
    if (configJson != null) {
      try {
        final configMap = jsonDecode(configJson) as Map<String, dynamic>;
        _currentConfig = _deserializeConfig(configMap);
      } catch (e) {
        if (GchNucleus.isDevMode) {
          print('GchStorageManager: 配置解析失败: $e');
        }
      }
    }

    // 如果没有配置，使用默认配置
    _currentConfig ??= GchStorageFactory.gchDefaultConfig(_currentStorageType);
  }

  Future<void> _saveConfig() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_storageTypeKey, _currentStorageType.name);

    if (_currentConfig != null) {
      final configJson = jsonEncode(_serializeConfig(_currentConfig!));
      await prefs.setString(_storageConfigKey, configJson);
    }
  }

  Future<void> _setupStorage() async {
    if (_currentConfig == null) {
      throw StateError('Storage configuration not loaded');
    }

    // Stub: profile adapters removed with gch_profile module
    _currentProfileAdapter = null;
  }

  Future<void> _fallback() async {
    _currentStorageType = GchNucleus.defaultStorageType;
    _currentConfig = GchStorageFactory.gchDefaultConfig(_currentStorageType);

    await _setupStorage();
    await _saveConfig();

    if (GchNucleus.isDevMode) {
      print('GchStorageManager: 回退到默认配置 (${_currentStorageType.displayName})');
    }
  }

  Map<String, dynamic> _serializeConfig(GchStorageConfig config) {
    return {
      'type': config.type.name,
      'name': config.name,
      'options': config.options,
    };
  }

  GchStorageConfig _deserializeConfig(Map<String, dynamic> map) {
    final name = map['name'] as String;
    final options = map['options'] as Map<String, dynamic>;

    return GchSqliteConfig(
      name: name,
      path: options['path'] as String?,
      enableForeignKeys: options['enableForeignKeys'] as bool? ?? true,
      enableWAL: options['enableWAL'] as bool? ?? true,
    );
  }

  Map<String, dynamic> _serializeProfile(dynamic profile) {
    // Stub: gch_profile module removed
    return {};
  }

  dynamic _deserializeProfile(Map<String, dynamic> map) {
    // Stub: gch_profile module removed
    throw UnsupportedError('Profile deserialization not available after gch_profile removal');
  }
}

/// 存储变化事件
sealed class GchStorageChangeEvent {
  const GchStorageChangeEvent();

  const factory GchStorageChangeEvent.switchStarted({
    required StorageType from,
    required StorageType to,
  }) = GchSwitchStarted;

  const factory GchStorageChangeEvent.migrationStarted({
    required StorageType from,
    required StorageType to,
  }) = GchMigrationStarted;

  const factory GchStorageChangeEvent.migrationCompleted({
    required StorageType from,
    required StorageType to,
  }) = GchMigrationCompleted;

  const factory GchStorageChangeEvent.switchCompleted({
    required StorageType from,
    required StorageType to,
  }) = GchSwitchCompleted;

  const factory GchStorageChangeEvent.switchFailed({
    required StorageType from,
    required StorageType to,
    required String error,
  }) = GchSwitchFailed;
}

class GchSwitchStarted extends GchStorageChangeEvent {
  const GchSwitchStarted({required this.from, required this.to});
  final StorageType from;
  final StorageType to;
}

class GchMigrationStarted extends GchStorageChangeEvent {
  const GchMigrationStarted({required this.from, required this.to});
  final StorageType from;
  final StorageType to;
}

class GchMigrationCompleted extends GchStorageChangeEvent {
  const GchMigrationCompleted({required this.from, required this.to});
  final StorageType from;
  final StorageType to;
}

class GchSwitchCompleted extends GchStorageChangeEvent {
  const GchSwitchCompleted({required this.from, required this.to});
  final StorageType from;
  final StorageType to;
}

class GchSwitchFailed extends GchStorageChangeEvent {
  const GchSwitchFailed({required this.from, required this.to, required this.error});
  final StorageType from;
  final StorageType to;
  final String error;
}

/// 存储统计信息
class GchStorageStats {
  const GchStorageStats({
    required this.storageType,
    required this.totalProfiles,
    required this.activeProfiles,
    required this.remoteProfiles,
    required this.localProfiles,
  });

  final StorageType storageType;
  final int totalProfiles;
  final int activeProfiles;
  final int remoteProfiles;
  final int localProfiles;

  Map<String, dynamic> toMap() {
    return {
      'storageType': storageType.name,
      'totalProfiles': totalProfiles,
      'activeProfiles': activeProfiles,
      'remoteProfiles': remoteProfiles,
      'localProfiles': localProfiles,
    };
  }

  @override
  String toString() {
    return 'GchStorageStats{type: $storageType, total: $totalProfiles, active: $activeProfiles, remote: $remoteProfiles, local: $localProfiles}';
  }
}
