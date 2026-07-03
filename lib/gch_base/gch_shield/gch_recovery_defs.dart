import 'package:flutter/foundation.dart';

/// 恢复策略枚举
enum GchRecoveryPlan {
  /// 手动恢复，显示重试按钮
  manual,
  
  /// 自动重试，达到次数后转为手动
  autoRetry,
  
  /// 自动重启应用
  autoRestart,
  
  /// 优雅降级，禁用有问题的功能
  gracefulDegradation,
}

/// 错误类型枚举
enum GchErrorKind {
  /// Native崩溃 (SIGSEGV, SIGABRT等)
  nativeCrash,
  
  /// Flutter框架异常
  flutterError,
  
  /// 网络相关错误
  networkError,
  
  /// 超时错误
  timeoutError,
  
  /// 配置错误
  configError,
  
  /// 其他未分类错误
  unknown,
}

/// 错误严重程度
enum GchSeverityLevel {
  /// 低 - 不影响核心功能
  low,
  
  /// 中 - 影响部分功能
  medium,
  
  /// 高 - 影响核心功能
  high,
  
  /// 致命 - 应用无法继续运行
  critical,
}

/// 错误信息数据类
class GchErrorDetail {
  /// 错误对象
  final Object error;
  
  /// 堆栈信息
  final StackTrace? stackTrace;
  
  /// 错误类型
  final GchErrorKind type;
  
  /// 错误严重程度
  final GchSeverityLevel severity;
  
  /// 发生时间
  final DateTime timestamp;
  
  /// 错误上下文信息
  final Map<String, dynamic> context;
  
  /// 是否可恢复
  final bool isRecoverable;

  const GchErrorDetail({
    required this.error,
    this.stackTrace,
    required this.type,
    required this.severity,
    required this.timestamp,
    this.context = const {},
    this.isRecoverable = true,
  });

  /// 从异常创建GchErrorDetail
  factory GchErrorDetail.fromException(
    Object error, 
    StackTrace? stackTrace, {
    Map<String, dynamic> context = const {},
  }) {
    return GchErrorDetail(
      error: error,
      stackTrace: stackTrace,
      type: _classifyError(error),
      severity: _assessSeverity(error),
      timestamp: DateTime.now(),
      context: context,
      isRecoverable: _isRecoverable(error),
    );
  }

  /// 错误分类算法
  static GchErrorKind _classifyError(Object error) {
    final errorStr = error.toString().toLowerCase();
    
    // Native崩溃特征
    if (errorStr.contains('sigsegv') || 
        errorStr.contains('sigabrt') ||
        errorStr.contains('boxservice') ||
        errorStr.contains('gchbox') ||
        errorStr.contains('panic') ||
        errorStr.contains('segmentation')) {
      return GchErrorKind.nativeCrash;
    }
    
    // 网络错误特征
    if (errorStr.contains('network') ||
        errorStr.contains('socket') ||
        errorStr.contains('connection') ||
        errorStr.contains('timeout')) {
      return GchErrorKind.networkError;
    }
    
    // 超时错误
    if (errorStr.contains('timeout') ||
        errorStr.contains('deadline exceeded')) {
      return GchErrorKind.timeoutError;
    }
    
    // 配置错误
    if (errorStr.contains('config') ||
        errorStr.contains('invalid') ||
        errorStr.contains('parse')) {
      return GchErrorKind.configError;
    }
    
    // Flutter框架错误
    if (error is FlutterError) {
      return GchErrorKind.flutterError;
    }
    
    return GchErrorKind.unknown;
  }

  /// 评估错误严重程度
  static GchSeverityLevel _assessSeverity(Object error) {
    final errorStr = error.toString().toLowerCase();
    
    // 致命错误
    if (errorStr.contains('sigsegv') || 
        errorStr.contains('sigabrt') ||
        errorStr.contains('fatal') ||
        errorStr.contains('panic')) {
      return GchSeverityLevel.critical;
    }
    
    // 高严重性错误
    if (errorStr.contains('boxservice') ||
        errorStr.contains('gchbox') ||
        errorStr.contains('connection failed')) {
      return GchSeverityLevel.high;
    }
    
    // 中等严重性错误
    if (errorStr.contains('network') ||
        errorStr.contains('timeout') ||
        errorStr.contains('config')) {
      return GchSeverityLevel.medium;
    }
    
    return GchSeverityLevel.low;
  }

  /// 判断是否可恢复
  static bool _isRecoverable(Object error) {
    final errorStr = error.toString().toLowerCase();
    
    // 不可恢复的错误
    if (errorStr.contains('out of memory') ||
        errorStr.contains('storage full') ||
        errorStr.contains('permission denied')) {
      return false;
    }
    
    return true;
  }

  /// 获取用户友好的错误描述
  String get userFriendlyMessage {
    switch (type) {
      case GchErrorKind.nativeCrash:
        return '核心服务遇到问题，正在尝试恢复...';
      case GchErrorKind.networkError:
        return '网络连接异常，请检查网络设置';
      case GchErrorKind.timeoutError:
        return '操作超时，请稍后重试';
      case GchErrorKind.configError:
        return '配置文件异常，正在尝试修复...';
      case GchErrorKind.flutterError:
        return '界面渲染异常，正在恢复...';
      case GchErrorKind.unknown:
        return '遇到未知问题，正在处理...';
    }
  }

  /// 获取建议的恢复策略
  GchRecoveryPlan get suggestedStrategy {
    switch (severity) {
      case GchSeverityLevel.critical:
        return GchRecoveryPlan.autoRestart;
      case GchSeverityLevel.high:
        return GchRecoveryPlan.autoRetry;
      case GchSeverityLevel.medium:
        return GchRecoveryPlan.gracefulDegradation;
      case GchSeverityLevel.low:
        return GchRecoveryPlan.manual;
    }
  }

  /// 转换为Map，便于日志记录和上报
  Map<String, dynamic> toMap() {
    return {
      'error': error.toString(),
      'stackTrace': stackTrace?.toString(),
      'type': type.name,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
      'isRecoverable': isRecoverable,
      'userMessage': userFriendlyMessage,
      'suggestedStrategy': suggestedStrategy.name,
    };
  }
}

/// 错误回调函数类型定义
typedef GchErrorCallback = void Function(GchErrorDetail errorInfo);

/// 恢复状态
enum GchRecoveryPhase {
  /// 正常状态
  normal,
  
  /// 检测到错误
  errorDetected,
  
  /// 恢复中
  recovering,
  
  /// 恢复成功
  recovered,
  
  /// 恢复失败
  failed,
}