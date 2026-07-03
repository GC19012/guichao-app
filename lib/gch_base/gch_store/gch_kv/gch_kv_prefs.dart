
import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../gch_kit/gch_loggers.dart';
import '../../gch_prefs/gch_type_adapter.dart';
import 'gch_kv_api.dart';
import 'gch_kv_box.dart';
import 'gch_kv_ex.dart';

/// KV存储版本的SharedPreferences替代实现
/// 提供与SharedPreferences完全兼容的API，同时支持Riverpod状态响应
class GchKvPrefs with GchInfraLogger {
  static GchKvPrefs? _instance;
  static final Completer<GchKvPrefs> _completer = Completer<GchKvPrefs>();

  GchKvBox<dynamic>? _prefsBox;
  bool _initialized = false;

  // 状态变化流控制器
  final StreamController<GchKvChangeEvent> _changeController =
      StreamController<GchKvChangeEvent>.broadcast();

  GchKvPrefs._();

  /// 获取单例实例
  static Future<GchKvPrefs> getInstance() async {
    if (_completer.isCompleted) {
      return _completer.future;
    }

    try {
      _instance ??= GchKvPrefs._();
      await _instance!._initialize();

      if (!_completer.isCompleted) {
        _completer.complete(_instance!);
      }

      return _instance!;
    } catch (e) {
      if (!_completer.isCompleted) {
        _completer.completeError(e);
      }
      rethrow;
    }
  }

  /// 初始化
  Future<void> _initialize() async {
    if (_initialized) return;

    try {
      loggy.debug('初始化GchKvPrefs...');

      // 确保KV存储已初始化
      await gchKv.init();

      // 初始化TypeAdapter系统
      _initializeTypeAdapters();

      // 创建preferences盒子，使用加密存储敏感设置
      _prefsBox = await gchOpenKvBox<dynamic>('app_preferences', secure: true);

      // 设置数据变化监听
      _setupChangeListener();

      _initialized = true;
      loggy.debug('GchKvPrefs初始化成功');
    } catch (e, stack) {
      loggy.error('GchKvPrefs初始化失败', e, stack);
      throw GchKvInitEx('Failed to initialize GchKvPrefs', cause: e, stackTrace: stack);
    }
  }

  /// 初始化TypeAdapter系统
  void _initializeTypeAdapters() {
    try {
      loggy.debug('初始化TypeAdapter系统...');
      initializeDefaultTypeAdapters();
      loggy.debug('TypeAdapter系统初始化完成');
    } catch (e) {
      loggy.warning('TypeAdapter系统初始化失败: $e');
      // 不抛出异常，因为这不是致命错误
    }
  }

  /// 设置变化监听器（支持Riverpod状态响应）
  void _setupChangeListener() {
    try {
      _prefsBox!.watch().listen((event) {
        _changeController.add(GchKvChangeEvent(
          key: event.key.toString(),
          value: event.value,
          deleted: event.deleted,
        ));
        loggy.debug('Preference变化: ${event.key} -> ${event.deleted ? "删除" : "更新"}');
      });
    } catch (e) {
      loggy.warning('设置变化监听失败: $e');
    }
  }

  void _checkInit() {
    if (!_initialized || _prefsBox == null) {
      throw GchKvEx('GchKvPrefs not initialized. Call getInstance() first.');
    }
  }

  // ========== SharedPreferences兼容API ==========

  /// 获取所有键
  Future<Set<String>> getKeys() async {
    _checkInit();
    try {
      final keys = await _prefsBox!.getKeys();
      return keys.cast<String>().toSet();
    } catch (e) {
      loggy.warning('获取keys失败: $e');
      return <String>{};
    }
  }

  /// 异步获取值
  Future<Object?> get(String key) async {
    _checkInit();
    try {
      return await _prefsBox!.get(key);
    } catch (e) {
      loggy.warning('获取值失败[$key]: $e');
      return null;
    }
  }

  /// 获取布尔值
  Future<bool?> getBool(String key) async {
    final value = await get(key);
    return value as bool?;
  }

  /// 获取整数值
  Future<int?> getInt(String key) async {
    final value = await get(key);
    return value as int?;
  }

  /// 获取双精度值
  Future<double?> getDouble(String key) async {
    final value = await get(key);
    return value as double?;
  }

  /// 获取字符串值
  Future<String?> getString(String key) async {
    final value = await get(key);
    return value as String?;
  }

  /// 获取字符串列表
  Future<List<String>?> getStringList(String key) async {
    final value = await get(key);
    if (value is List) {
      return value.cast<String>();
    }
    return null;
  }

  // ========== 同步读取方法 ==========

  /// 同步获取值
  Object? getSync(String key) {
    _checkInit();
    try {
      // 使用 GchKvBox 的同步 get 方法
      return _prefsBox!.getSync(key);
    } catch (e) {
      loggy.warning('同步获取值失败[$key]: $e');
      return null;
    }
  }

  /// 同步获取布尔值
  bool? getBoolSync(String key) {
    final value = getSync(key);
    return value as bool?;
  }

  /// 同步获取整数值
  int? getIntSync(String key) {
    final value = getSync(key);
    return value as int?;
  }

  /// 同步获取双精度值
  double? getDoubleSync(String key) {
    final value = getSync(key);
    return value as double?;
  }

  /// 同步获取字符串值
  String? getStringSync(String key) {
    final value = getSync(key);
    return value as String?;
  }

  /// 同步获取字符串列表
  List<String>? getStringListSync(String key) {
    final value = getSync(key);
    if (value is List) {
      return value.cast<String>();
    }
    return null;
  }

  // ========== 设置值的方法 ==========

  /// 设置布尔值
  Future<bool> setBool(String key, bool value) async {
    _checkInit();
    try {
      await _prefsBox!.put(key, value);
      loggy.debug('设置布尔值[$key]: $value');
      return true;
    } catch (e) {
      loggy.warning('设置布尔值失败[$key]: $e');
      return false;
    }
  }

  /// 设置整数值
  Future<bool> setInt(String key, int value) async {
    _checkInit();
    try {
      await _prefsBox!.put(key, value);
      loggy.debug('设置整数值[$key]: $value');
      return true;
    } catch (e) {
      loggy.warning('设置整数值失败[$key]: $e');
      return false;
    }
  }

  /// 设置双精度值
  Future<bool> setDouble(String key, double value) async {
    _checkInit();
    try {
      await _prefsBox!.put(key, value);
      loggy.debug('设置双精度值[$key]: $value');
      return true;
    } catch (e) {
      loggy.warning('设置双精度值失败[$key]: $e');
      return false;
    }
  }

  /// 设置字符串值
  Future<bool> setString(String key, String value) async {
    _checkInit();
    try {
      await _prefsBox!.put(key, value);
      loggy.debug('设置字符串值[$key]: $value');
      return true;
    } catch (e) {
      loggy.warning('设置字符串值失败[$key]: $e');
      return false;
    }
  }

  /// 设置字符串列表
  Future<bool> setStringList(String key, List<String> value) async {
    _checkInit();
    try {
      await _prefsBox!.put(key, value);
      loggy.debug('设置字符串列表[$key]: ${value.length}项');
      return true;
    } catch (e) {
      loggy.warning('设置字符串列表失败[$key]: $e');
      return false;
    }
  }

  // ========== 同步写入方法 ==========

  /// 同步设置布尔值
  bool setBoolSync(String key, bool value) {
    _checkInit();
    try {
      _prefsBox!.putSync(key, value);
      loggy.debug('同步设置布尔值[$key]: $value');
      return true;
    } catch (e) {
      loggy.warning('同步设置布尔值失败[$key]: $e');
      return false;
    }
  }

  /// 同步设置整数值
  bool setIntSync(String key, int value) {
    _checkInit();
    try {
      _prefsBox!.putSync(key, value);
      loggy.debug('同步设置整数值[$key]: $value');
      return true;
    } catch (e) {
      loggy.warning('同步设置整数值失败[$key]: $e');
      return false;
    }
  }

  /// 同步设置双精度值
  bool setDoubleSync(String key, double value) {
    _checkInit();
    try {
      _prefsBox!.putSync(key, value);
      loggy.debug('同步设置双精度值[$key]: $value');
      return true;
    } catch (e) {
      loggy.warning('同步设置双精度值失败[$key]: $e');
      return false;
    }
  }

  /// 同步设置字符串值
  bool setStringSync(String key, String value) {
    _checkInit();
    try {
      _prefsBox!.putSync(key, value);
      loggy.debug('同步设置字符串值[$key]: $value');
      return true;
    } catch (e) {
      loggy.warning('同步设置字符串值失败[$key]: $e');
      return false;
    }
  }

  /// 同步设置字符串列表
  bool setStringListSync(String key, List<String> value) {
    _checkInit();
    try {
      _prefsBox!.putSync(key, value);
      loggy.debug('同步设置字符串列表[$key]: ${value.length}项');
      return true;
    } catch (e) {
      loggy.warning('同步设置字符串列表失败[$key]: $e');
      return false;
    }
  }

  /// 移除键
  Future<bool> remove(String key) async {
    _checkInit();
    try {
      await _prefsBox!.delete(key);
      loggy.debug('移除键[$key]');
      return true;
    } catch (e) {
      loggy.warning('移除键失败[$key]: $e');
      return false;
    }
  }

  /// 清除所有数据
  Future<bool> clear() async {
    _checkInit();
    try {
      await _prefsBox!.clear();
      loggy.debug('清除所有preferences数据');
      return true;
    } catch (e) {
      loggy.warning('清除数据失败: $e');
      return false;
    }
  }

  /// 重新加载（Hive不需要，但为了兼容性保留）
  Future<void> reload() async {
    loggy.debug('重新加载preferences（Hive自动同步）');
    // Hive自动处理数据同步，无需手动重载
  }

  /// 检查键是否存在
  Future<bool> containsKey(String key) async {
    _checkInit();
    try {
      return await _prefsBox!.containsKey(key);
    } catch (e) {
      loggy.warning('检查键存在失败[$key]: $e');
      return false;
    }
  }

  // ========== 扩展功能 ==========

  /// 批量设置（Hive独有优势）
  Future<bool> setAll(Map<String, dynamic> values) async {
    _checkInit();
    try {
      await _prefsBox!.putAll(values.cast<String, dynamic>());
      loggy.debug('批量设置${values.keys.length}个preferences');
      return true;
    } catch (e) {
      loggy.warning('批量设置失败: $e');
      return false;
    }
  }

  /// 获取盒子统计信息
  Future<String> getStats() async {
    _checkInit();
    try {
      final stats = await _prefsBox!.getStats();
      return stats.toString();
    } catch (e) {
      return 'Stats unavailable: $e';
    }
  }

  /// 监听所有数据变化（支持Riverpod响应）
  Stream<GchKvChangeEvent> get changeStream => _changeController.stream;

  /// 监听特定键的变化（支持Riverpod响应）
  Stream<GchKvChangeEvent> watchKey(String key) {
    return _changeController.stream.where((event) => event.key == key);
  }

  /// 安全关闭
  Future<void> dispose() async {
    await _changeController.close();
    if (_prefsBox != null) {
      await _prefsBox!.dispose();
      _prefsBox = null;
    }
    _initialized = false;
    loggy.debug('GchKvPrefs已关闭');
  }

  /// 静态关闭方法 - 用于应用终止时清理单例资源
  static Future<void> shutdown() async {
    if (_completer.isCompleted) {
      try {
        final instance = await _completer.future;
        await instance.dispose();
        _instance = null;
      } catch (e) {
        // 已经关闭或初始化失败，忽略错误
      }
    }
  }
}

/// KV变化事件
class GchKvChangeEvent {
  final String key;
  final dynamic value;
  final bool deleted;

  const GchKvChangeEvent({
    required this.key,
    required this.value,
    required this.deleted,
  });

  @override
  String toString() => 'GchKvChangeEvent(key: $key, deleted: $deleted)';
}

/// Riverpod Provider - 替代SharedPreferences
final kvPreferencesProvider = FutureProvider<GchKvPrefs>((ref) async {
  final instance = await GchKvPrefs.getInstance();
  ref.onDispose(() async {
    await instance.dispose();
  });
  return instance;
});
