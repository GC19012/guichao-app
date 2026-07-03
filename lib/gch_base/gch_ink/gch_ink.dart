import 'package:flutter/foundation.dart';
import 'package:guichao/gch_aux/gch_crash_report/gch_reporter.dart';
import 'package:loggy/loggy.dart';

class GchInk {
  static final app = Loggy("app");
  static final boot = Loggy("bootstrap");

  static void captureFlutterError(FlutterErrorDetails details) {
    if (details.silent) return;

    final description = details.exceptionAsString();
    app.error('Flutter Error: $description', details.exception, details.stack);
    ErrorReporterFactory.instance?.recordFlutterError(details);
  }

  static bool capturePlatformError(Object error, StackTrace stackTrace) {
    app.error('PlatformDispatcherError: $error', error, stackTrace);
    ErrorReporterFactory.instance?.recordError(error, stackTrace, reason: 'PlatformDispatcher');
    return true;
  }
}
