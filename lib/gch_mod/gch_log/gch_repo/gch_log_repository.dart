import 'dart:async';
import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:watcher/watcher.dart';
import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';
import 'package:guichao/gch_base/gch_kit/gch_catch.dart';
import 'package:guichao/gch_mod/gch_log/gch_repo/gch_log_parser.dart';
import 'package:guichao/gch_mod/gch_log/gch_repo/gch_log_path_resolver.dart';
import 'package:guichao/gch_mod/gch_log/gch_model/gch_log_entity.dart';
import 'package:guichao/gch_mod/gch_log/gch_model/gch_log_failure.dart';
import 'package:guichao/gch_aux/gch_log_mix.dart';

abstract interface class GchTraceArchive {
  TaskEither<GchTraceFault, Unit> init();
  Stream<Either<GchTraceFault, List<GchTraceEntry>>> streamLogs();
  TaskEither<GchTraceFault, Unit> purgeLogs();
}

class GchTraceArchiveImpl
    with GchErrHandler, GchInfraLogger
    implements GchTraceArchive {
  GchTraceArchiveImpl({
    required this.logPathResolver,
  });

  final GchTraceLocator logPathResolver;

  StreamSubscription? _appWatcher;
  StreamSubscription? _coreWatcher;
  bool _disposed = false;
  bool _initialized = false;

  /// 正在滚动的文件路径集合，防止同一文件并发滚动
  final Set<String> _rotatingFiles = {};

  /// 强制截断阈值：50MB（滚动失败时的最后防线）
  static const int _forceCleanupThreshold = 50 * 1024 * 1024;

  @override
  TaskEither<GchTraceFault, Unit> init() {
    return exceptionHandler(
      () async {
        if (_disposed) {
          return left(GchTraceUnexpected('Repository already disposed'));
        }

        // 确保目录存在
        final dir = logPathResolver.directory;
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        // 初始化日志文件
        final coreFile = await logPathResolver.coreFile();
        await _checkFileExists(coreFile);
        await _checkFileExists(logPathResolver.appFile());

        _initialized = true;

        // 启动时清理：检查并处理过大的日志文件
        await _cleanupOnStartup(coreFile);
        await _cleanupOnStartup(logPathResolver.appFile());

        await _startRoller();

        return right(unit);
      },
      GchTraceUnexpected.new,
    );
  }

  Future<void> _checkFileExists(File file) async {
    try {
      if (await file.exists()) {
        await file.writeAsString('');
      } else {
        await file.create(recursive: true);
      }
    } catch (e, s) {
      loggy.warning('创建日志文件失败: ${file.path}', e, s);
    }
  }

  @override
  Stream<Either<GchTraceFault, List<GchTraceEntry>>> streamLogs() async* {
    if (_disposed || !_initialized) {
      yield left(GchTraceUnexpected('Repository not initialized or disposed'));
      return;
    }

    // VPN kernel removed — yield empty stream; log tail via file watcher instead
    yield right(<GchTraceEntry>[]);
  }

  @override
  TaskEither<GchTraceFault, Unit> purgeLogs() {
    return exceptionHandler(
      () async {
        final coreFile = await logPathResolver.coreFile();
        await _checkFileExists(coreFile);
        await _checkFileExists(logPathResolver.appFile());
        return right(unit);
      },
      GchTraceFault.unexpected,
    );
  }

  // ========== 日志滚动 ==========

  Future<void> _startRoller() async {
    if (_disposed || !_initialized) return;

    try {
      final appFile = logPathResolver.appFile();
      final coreFile = await logPathResolver.coreFile();

      // 确保文件存在后再监控
      if (await appFile.exists()) {
        _appWatcher = Watcher(appFile.path).events.listen(
          (event) {
            if (_disposed) return;
            if (event.type == ChangeType.MODIFY) {
              _checkRotate(appFile);
            }
          },
          onError: (Object e, StackTrace s) => loggy.warning('app.log 监控错误', e, s),
          cancelOnError: false,
        );
      }

      if (await coreFile.exists()) {
        _coreWatcher = Watcher(coreFile.path).events.listen(
          (event) {
            if (_disposed) return;
            if (event.type == ChangeType.MODIFY) {
              _checkRotate(coreFile);
            }
          },
          onError: (Object e, StackTrace s) => loggy.warning('box.log 监控错误', e, s),
          cancelOnError: false,
        );
      }

      loggy.info('日志滚动监控已启动');
    } catch (e, s) {
      loggy.error('日志滚动监控启动失败', e, s);
    }
  }

  Future<void> _checkRotate(File file) async {
    if (_disposed) return;

    final path = file.path;

    // 并发锁：如果该文件正在滚动，跳过本次检查
    if (_rotatingFiles.contains(path)) {
      return;
    }

    try {
      if (!await file.exists()) return;

      final size = await file.length();
      const maxSize = GchNucleus.logUploadSize; // 10MB

      if (size >= maxSize) {
        await _rotate(file);
        // 注：_rotate 内部已处理失败时的强制截断逻辑
      }
    } catch (e, s) {
      loggy.error('检查日志大小失败', e, s);
    }
  }

  Future<void> _rotate(File file) async {
    if (_disposed) return;

    final path = file.path;

    // 并发锁：获取锁，如果已被锁定则跳过
    if (_rotatingFiles.contains(path)) {
      loggy.debug('文件正在滚动中，跳过: $path');
      return;
    }

    _rotatingFiles.add(path);

    try {
      const maxBackups = 3;

      // 删除最老备份
      final oldest = File('$path.$maxBackups');
      if (await oldest.exists()) {
        await oldest.delete();
      }

      // 滚动重命名
      for (int i = maxBackups - 1; i >= 1; i--) {
        final current = File('$path.$i');
        if (await current.exists()) {
          await current.rename('$path.${i + 1}');
        }
      }

      // 当前文件重命名为 .1
      if (await file.exists()) {
        await file.rename('$path.1');
      }

      // 创建新文件
      await File(path).create();

      loggy.info('日志滚动完成: $path');
    } catch (e, s) {
      loggy.error('日志滚动失败: $path', e, s);

      // 滚动失败时，尝试强制截断防止文件无限增长
      try {
        if (await file.exists()) {
          final size = await file.length();
          if (size >= _forceCleanupThreshold) {
            loggy.warning('滚动失败，执行强制截断: $path');
            await _forceTruncate(file);
          }
        }
      } catch (_) {
        // 忽略截断时的错误
      }
    } finally {
      // 释放锁
      _rotatingFiles.remove(path);
    }
  }

  /// 启动时清理：检查过大的日志文件
  Future<void> _cleanupOnStartup(File file) async {
    try {
      if (!await file.exists()) return;

      final size = await file.length();
      final path = file.path;

      // 清理过多的备份文件（保留最多3个）
      await _cleanupExcessBackups(path, 3);

      // 如果主文件超过阈值，强制截断
      if (size >= _forceCleanupThreshold) {
        loggy.warning('启动时发现过大日志文件，执行清理: $path ($size bytes)');
        await _forceTruncate(file);
      } else if (size >= GchNucleus.logUploadSize) {
        // 正常大小但需要滚动
        await _rotate(file);
      }
    } catch (e, s) {
      loggy.warning('启动清理失败: ${file.path}', e, s);
    }
  }

  /// 清理过多的备份文件
  Future<void> _cleanupExcessBackups(String basePath, int maxBackups) async {
    try {
      // 检查并删除超出限制的备份文件
      for (int i = maxBackups + 1; i <= 10; i++) {
        final backupFile = File('$basePath.$i');
        if (await backupFile.exists()) {
          await backupFile.delete();
          loggy.info('删除多余备份文件: $basePath.$i');
        }
      }
    } catch (e) {
      loggy.warning('清理备份文件失败: $basePath', e);
    }
  }

  /// 强制截断文件（最后防线）
  /// 当正常滚动失败时，直接截断文件防止无限增长
  Future<void> _forceTruncate(File file) async {
    try {
      final path = file.path;

      // 先尝试备份当前内容的尾部（保留最后1MB供调试）
      const keepSize = 1024 * 1024; // 1MB
      final size = await file.length();

      if (size > keepSize) {
        final raf = await file.open(mode: FileMode.read);
        try {
          // 读取文件尾部
          await raf.setPosition(size - keepSize);
          final tailContent = await raf.read(keepSize);
          await raf.close();

          // 写回尾部内容
          await file.writeAsBytes(tailContent);
          loggy.info('强制截断完成，保留尾部 $keepSize bytes: $path');
        } catch (e) {
          await raf.close();
          // 如果读取失败，直接清空
          await file.writeAsString('');
          loggy.info('强制清空日志文件: $path');
        }
      } else {
        // 文件较小，直接清空
        await file.writeAsString('');
        loggy.info('清空日志文件: $path');
      }
    } catch (e, s) {
      loggy.error('强制截断失败', e, s);
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;

    loggy.info('释放日志仓库资源');

    _appWatcher?.cancel();
    _appWatcher = null;
    _coreWatcher?.cancel();
    _coreWatcher = null;
    _rotatingFiles.clear();
  }
}
