import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';
import 'package:guichao/gch_aux/gch_crash_report/gch_reporter.dart';

/// ANR 检测和预防工具
/// 专门用于检测和解决主线程阻塞问题
class ANRDetector {
  static final ANRDetector _instance = ANRDetector._internal();
  factory ANRDetector() => _instance;
  ANRDetector._internal();

  Timer? _memoryPressureTimer;
  bool _isWatching = false;
  bool _frameCallbackRegistered = false;
  // ✅ 添加disposed标志防止重复操作
  bool _disposed = false;

  /// ANR检测阈值 (通过帧回调监控，不再需要watchdog timer)
  static const Duration kANRThreshold = Duration(seconds: 3);
  // ✅ 内存检查间隔从5秒优化到1分钟，减少92%的CPU开销
  static const Duration kMemoryCheckInterval = Duration(minutes: 1);

  /// 启动ANR检测
  void startWatching() {
    if (_isWatching || !GchNucleus.isDevMode) return;
    _isWatching = true;

    debugPrint('🔍 启动ANR检测器');

    // 1. 帧率监控（同时监控主线程响应性）
    _startFrameRateMonitoring();

    // 2. 内存压力监控（降低频率，1分钟检查一次）
    _startMemoryPressureMonitoring();
  }

  /// 内存压力监控
  void _startMemoryPressureMonitoring() {
    _memoryPressureTimer = Timer.periodic(kMemoryCheckInterval, (_) {
      _checkMemoryPressure();
    });
  }

  /// 帧率监控
  void _startFrameRateMonitoring() {
    if (!_frameCallbackRegistered) {
      SchedulerBinding.instance.addPersistentFrameCallback(_frameCallback);
      _frameCallbackRegistered = true;
    }
  }

  Duration? _lastFrameTime;
  int _jankFrames = 0;
  int _totalFrames = 0;

  void _frameCallback(Duration timestamp) {
    if (!_isWatching || !_frameCallbackRegistered) return;

    if (_lastFrameTime != null) {
      final frameDuration = timestamp - _lastFrameTime!;
      _totalFrames++;

      // 检测掉帧 (超过16.67ms * 2 = 33.34ms)
      if (frameDuration.inMilliseconds > 33) {
        _jankFrames++;

        // 严重掉帧
        if (frameDuration.inMilliseconds > 100) {
          debugPrint('⚠️ 严重掉帧检测: ${frameDuration.inMilliseconds}ms');

          // 上报严重掉帧事件
          if (ErrorReporterFactory.hasReporter) {
            ErrorReporterFactory.instance!.addBreadcrumb(
              message: '严重掉帧: ${frameDuration.inMilliseconds}ms',
              category: 'performance',
              data: {
                'frame_duration_ms': frameDuration.inMilliseconds,
                'jank_frames': _jankFrames,
                'total_frames': _totalFrames,
              },
              level: ErrorLevel.warning,
            );
          }

          _emergencyGCRelief();
        }
      }

      // 每100帧报告一次
      if (_totalFrames % 100 == 0) {
        final jankRate = (_jankFrames / _totalFrames * 100).toStringAsFixed(1);
        if (double.parse(jankRate) > 10) {
          debugPrint('📊 掉帧率: $jankRate% ($_jankFrames/$_totalFrames)');

          // 上报高掉帧率
          if (ErrorReporterFactory.hasReporter && double.parse(jankRate) > 20) {
            ErrorReporterFactory.instance!.recordMessage(
              '高掉帧率检测: $jankRate%',
              level: ErrorLevel.warning,
              extras: {
                'jank_rate': jankRate,
                'jank_frames': _jankFrames,
                'total_frames': _totalFrames,
              },
            );
          }
        }
      }
    }
    _lastFrameTime = timestamp;
  }

  /// 紧急GC释放（严重掉帧时触发）
  void _emergencyGCRelief() {
    try {
      // 强制垃圾回收
      SchedulerBinding.instance.addPostFrameCallback((_) {
        // 清理图片缓存
        if (PaintingBinding.instance.imageCache.currentSize > 50) {
          PaintingBinding.instance.imageCache.clear();
          debugPrint('🧹 清理图片缓存');
        }
      });
    } catch (e) {
      debugPrint('GC清理失败: $e');
    }
  }

  /// 检查内存压力
  void _checkMemoryPressure() {
    final imageCache = PaintingBinding.instance.imageCache;
    final cacheSize = imageCache.currentSize;
    final maxSize = imageCache.maximumSize;

    if (cacheSize > maxSize * 0.8) {
      debugPrint('⚠️ 内存压力高: 图片缓存 $cacheSize/$maxSize');
      imageCache.clear();
    }
  }

  /// 停止监控
  void stopWatching() {
    if (!_isWatching && !_disposed) return;

    // ✅ 清理内存压力检查Timer
    _memoryPressureTimer?.cancel();
    _memoryPressureTimer = null;

    // ✅ 清除FrameCallback标志（回调通过_isWatching和_frameCallbackRegistered双重检查自动忽略）
    if (_frameCallbackRegistered) {
      _frameCallbackRegistered = false;
      debugPrint('✅ FrameCallback标志已清除，回调将被忽略');
    }

    _isWatching = false;
    _disposed = false; // 允许重新启动

    debugPrint('🔍 ANR检测器已停止');
  }

  /// 完全销毁（用于应用退出）
  /// ✅ 修复 CRITICAL 级别的双Timer永久运行
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    stopWatching();

    // 重置统计数据
    _lastFrameTime = null;
    _jankFrames = 0;
    _totalFrames = 0;

    debugPrint('🔍 ANR检测器已销毁');
  }

  /// 手动触发内存清理
  static void manualCleanup() {
    try {
      // 清理图片缓存
      PaintingBinding.instance.imageCache.clear();

      // 清理字体缓存 (Flutter字体缓存API有限，跳过此步骤)
      // 字体缓存无法直接清理，但可以减少新的分配

      debugPrint('🧹 手动内存清理完成');
    } catch (e) {
      debugPrint('手动清理失败: $e');
    }
  }
}

/// ANR 预防扩展
extension ANRPrevention on Widget {
  /// 包装Widget以防止ANR
  Widget preventANR() {
    return Builder(
      builder: (context) {
        // 在第一帧后启动ANR检测
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ANRDetector().startWatching();
        });

        return this;
      },
    );
  }
}

/// 主线程任务分片器
class TaskSlicer {
  /// 将大任务分片执行，避免阻塞主线程
  static Future<void> runSliced<T>(
    Iterable<T> items,
    void Function(T) task, {
    int batchSize = 10,
    Duration delay = const Duration(milliseconds: 1),
  }) async {
    final iterator = items.iterator;

    while (iterator.moveNext()) {
      int count = 0;

      // 执行一批任务
      do {
        task(iterator.current);
        count++;
      } while (count < batchSize && iterator.moveNext());

      // 让出执行权给其他任务
      await Future.delayed(delay);
    }
  }

  /// 异步执行重任务
  static Future<R> runHeavyTask<R>(Future<R> Function() task) {
    final completer = Completer<R>();

    // 在下一帧执行
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        final result = await task();
        completer.complete(result);
      } catch (e) {
        completer.completeError(e);
      }
    });

    return completer.future;
  }
}
