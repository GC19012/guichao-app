import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:guichao/gch_mod/gch_log/gch_model/gch_log_level.dart';

part 'gch_log_entity.freezed.dart';

@freezed
abstract class GchTraceEntry with _$GchTraceEntry {
  const factory GchTraceEntry({
    GchLogLevel? level,
    DateTime? time,
    required String message,
    String? source,
  }) = _GchTraceEntry;
}
