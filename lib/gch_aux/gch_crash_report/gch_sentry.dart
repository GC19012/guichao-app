import 'package:flutter/foundation.dart';
import 'package:guichao/gch_aux/gch_crash_report/gch_reporter.dart';
import 'package:guichao/gch_aux/gch_common.dart';

/// 空实现的错误报告器（Sentry 已移除）
class SentryErrorReporter extends ErrorReporter with GchAppLogger {
  @override
  String get name => 'NoOpReporter';

  @override
  bool get isInitialized => false;

  @override
  Future<void> initAndRunGuarded({
    required ErrorReporterConfig config,
    required Future<void> Function() appRunner,
  }) async {
    await appRunner();
  }

  @override
  Future<void> initialize({
    required String dsn,
    required String environment,
    required String release,
    bool enableInDevMode = false,
    double tracesSampleRate = 0.1,
    double profilesSampleRate = 0.1,
  }) async {}

  @override
  Future<void> recordError(dynamic error, StackTrace? stackTrace,
      {String? reason, Map<String, dynamic>? extras, bool fatal = false}) async {}

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details,
      {bool fatal = false}) async {}

  @override
  Future<void> recordMessage(String message,
      {ErrorLevel level = ErrorLevel.info,
      Map<String, dynamic>? extras}) async {}

  @override
  void addBreadcrumb(
      {required String message,
      String? category,
      Map<String, dynamic>? data,
      ErrorLevel level = ErrorLevel.info}) {}

  @override
  void setUser(
      {String? id,
      String? email,
      String? username,
      Map<String, dynamic>? extras}) {}

  @override
  void setTag(String key, String value) {}

  @override
  void setTags(Map<String, String> tags) {}

  @override
  void setContextData(String key, dynamic value) {}

  @override
  void clearUser() {}

  @override
  Future<void> close() async {}
}
