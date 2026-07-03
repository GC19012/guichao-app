
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';

import 'gch_kv_ex.dart';
import 'gch_kv_mgr.dart';

/// 简化的KV盒子操作类
class GchKvBox<T> {
  final String _name;
  final bool _encrypted;
  final bool _lazy;

  // 内部状态
  Box<T>? _box;
  LazyBox<T>? _lazyBox;
  bool _disposed = false;

  GchKvBox._(this._name, {bool encrypted = false, bool lazy = false})
      : _encrypted = encrypted,
        _lazy = lazy;

  /// 创建盒子实例
  static Future<GchKvBox<T>> create<T>(
    String name, {
    bool encrypted = false,
    bool lazy = false,
  }) async {
    final box = GchKvBox<T>._(name, encrypted: encrypted, lazy: lazy);
    await box._initialize();
    return box;
  }

  /// 初始化盒子
  Future<void> _initialize() async {
    try {
      final manager = await GchKvMgr.getInstance();

      if (_lazy) {
        _lazyBox = await manager.openLazyBox<T>(_name, encrypted: _encrypted);
      } else {
        _box = await manager.openBox<T>(_name, encrypted: _encrypted);
      }
    } catch (e, stack) {
      throw GchKvBoxEx(
        'Failed to initialize GchKvBox: $_name',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// 存储数据
  Future<void> put(String key, T value) async {
    _checkDisposed();
    _validateKey(key);
    _validateValue(value);

    try {
      if (_lazy) {
        final box = _lazyBox;
        if (box == null || !box.isOpen) {
          throw GchKvBoxEx('Lazy box is not available');
        }
        await box.put(key, value);
      } else {
        final box = _box;
        if (box == null || !box.isOpen) {
          throw GchKvBoxEx('Box is not available');
        }
        await box.put(key, value);
      }
    } catch (e, stack) {
      throw GchKvStorageEx(
        'Failed to put value for key: $key',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// 获取数据
  Future<T?> get(String key, {T? defaultValue}) async {
    _checkDisposed();
    _validateKey(key);

    try {
      if (_lazy) {
        final box = _lazyBox;
        if (box == null || !box.isOpen) {
          return defaultValue;
        }
        return await box.get(key, defaultValue: defaultValue);
      } else {
        final box = _box;
        if (box == null || !box.isOpen) {
          return defaultValue;
        }
        return box.get(key, defaultValue: defaultValue);
      }
    } catch (e, stack) {
      throw GchKvStorageEx(
        'Failed to get value for key: $key',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// 同步获取数据 [已弃用 - 可能阻塞UI线程]
  @Deprecated('使用异步的 get() 方法避免阻塞UI线程')
  T? getSync(String key, {T? defaultValue}) {
    _checkDisposed();
    _validateKey(key);

    try {
      if (_lazy) {
        // Lazy box 不支持同步操作
        throw GchKvBoxEx('LazyBox does not support sync operations');
      } else {
        final box = _box;
        if (box == null || !box.isOpen) {
          return defaultValue;
        }
        return box.get(key, defaultValue: defaultValue);
      }
    } catch (e, stack) {
      throw GchKvStorageEx(
        'Failed to get sync value for key: $key',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// 同步存储数据 [已弃用 - 可能阻塞UI线程]
  @Deprecated('使用异步的 put() 方法避免阻塞UI线程')
  void putSync(String key, T value) {
    _checkDisposed();
    _validateKey(key);
    _validateValue(value);

    try {
      if (_lazy) {
        // Lazy box 不支持同步操作
        throw GchKvBoxEx('LazyBox does not support sync operations');
      } else {
        final box = _box;
        if (box == null || !box.isOpen) {
          throw GchKvBoxEx('Box is not available');
        }
        box.put(key, value);
      }
    } catch (e, stack) {
      throw GchKvStorageEx(
        'Failed to put sync value for key: $key',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// 删除数据
  Future<void> delete(String key) async {
    _checkDisposed();
    _validateKey(key);

    try {
      if (_lazy) {
        final box = _lazyBox;
        if (box == null || !box.isOpen) {
          throw GchKvBoxEx('Lazy box is not available');
        }
        await box.delete(key);
      } else {
        final box = _box;
        if (box == null || !box.isOpen) {
          throw GchKvBoxEx('Box is not available');
        }
        await box.delete(key);
      }
    } catch (e, stack) {
      throw GchKvStorageEx(
        'Failed to delete key: $key',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// 批量存储
  Future<void> putAll(Map<String, T> entries) async {
    _checkDisposed();

    if (entries.isEmpty) return;

    // 验证所有键值对
    for (final entry in entries.entries) {
      _validateKey(entry.key);
      _validateValue(entry.value);
    }

    try {
      if (_lazy) {
        final box = _lazyBox;
        if (box == null || !box.isOpen) {
          throw GchKvBoxEx('Lazy box is not available');
        }

        // 对于懒加载盒子，逐个插入与给UI线程喂息机会
        for (final entry in entries.entries) {
          await box.put(entry.key, entry.value);
          // 在批量操作中给UI线程喂息机会
          if (entries.length > 50) {
            await Future.delayed(const Duration(microseconds: 1));
          }
        }
      } else {
        final box = _box;
        if (box == null || !box.isOpen) {
          throw GchKvBoxEx('Box is not available');
        }
        await box.putAll(entries);
      }
    } catch (e, stack) {
      throw GchKvStorageEx(
        'Failed to put multiple entries',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// 检查键是否存在
  Future<bool> containsKey(String key) async {
    _checkDisposed();
    _validateKey(key);

    try {
      if (_lazy) {
        final box = _lazyBox;
        if (box == null || !box.isOpen) return false;
        return box.containsKey(key);
      } else {
        final box = _box;
        if (box == null || !box.isOpen) return false;
        return box.containsKey(key);
      }
    } catch (e) {
      return false;
    }
  }

  /// 获取所有键
  Future<Iterable<String>> getKeys() async {
    _checkDisposed();

    try {
      if (_lazy) {
        final box = _lazyBox;
        if (box == null || !box.isOpen) return <String>[];
        return box.keys.cast<String>();
      } else {
        final box = _box;
        if (box == null || !box.isOpen) return <String>[];
        return box.keys.cast<String>();
      }
    } catch (e, stack) {
      throw GchKvStorageEx(
        'Failed to get keys',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// 获取所有值（仅支持非懒加载盒子）
  Future<Iterable<T>> getValues() async {
    _checkDisposed();

    if (_lazy) {
      throw GchKvEx('Cannot get all values from lazy box');
    }

    try {
      final box = _box;
      if (box == null || !box.isOpen) return <T>[];
      return box.values;
    } catch (e, stack) {
      throw GchKvStorageEx(
        'Failed to get values',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// 获取盒子长度
  Future<int> getLength() async {
    _checkDisposed();

    try {
      if (_lazy) {
        final box = _lazyBox;
        if (box == null || !box.isOpen) return 0;
        return box.length;
      } else {
        final box = _box;
        if (box == null || !box.isOpen) return 0;
        return box.length;
      }
    } catch (e) {
      return 0;
    }
  }

  /// 清空盒子
  Future<void> clear() async {
    _checkDisposed();

    try {
      if (_lazy) {
        final box = _lazyBox;
        if (box == null || !box.isOpen) {
          throw GchKvBoxEx('Lazy box is not available');
        }
        await box.clear();
      } else {
        final box = _box;
        if (box == null || !box.isOpen) {
          throw GchKvBoxEx('Box is not available');
        }
        await box.clear();
      }
    } catch (e, stack) {
      throw GchKvStorageEx(
        'Failed to clear box',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// 监听变化事件（仅支持非懒加载盒子）
  Stream<BoxEvent> watch({String? key}) {
    _checkDisposed();

    if (_lazy) {
      throw GchKvEx('Cannot watch lazy box events');
    }

    final box = _box;
    if (box == null || !box.isOpen) {
      return Stream.empty();
    }

    return box.watch(key: key);
  }

  /// 获取盒子统计信息
  Future<KvBoxStats> getStats() async {
    _checkDisposed();

    try {
      final length = await getLength();
      final keys = await getKeys();

      return KvBoxStats(
        name: _name,
        encrypted: _encrypted,
        lazy: _lazy,
        length: length,
        keyCount: keys.length,
        isOpen: _isOpen(),
      );
    } catch (e, stack) {
      throw GchKvStorageEx(
        'Failed to get box stats',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// 关闭盒子
  Future<void> dispose() async {
    if (_disposed) return;

    try {
      // 先关闭盒子，再清理引用
      if (_lazy) {
        final box = _lazyBox;
        if (box != null && box.isOpen) {
          await box.close();
        }
        _lazyBox = null;
      } else {
        final box = _box;
        if (box != null && box.isOpen) {
          await box.close();
        }
        _box = null;
      }

      _disposed = true;
    } catch (e) {
      // 关闭失败不抛异常，但记录错误
      print('Warning: Failed to close GchKvBox $_name: $e');
    }
  }

  // ========== 私有辅助方法 ==========

  void _checkDisposed() {
    if (_disposed) {
      throw GchKvEx('GchKvBox has been disposed');
    }
  }

  void _validateKey(String key) {
    if (key.isEmpty) {
      throw GchKvEx('Key cannot be empty');
    }
  }

  void _validateValue(T? value) {
    if (value == null) {
      throw GchKvEx('Value cannot be null');
    }
  }

  bool _isOpen() {
    if (_lazy) {
      return _lazyBox?.isOpen ?? false;
    } else {
      return _box?.isOpen ?? false;
    }
  }
}

/// 盒子统计信息
class KvBoxStats {
  final String name;
  final bool encrypted;
  final bool lazy;
  final int length;
  final int keyCount;
  final bool isOpen;
  final DateTime timestamp;

  KvBoxStats({
    required this.name,
    required this.encrypted,
    required this.lazy,
    required this.length,
    required this.keyCount,
    required this.isOpen,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    return 'KvBoxStats(name: $name, length: $length, encrypted: $encrypted, lazy: $lazy, open: $isOpen)';
  }
}
