
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';

import 'gch_kv_mgr.dart';
import 'gch_kv_box.dart';
import 'gch_kv_ex.dart';

/// 极简高级 API - 生产级使用
class GchKvApi {
  static GchKvApi? _instance;
  static GchKvApi get I => _instance ??= GchKvApi._();

  GchKvApi._();

  GchKvMgr? _manager;
  bool _initialized = false;

  /// 初始化
  Future<void> init() async {
    if (_initialized) return;

    try {
      _manager = await GchKvMgr.getInstance();
      _initialized = true;
    } catch (e, stack) {
      throw GchKvInitEx(
        'Failed to initialize GchKvApi',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// 注册适配器
  Future<void> adapter<T>(TypeAdapter<T> adapter) async {
    _checkInit();
    await _manager!.registerAdapter(adapter);
  }

  /// 创建盒子
  Future<GchKvBox<T>> box<T>(
    String name, {
    bool secure = false,
    bool lazy = false,
  }) async {
    _checkInit();
    return await GchKvBox.create<T>(
      name,
      encrypted: secure,
      lazy: lazy,
    );
  }

  /// 删除盒子
  Future<void> deleteBox(String name) async {
    _checkInit();
    await _manager!.deleteBox(name);
  }

  /// 检查盒子是否存在
  Future<bool> exists(String name) async {
    _checkInit();
    return await _manager!.boxExists(name);
  }

  /// 获取所有盒子信息
  Future<List<GchKvBoxInfo>> getAllBoxes() async {
    _checkInit();
    return await _manager!.getAllBoxInfo();
  }

  /// 执行健康检查
  Future<GchKvHealthReport> checkHealth(String name) async {
    _checkInit();
    return await _manager!.checkBoxHealth(name);
  }

  /// 关闭所有资源
  Future<void> dispose() async {
    if (_manager != null) {
      await _manager!.dispose();
      _manager = null;
    }
    _initialized = false;
  }

  void _checkInit() {
    if (!_initialized || _manager == null) {
      throw GchKvInitEx('GchKvApi not initialized. Call init() first.');
    }
  }
}

/// 全局便捷函数
final gchKv = GchKvApi.I;

/// 创建盒子的便捷函数
Future<GchKvBox<T>> gchOpenKvBox<T>(
  String name, {
  bool secure = false,
  bool lazy = false,
}) async {
  return await gchKv.box<T>(name, secure: secure, lazy: lazy);
}
