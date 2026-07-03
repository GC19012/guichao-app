import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:guichao/gch_bootstrap.dart';
import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';
import 'package:guichao/gch_base/gch_ink/gch_ink_printer.dart';
import 'package:guichao/gch_base/gch_ink/gch_ink_ctrl.dart';
import 'package:guichao/gch_base/gch_schema/gch_env.dart';
import 'package:guichao/gch_base/gch_shield/gch_boot_wall.dart';

int _globalRetryCount = 0;
const int _maxGlobalRetries = 5;
const Duration _bootstrapTimeout = Duration(seconds: 15);

void main() async {
  // ZoneSpecification 拦截 print() 调用，统一写入 JSON 日志文件
  runZonedGuarded<void>(
    () async {
      await _initializeApp();
    },
    (error, stackTrace) {
      if (GchNucleus.isDevMode) {
        debugPrint('🔴 未捕获异常: $error');
        debugPrint('🔴 堆栈跟踪: $stackTrace');
      }
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        GchInkCtrl.scribble('print', line);
        if (GchConsolePrinter.enabled) parent.print(zone, line);
      },
    ),
  );
}

Future<void> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  resetBootstrapState();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      // iOS：light = 深色图标；Android：dark = 深色图标
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    await _runApp();
  } catch (error, stackTrace) {
    await _showGchBootWall(error, stackTrace);
  }
}

Future<void> _runApp() async {
  final bootstrapFuture = lazyBootstrap(WidgetsBinding.instance, GchEnv.prod);
  final timeoutCompleter = Completer<void>();
  final timer = Timer(_bootstrapTimeout, () {
    if (timeoutCompleter.isCompleted) return;
    if (!BootstrapProgressTracker.instance.notifier.value.isRunning) return;
    final stepName = BootstrapProgressTracker.instance.notifier.value.currentStep?.name;
    final error = BootstrapTimeoutException(_bootstrapTimeout, stepName: stepName);
    abortBootstrap(error);
    timeoutCompleter.completeError(error, StackTrace.current);
  });
  try {
    await Future.any([bootstrapFuture, timeoutCompleter.future]);
  } catch (error) {
    if (error is BootstrapTimeoutException) {
      unawaited(bootstrapFuture.catchError((_) {}));
    }
    rethrow;
  } finally {
    timer.cancel();
  }
}

Future<void> _showGchBootWall(Object error, StackTrace stackTrace) async {
  if (GchNucleus.isDevMode) {
    debugPrint('🔴 启动失败: $error');
    debugPrint('🔴 堆栈跟踪: $stackTrace');
  }

  try {
    FlutterNativeSplash.remove();
  } catch (_) {}

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GchBootWall(
        error: error,
        stackTrace: stackTrace,
        progressTracker: BootstrapProgressTracker.instance,
        maxGlobalRetries: _maxGlobalRetries,
        currentGlobalRetry: _globalRetryCount,
        onRetry: () async {
          if (_globalRetryCount >= _maxGlobalRetries) {
            throw StateError('已达到最大全局重试次数 ($_maxGlobalRetries)，请重启应用');
          }
          _globalRetryCount++;
          await _runApp();
        },
      ),
    ),
  );
}
