import 'dart:async';
import 'dart:isolate';
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

/// 全局重试计数器 - 防止无限重试循环
int _globalRetryCount = 0;
const int _maxGlobalRetries = 5;
const Duration _bootstrapTimeout = Duration(seconds: 15);

void main() async {
  // 统一错误处理 - 使用runZonedGuarded包裹整个应用启动
  // ZoneSpecification 拦截 print() 调用，统一写入 JSON 日志文件
  runZonedGuarded<void>(
    () async {
      await _initializeApp();
    },
    (error, stackTrace) {
      // 全局未捕获异常处理
      _handleUncaughtError(error, stackTrace);
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

  // 清理残留的启动状态，避免上一次崩溃后阻止本次重新初始化
  resetBootstrapState();

  // 设置Isolate错误处理
  Isolate.current.addErrorListener(RawReceivePort((dynamic pair) {
    if (pair is List<dynamic> && pair.length >= 2) {
      _handleUncaughtError(pair[0] as Object, pair[1] as StackTrace);
    }
  }).sendPort);
  try {
    await _runApp();
  } catch (error, stackTrace) {
    await _showGchBootWall(error, stackTrace);
  }
}

Future<void> _runApp() async {
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

  final bootstrapFuture = lazyBootstrap(WidgetsBinding.instance, GchEnv.dev);
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

/// 全局未捕获异常处理器
void _handleUncaughtError(Object error, StackTrace stackTrace) {
  // 记录错误但不影响应用运行
  if (GchNucleus.isDevMode) {
    debugPrint('🔴 未捕获异常: $error');
    debugPrint('🔴 堆栈跟踪: $stackTrace');
  }

  // 生产环境可以发送到崩溃报告服务
  // FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: false);
}

/// 显示启动崩溃边界
Future<void> _showGchBootWall(Object error, StackTrace stackTrace) async {
  if (GchNucleus.isDevMode) {
    debugPrint('🔴 启动失败: $error');
    debugPrint('🔴 堆栈跟踪: $stackTrace');
  }

  try {
    FlutterNativeSplash.remove();
  } catch (_) {}

  // 显示启动崩溃恢复界面
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
          // 检查全局重试次数，防止无限循环
          if (_globalRetryCount >= _maxGlobalRetries) {
            throw StateError('已达到最大全局重试次数 ($_maxGlobalRetries)，请重启应用');
          }
          _globalRetryCount++;

          // 重试启动 - 捕获异常避免递归调用 _showGchBootWall
          try {
            await _runApp();
          } catch (retryError, _) {
            // 重新抛出，让 GchBootWall 处理
            rethrow;
          }
        },
      ),
    ),
  );
}
