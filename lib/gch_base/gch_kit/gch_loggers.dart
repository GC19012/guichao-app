// lib/core/gch_kit/gch_loggers.dart

import 'package:flutter/foundation.dart';
import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';

/// 基础日志接口
abstract class Logger {
  void debug(String message);
  void info(String message);
  void warning(String message, [Object? error]);
  void error(String message, [Object? error, StackTrace? stackTrace]);
}

/// 简单的控制台日志实现
class ConsoleLogger implements Logger {
  final String name;
  
  const ConsoleLogger(this.name);
  
  @override
  void debug(String message) {
    if (GchNucleus.isDevMode) {
      debugPrint('[$name] DEBUG: $message');
    }
  }
  
  @override
  void info(String message) {
    debugPrint('[$name] INFO: $message');
  }
  
  @override
  void warning(String message, [Object? error]) {
    debugPrint('[$name] WARNING: $message${error != null ? ' - $error' : ''}');
  }
  
  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[$name] ERROR: $message${error != null ? ' - $error' : ''}');
    if (stackTrace != null && GchNucleus.isDevMode) {
      debugPrint('Stack trace: $stackTrace');
    }
  }
}

/// 基础设施日志 Mixin
mixin GchInfraLogger {
  Logger get loggy => ConsoleLogger(runtimeType.toString());
}

/// 基础设施日志 Mixin（带名称）
class InfraLoggerMixin {
  final String _name;
  late final Logger loggy;
  
  InfraLoggerMixin(this._name) {
    loggy = ConsoleLogger(_name);
  }
}