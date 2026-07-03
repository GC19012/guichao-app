// lib/core/gch_prefs/gch_mem_store.dart

import 'dart:async';
import '../gch_kit/gch_loggers.dart';
import 'gch_store.dart';

/// 内存存储实现 - 用作降级方案
/// 当主存储（Hive）初始化失败时使用
class GchMemStore with GchInfraLogger implements GchStore {
  final Map<String, dynamic> _data = {};
  final StreamController<GchStoreEvent> _controller = StreamController<GchStoreEvent>.broadcast();
  bool _ready = false;

  @override
  String get type => 'memory';

  @override
  bool get ready => _ready;

  @override
  Future<void> init() async {
    loggy.debug('初始化内存存储...');
    _ready = true;
    loggy.warning('使用内存存储作为降级方案，数据不会持久化！');
  }

  @override
  Future<void> close() async {
    _data.clear();
    await _controller.close();
    _ready = false;
  }

  @override
  Future<Set<String>> keys() async => _data.keys.toSet();

  @override
  Future<bool> has(String key) async => _data.containsKey(key);

  @override
  Future<T?> get<T>(String key) async => _data[key] as T?;

  @override
  Future<bool> put<T>(String key, T value) async {
    _data[key] = value;
    _controller.add(GchStoreEvent(
      key: key,
      value: value,
      deleted: false,
      time: DateTime.now(),
    ));
    return true;
  }

  @override
  Future<bool> delete(String key) async {
    final removed = _data.remove(key) != null;
    if (removed) {
      _controller.add(GchStoreEvent(
        key: key,
        value: null,
        deleted: true,
        time: DateTime.now(),
      ));
    }
    return removed;
  }

  @override
  Future<bool> clear() async {
    _data.clear();
    return true;
  }

  // 类型安全方法
  @override
  Future<bool?> getBool(String key) async => _data[key] as bool?;

  @override
  Future<int?> getInt(String key) async => _data[key] as int?;

  @override
  Future<double?> getDouble(String key) async => _data[key] as double?;

  @override
  Future<String?> getString(String key) async => _data[key] as String?;

  @override
  Future<List<String>?> getStringList(String key) async {
    final value = _data[key];
    return value is List ? value.cast<String>() : null;
  }

  // 同步读取方法
  @override
  bool? getBoolSync(String key) => _data[key] as bool?;

  @override
  int? getIntSync(String key) => _data[key] as int?;

  @override
  double? getDoubleSync(String key) => _data[key] as double?;

  @override
  String? getStringSync(String key) => _data[key] as String?;

  @override
  List<String>? getStringListSync(String key) {
    final value = _data[key];
    return value is List ? value.cast<String>() : null;
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

  // 对象存储
  @override
  Future<T?> getObject<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    final value = _data[key];
    if (value is Map<String, dynamic>) {
      return fromJson(value);
    }
    return null;
  }

  @override
  Future<bool> setObject<T>(String key, T value, Map<String, dynamic> Function(T)? toJson) async {
    if (toJson != null) {
      _data[key] = toJson(value);
    } else {
      _data[key] = value;
    }
    return true;
  }

  @override
  Future<Map<String, dynamic>?> getMap(String key) async {
    final value = _data[key];
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return null;
  }

  @override
  Future<bool> setMap(String key, Map<String, dynamic> value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<List<T>?> getList<T>(String key, T Function(Map<String, dynamic>)? fromJson) async {
    final value = _data[key];
    if (value is List) {
      if (fromJson != null) {
        return value.map((e) => fromJson(e as Map<String, dynamic>)).toList();
      }
      return value.cast<T>();
    }
    return null;
  }

  @override
  Future<bool> setList<T>(String key, List<T> value, Map<String, dynamic> Function(T)? toJson) async {
    if (toJson != null) {
      _data[key] = value.map(toJson).toList();
    } else {
      _data[key] = value;
    }
    return true;
  }

  @override
  Future<bool> putAll(Map<String, dynamic> data) async {
    _data.addAll(data);
    return true;
  }

  @override
  Future<void> reload() async {
    // 内存存储无需重载
  }

  @override
  Stream<GchStoreEvent> get changes => _controller.stream;

  @override
  Stream<GchStoreEvent> watch(String key) {
    return _controller.stream.where((event) => event.key == key);
  }
}