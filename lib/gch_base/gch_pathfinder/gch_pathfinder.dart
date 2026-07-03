import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guichao/gch_base/gch_schema/gch_dirs.dart';
import 'package:guichao/gch_base/gch_bridge/gch_channel_ext.dart';
import 'package:guichao/gch_aux/gch_log_mix.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gch_pathfinder.g.dart';

@Riverpod(keepAlive: true)
class GchPathfinder extends _$GchPathfinder with GchInfraLogger {
  static const _iosChannel = MethodChannel("com.example.app/gch.pf");
  static const _defaultChannel = MethodChannel("com.example.app/gch.pf");

  MethodChannel get _bridge => Platform.isIOS ? _iosChannel : _defaultChannel;

  static const _probeTimeout = Duration(seconds: 3);

  @override
  Future<GchDirs> build() async {
    loggy.debug("开始初始化目录...");

    final GchDirs dirs;
    if (Platform.isIOS) {
      dirs = await _resolveIosPaths();
    } else {
      dirs = await _resolveStdPaths();
    }

    unawaited(_ensurePaths(dirs));

    loggy.debug("目录初始化完成，延迟创建已安排");
    return dirs;
  }

  Future<GchDirs> _resolveStdPaths() async {
    try {
      final baseDir = await getApplicationSupportDirectory()
          .timeout(_probeTimeout);

      final workingDir = baseDir;

      final tempDir = await getTemporaryDirectory()
          .timeout(_probeTimeout);

      return (
        baseDir: baseDir,
        workingDir: workingDir,
        tempDir: tempDir,
      );
    } catch (e) {
      loggy.warning('目录获取失败或超时: $e，使用备用方案');
      return await _resolveFallback();
    }
  }

  Future<GchDirs> _resolveFallback() async {
    try {
      final tempDir = await getTemporaryDirectory()
          .timeout(const Duration(seconds: 2));
      final appDir = Directory('${tempDir.path}/guichao_app');
      return (
        baseDir: appDir,
        workingDir: appDir,
        tempDir: tempDir,
      );
    } catch (e) {
      loggy.error('备用目录方案也失败: $e');
      final currentDir = Directory.current;
      return (
        baseDir: currentDir,
        workingDir: currentDir,
        tempDir: currentDir,
      );
    }
  }

  Future<GchDirs> _resolveIosPaths() async {
    try {
      final result = await _bridge
          .invokeTask<Map>("gch_resolve_paths")
          .run()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => left("Timeout"),
          );

      return result.fold(
        (error) {
          loggy.warning("获取iOS路径失败: $error，使用默认路径");
          return _resolveDefaults();
        },
        (paths) async {
          if (paths == null) {
            loggy.warning("iOS路径为空，回退到默认路径");
            return await _resolveDefaults();
          }

          final basePath = paths["base"] as String?;
          final workingPath = paths["working"] as String?;
          final tempPath = paths["temp"] as String?;

          if (basePath == null || workingPath == null || tempPath == null) {
            loggy.warning("iOS路径不完整，回退到默认路径");
            return await _resolveDefaults();
          }

          loggy.debug("iOS paths: $paths");
          return (
            baseDir: Directory(basePath),
            workingDir: Directory(workingPath),
            tempDir: Directory(tempPath),
          );
        },
      );
    } catch (e) {
      loggy.warning("获取iOS路径异常: $e，使用默认路径");
      return await _resolveDefaults();
    }
  }

  Future<GchDirs> _resolveDefaults() async {
    final baseDir = await getApplicationSupportDirectory();
    final tempDir = await getTemporaryDirectory();
    return (
      baseDir: baseDir,
      workingDir: baseDir,
      tempDir: tempDir,
    );
  }

  Future<void> _ensurePaths(GchDirs dirs) async {
    try {
      final futures = <Future<void>>[];

      if (!(await dirs.baseDir.exists())) {
        loggy.debug("创建baseDir: ${dirs.baseDir.path}");
        futures.add(dirs.baseDir.create(recursive: true));
      }

      if (!(await dirs.workingDir.exists())) {
        loggy.debug("创建workingDir: ${dirs.workingDir.path}");
        futures.add(dirs.workingDir.create(recursive: true));
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
        loggy.debug("所有目录创建完成");
      } else {
        loggy.debug("所有目录已存在，无需创建");
      }
    } catch (e, stackTrace) {
      loggy.error("目录创建失败，但不影响应用启动", e, stackTrace);
    }
  }

  static Future<Directory> locateDbPath() async {
    if (Platform.isIOS) {
      try {
        final result = await _iosChannel.invokeMethod<Map>('gch_resolve_paths');
        final basePath = result?['base'] as String?;
        if (basePath != null) return Directory(basePath);
      } catch (_) {
        // fall through to default
      }
    }
    return getLibraryDirectory();
  }
}
