import 'package:flutter/foundation.dart';

/// 错误报告器配置
/// 统一的配置类，支持不同后端的通用配置
class ErrorReporterConfig {
  const ErrorReporterConfig({
    required this.dsn,
    required this.environment,
    required this.release,
    this.enableInDevMode = true,
    this.tracesSampleRate = 0.1,
    this.profilesSampleRate = 0.1,
  });

  final String dsn;
  final String environment;
  final String release;
  final bool enableInDevMode;
  final double tracesSampleRate;
  final double profilesSampleRate;
}

/// 错误报告器接口
/// 提供统一的错误报告抽象，支持多种后端（Sentry、Firebase等）
abstract class ErrorReporter {
  /// 错误报告器名称
  String get name;

  /// 是否已初始化
  bool get isInitialized;

  /// 初始化错误报告器
  Future<void> initialize({
    required String dsn,
    required String environment,
    required String release,
    bool enableInDevMode = false,
    double tracesSampleRate = 0.1,
    double profilesSampleRate = 0.1,
  });

  /// 使用配置对象初始化
  Future<void> initializeWithConfig(ErrorReporterConfig config) {
    return initialize(
      dsn: config.dsn,
      environment: config.environment,
      release: config.release,
      enableInDevMode: config.enableInDevMode,
      tracesSampleRate: config.tracesSampleRate,
      profilesSampleRate: config.profilesSampleRate,
    );
  }

  /// 在错误捕获 Zone 中运行应用
  ///
  /// 这是确保完整错误捕获的推荐方式：
  /// - 捕获 appRunner 执行期间的所有未处理异常
  /// - 对于 Sentry，内部使用 SentryFlutter.init 的 appRunner 参数
  /// - 对于 Firebase，内部使用 runZonedGuarded
  ///
  /// [config] 错误报告器配置
  /// [appRunner] 应用启动函数，通常包含 runApp() 调用
  ///
  /// 示例：
  /// ```dart
  /// await reporter.initAndRunGuarded(
  ///   config: config,
  ///   appRunner: () async {
  ///     // 初始化其他服务...
  ///     runApp(MyApp());
  ///   },
  /// );
  /// ```
  Future<void> initAndRunGuarded({
    required ErrorReporterConfig config,
    required Future<void> Function() appRunner,
  });

  /// 记录错误
  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? extras,
    bool fatal = false,
  });

  /// 记录Flutter错误
  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  });

  /// 记录消息
  Future<void> recordMessage(
    String message, {
    ErrorLevel level = ErrorLevel.info,
    Map<String, dynamic>? extras,
  });

  /// 记录面包屑（用于追踪用户操作路径）
  void addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
    ErrorLevel level = ErrorLevel.info,
  });

  /// 设置用户信息
  void setUser({
    String? id,
    String? email,
    String? username,
    Map<String, dynamic>? extras,
  });

  /// 设置上下文标签
  void setTag(String key, String value);

  /// 设置多个上下文标签
  void setTags(Map<String, String> tags);

  /// 设置额外上下文数据
  void setContextData(String key, dynamic value);

  /// 清除用户信息
  void clearUser();

  /// 关闭错误报告器
  Future<void> close();
}

/// 错误等级
enum ErrorLevel {
  debug,
  info,
  warning,
  error,
  fatal;

}

/// 错误报告器工厂
class ErrorReporterFactory {
  static ErrorReporter? _instance;

  /// 获取当前错误报告器实例
  static ErrorReporter? get instance => _instance;

  /// 设置错误报告器实例
  static void setInstance(ErrorReporter reporter) {
    _instance = reporter;
  }

  /// 清除错误报告器实例
  static void clearInstance() {
    _instance = null;
  }

  /// 是否有可用的错误报告器
  static bool get hasReporter => _instance != null && _instance!.isInitialized;

  /// 使用错误报告器初始化并运行应用
  ///
  /// 这是推荐的应用启动方式，确保：
  /// 1. 错误报告器在应用启动前初始化
  /// 2. appRunner 在错误捕获 Zone 中执行
  /// 3. 全局实例自动设置
  ///
  /// [reporter] 错误报告器实例
  /// [config] 错误报告器配置
  /// [appRunner] 应用启动函数
  /// [onInitialized] 初始化成功后的回调（在 appRunner 之前调用）
  static Future<void> initAndRun({
    required ErrorReporter reporter,
    required ErrorReporterConfig config,
    required Future<void> Function() appRunner,
    void Function(ErrorReporter reporter)? onInitialized,
  }) async {
    await reporter.initAndRunGuarded(
      config: config,
      appRunner: () async {
        // 设置全局实例
        setInstance(reporter);
        // 调用初始化回调
        onInitialized?.call(reporter);
        // 运行应用
        await appRunner();
      },
    );
  }
}
