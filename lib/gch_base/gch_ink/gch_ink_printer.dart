// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:loggy/loggy.dart';

class GchConsolePrinter extends LoggyPrinter {
  const GchConsolePrinter({
    this.showColors = false,
  });

  final bool showColors;

  static bool enabled = true;

  static final _levelColors = {
    LogLevel.debug:
        AnsiColor(foregroundColor: AnsiColor.grey(0.5), italic: true),
    LogLevel.info: AnsiColor(foregroundColor: 35),
    LogLevel.warning: AnsiColor(foregroundColor: 214),
    LogLevel.error: AnsiColor(foregroundColor: 196),
  };

  @override
  void onLog(LogRecord record) {
    if (!enabled) return;

    final colorize = showColors && stdout.supportsAnsiEscapes;
    final time = record.time.toIso8601String().split('T')[1];
    final callerFrame = record.callerFrame == null
        ? ' '
        : ' (${record.callerFrame?.location}) ';

    final String logLevel;
    if (colorize) {
      logLevel = record.level.name.toUpperCase().padRight(8);
    } else {
      logLevel = "[${record.level.name.toUpperCase()}]".padRight(10);
    }

    final color =
        showColors ? levelColor(record.level) ?? AnsiColor() : AnsiColor();

    stdout.writeln(
      color(
        '$time $logLevel [${record.loggerName}]$callerFrame${record.message}',
      ),
    );

    if (record.stackTrace != null) {
      stdout.writeln(record.stackTrace);
    }
  }

  AnsiColor? levelColor(LogLevel level) {
    return _levelColors[level];
  }
}

class GchFilePrinter extends LoggyPrinter {
  GchFilePrinter(
    String filePath, {
    this.minLevel = LogLevel.debug,
  }) : _logFile = File(filePath);

  final File _logFile;
  final LogLevel minLevel;

  late final _sink = _logFile.openWrite(
    mode: FileMode.append,
  );

  @override
  void onLog(LogRecord record) {
    final logEntry = {
      'time': record.time.toUtc().toIso8601String(),
      'level': record.level.name.toUpperCase(),
      'tag': record.loggerName,
      'message': record.message,
      if (record.error != null) 'error': record.error.toString(),
      if (record.stackTrace != null) 'stack': record.stackTrace.toString(),
      'platform': Platform.operatingSystem,
    };
    _sink.writeln(jsonEncode(logEntry));
  }

  void dispose() {
    _sink.close();
  }
}
