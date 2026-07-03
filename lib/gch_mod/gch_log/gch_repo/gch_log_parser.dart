// ignore_for_file: parameter_assignments

import 'package:dartx/dartx.dart';
import 'package:guichao/gch_mod/gch_log/gch_model/gch_log_entity.dart';
import 'package:guichao/gch_mod/gch_log/gch_model/gch_log_level.dart';

abstract class GchTraceParser {
  /// ANSI escape 序列（颜色/样式码）—— Gch 日志常带 `\x1B[...m`
  static final _ansiEscape = RegExp(r'\x1B\[[0-9;]*[a-zA-Z]');

  static GchTraceEntry decodeEntry(String log) {
    log = log.replaceAll(_ansiEscape, '');
    DateTime? time;
    if (log.length > 25) {
      time = DateTime.tryParse(log.substring(6, 25));
    }
    if (time != null) {
      log = log.substring(26);
    }
    final level = GchLogLevel.values.firstOrNullWhere(
      (e) {
        if (log.startsWith(e.name.toUpperCase())) {
          log = log.removePrefix(e.name.toUpperCase());
          return true;
        }
        return false;
      },
    );
    return GchTraceEntry(
      level: level,
      time: time,
      message: log.trim(),
    );
  }
}
