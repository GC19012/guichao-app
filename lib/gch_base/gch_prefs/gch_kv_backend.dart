// lib/core/gch_prefs/gch_kv_backend.dart

import 'dart:async';
import '../gch_kit/gch_loggers.dart';
import '../gch_store/gch_kv/gch_kv_api.dart';
import '../gch_store/gch_kv/gch_kv_box.dart';
import '../gch_store/gch_kv/gch_kv_ex.dart';
import 'gch_store.dart';
import 'gch_store_codec.dart';

/// Hive实现的存储后端
class GchKvBackend with GchInfraLogger implements GchStore {
  static GchKvBackend? _instance;
  static Completer<GchKvBackend>? _currentCompleter;

  GchKvBox<dynamic>? _box;
  bool _ready = false;

  final StreamController<GchStoreEvent> _controller =
      StreamController<GchStoreEvent>.broadcast();

  GchKvBackend._();

  /// 获取单例（改进版：支持错误恢复和超时）
  static Future<GchKvBackend> getInstance() async {
    // 如果已经成功初始化，直接返回实例
    if (_instance != null && _instance!._ready) {
      return _instance!;
    }

    // 如果正在初始化，等待当前初始化完成
    if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
      return _currentCompleter!.future;
    }

    // 开始新的初始化（支持重试）
    _currentCompleter = Completer<GchKvBackend>();

    try {
      _instance ??= GchKvBackend._();

      // 添加超时保护（3秒超时）
      await _instance!.init().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw GchKvInitEx('GchKvBackend初始化超时（3秒）');
        },
      );

      _currentCompleter!.complete(_instance!);
      return _instance!;
    } catch (e) {
      _currentCompleter!.completeError(e);

      // 重要：重置completer以允许重试
      final errorCompleter = _currentCompleter;
      _currentCompleter = null;

      // 清理失败的实例
      _instance?._ready = false;
      _instance?._box = null;

      // 等待错误completer返回错误
      return errorCompleter!.future;
    }
  }
  
  @override
  String get type => 'hive';
  
  @override
  bool get ready => _ready;
  
  @override
  Future<void> init() async {
    if (_ready) return;

    try {
      loggy.debug('初始化GchKvBackend...');

      // 步骤1: 初始化Hive（添加超时）
      await Future.microtask(() async {
        await gchKv.init();
      }).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          throw GchKvInitEx('gchKv.init() 超时');
        },
      );

      // 步骤2: 打开盒子（使用非加密盒子加速首次启动）
      try {
        // 首先尝试打开加密盒子
        _box = await gchOpenKvBox<dynamic>('app_prefs', secure: true).timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            throw TimeoutException('加密盒子打开超时');
          },
        );
      } catch (e) {
        loggy.warning('加密盒子打开失败，尝试非加密盒子: $e');
        // 降级到非加密盒子（首次安装时更快）
        _box = await gchOpenKvBox<dynamic>('app_prefs', secure: false);
      }

      // 步骤3: 设置监听器（异步执行，不阻塞）
      Future.microtask(() => _setupWatcher());

      _ready = true;
      loggy.debug('GchKvBackend初始化完成');
    } catch (e, stack) {
      _ready = false;
      loggy.error('GchKvBackend初始化失败', e, stack);
      throw GchKvInitEx('GchKvBackend init failed', cause: e, stackTrace: stack);
    }
  }
  
  void _setupWatcher() {
    try {
      _box!.watch().listen((event) {
        _controller.add(GchStoreEvent(
          key: event.key.toString(),
          value: event.value,
          deleted: event.deleted,
          time: DateTime.now(),
        ));
      });
    } catch (e) {
      loggy.warning('设置监听器失败: $e');
    }
  }
  
  void _checkReady() {
    if (!_ready || _box == null) {
      throw GchKvEx('GchKvBackend not ready. Call getInstance() first.');
    }
  }
  
  @override
  Future<void> close() async {
    await _controller.close();
    if (_box != null) {
      await _box!.dispose();
      _box = null;
    }
    _ready = false;
    loggy.debug('GchKvBackend已关闭');
  }
  
  // ========== 基础操作 ==========
  
  @override
  Future<Set<String>> keys() async {
    _checkReady();
    try {
      final keys = await _box!.getKeys();
      return keys.cast<String>().toSet();
    } catch (e) {
      loggy.warning('获取keys失败: $e');
      return <String>{};
    }
  }
  
  @override
  Future<bool> has(String key) async {
    _checkReady();
    try {
      return await _box!.containsKey(key);
    } catch (e) {
      loggy.warning('检查key失败[$key]: $e');
      return false;
    }
  }
  
  @override
  Future<T?> get<T>(String key) async {
    _checkReady();
    try {
      return await _box!.get(key) as T?;
    } catch (e) {
      loggy.warning('获取值失败[$key]: $e');
      return null;
    }
  }
  
  @override
  Future<bool> put<T>(String key, T value) async {
    _checkReady();
    try {
      await _box!.put(key, value);
      loggy.debug('设置值[$key]: $value');
      return true;
    } catch (e) {
      loggy.warning('设置值失败[$key]: $e');
      return false;
    }
  }
  
  @override
  Future<bool> delete(String key) async {
    _checkReady();
    try {
      await _box!.delete(key);
      loggy.debug('删除键[$key]');
      return true;
    } catch (e) {
      loggy.warning('删除键失败[$key]: $e');
      return false;
    }
  }
  
  @override
  Future<bool> clear() async {
    _checkReady();
    try {
      await _box!.clear();
      loggy.debug('清空所有数据');
      return true;
    } catch (e) {
      loggy.warning('清空失败: $e');
      return false;
    }
  }
  
  // ========== 类型安全方法 ==========
  
  @override
  Future<bool?> getBool(String key) async {
    final value = await get(key);
    return value as bool?;
  }
  
  @override
  Future<int?> getInt(String key) async {
    final value = await get(key);
    return value as int?;
  }
  
  @override
  Future<double?> getDouble(String key) async {
    final value = await get(key);
    return value as double?;
  }
  
  @override
  Future<String?> getString(String key) async {
    final value = await get(key);
    return value as String?;
  }
  
  @override
  Future<List<String>?> getStringList(String key) async {
    final value = await get(key);
    if (value is List) {
      return value.cast<String>();
    }
    return null;
  }
  
  @override
  Future<bool> setBool(String key, bool value) => put(key, value);
  
  @override
  Future<bool> setInt(String key, int value) => put(key, value);
  
  @override
  Future<bool> setDouble(String key, double value) => put(key, value);
  
  @override
  Future<bool> setString(String key, String value) => put(key, value);
  
  @override
  Future<bool> setStringList(String key, List<String> value) => put(key, value);
  
  // ========== 同步读取方法实现 ==========
  
  @override
  bool? getBoolSync(String key) {
    _checkReady();
    try {
      final value = _box!.getSync(key);
      return value as bool?;
    } catch (e) {
      loggy.warning('同步获取布尔值失败[$key]: $e');
      return null;
    }
  }
  
  @override
  int? getIntSync(String key) {
    _checkReady();
    try {
      final value = _box!.getSync(key);
      return value as int?;
    } catch (e) {
      loggy.warning('同步获取整数值失败[$key]: $e');
      return null;
    }
  }
  
  @override
  double? getDoubleSync(String key) {
    _checkReady();
    try {
      final value = _box!.getSync(key);
      return value as double?;
    } catch (e) {
      loggy.warning('同步获取双精度值失败[$key]: $e');
      return null;
    }
  }
  
  @override
  String? getStringSync(String key) {
    _checkReady();
    try {
      final value = _box!.getSync(key);
      return value as String?;
    } catch (e) {
      loggy.warning('同步获取字符串值失败[$key]: $e');
      return null;
    }
  }
  
  @override
  List<String>? getStringListSync(String key) {
    _checkReady();
    try {
      final value = _box!.getSync(key);
      if (value is List) {
        return value.cast<String>();
      }
      return null;
    } catch (e) {
      loggy.warning('同步获取字符串列表失败[$key]: $e');
      return null;
    }
  }
  
  // ========== 批量操作 ==========
  
  @override
  Future<bool> putAll(Map<String, dynamic> data) async {
    _checkReady();
    try {
      await _box!.putAll(data.cast<String, dynamic>());
      loggy.debug('批量设置${data.keys.length}个项目');
      return true;
    } catch (e) {
      loggy.warning('批量设置失败: $e');
      return false;
    }
  }
  
  @override
  Future<void> reload() async {
    loggy.debug('重新加载(Hive自动同步)');
    // Hive自动处理同步，无需手动重载
  }
  
  // ========== 对象存储方法 ==========
  
  @override
  Future<T?> getObject<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    _checkReady();
    try {
      final value = await _box!.get(key);
      if (value == null) return null;
      
      // 如果存储的是Map，直接使用
      if (value is Map<String, dynamic>) {
        return fromJson(value);
      } else if (value is Map) {
        return fromJson(value.cast<String, dynamic>());
      } else if (value is String) {
        // 如果存储的是JSON字符串，解码后使用
        return GchStoreCodec.decodeJson(value, fromJson);
      } else {
        loggy.warning('获取对象失败，不支持的数据类型[$key]: ${value.runtimeType}');
        return null;
      }
    } catch (e) {
      loggy.warning('获取对象失败[$key]: $e');
      return null;
    }
  }
  
  @override
  Future<bool> setObject<T>(String key, T value, Map<String, dynamic> Function(T)? toJson) async {
    _checkReady();
    try {
      Map<String, dynamic> data;
      
      if (toJson != null) {
        // 使用提供的序列化方法
        data = GchStoreCodec.encodeObject(value, toJson);
      } else {
        // 尝试自动序列化
        data = GchStoreCodec.encodeObject(value, null);
      }
      
      await _box!.put(key, data);
      loggy.debug('设置对象[$key]: ${data.keys.join(", ")}');
      return true;
    } catch (e) {
      loggy.warning('设置对象失败[$key]: $e');
      return false;
    }
  }
  
  @override
  Future<Map<String, dynamic>?> getMap(String key) async {
    _checkReady();
    try {
      final value = await _box!.get(key);
      if (value == null) return null;
      
      if (value is Map<String, dynamic>) {
        return value;
      } else if (value is Map) {
        return value.cast<String, dynamic>();
      } else if (value is String) {
        // 如果存储的是JSON字符串
        final decoded = GchStoreCodec.decodeJson<Map<String, dynamic>>(
          value, 
          (data) => data,
        );
        return decoded;
      } else {
        loggy.warning('获取Map失败，不支持的数据类型[$key]: ${value.runtimeType}');
        return null;
      }
    } catch (e) {
      loggy.warning('获取Map失败[$key]: $e');
      return null;
    }
  }
  
  @override
  Future<bool> setMap(String key, Map<String, dynamic> value) async {
    _checkReady();
    try {
      await _box!.put(key, value);
      loggy.debug('设置Map[$key]: ${value.keys.length}个键');
      return true;
    } catch (e) {
      loggy.warning('设置Map失败[$key]: $e');
      return false;
    }
  }
  
  @override
  Future<List<T>?> getList<T>(String key, T Function(Map<String, dynamic>)? fromJson) async {
    _checkReady();
    try {
      final value = await _box!.get(key);
      if (value == null) return null;
      
      if (value is List) {
        if (fromJson != null) {
          // 需要反序列化的复杂对象列表
          return GchStoreCodec.decodeList(value, fromJson);
        } else {
          // 简单类型列表
          return value.cast<T>();
        }
      } else {
        loggy.warning('获取List失败，不是List类型[$key]: ${value.runtimeType}');
        return null;
      }
    } catch (e) {
      loggy.warning('获取List失败[$key]: $e');
      return null;
    }
  }
  
  @override
  Future<bool> setList<T>(String key, List<T> value, Map<String, dynamic> Function(T)? toJson) async {
    _checkReady();
    try {
      if (toJson != null) {
        // 需要序列化的复杂对象列表
        final encodedList = GchStoreCodec.encodeList(value, toJson);
        await _box!.put(key, encodedList);
      } else {
        // 简单类型列表，直接存储
        await _box!.put(key, value);
      }
      loggy.debug('设置List[$key]: ${value.length}个项目');
      return true;
    } catch (e) {
      loggy.warning('设置List失败[$key]: $e');
      return false;
    }
  }
  
  // ========== 响应式 ==========
  
  @override
  Stream<GchStoreEvent> get changes => _controller.stream;
  
  @override
  Stream<GchStoreEvent> watch(String key) {
    return _controller.stream.where((event) => event.key == key);
  }
}