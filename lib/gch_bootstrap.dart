import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart'; // 重新启用splash以便可控时长
import 'package:guichao/gch_base/gch_shuju_tongji/gch_tongji_kongzhi.dart';
import 'package:guichao/gch_base/gch_umeng/gch_umeng_svc.dart';
import 'package:guichao/gch_base/gch_app_xinxi/gch_yingyong_xinxi.dart';
import 'package:guichao/gch_base/gch_store/gch_db_provider.dart';
import 'package:guichao/gch_base/gch_store/gch_crypt/gch_crypt_conv.dart';
import 'package:guichao/gch_base/gch_store/gch_init_data.dart';
import 'package:guichao/gch_base/gch_pathfinder/gch_pathfinder.dart';
import 'package:guichao/gch_base/gch_ink/gch_ink_printer.dart';
import 'package:guichao/gch_base/gch_ink/gch_ink.dart';
import 'package:guichao/gch_base/gch_ink/gch_ink_ctrl.dart';
import 'package:guichao/gch_base/gch_schema/gch_app_meta.dart';
import 'package:guichao/gch_base/gch_schema/gch_env.dart';
import 'package:guichao/gch_base/gch_prefs/gch_general_pref.dart';
import 'package:guichao/gch_base/gch_prefs/gch_prefs_migration.dart';
import 'package:guichao/gch_base/gch_prefs/gch_store_provider.dart';
import 'package:guichao/gch_base/gch_biz/gch_wire/gch_appprovider.dart' as usersvc;
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_providers/gch_auth_providers.dart';
import 'package:guichao/gch_mod/gch_app/gch_widget/gch_root.dart';
import 'package:guichao/gch_mod/gch_deeplink/gch_ctrl/gch_deep_link_notifier.dart';
import 'package:guichao/gch_mod/gch_log/gch_repo/gch_log_data_providers.dart';
import 'package:guichao/gch_mod/gch_user/gch_boot/gch_bootstrap_extension.dart';
import 'package:guichao/gch_aux/gch_crash_report/gch_reporter.dart';
import 'package:guichao/gch_aux/gch_crash_report/gch_sentry.dart';
import 'package:guichao/gch_base/gch_store/gch_kv/gch_kv_prefs.dart';
import 'package:guichao/gch_base/gch_store/gch_storage/gch_manager.dart';
// 订阅系统导入

import 'package:guichao/gch_base/gch_biz/gch_sub/gch_subscription_provider.dart'; // 新的简化订阅系统
// 测试订单同步
import 'package:guichao/gch_base/gch_shield/gch_crash_wall.dart';
import 'package:guichao/gch_mod/gch_tool/gch_traffic/gch_session_history_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';
enum BootstrapStepStatus { pending, running, success, failed }

const Duration _debugBootstrapDelay = Duration(seconds: 0);

class BootstrapStepRecord {
  const BootstrapStepRecord({
    required this.name,
    required this.status,
    required this.startedAt,
    this.duration,
    this.error,
    this.stackTrace,
  });

  final String name;
  final BootstrapStepStatus status;
  final DateTime startedAt;
  final Duration? duration;
  final Object? error;
  final StackTrace? stackTrace;

  BootstrapStepRecord copyWith({
    BootstrapStepStatus? status,
    Duration? duration,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return BootstrapStepRecord(
      name: name,
      status: status ?? this.status,
      startedAt: startedAt,
      duration: duration ?? this.duration,
      error: error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }
}

class BootstrapProgressState {
  const BootstrapProgressState({
    required this.attempt,
    required this.isRunning,
    required this.history,
    required this.currentStep,
    required this.failedStep,
    required this.startedAt,
    required this.fatalError,
  });

  final int attempt;
  final bool isRunning;
  final List<BootstrapStepRecord> history;
  final BootstrapStepRecord? currentStep;
  final BootstrapStepRecord? failedStep;
  final DateTime? startedAt;
  final Object? fatalError;

  factory BootstrapProgressState.initial({int attempt = 0}) {
    return BootstrapProgressState(
      attempt: attempt,
      isRunning: false,
      history: const [],
      currentStep: null,
      failedStep: null,
      startedAt: null,
      fatalError: null,
    );
  }

  BootstrapProgressState copyWith({
    int? attempt,
    bool? isRunning,
    List<BootstrapStepRecord>? history,
    BootstrapStepRecord? currentStep,
    BootstrapStepRecord? failedStep,
    DateTime? startedAt,
    Object? fatalError,
  }) {
    return BootstrapProgressState(
      attempt: attempt ?? this.attempt,
      isRunning: isRunning ?? this.isRunning,
      history: history ?? this.history,
      currentStep: currentStep,
      failedStep: failedStep,
      startedAt: startedAt ?? this.startedAt,
      fatalError: fatalError ?? this.fatalError,
    );
  }
}

class BootstrapProgressTracker {
  BootstrapProgressTracker._();
  static final BootstrapProgressTracker instance = BootstrapProgressTracker._();

  final ValueNotifier<BootstrapProgressState> notifier = ValueNotifier(BootstrapProgressState.initial());

  void startAttempt() {
    final nextAttempt = notifier.value.attempt + 1;
    notifier.value = BootstrapProgressState.initial(attempt: nextAttempt).copyWith(
      isRunning: true,
      startedAt: DateTime.now(),
    );
  }

  void stepStarted(String name) {
    final record = BootstrapStepRecord(
      name: name,
      status: BootstrapStepStatus.running,
      startedAt: DateTime.now(),
    );
    notifier.value = notifier.value.copyWith(
      currentStep: record,
      isRunning: true,
    );
  }

  void stepCompleted(String name, Duration duration) {
    final current = notifier.value.currentStep;
    if (current == null || current.name != name) return;
    final completed = current.copyWith(
      status: BootstrapStepStatus.success,
      duration: duration,
    );
    final updatedHistory = List<BootstrapStepRecord>.from(notifier.value.history)..add(completed);
    notifier.value = notifier.value.copyWith(
      currentStep: null,
      history: updatedHistory,
    );
  }

  void stepFailed(String name, Object error, StackTrace stackTrace, Duration duration) {
    final failedRecord = BootstrapStepRecord(
      name: name,
      status: BootstrapStepStatus.failed,
      startedAt: notifier.value.currentStep?.startedAt ?? DateTime.now(),
      duration: duration,
      error: error,
      stackTrace: stackTrace,
    );
    final updatedHistory = List<BootstrapStepRecord>.from(notifier.value.history)..add(failedRecord);
    notifier.value = notifier.value.copyWith(
      currentStep: null,
      history: updatedHistory,
      failedStep: failedRecord,
      isRunning: false,
    );
  }

  void recordFatalError(Object error) {
    notifier.value = notifier.value.copyWith(
      fatalError: error,
      isRunning: false,
    );
  }

  void completeAttempt() {
    notifier.value = notifier.value.copyWith(
      isRunning: false,
      currentStep: null,
    );
  }

  void reset() {
    notifier.value = BootstrapProgressState.initial(attempt: notifier.value.attempt);
  }
}

class BootstrapStepException implements Exception {
  BootstrapStepException(this.stepName, this.originalError, this.originalStackTrace);

  final String stepName;
  final Object originalError;
  final StackTrace originalStackTrace;

  @override
  String toString() => 'BootstrapStepException(step: $stepName, error: $originalError)';
}

class BootstrapAbortException implements Exception {
  BootstrapAbortException(this.reason);

  final Object? reason;

  @override
  String toString() => 'BootstrapAbortException(reason: $reason)';
}

class BootstrapTimeoutException extends BootstrapAbortException {
  BootstrapTimeoutException(this.timeout, {this.stepName})
      : super('Bootstrap timeout after ${timeout.inSeconds}s'
            '${stepName != null ? " at step $stepName" : ""}');

  final Duration timeout;
  final String? stepName;
}

// 初始化状态管理 - 防止重复初始化
class _BootstrapState {
  static bool _isInitializing = false;
  static bool _isInitialized = false;
  static Object? _abortReason;
  static int? _abortAttemptId;
  static int _attemptCounter = 0;
  static int _activeAttemptId = 0;
  static ProviderContainer? _container;
  static AppLifecycleListener? _lifecycleListener;

  static bool get isInitializing => _isInitializing;
  static bool get isInitialized => _isInitialized;
  static int get activeAttemptId => _activeAttemptId;
  static ProviderContainer? get container => _container;

  static int setInitializing() {
    _isInitializing = true;
    _isInitialized = false;
    _attemptCounter += 1;
    _activeAttemptId = _attemptCounter;
    return _activeAttemptId;
  }

  static bool isActiveAttempt(int attemptId) => _activeAttemptId == attemptId;

  static void abort(Object reason) {
    _abortReason = reason;
    _abortAttemptId = _activeAttemptId;
  }

  static Object? abortReasonForAttempt(int attemptId) {
    if (_abortAttemptId != attemptId) return null;
    return _abortReason;
  }

  static void setInitialized(
    ProviderContainer container,
    AppLifecycleListener listener, {
    required int attemptId,
  }) {
    if (!isActiveAttempt(attemptId)) return;
    _abortReason = null;
    _abortAttemptId = null;
    _isInitializing = false;
    _isInitialized = true;
    _container = container;
    _lifecycleListener = listener;
  }

  static void reset({
    bool disposeContainer = true,
    bool clearAbort = true,
    int? attemptId,
  }) {
    if (attemptId != null && !isActiveAttempt(attemptId)) {
      return;
    }
    _isInitializing = false;
    _isInitialized = false;
    if (clearAbort) {
      _abortReason = null;
      _abortAttemptId = null;
    }
    _lifecycleListener?.dispose();
    _lifecycleListener = null;
    if (disposeContainer) {
      _container?.dispose();
      _container = null;
    }
  }
}

void abortBootstrap(Object reason) {
  _BootstrapState.abort(reason);
}

void _checkBootstrapAbort(int attemptId) {
  final reason = _BootstrapState.abortReasonForAttempt(attemptId);
  if (reason == null) return;
  if (reason is Exception) {
    throw reason;
  }
  throw BootstrapAbortException(reason);
}

/// 创建默认的错误报告器（用于依赖注入）
ErrorReporter createDefaultErrorReporter() => SentryErrorReporter();

Future<void> lazyBootstrap(
    WidgetsBinding widgetsBinding,
    GchEnv env, {
    /// 可选的错误报告器，用于依赖注入（测试或切换到 Firebase 等）
    /// 如果不提供，默认使用 SentryErrorReporter
    ErrorReporter? errorReporter,
    }) async {
  // 防止重复初始化
  if (_BootstrapState.isInitializing) {
    throw StateError('Bootstrap is already in progress');
  }

  if (_BootstrapState.isInitialized) {
    throw StateError('Bootstrap has already been completed');
  }

  final attemptId = _BootstrapState.setInitializing();
  BootstrapProgressTracker.instance.startAttempt();

  try {
    // 保持原生启动页，直到我们显式移除（可控显示时长）
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    if (GchNucleus.isDevMode &&
        _debugBootstrapDelay > Duration.zero &&
        attemptId == 1) {
      await Future.delayed(_debugBootstrapDelay);
      _checkBootstrapAbort(attemptId);
    }
  GchInkCtrl.warmup();
  FlutterError.onError = GchInk.captureFlutterError;
  WidgetsBinding.instance.platformDispatcher.onError = GchInk.capturePlatformError;
  final stopWatch = Stopwatch()..start();
  final container = ProviderContainer(
    overrides: [
      environmentProvider.overrideWithValue(env),
    ],
  );

  // 设置容器引用，用于支付系统初始化
  BootstrapExtension.setContainer(container);
  await _init(
    "directories",
        () => container.read(gchPathfinderProvider.future),
    timeout: 3000, // 10秒超时
  );
  GchInkCtrl.ignite(container.read(gchTraceLocatorProvider).appFile().path);

  // 设置 console 日志开关：debug 模式或手动强制开启时才输出到 console
  GchConsolePrinter.enabled = GchNucleus.isDevMode || GchNucleus.forceConsoleLog;

  // 拦截 debugPrint，统一写入 JSON 日志文件
  final originalDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message == null) return;
    GchInkCtrl.scribble('debugPrint', message);
    if (GchConsolePrinter.enabled) originalDebugPrint(message, wrapWidth: wrapWidth);
  };

  // 初始化GchNucleus
  await _init(
    "app global",
        () => GchNucleus.bootstrap(debugMode: GchNucleus.isDevMode),
    timeout: 4000,
  );

  final appInfo = await _init(
    "app info",
        () => container.read(gchYingyongXinxiProvider.future),
    timeout: 2000, // 5秒超时
  );

  final reporterConfig = ErrorReporterConfig(
    dsn: '',
    environment: appInfo.environment.name,
    release: '${appInfo.name}@${appInfo.version}+${appInfo.buildNumber}',
  );

  // ✅ 使用 initAndRunGuarded 包裹剩余初始化和 runApp
  // 这样可以确保错误报告器能捕获所有后续初始化过程中的错误
  final reporter = errorReporter ?? createDefaultErrorReporter();
  await reporter.initAndRunGuarded(
    config: reporterConfig,
    appRunner: () async {
      try {
        // 设置为全局错误报告器
        ErrorReporterFactory.setInstance(reporter);

        // 设置平台和设备信息标签
        if (reporter.isInitialized) {
          reporter.setTags({
            'platform': Platform.operatingSystem,
            'os_version': Platform.operatingSystemVersion,
            'environment': appInfo.environment.name,
            'release_type': appInfo.release.name,
          });
        }

        GchInk.boot.info("${reporter.name} 错误报告器已配置（appRunner 模式）");

        // 继续剩余的初始化流程
        await _continueBootstrap(
          container: container,
          appInfo: appInfo,
          attemptId: attemptId,
          stopWatch: stopWatch,
        );
      } catch (error, _) {
        // ✅ 确保即使被错误报告器捕获，清理逻辑也会执行
        BootstrapProgressTracker.instance.recordFatalError(error);
        if (_BootstrapState.isActiveAttempt(attemptId)) {
          _BootstrapState.reset(
            disposeContainer: false,
            clearAbort: false,
            attemptId: attemptId,
          );
        }
        try {
          FlutterNativeSplash.remove();
        } catch (_) {}
        rethrow;
      }
    },
  );

  } catch (error, _) {
    BootstrapProgressTracker.instance.recordFatalError(error);
    if (_BootstrapState.isActiveAttempt(attemptId)) {
      _BootstrapState.reset(
        disposeContainer: false,
        clearAbort: false,
        attemptId: attemptId,
      );
    }

    // ✅【关键】即使初始化失败，也必须移除 Splash
    try {
      FlutterNativeSplash.remove();
    } catch (_) {}

    rethrow;
  }
}

/// 继续 Bootstrap 的后半部分
Future<void> _continueBootstrap({
  required ProviderContainer container,
  required GchAppMeta appInfo,
  required int attemptId,
  required Stopwatch stopWatch,
}) async {
  // 【确定存储类型】根据全局配置决定初始化哪些组件
  final globalStorageType = GchNucleus.defaultStorageType;
  final preferencesStorageType = GchNucleus.defaultPreferencesStorageType;
  print('📊 存储类型配置:');
  print('   - 业务数据: ${globalStorageType.displayName}');
  print('   - Preferences: ${preferencesStorageType.name.toUpperCase()}');
  GchInk.boot.info('业务数据存储: ${globalStorageType.displayName}');
  GchInk.boot.info('Preferences存储: ${preferencesStorageType.name.toUpperCase()}');

  // 并行初始化独立组件（不互相依赖的组件）
  final parallelInits = <Future>[];

  // Store 初始化（Hive.initFlutter 在此完成，必须先于 FieldEncryptor）
  final prefStore = await _init(
    "preferences",
        () => container.read(gchStoreProvider.future),
    timeout: 3000,
  );
  await _tryInit(
    "prefs migration",
        () => GchPrefsMigration.run(prefStore),
  );

  // FieldEncryptor 依赖 Hive 已初始化
  await _init(
    "field encryptor",
        () => FieldEncryptor.setup(),
    timeout: 2000,
  );

  await _tryInit(
    "intro completed",
        () => container.read(GchPrefs.introCompleted.notifier).updateValue(true),
    timeout: 1000,
  );

  // 以下组件可以并行初始化
  parallelInits.add(
    _tryInit(
      "analytics",
          () async {
        final enableAnalytics = await container.read(tongjiKongzhiProvider.future);
        if (enableAnalytics) {
          await container.read(tongjiKongzhiProvider.notifier).qiyongTongji();
        }
      },
      timeout: 1000,
    ),
  );

  // 友盟统计 SDK 初始化（非阻塞，带超时保护）
  parallelInits.add(Future(() async {
    try {
      GchInk.boot.info('开始初始化友盟 SDK...');
      await GchUmengSvc.setup().timeout(const Duration(seconds: 3));
      GchInk.boot.info('友盟 SDK 初始化完成, isReady=${GchUmengSvc.isReady}');
    } catch (e) {
      GchInk.boot.warning('友盟 SDK 初始化失败或超时: $e');
    }
  }));

  // 初始化ANR检测器（仅debug模式）
  parallelInits.add(
    _tryInit(
      "anr detector",
          () async {
        container.read(usersvc.anrDetectorProvider);
        GchInk.boot.debug("ANR detector initialized");
      },
      timeout: 500,
    ),
  );


  // 【延迟数据库初始化】
  // 数据库初始化移到靠近 gchVpnConfRepo 的位置，避免阻塞早期启动
  // 见 330 行附近

  // 等待所有并行初始化完成（使用 eagerError: false 避免一个失败导致全部失败）
  await Future.wait(parallelInits, eagerError: false);

  _checkBootstrapAbort(attemptId);

  final debug = container.read(gchDebugModeProvider) || GchNucleus.isDevMode;
  await _init(
    "logs repository",
        () => container.read(gchTraceArchiveProvider.future),
  );

  // 【新增】启动日志监听器 - 即使用户没有打开日志页面也会记录日志
  await _tryInit(
    "log listener",
        () => container.read(gchAuditListenerProvider.future),
    timeout: 2000,
  );

  // 同步激活 Session 历史 notifier，确保 VPN 连接/断开事件在 runApp 前就被监听
  container.read(gchSessionHistoryNotifierProvider);

  await _init("logger controller", () => GchInkCtrl.calibrate(debug));
// authmanager一定要放这里，否则riverpod的相互依赖有先后顺序，导致无法启动
// profile repository放到前面就无法启动了
  GchInk.boot.info(appInfo.format());

  // ✅ Auth manager 是关键组件，失败时记录警告但允许应用继续（用户可稍后重试登录）
  final authResult = await _tryInit(
    "auth manager",
        () => container.read(authManagerProvider.future),
    timeout: 1800,
  );
  if (authResult == null) {
    GchInk.boot.warning('⚠️ Auth manager 初始化失败，用户需要手动登录');
    // 可选：上报到 Sentry
    ErrorReporterFactory.instance?.recordMessage(
      'Auth manager initialization failed during bootstrap',
      level: ErrorLevel.warning,
      extras: {'attemptId': attemptId},
    );
  }

  // 【数据库初始数据插入】在数据库初始化成功后插入初始数据
  await _tryInit(
    "database init data (${globalStorageType.displayName})",
        () async {
      try {
        final db = container.read(gchDatabaseProvider);
        await InitData.init(db: db);
        print('✅ SQLite 数据库初始数据插入成功');
        GchInk.boot.info('SQLite 数据库初始化完成');
      } catch (e, stackTrace) {
        print('⚠️ 数据库初始数据插入失败: $e');
        GchInk.boot.warning('数据库初始数据插入失败', e, stackTrace);
        return null;
      }
    },
    timeout: 3000,
  );

  // profile repository disabled - gch_profile module removed

  // 支付系统初始化
  await _tryInit(
    "payment system",
        () async {
      await BootstrapExtension.initPayment();
      GchInk.boot.info("支付系统初始化完成");
      return true;
    },
    timeout: 4000,
  );
  // active profile, core-engine, ios config sync, grpc lifecycle/event disabled - modules removed


  // 新的简化订阅管理器初始化
  await _tryInit(
    "subscription manager",
        () async {
      // 初始化订阅管理器（会自动启动定时器和监听认证状态）
      final manager = container.read(subscriptionManagerProvider);
      GchInk.boot.info("新订阅管理器初始化完成");

      // 可选：监听订阅事件用于调试
      if (GchNucleus.isDevMode) {
        container.listen<AsyncValue<SubscriptionEvent>>(
          subscriptionEventStreamProvider,
              (previous, next) {
            next.when(
              data: (event) {
                GchInk.boot.debug("订阅事件: $event");
              },
              loading: () {
                GchInk.boot.debug("订阅事件流加载中...");
              },
              error: (error, stackTrace) {
                GchInk.boot.error("订阅事件流错误", error, stackTrace);
              },
            );
          },
        );
      }

      return manager;
    },
    timeout: 1300,
  );

  // 支付系统初始化推迟到App启动后，因为需要数据库Provider
  // 将在App widget中的init()方法中初始化

  // native settings channel disabled - nativeFlutterBridgeProvider module removed


  GchInk.boot.info("core bootstrap took [${stopWatch.elapsedMilliseconds}ms]");
  stopWatch.stop();

  _checkBootstrapAbort(attemptId);

  // ✅ 注册应用生命周期监听
  AppLifecycleListener? lifecycleListener;
  try {
    lifecycleListener = AppLifecycleListener(
      onStateChange: (AppLifecycleState state) {
        if (state == AppLifecycleState.detached) {
          GchInk.boot.info('应用即将退出，清理单例资源...');
          unawaited(GchKvPrefs.shutdown());
          unawaited(GchStorageManager.gchShutdown());
          GchInk.boot.info('单例资源清理完成');
        }
      },
    );

    // 标记初始化完成
    _checkBootstrapAbort(attemptId);
    if (!_BootstrapState.isActiveAttempt(attemptId)) {
      // ✅ 确保 lifecycleListener 被释放
      lifecycleListener.dispose();
      if (container != _BootstrapState.container) {
        container.dispose();
      }
      return;
    }
    _BootstrapState.setInitialized(container, lifecycleListener, attemptId: attemptId);
    lifecycleListener = null; // 所有权已转移给 _BootstrapState
  } catch (e) {
    // ✅ 异常时确保资源释放
    lifecycleListener?.dispose();
    rethrow;
  }

  // ✅【关键】先启动 Flutter UI，确保第一帧能显示
  _checkBootstrapAbort(attemptId);
  if (!_BootstrapState.isActiveAttempt(attemptId)) {
    return;
  }
  runApp(
    GchCrashWall(
      enableDebugInfo: GchNucleus.isDevMode,
      child: ProviderScope(
        parent: container,
        child: const GchRoot(),
      ),
    ),
  );

  // ✅【关键】确保 Splash 一定会被移除（即使后续初始化失败）
  // 使用 addPostFrameCallback 确保在首帧渲染后移除
  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      FlutterNativeSplash.remove();
      GchInk.boot.info('✅ Native splash removed after first frame');
    } catch (e) {
      GchInk.boot.warning('Failed to remove native splash: $e');
    }
  });

  // Deep link service 需要插件注册完成后再初始化
  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      container.read(deepLinkNotifierProvider);
    } catch (e, stackTrace) {
      GchInk.boot.warning('post-frame deep link init failed', e, stackTrace);
    }
  });


  BootstrapProgressTracker.instance.completeAttempt();
}

/// 重置启动状态 - 用于测试或错误恢复
void resetBootstrapState({bool disposeContainer = true, bool clearAbort = true}) {
  _BootstrapState.reset(
    disposeContainer: disposeContainer,
    clearAbort: clearAbort,
  );
  BootstrapProgressTracker.instance.reset();
}

Future<T> _init<T>(
    String name,
    Future<T> Function() initializer, {
      int? timeout,
    }) async {
  final stopWatch = Stopwatch()..start();
  print("🚀 BOOTSTRAP: Starting [$name]"); // 使用print确保输出
  GchInk.boot.info("initializing [$name]");
  BootstrapProgressTracker.instance.stepStarted(name);

  Future<T> func() => timeout != null ? initializer().timeout(Duration(milliseconds: timeout)) : initializer();
  try {
    _checkBootstrapAbort(_BootstrapState.activeAttemptId);
    final result = await func();
    _checkBootstrapAbort(_BootstrapState.activeAttemptId);
    print("✅ BOOTSTRAP: [$name] completed in ${stopWatch.elapsedMilliseconds}ms");
    GchInk.boot.debug("[$name] initialized in ${stopWatch.elapsedMilliseconds}ms");
    BootstrapProgressTracker.instance.stepCompleted(name, Duration(milliseconds: stopWatch.elapsedMilliseconds));
    return result;
  } catch (e, stackTrace) {
    print("❌ BOOTSTRAP: [$name] FAILED: $e");
    GchInk.boot.error("[$name] error initializing", e, stackTrace);

    // 记录初始化失败
    GchInk.boot.error("initialization failed for [$name]", e, stackTrace);

    final duration = Duration(milliseconds: stopWatch.elapsedMilliseconds);
    if (e is BootstrapStepException) {
      BootstrapProgressTracker.instance.stepFailed(name, e.originalError, e.originalStackTrace, duration);
      rethrow;
    } else {
      BootstrapProgressTracker.instance.stepFailed(name, e, stackTrace, duration);
      throw BootstrapStepException(name, e, stackTrace);
    }
  } finally {
    stopWatch.stop();
  }
}

Future<T?> _tryInit<T>(
    String name,
    Future<T> Function() initializer, {
      int timeout=10000,
    }) async {
  try {
    return await _init(name, initializer, timeout: timeout);
  } catch (e, stackTrace) {
    // 【修复：错误静默吞噬】区分超时和其他错误，记录日志
    if (e is TimeoutException) {
      GchInk.boot.warning('⏱️ [$name] 初始化超时 (${timeout}ms)，跳过此步骤');
    } else if (e is BootstrapStepException) {
      // BootstrapStepException 已在 _init 中记录，这里只记录跳过信息
      GchInk.boot.warning('⚠️ [$name] 初始化失败，跳过此步骤: ${e.originalError}');
    } else {
      GchInk.boot.warning('⚠️ [$name] 初始化异常，跳过此步骤', e, stackTrace);
    }

    // 上报到错误监控（非致命错误）
    // 使用 try-catch 包装，防止上报失败影响主流程
    try {
      await ErrorReporterFactory.instance?.recordError(
        e,
        stackTrace,
        reason: 'Bootstrap optional step failed: $name',
        extras: {'stepName': name, 'timeout': timeout},
        fatal: false,
      );
    } catch (_) {
      // 上报失败不影响主流程
    }

    return null;
  }
}
