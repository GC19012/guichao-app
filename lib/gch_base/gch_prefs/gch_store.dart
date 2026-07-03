// lib/core/gch_prefs/gch_store.dart

import 'dart:async';

/// 简洁的偏好存储抽象接口
abstract interface class GchStore {
  /// 存储类型
  String get type;
  
  /// 是否已初始化
  bool get ready;
  
  /// 初始化
  Future<void> init();
  
  /// 关闭
  Future<void> close();
  
  // ========== 基础操作 ==========
  
  /// 获取所有键
  Future<Set<String>> keys();
  
  /// 检查键是否存在
  Future<bool> has(String key);
  
  /// 获取值
  Future<T?> get<T>(String key);
  
  /// 设置值
  Future<bool> put<T>(String key, T value);
  
  /// 删除键
  Future<bool> delete(String key);
  
  /// 清空所有
  Future<bool> clear();
  
  // ========== 类型安全方法 ==========
  
  Future<bool?> getBool(String key);
  Future<int?> getInt(String key);
  Future<double?> getDouble(String key);
  Future<String?> getString(String key);
  Future<List<String>?> getStringList(String key);
  
  // ========== 同步读取方法 ==========
  
  bool? getBoolSync(String key);
  int? getIntSync(String key);
  double? getDoubleSync(String key);
  String? getStringSync(String key);
  List<String>? getStringListSync(String key);
  
  Future<bool> setBool(String key, bool value);
  Future<bool> setInt(String key, int value);
  Future<bool> setDouble(String key, double value);
  Future<bool> setString(String key, String value);
  Future<bool> setStringList(String key, List<String> value);
  
  // ========== 对象存储方法 ==========
  
  /// 获取对象 - 支持JSON反序列化
  Future<T?> getObject<T>(String key, T Function(Map<String, dynamic>) fromJson);
  
  /// 设置对象 - 支持JSON序列化  
  Future<bool> setObject<T>(String key, T value, Map<String, dynamic> Function(T)? toJson);
  
  /// 获取Map对象
  Future<Map<String, dynamic>?> getMap(String key);
  
  /// 设置Map对象
  Future<bool> setMap(String key, Map<String, dynamic> value);
  
  /// 获取List对象
  Future<List<T>?> getList<T>(String key, T Function(Map<String, dynamic>)? fromJson);
  
  /// 设置List对象
  Future<bool> setList<T>(String key, List<T> value, Map<String, dynamic> Function(T)? toJson);
  
  // ========== 批量操作 ==========
  
  /// 批量设置
  Future<bool> putAll(Map<String, dynamic> data);
  
  /// 重新加载
  Future<void> reload();
  
  // ========== 响应式 ==========
  
  /// 监听所有变化
  Stream<GchStoreEvent> get changes;

  /// 监听特定键
  Stream<GchStoreEvent> watch(String key);
}

/// 存储事件
class GchStoreEvent {
  final String key;
  final dynamic value;
  final bool deleted;
  final DateTime time;
  
  const GchStoreEvent({
    required this.key,
    required this.value,
    required this.deleted,
    required this.time,
  });
  
  @override
  String toString() => 'GchStoreEvent(key: $key, deleted: $deleted)';
}

/// 存储类型
enum GchStoreType {
  hive,
  shared,
  isar,
  memory,
  custom;

  @override
  String toString() => name;
}