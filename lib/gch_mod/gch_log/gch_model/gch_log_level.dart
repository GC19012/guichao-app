import 'package:dart_mappable/dart_mappable.dart';
import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';

part 'gch_log_level.mapper.dart';

@MappableEnum()
enum GchLogLevel {
  trace,
  debug,
  info,
  warn,
  error,
  fatal,
  panic;

  /// [GchLogLevel] selectable by user as preference
  static List<GchLogLevel> get choices => values.takeFirst(4);

  Color? get color => switch (this) {
        trace => Colors.lightBlueAccent,
        debug => Colors.grey,
        info => Colors.lightGreen,
        warn => Colors.orange,
        error => Colors.redAccent,
        fatal => Colors.red,
        panic => Colors.red,
      };
}
