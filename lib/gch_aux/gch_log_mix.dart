import 'package:loggy/loggy.dart';

/// application layer logger
///
/// used in notifiers and controllers
mixin GchAppLogger implements LoggyType {
  @override
  Loggy<GchAppLogger> get loggy => Loggy<GchAppLogger>('$runtimeType');
}

/// presentation layer logger
///
/// used in widgets and ui
mixin GchPresLogger implements LoggyType {
  @override
  Loggy<GchPresLogger> get loggy => Loggy<GchPresLogger>('$runtimeType');
}

/// data layer logger
///
/// used in Repositories, DAOs, Services
mixin GchInfraLogger implements LoggyType {
  @override
  Loggy<GchInfraLogger> get loggy => Loggy<GchInfraLogger>('$runtimeType');
}

abstract class LoggerMixin {
  LoggerMixin(this.loggy);

  final Loggy loggy;
}
