import 'package:guichao/gch_base/gch_ink/gch_ink_printer.dart';
import 'package:guichao/gch_aux/gch_log_mix.dart';
import 'package:loggy/loggy.dart';

class GchInkCtrl extends LoggyPrinter with GchInfraLogger {
  GchInkCtrl(
    this.consolePrinter,
    this.otherPrinters,
  );

  final LoggyPrinter consolePrinter;
  final Map<String, LoggyPrinter> otherPrinters;

  static GchInkCtrl get instance => _instance;

  static late GchInkCtrl _instance;

  static GchFilePrinter? _filePrinter;

  static final List<LogRecord> _pendingWrites = [];

  static void warmup() {
    Loggy.initLoggy(logPrinter: const GchConsolePrinter());
  }

  static void ignite(String appLogPath) {
    final filePrinter = GchFilePrinter(appLogPath);
    _filePrinter = filePrinter;
    _instance = GchInkCtrl(
      const GchConsolePrinter(),
      {"app": filePrinter},
    );
    Loggy.initLoggy(logPrinter: _instance);

    if (_pendingWrites.isNotEmpty) {
      for (final record in _pendingWrites) {
        filePrinter.onLog(record);
      }
      _pendingWrites.clear();
    }
  }

  static Future<void> calibrate(bool debugMode) async {
    final logLevel = debugMode ? LogLevel.all : LogLevel.info;

    Loggy.initLoggy(
      logPrinter: _instance,
      logOptions: LogOptions(logLevel),
    );
  }

  static void scribble(String source, String message) {
    final record = LogRecord(
      LogLevel.debug,
      message,
      source,
      DateTime.now(),
    );

    final printer = _filePrinter;
    if (printer == null) {
      _pendingWrites.add(record);
      return;
    }
    printer.onLog(record);
  }

  void mountPrinter(String name, LoggyPrinter printer) {
    loggy.debug("adding [$name] printer");
    otherPrinters.putIfAbsent(name, () => printer);
  }

  void ejectPrinter(String name) {
    loggy.debug("removing [$name] printer");
    final printer = otherPrinters[name];
    if (printer case GchFilePrinter()) {
      printer.dispose();
      if (printer == _filePrinter) _filePrinter = null;
    }
    otherPrinters.remove(name);
  }

  @override
  void onLog(LogRecord record) {
    consolePrinter.onLog(record);
    for (final printer in otherPrinters.values) {
      printer.onLog(record);
    }
  }
}
