// lib/core/gch_prefs/gch_type_adapter.dart

import 'dart:async';
import 'gch_store.dart';

/// 类型适配器抽象接口
abstract interface class GchTypeAdapter<T> {
  /// 从GchStore读取值
  Future<T?> read(GchStore store, String key);
  
  /// 向GchStore写入值
  Future<bool> write(GchStore store, String key, T value);
  
  /// 支持的类型
  Type get supportedType;
}

/// 默认类型适配器注册表
class GchTypeRegistry {
  static final Map<Type, GchTypeAdapter> _adapters = {};
  
  /// 注册类型适配器
  static void register<T>(GchTypeAdapter<T> adapter) {
    _adapters[T] = adapter;
  }
  
  /// 获取类型适配器
  static GchTypeAdapter<T>? get<T>() {
    return _adapters[T] as GchTypeAdapter<T>?;
  }
  
  /// 检查是否有特定类型的适配器
  static bool hasAdapter<T>() => _adapters.containsKey(T);
  
  /// 清空所有适配器
  static void clear() => _adapters.clear();
}

/// 基础类型适配器
class StringAdapter implements GchTypeAdapter<String> {
  @override
  Future<String?> read(GchStore store, String key) => store.getString(key);
  
  @override
  Future<bool> write(GchStore store, String key, String value) => 
      store.setString(key, value);
  
  @override
  Type get supportedType => String;
}

class BoolAdapter implements GchTypeAdapter<bool> {
  @override
  Future<bool?> read(GchStore store, String key) => store.getBool(key);
  
  @override
  Future<bool> write(GchStore store, String key, bool value) => 
      store.setBool(key, value);
  
  @override
  Type get supportedType => bool;
}

class IntAdapter implements GchTypeAdapter<int> {
  @override
  Future<int?> read(GchStore store, String key) => store.getInt(key);
  
  @override
  Future<bool> write(GchStore store, String key, int value) => 
      store.setInt(key, value);
  
  @override
  Type get supportedType => int;
}

class DoubleAdapter implements GchTypeAdapter<double> {
  @override
  Future<double?> read(GchStore store, String key) => store.getDouble(key);
  
  @override
  Future<bool> write(GchStore store, String key, double value) => 
      store.setDouble(key, value);
  
  @override
  Type get supportedType => double;
}

/// List<String> 特殊类型适配器
class StringListAdapter implements GchTypeAdapter<List<String>> {
  @override
  Future<List<String>?> read(GchStore store, String key) => 
      store.getStringList(key);
  
  @override
  Future<bool> write(GchStore store, String key, List<String> value) => 
      store.setStringList(key, value);
  
  @override
  Type get supportedType => List<String>;
}

/// 泛型适配器 - 用于不在特殊处理列表中的类型
class GenericAdapter<T> implements GchTypeAdapter<T> {
  @override
  Future<T?> read(GchStore store, String key) => store.get<T>(key);
  
  @override
  Future<bool> write(GchStore store, String key, T value) => 
      store.put<T>(key, value);
  
  @override
  Type get supportedType => T;
}

/// 初始化默认类型适配器
void initializeDefaultTypeAdapters() {
  GchTypeRegistry.register(StringAdapter());
  GchTypeRegistry.register(BoolAdapter());
  GchTypeRegistry.register(IntAdapter());
  GchTypeRegistry.register(DoubleAdapter());
  GchTypeRegistry.register(StringListAdapter());
}