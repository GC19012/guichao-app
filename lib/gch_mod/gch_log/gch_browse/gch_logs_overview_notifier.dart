import 'dart:async';

import 'package:flutter/services.dart';
import 'package:guichao/gch_mod/gch_log/gch_repo/gch_log_data_providers.dart';
import 'package:guichao/gch_mod/gch_log/gch_model/gch_log_entity.dart';
import 'package:guichao/gch_mod/gch_log/gch_model/gch_log_level.dart';
import 'package:guichao/gch_mod/gch_log/gch_browse/gch_logs_overview_state.dart';
import 'package:guichao/gch_aux/gch_pod_ext.dart';
import 'package:guichao/gch_aux/gch_common.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'gch_logs_overview_notifier.g.dart';

@riverpod
class GchLogBrowseNotifier extends _$GchLogBrowseNotifier with GchAppLogger {
  @override
  LogsOverviewState build() {
    ref.disposeDelay(const Duration(seconds: 20));
    state = const LogsOverviewState();
    ref.onDispose(
      () {
        loggy.debug("disposing");
        final previous = _listener;
        _listener = null;
        unawaited(_cancelQuietly(previous));
      },
    );
    ref.onCancel(
      () {
        if (_listener?.isPaused != true) {
          loggy.debug("pausing");
          _listener?.pause();
        }
      },
    );
    ref.onResume(
      () {
        if (!state.paused && (_listener?.isPaused ?? false)) {
          loggy.debug("resuming");
          _listener?.resume();
        }
      },
    );

    _addListeners();
    return const LogsOverviewState();
  }

  StreamSubscription? _listener;
  Future<void> _cancelQuietly(StreamSubscription? sub) async {
    if (sub == null) return;
    try {
      await sub.cancel();
    } on PlatformException catch (e) {
      if (e.code == 'error' && (e.message?.contains('No active stream to cancel') ?? false)) {
        return;
      }
    } catch (_) {
      // Ignore cancellation errors triggered by raced native teardown.
    }
  }

  Future<void> _addListeners() async {
    loggy.debug("🎧 [NOTIFIER-1] adding listeners 开始");
    final previous = _listener;
    _listener = null;
    await _cancelQuietly(previous);
    loggy.debug("🎧 [NOTIFIER-2] 旧 listener 已取消");
    final repo = ref.read(gchTraceArchiveProvider).requireValue;
    loggy.debug("🎧 [NOTIFIER-3] logRepository 获取成功: $repo");
    _listener = repo
        .streamLogs()
        .throttle(
          (_) => Stream.value(_listener?.isPaused ?? false),
          leading: false,
          trailing: true,
        )
        .throttleTime(
          const Duration(milliseconds: 250),
          leading: false,
          trailing: true,
        )
        .asyncMap(
      (event) async {
        await event.fold(
          (f) {
            _logs = [];
            state = state.copyWith(logs: AsyncError(f, StackTrace.current));
          },
          (a) async {
            _logs = a.reversed;
            state = state.copyWith(logs: AsyncData(await _computeLogs()));
          },
        );
      },
    ).listen((event) {});
  }

  Iterable<GchTraceEntry> _logs = [];
  final _debouncer = GchDebouncer(const Duration(milliseconds: 200));
  GchLogLevel? _levelFilter;
  String _filter = "";

  Future<List<GchTraceEntry>> _computeLogs() async {
    if (_levelFilter == null && _filter.isEmpty) return _logs.toList();
    return _logs.where((e) {
      return (_filter.isEmpty || e.message.contains(_filter)) &&
          (_levelFilter == null ||
              e.level == null ||
              e.level!.index >= _levelFilter!.index);
    }).toList();
  }

  void pause() {
    loggy.debug("pausing");
    _listener?.pause();
    state = state.copyWith(paused: true);
  }

  void resume() {
    loggy.debug("resuming");
    _listener?.resume();
    state = state.copyWith(paused: false);
  }

  Future<void> clear() async {
    loggy.debug("clearing");
    await ref.read(gchTraceArchiveProvider).requireValue.purgeLogs().match(
      (l) {
        loggy.warning("error clearing logs", l);
      },
      (_) {
        _logs = [];
        state = state.copyWith(logs: const AsyncData([]));
      },
    ).run();
  }

  void filterMessage(String? filter) {
    _filter = filter ?? '';
    _debouncer(
      () async {
        if (state.logs case AsyncData()) {
          state = state.copyWith(
            filter: _filter,
            logs: AsyncData(await _computeLogs()),
          );
        }
      },
    );
  }

  Future<void> filterLevel(GchLogLevel? level) async {
    _levelFilter = level;
    if (state.logs case AsyncData()) {
      state = state.copyWith(
        levelFilter: _levelFilter,
        logs: AsyncData(await _computeLogs()),
      );
    }
  }
}
