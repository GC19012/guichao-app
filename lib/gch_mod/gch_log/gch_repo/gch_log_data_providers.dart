import 'dart:async';

import 'package:guichao/gch_base/gch_pathfinder/gch_pathfinder.dart';
import 'package:guichao/gch_base/gch_bridge/gch_platform_link.dart';
import 'package:guichao/gch_mod/gch_log/gch_repo/gch_log_path_resolver.dart';
import 'package:guichao/gch_mod/gch_log/gch_repo/gch_log_repository.dart';
import 'package:guichao/gch_aux/gch_log_mix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gch_log_data_providers.g.dart';

@Riverpod(keepAlive: true)
Future<GchTraceArchive> gchTraceArchive(GchTraceArchiveRef ref) async {
  final repo = GchTraceArchiveImpl(
    logPathResolver: ref.watch(gchTraceLocatorProvider),
  );

  // 注册资源清理回调
  ref.onDispose(() {
    repo.dispose();
  });

  await repo.init().getOrElse((l) => throw l).run();
  return repo;
}

@Riverpod(keepAlive: true)
GchTraceLocator gchTraceLocator(GchTraceLocatorRef ref) {
  final bridge = ref.watch(platformBridgeProvider);

  return GchTraceLocator(
    ref.watch(gchPathfinderProvider).requireValue.workingDir,
    bridge: bridge,
  );
}

/// 始终活跃的日志监听器 - 即使用户没有打开日志页面也会记录日志
@Riverpod(keepAlive: true)
class GchAuditListener extends _$GchAuditListener with GchInfraLogger {
  StreamSubscription? _subscription;

  @override
  Future<void> build() async {
    //loggy.info("🎧 [LOG-LISTENER] 初始化日志监听器");

    ref.onDispose(() {
      //loggy.info("🎧 [LOG-LISTENER] 释放日志监听器");
      _subscription?.cancel();
      _subscription = null;
    });

    try {
      final repo = await ref.watch(gchTraceArchiveProvider.future);
      //loggy.info("🎧 [LOG-LISTENER] 获取 GchTraceArchive 成功，准备订阅 streamLogs()");
      _subscription = repo.streamLogs().listen(
        (logResult) {
          logResult.fold(
            (failure) {
              loggy.warning("🎧 [LOG-LISTENER] ⚠️ 收到日志失败事件: $failure");
            },
            (logs) {
              // 日志已经通过 EventChannel 自动缓存到 MainActivity.logList
              // 这里只需要保持订阅活跃即可
             // loggy.debug("🎧 [LOG-LISTENER] 📝 收到日志更新，日志数量: ${logs.length}");
            },
          );
        },
        onError: (Object error, StackTrace stackTrace) {
          loggy.warning("🎧 [LOG-LISTENER-ERROR] 监听器错误", error, stackTrace);
        },
        onDone: () {
          loggy.info("🎧 [LOG-LISTENER] 监听器流已关闭");
        },
      );

      loggy.info("🎧 [LOG-LISTENER] ✅ 日志监听器启动成功");
    } catch (e, stackTrace) {
      loggy.error("🎧 [LOG-LISTENER-FATAL] 初始化失败", e, stackTrace);
      rethrow;
    }
  }
}
