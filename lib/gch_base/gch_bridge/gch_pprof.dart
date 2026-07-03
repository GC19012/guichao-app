import 'dart:convert';

import 'package:guichao/gch_base/gch_bridge/gch_platform_link.dart';
import 'package:guichao/gch_base/gch_kit/gch_loggers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gch_pprof.g.dart';

/// Pprof 运行时统计信息
class PprofRuntimeStats {
  final int goroutines;
  final Map<String, dynamic> memory;
  final Map<String, dynamic> cpu;

  PprofRuntimeStats({
    required this.goroutines,
    required this.memory,
    required this.cpu,
  });

  factory PprofRuntimeStats.fromJson(Map<String, dynamic> json) {
    return PprofRuntimeStats(
      goroutines: json['goroutines'] as int? ?? 0,
      memory: json['memory'] as Map<String, dynamic>? ?? {},
      cpu: json['cpu'] as Map<String, dynamic>? ?? {},
    );
  }

  double get allocMb => (memory['alloc_mb'] as num?)?.toDouble() ?? 0.0;
  double get sysMb => (memory['sys_mb'] as num?)?.toDouble() ?? 0.0;
  int get numGc => memory['num_gc'] as int? ?? 0;
  int get numCpu => cpu['num_cpu'] as int? ?? 0;
}

/// Pprof 性能调试服务
class PprofService with GchInfraLogger {
  final UniversalPlatformBridge _bridge;

  PprofService(this._bridge);

  /// 启动 pprof HTTP 服务器
  ///
  /// [port] 端口号，默认 ":6060"
  /// [dir] profile 文件保存目录，留空使用默认目录
  Future<bool> startServer({String port = ':6060', String? dir}) async {
    try {
      // 构建参数: 如果 dir 为 null,不传递该字段,让原生端使用默认目录 (外部存储)
      final args = <String, dynamic>{'port': port};
      if (dir != null && dir.isNotEmpty) {
        args['dir'] = dir;
      }

      final result = await _bridge.call<bool>('pprof.startServer', args);

      if (result.success) {
        loggy.info('Pprof server started on port $port');
        return result.data ?? false;
      } else {
        loggy.error('Failed to start pprof server: ${result.error}');
        return false;
      }
    } catch (e) {
      loggy.error('Error starting pprof server', e);
      return false;
    }
  }

  /// 停止 pprof HTTP 服务器
  Future<bool> stopServer() async {
    try {
      final result = await _bridge.call<bool>('pprof.stopServer', {});

      if (result.success) {
        loggy.info('Pprof server stopped');
        return result.data ?? false;
      } else {
        loggy.error('Failed to stop pprof server: ${result.error}');
        return false;
      }
    } catch (e) {
      loggy.error('Error stopping pprof server', e);
      return false;
    }
  }

  /// 采集 CPU profile
  ///
  /// [seconds] 采集时长（秒），默认 30 秒
  /// [filename] 文件名，留空自动生成时间戳
  /// 返回保存的文件路径
  Future<String?> collectCpuProfile({int seconds = 30, String filename = ''}) async {
    try {
      loggy.info('Starting CPU profile collection for $seconds seconds...');

      final result = await _bridge.call<String>(
        'pprof.collectCpuProfile',
        {'seconds': seconds, 'filename': filename},
        timeout: Duration(seconds: seconds + 10),
      );

      if (result.success) {
        loggy.info('CPU profile saved to: ${result.data}');
        return result.data;
      } else {
        loggy.error('Failed to collect CPU profile: ${result.error}');
        return null;
      }
    } catch (e) {
      loggy.error('Error collecting CPU profile', e);
      return null;
    }
  }

  /// 采集堆内存 profile
  ///
  /// [filename] 文件名，留空自动生成时间戳
  /// 返回保存的文件路径
  Future<String?> collectHeapProfile({String filename = ''}) async {
    try {
      loggy.info('Collecting heap profile...');

      final result = await _bridge.call<String>(
        'pprof.collectHeapProfile',
        {'filename': filename},
      );

      if (result.success) {
        loggy.info('Heap profile saved to: ${result.data}');
        return result.data;
      } else {
        loggy.error('Failed to collect heap profile: ${result.error}');
        return null;
      }
    } catch (e) {
      loggy.error('Error collecting heap profile', e);
      return null;
    }
  }

  /// 采集 goroutine profile
  ///
  /// [filename] 文件名，留空自动生成时间戳
  /// 返回保存的文件路径
  Future<String?> collectGoroutineProfile({String filename = ''}) async {
    try {
      loggy.info('Collecting goroutine profile...');

      final result = await _bridge.call<String>(
        'pprof.collectGoroutineProfile',
        {'filename': filename},
      );

      if (result.success) {
        loggy.info('Goroutine profile saved to: ${result.data}');
        return result.data;
      } else {
        loggy.error('Failed to collect goroutine profile: ${result.error}');
        return null;
      }
    } catch (e) {
      loggy.error('Error collecting goroutine profile', e);
      return null;
    }
  }

  /// 获取运行时统计信息
  Future<PprofRuntimeStats?> getRuntimeStats() async {
    try {
      final result = await _bridge.call<String>('pprof.getRuntimeStats', {});

      if (result.success && result.data != null) {
        final json = jsonDecode(result.data!) as Map<String, dynamic>;
        return PprofRuntimeStats.fromJson(json);
      } else {
        loggy.error('Failed to get runtime stats: ${result.error}');
        return null;
      }
    } catch (e) {
      loggy.error('Error getting runtime stats', e);
      return null;
    }
  }

  /// 启用阻塞分析
  ///
  /// [rate] 采样率，1 表示记录所有阻塞事件
  Future<bool> enableBlockProfile({int rate = 1}) async {
    try {
      final result = await _bridge.call<bool>(
        'pprof.enableBlockProfile',
        {'rate': rate},
      );

      if (result.success) {
        loggy.info('Block profile enabled with rate: $rate');
        return result.data ?? false;
      } else {
        loggy.error('Failed to enable block profile: ${result.error}');
        return false;
      }
    } catch (e) {
      loggy.error('Error enabling block profile', e);
      return false;
    }
  }

  /// 启用互斥锁分析
  ///
  /// [fraction] 采样分数，1 表示记录所有互斥锁竞争
  Future<bool> enableMutexProfile({int fraction = 1}) async {
    try {
      final result = await _bridge.call<bool>(
        'pprof.enableMutexProfile',
        {'fraction': fraction},
      );

      if (result.success) {
        loggy.info('Mutex profile enabled with fraction: $fraction');
        return result.data ?? false;
      } else {
        loggy.error('Failed to enable mutex profile: ${result.error}');
        return false;
      }
    } catch (e) {
      loggy.error('Error enabling mutex profile', e);
      return false;
    }
  }

  /// 获取 profile 文件列表
  Future<List<String>> getProfileFiles() async {
    try {
      final result = await _bridge.call<List<dynamic>>('pprof.getProfileFiles', {});

      if (result.success && result.data != null) {
        return result.data!.map((e) => e.toString()).toList();
      } else {
        loggy.error('Failed to get profile files: ${result.error}');
        return [];
      }
    } catch (e) {
      loggy.error('Error getting profile files', e);
      return [];
    }
  }

  /// 获取服务器运行状态
  Future<bool> isRunning() async {
    try {
      final result = await _bridge.call<bool>('pprof.isRunning', {});
      return result.data ?? false;
    } catch (e) {
      loggy.error('Error checking server status', e);
      return false;
    }
  }

  /// 获取 profile 目录
  Future<String> getProfileDir() async {
    try {
      final result = await _bridge.call<String>('pprof.getProfileDir', {});
      return result.data ?? '';
    } catch (e) {
      loggy.error('Error getting profile directory', e);
      return '';
    }
  }
}

/// Pprof 服务提供者
@riverpod
PprofService pprofService(PprofServiceRef ref) {
  final bridge = ref.watch(initializedPlatformBridgeProvider).value;
  if (bridge == null) {
    throw StateError('PlatformBridge not initialized');
  }
  return PprofService(bridge);
}

/// Pprof 服务器运行状态提供者
@riverpod
Future<bool> pprofServerStatus(PprofServerStatusRef ref) async {
  final service = ref.watch(pprofServiceProvider);
  return service.isRunning();
}

/// Pprof 运行时统计提供者
@riverpod
Future<PprofRuntimeStats?> pprofRuntimeStats(PprofRuntimeStatsRef ref) async {
  final service = ref.watch(pprofServiceProvider);
  return service.getRuntimeStats();
}
