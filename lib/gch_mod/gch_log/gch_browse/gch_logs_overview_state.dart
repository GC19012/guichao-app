import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:guichao/gch_mod/gch_log/gch_model/gch_log_entity.dart';
import 'package:guichao/gch_mod/gch_log/gch_model/gch_log_level.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gch_logs_overview_state.freezed.dart';

@freezed
abstract class LogsOverviewState with _$LogsOverviewState {
  const LogsOverviewState._();

  const factory LogsOverviewState({
    @Default(AsyncLoading()) AsyncValue<List<GchTraceEntry>> logs,
    @Default(false) bool paused,
    @Default("") String filter,
    GchLogLevel? levelFilter,
    @Default(true) bool autoScroll,
  }) = _LogsOverviewState;
}
