import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:guichao/gch_base/gch_prefs/gch_store_provider.dart';
import 'package:guichao/gch_base/gch_kit/gch_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 平台桥接结果
class PlatformResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? errorCode;
  final String? callId;
  final DateTime timestamp;

  PlatformResult.success(this.data, {this.callId})
      : success = true,
        error = null,
        errorCode = null,
        timestamp = DateTime.now();

  PlatformResult.failure(this.error, [this.errorCode, this.callId])
      : success = false,
        data = null,
        timestamp = DateTime.now();

  Map<String, dynamic> toMap() => {
        'success': success,
        'data': data,
        'error': error,
        'errorCode': errorCode,
        'callId': callId,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  @override
  String toString() => 'PlatformResult(success: $success, error: $error)';
}

/// 平台桥接接口
abstract class PlatformBridge {
  /// 调用原生方法
  Future<PlatformResult<T>> call<T>(
    String method,
    Map<String, dynamic> arguments, {
    Duration timeout = const Duration(seconds: 30),
  });

  /// 注册Flutter方法供原生调用
  void registerMethod(String name, Function handler);

  /// 注销方法
  void unregisterMethod(String name);

  /// 获取已注册的方法列表
  List<String> getRegisteredMethods();

  /// 释放资源
  void dispose();
}

/// 高级平台桥接实现
class UniversalPlatformBridge with GchInfraLogger implements PlatformBridge {
  static const MethodChannel _channel = MethodChannel('com.example.app/universal_bridge');

  final ProviderContainer _container;
  final Map<String, Function> _registeredMethods = {};
  final Map<String, DateTime> _methodLastUsed = {};
  bool _isDisposed = false;

  // 配置
  static const int _maxCachedMethods = 100;
  static const Duration _methodCacheExpiry = Duration(hours: 1);

  // 性能监控
  int _totalCalls = 0;
  int _successfulCalls = 0;
  int _failedCalls = 0;
  final Map<String, int> _methodCallCounts = {};

  UniversalPlatformBridge(this._container) {
    _channel.setMethodCallHandler(_handleMethodCall);
    _registerCoreMethods();
    loggy.info('UniversalPlatformBridge initialized');
  }

  @override
  Future<PlatformResult<T>> call<T>(
    String method,
    Map<String, dynamic> arguments, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_isDisposed) {
      return PlatformResult.failure('Bridge is disposed', -1);
    }

    if (method.trim().isEmpty) {
      return PlatformResult.failure('Method name cannot be empty', 400);
    }

    _totalCalls++;
    _methodCallCounts[method] = (_methodCallCounts[method] ?? 0) + 1;

    final stopwatch = Stopwatch()..start();

    try {
      final result = await _channel.invokeMethod(method, arguments).timeout(timeout);
      stopwatch.stop();

      _successfulCalls++;

      if (result is Map) {
        final resultMap = Map<String, dynamic>.from(result);
        if (resultMap['success'] == true) {
          return PlatformResult.success(resultMap['data'] as T?, callId: resultMap['callId'] as String?);
        } else {
          return PlatformResult.failure(
            resultMap['error'] as String? ?? 'Unknown error',
            resultMap['errorCode'] as int?,
            resultMap['callId'] as String?,
          );
        }
      }

      return PlatformResult.success(result as T?);
    } on TimeoutException {
      _failedCalls++;
      return PlatformResult.failure('Method call timeout', 408);
    } on PlatformException catch (e) {
      _failedCalls++;
      return PlatformResult.failure(e.message ?? 'Platform error', int.tryParse(e.code));
    } catch (e) {
      _failedCalls++;
      loggy.error('Unexpected error calling method $method', e);
      return PlatformResult.failure('Unexpected error: $e', 500);
    } finally {
      stopwatch.stop();
      loggy.debug('Method $method completed in ${stopwatch.elapsedMilliseconds}ms');
    }
  }

  @override
  void registerMethod(String name, Function handler) {
    if (_isDisposed) {
      throw StateError('Bridge is disposed');
    }

    if (name.trim().isEmpty) {
      throw ArgumentError('Method name cannot be empty');
    }

    _cleanupExpiredMethods();

    _registeredMethods[name] = handler;
    _methodLastUsed[name] = DateTime.now();
    loggy.debug('Registered method: $name');
  }

  @override
  void unregisterMethod(String name) {
    _registeredMethods.remove(name);
    _methodLastUsed.remove(name);
    loggy.debug('Unregistered method: $name');
  }

  @override
  List<String> getRegisteredMethods() {
    return _registeredMethods.keys.toList();
  }

  /// 处理来自原生的方法调用
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (_isDisposed) {
      return PlatformResult.failure('Bridge is disposed', -1).toMap();
    }

    final stopwatch = Stopwatch()..start();
    loggy.debug('Handling native method call: ${call.method}');

    try {
      final methodName = call.method;
      final arguments = call.arguments != null ? Map<String, dynamic>.from(call.arguments as Map) : <String, dynamic>{};

      final handler = _registeredMethods[methodName];
      if (handler == null) {
        if (methodName.startsWith('store.')) {
          return PlatformResult.failure('Store methods not yet initialized, please try again in a moment', 503).toMap();
        }
        return PlatformResult.failure('Method $methodName not found', 404).toMap();
      }

      _methodLastUsed[methodName] = DateTime.now();

      final result = await _executeMethod(handler, arguments);

      loggy.debug('Method $methodName completed in ${stopwatch.elapsedMilliseconds}ms');
      return PlatformResult.success(result).toMap();
    } catch (e, stackTrace) {
      loggy.error('Error in platform bridge method: ${call.method}', e, stackTrace);
      return PlatformResult.failure(e.toString(), 500).toMap();
    } finally {
      stopwatch.stop();
    }
  }

  /// 执行方法（支持同步和异步）
  Future<dynamic> _executeMethod(Function handler, Map<String, dynamic> args) async {
    try {
      final result = handler(args);
      if (result is Future) {
        return await result;
      }
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// 注册核心方法
  void _registerCoreMethods() {
    registerMethod('system.info', _getSystemInfo);
    registerMethod('system.ping', _ping);
    registerMethod('system.stats', _getStats);
  }

  /// 延迟注册Store相关方法（在Store准备就绪后调用）
  Future<void> registerStoreMethods() async {
    try {
      await _container.read(gchStoreProvider.future);

      registerMethod('store.get', _storeGet);
      registerMethod('store.put', _storePut);
      registerMethod('store.delete', _storeDelete);
      registerMethod('store.clear', _storeClear);
      registerMethod('store.has', _storeHas);
      registerMethod('store.keys', _storeKeys);
      registerMethod('store.batch', _storeBatch);
      registerMethod('system.healthCheck', _healthCheck);

      loggy.info('Store methods registered successfully');
    } catch (e) {
      loggy.error('Failed to register store methods', e);
    }
  }

  /// 清理过期的方法缓存
  void _cleanupExpiredMethods() {
    if (_registeredMethods.length < _maxCachedMethods) return;

    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _methodLastUsed.entries) {
      if (now.difference(entry.value) > _methodCacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _registeredMethods.remove(key);
      _methodLastUsed.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      loggy.debug('Cleaned up ${expiredKeys.length} expired methods');
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _channel.setMethodCallHandler(null);
    _registeredMethods.clear();
    _methodLastUsed.clear();
    _methodCallCounts.clear();

    loggy.info('UniversalPlatformBridge disposed');
  }

  /// 获取性能统计
  Map<String, dynamic> _getStats(Map<String, dynamic> args) {
    return {
      'totalCalls': _totalCalls,
      'successfulCalls': _successfulCalls,
      'failedCalls': _failedCalls,
      'successRate': _totalCalls > 0 ? _successfulCalls / _totalCalls : 0.0,
      'registeredMethods': _registeredMethods.length,
      'methodCounts': _methodCallCounts,
      'isDisposed': _isDisposed,
    };
  }

  /// 获取原生日志路径
  Future<String?> getLogPath() async {
    final result = await call<String>('system.logPath', {});
    return result.success ? result.data : null;
  }

  /// 系统信息
  Map<String, dynamic> _getSystemInfo(Map<String, dynamic> args) {
    return {
      'platform': 'flutter',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'version': '2.0.0',
      'registeredMethods': getRegisteredMethods(),
      'stats': _getStats({}),
    };
  }

  /// Ping测试
  Map<String, dynamic> _ping(Map<String, dynamic> args) {
    return {
      'status': 'ok',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'message': 'pong',
      'echo': args,
    };
  }

  // ===================== Store 方法实现 =====================

  Future<dynamic> _storeGet(Map<String, dynamic> args) async {
    final key = args['key'] as String?;
    final defaultValue = args['defaultValue'];

    if (key == null || key.isEmpty) {
      throw ArgumentError('Key is required');
    }

    final store = await _container.read(gchStoreProvider.future);
    final value = await store.get<dynamic>(key);
    return value ?? defaultValue;
  }

  Future<bool> _storePut(Map<String, dynamic> args) async {
    final key = args['key'] as String?;
    final value = args['value'];

    if (key == null || key.isEmpty) {
      throw ArgumentError('Key is required');
    }

    if (value != null) {
      try {
        jsonEncode(value);
      } catch (e) {
        throw ArgumentError('Value is not serializable: $e');
      }
    }

    final store = await _container.read(gchStoreProvider.future);
    return await store.put<dynamic>(key, value);
  }

  Future<bool> _storeDelete(Map<String, dynamic> args) async {
    final key = args['key'] as String?;

    if (key == null || key.isEmpty) {
      throw ArgumentError('Key is required');
    }

    final store = await _container.read(gchStoreProvider.future);
    return await store.delete(key);
  }

  Future<bool> _storeClear(Map<String, dynamic> args) async {
    final store = await _container.read(gchStoreProvider.future);
    return await store.clear();
  }

  Future<bool> _storeHas(Map<String, dynamic> args) async {
    final key = args['key'] as String?;

    if (key == null || key.isEmpty) {
      throw ArgumentError('Key is required');
    }

    final store = await _container.read(gchStoreProvider.future);
    return await store.has(key);
  }

  Future<List<String>> _storeKeys(Map<String, dynamic> args) async {
    final store = await _container.read(gchStoreProvider.future);
    final keys = await store.keys();
    return keys.toList();
  }

  Future<Map<String, dynamic>> _storeBatch(Map<String, dynamic> args) async {
    final operations = args['operations'] as List<dynamic>?;

    if (operations == null) {
      throw ArgumentError('Operations list is required');
    }

    final results = <String, dynamic>{};
    final errors = <String, String>{};

    final store = await _container.read(gchStoreProvider.future);

    for (final op in operations) {
      final operation = op as Map<String, dynamic>;
      final type = operation['type'] as String;
      final key = operation['key'] as String;

      try {
        switch (type) {
          case 'get':
            final defaultValue = operation['defaultValue'];
            final value = await store.get<dynamic>(key);
            results[key] = value ?? defaultValue;
            break;

          case 'put':
            final value = operation['value'];
            final success = await store.put<dynamic>(key, value);
            results[key] = success;
            break;

          case 'delete':
            final success = await store.delete(key);
            results[key] = success;
            break;

          case 'has':
            final exists = await store.has(key);
            results[key] = exists;
            break;

          default:
            throw ArgumentError('Unknown operation type: $type');
        }
      } catch (e) {
        errors[key] = e.toString();
      }
    }

    return {
      'results': results,
      'errors': errors,
      'totalCount': operations.length,
      'successCount': results.length,
      'errorCount': errors.length,
    };
  }

  Future<Map<String, dynamic>> _healthCheck(Map<String, dynamic> args) async {
    final testKey = '__health_check_${DateTime.now().millisecondsSinceEpoch}';
    final testValue = 'health_check_value';

    try {
      final store = await _container.read(gchStoreProvider.future);

      final putSuccess = await store.put(testKey, testValue);
      if (!putSuccess) throw Exception('Put operation failed');

      final getValue = await store.get(testKey);
      if (getValue != testValue) throw Exception('Get operation failed');

      await store.delete(testKey);

      return {'healthy': true, 'timestamp': DateTime.now().millisecondsSinceEpoch, 'message': 'All operations successful'};
    } catch (e) {
      return {'healthy': false, 'timestamp': DateTime.now().millisecondsSinceEpoch, 'error': e.toString()};
    }
  }
}

/// 平台桥接扩展接口
abstract class PlatformBridgeExtension {
  void registerMethods(PlatformBridge bridge);
  void cleanup() {}
}

/// 桥接扩展管理器
class BridgeExtensionManager {
  static final List<PlatformBridgeExtension> _extensions = [];

  static void registerExtension(PlatformBridgeExtension extension) {
    _extensions.add(extension);
  }

  static void initializeExtensions(PlatformBridge bridge) {
    for (final extension in _extensions) {
      try {
        extension.registerMethods(bridge);
      } catch (e) {
        // 记录错误但继续处理其他扩展
        print('Failed to register extension ${extension.runtimeType}: $e');
      }
    }
  }

  static void cleanupExtensions() {
    for (final extension in _extensions) {
      try {
        extension.cleanup();
      } catch (e) {
        print('Error cleaning up extension ${extension.runtimeType}: $e');
      }
    }
    _extensions.clear();
  }
}

/// 平台桥接提供者
final platformBridgeProvider = Provider<UniversalPlatformBridge>((ref) {
  final bridge = UniversalPlatformBridge(ref.container);

  ref.onDispose(() {
    BridgeExtensionManager.cleanupExtensions();
    bridge.dispose();
  });

  return bridge;
});

/// 初始化完成的平台桥接提供者
final initializedPlatformBridgeProvider = FutureProvider<UniversalPlatformBridge>((ref) async {
  final bridge = ref.watch(platformBridgeProvider);
  await bridge.registerStoreMethods();
  BridgeExtensionManager.initializeExtensions(bridge);
  return bridge;
});
