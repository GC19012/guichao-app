import 'dart:async';
import 'package:guichao/gch_base/gch_prefs/gch_store_provider.dart';
import 'package:guichao/gch_base/gch_prefs/gch_store.dart';
import 'package:guichao/gch_base/gch_prefs/gch_type_adapter.dart';
import 'package:guichao/gch_aux/gch_log_mix.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GchPrefEntry<T, P> with GchInfraLogger {
  GchPrefEntry({
    required this.preferences,
    required this.key,
    required this.defaultValue,
    this.mapFrom,
    this.mapTo,
    this.validator,
  });

  final GchStore preferences;
  final String key;
  final T defaultValue;
  final T Function(P value)? mapFrom;
  final P Function(T value)? mapTo;
  final bool Function(T value)? validator;

  Future<T> read() async {
    try {
      final T value;
      
      if (mapFrom != null) {
        // 处理需要类型转换的情况
        final persisted = await preferences.get<P>(key);
        if (persisted == null) {
          value = defaultValue;
        } else {
          value = mapFrom!(persisted);
        }
      } else {
        // 使用TypeAdapter系统处理类型特例
        final adapter = GchTypeRegistry.get<T>();
        if (adapter != null) {
          // 使用特定的类型适配器
          value = await adapter.read(preferences, key) ?? defaultValue;
        } else {
          // 回退到泛型方法
          value = await preferences.get<T>(key) ?? defaultValue;
        }
      }

      if (validator?.call(value) ?? true) return value;
      return defaultValue;
    } catch (e, stackTrace) {
      loggy.warning("error getting preference[$key]: $e", e, stackTrace);
      return defaultValue;
    }
  }

  Future<bool> write(T value) async {
    try {
      if (!(validator?.call(value) ?? true)) {
        loggy.warning("invalid value [$value] for preference [$key]($T)");
        return false;
      }

      bool result;
      if (mapTo != null) {
        // 处理需要类型转换的情况
        final mapped = mapTo!(value);
        result = await preferences.put(key, mapped);
        print('GchPrefEntry: write - mapped value: $mapped, result: $result');
      } else {
        // 使用TypeAdapter系统处理类型特例
        final adapter = GchTypeRegistry.get<T>();
        if (adapter != null) {
          // 使用特定的类型适配器
          result = await adapter.write(preferences, key, value);
          print('GchPrefEntry: write - using adapter, result: $result');
        } else {
          // 回退到泛型方法
          result = await preferences.put<T>(key, value);
          print('GchPrefEntry: write - using generic put, result: $result');
        }
      }
      return result;
    } catch (e, stackTrace) {
      loggy.warning("error updating preference[$key]: $e", e, stackTrace);
      print('GchPrefEntry: write - error: $e');
      return false;
    }
  }

  Future<T?> writeRaw(P input) async {
    final T value;
    if (mapFrom != null) {
      value = mapFrom!(input);
    } else {
      value = input as T;
    }
    if (await write(value)) return value;
    return null;
  }

  Future<void> remove() async {
    try {
      await preferences.delete(key);
    } catch (e, stackTrace) {
      loggy.warning("error removing preference[$key]: $e", e, stackTrace);
    }
  }
}

class GchPrefNotifier<T, P> extends AsyncNotifier<T> {
  GchPrefNotifier._({
    required this.key,
    required this.defaultValue,
    this.mapFrom,
    this.mapTo,
    this.validator,
    this.overrideValue,
    this.possibleValues,
  });

  final String key;
  final T defaultValue;
  final T Function(P value)? mapFrom;
  final P Function(T value)? mapTo;
  final bool Function(T value)? validator;
  final T? overrideValue;
  final List<T>? possibleValues;
  
  GchPrefEntry<T, P>? _entry;
  Completer<GchPrefEntry<T, P>>? _entryCompleter;

  @override
  Future<T> build() async {
    // 如果有覆盖值，直接返回
    if (overrideValue != null) {
      return overrideValue!;
    }

    try {
      // 异步获取Store并创建GchPrefEntry
      final store = await ref.read(gchStoreProvider.future);
      _entry = GchPrefEntry<T, P>(
        preferences: store,
        key: key,
        defaultValue: defaultValue,
        mapFrom: mapFrom,
        mapTo: mapTo,
        validator: validator,
      );
      
      // 读取持久化的值
      return await _entry!.read();
    } catch (e) {
      // 出错时返回默认值
      return defaultValue;
    }
  }

  /// 获取GchPrefEntry，如果不存在则异步创建
  /// 使用Completer确保多个并发调用只初始化一次
  Future<GchPrefEntry<T, P>> _getEntry() async {
    // 如果已经初始化完成，直接返回
    if (_entry != null) return _entry!;
    
    // 如果正在初始化，等待初始化完成
    if (_entryCompleter != null) {
      return await _entryCompleter!.future;
    }
    
    // 开始初始化
    _entryCompleter = Completer<GchPrefEntry<T, P>>();
    
    try {
      final store = await ref.read(gchStoreProvider.future);
      _entry = GchPrefEntry<T, P>(
        preferences: store,
        key: key,
        defaultValue: defaultValue,
        mapFrom: mapFrom,
        mapTo: mapTo,
        validator: validator,
      );
      
      // 完成初始化
      _entryCompleter!.complete(_entry!);
      return _entry!;
    } catch (error, stackTrace) {
      // 初始化失败，清理状态并传播错误
      _entryCompleter!.completeError(error, stackTrace);
      _entryCompleter = null;
      rethrow;
    }
  }

  static AsyncNotifierProvider<GchPrefNotifier<T, P>, T> create<T, P>(
    String key, 
    T defaultValue, {
    T Function(Ref ref)? defaultValueFunction, 
    T Function(P value)? mapFrom, 
    P Function(T value)? mapTo, 
    bool Function(T value)? validator, 
    T? overrideValue, 
    List<T>? possibleValues,
  }) =>
      AsyncNotifierProvider<GchPrefNotifier<T, P>, T>(
        () => GchPrefNotifier._(
          key: key,
          defaultValue: defaultValueFunction != null 
              ? throw ArgumentError('defaultValueFunction not supported with AsyncNotifier')
              : defaultValue,
          mapFrom: mapFrom,
          mapTo: mapTo,
          validator: validator,
          overrideValue: overrideValue,
          possibleValues: possibleValues,
        ),
      );

  static AutoDisposeAsyncNotifierProvider<AutoDisposePreferencesNotifier<T, P>, T> createAutoDispose<T, P>(
    String key,
    T defaultValue, {
    T Function(P value)? mapFrom,
    P Function(T value)? mapTo,
    bool Function(T value)? validator,
    T? overrideValue,
  }) =>
      AutoDisposeAsyncNotifierProvider<AutoDisposePreferencesNotifier<T, P>, T>(
        () => AutoDisposePreferencesNotifier._(
          key: key,
          defaultValue: defaultValue,
          mapFrom: mapFrom,
          mapTo: mapTo,
          validator: validator,
          overrideValue: overrideValue,
          possibleValues: null,
        ),
      );

  P raw() {
    final currentState = state;
    final value = overrideValue ?? (currentState.hasValue ? currentState.value! : defaultValue);
    if (mapTo != null) return mapTo!(value);
    return value as P;
  }

  /// 使用原始类型更新值（会自动进行类型转换）
  /// 这是 update((_) => mapFrom(input)) 的便捷方法
  Future<void> updateRaw(P input) async {
    if (mapFrom != null) {
      await update((_) => mapFrom!(input));
    } else {
      await update((_) => input as T);
    }
  }

  @override
  Future<T> update(FutureOr<T> Function(T) cb, {Object? updateId, void Function(Object, StackTrace)? onError}) async {
    final currentValue = state.hasValue ? state.value! : defaultValue;
    final newValue = await cb(currentValue);
    final entry = await _getEntry();
    if (await entry.write(newValue)) {
      state = AsyncValue.data(newValue);
    }
    return newValue;
  }

  /// 直接更新为指定值
  /// 这是 update((_) => value) 的便捷方法
  Future<void> updateValue(T value) async {
    await update((_) => value);
  }

  Future<void> reset() async {
    final entry = await _getEntry();
    await entry.remove();
    ref.invalidateSelf();
  }
}

class AutoDisposePreferencesNotifier<T, P> extends AutoDisposeAsyncNotifier<T> {
  AutoDisposePreferencesNotifier._({
    required this.key,
    required this.defaultValue,
    this.mapFrom,
    this.mapTo,
    this.validator,
    this.overrideValue,
    this.possibleValues,
  });

  final String key;
  final T defaultValue;
  final T Function(P value)? mapFrom;
  final P Function(T value)? mapTo;
  final bool Function(T value)? validator;
  final T? overrideValue;
  final List<T>? possibleValues;
  
  GchPrefEntry<T, P>? _entry;
  Completer<GchPrefEntry<T, P>>? _entryCompleter;

  @override
  Future<T> build() async {
    // 如果有覆盖值，直接返回
    if (overrideValue != null) {
      return overrideValue!;
    }

    try {
      // 异步获取Store并创建GchPrefEntry
      final store = await ref.read(gchStoreProvider.future);
      _entry = GchPrefEntry<T, P>(
        preferences: store,
        key: key,
        defaultValue: defaultValue,
        mapFrom: mapFrom,
        mapTo: mapTo,
        validator: validator,
      );
      
      // 读取持久化的值
      return await _entry!.read();
    } catch (e) {
      // 出错时返回默认值
      return defaultValue;
    }
  }

  Future<GchPrefEntry<T, P>> _getEntry() async {
    // 如果已经初始化完成，直接返回
    if (_entry != null) return _entry!;
    
    // 如果正在初始化，等待初始化完成
    if (_entryCompleter != null) {
      return await _entryCompleter!.future;
    }
    
    // 开始初始化
    _entryCompleter = Completer<GchPrefEntry<T, P>>();
    
    try {
      final store = await ref.read(gchStoreProvider.future);
      _entry = GchPrefEntry<T, P>(
        preferences: store,
        key: key,
        defaultValue: defaultValue,
        mapFrom: mapFrom,
        mapTo: mapTo,
        validator: validator,
      );
      
      // 完成初始化
      _entryCompleter!.complete(_entry!);
      return _entry!;
    } catch (error, stackTrace) {
      // 初始化失败，清理状态并传播错误
      _entryCompleter!.completeError(error, stackTrace);
      _entryCompleter = null;
      rethrow;
    }
  }

  @override
  Future<T> update(FutureOr<T> Function(T) cb, {Object? updateId, void Function(Object, StackTrace)? onError}) async {
    final currentValue = state.hasValue ? state.value! : defaultValue;
    final newValue = await cb(currentValue);
    final entry = await _getEntry();
    if (await entry.write(newValue)) {
      state = AsyncValue.data(newValue);
    }
    return newValue;
  }

  P raw() {
    final currentState = state;
    final value = overrideValue ?? (currentState.hasValue ? currentState.value! : defaultValue);
    if (mapTo != null) return mapTo!(value);
    return value as P;
  }

  Future<void> updateRaw(P input) async {
    await update((_) => mapFrom != null ? mapFrom!(input) : input as T);
  }

  /// 直接更新为指定值
  /// 这是 update((_) => value) 的便捷方法
  Future<void> updateValue(T value) async {
    await update((_) => value);
  }

  Future<void> reset() async {
    final entry = await _getEntry();
    await entry.remove();
    ref.invalidateSelf();
  }
}
