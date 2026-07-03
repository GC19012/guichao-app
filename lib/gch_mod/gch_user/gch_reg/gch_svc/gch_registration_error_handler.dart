// registration_error_handler.dart
import 'package:flutter/material.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:guichao/gch_base/gch_cuowu/gch_cuowu_fanyi.dart';
import 'package:guichao/gch_base/gch_signal/gch_signal_hub.dart';
import 'package:guichao/gch_mod/gch_user/gch_reg/gch_model/gch_registration_state.dart';
import 'package:guichao/gch_gen/gch_text.dart';

/// 注册错误处理器
///
/// 提供统一的错误处理、用户反馈和错误恢复建议
class RegistrationErrorHandler {

  /// 处理注册错误并返回用户友好的错误信息
  /// [] 翻译对象，用于获取本地化文本
  static RegistrationErrorInfo handleError(
    RegistrationErrorType errorType,
    String? originalMessage, {
    String? context,
  }) {
    switch (errorType) {
      case RegistrationErrorType.network:
        return RegistrationErrorInfo(
          title: GchText.userRegisterErrorsNetworkTitle,
          message: GchText.userRegisterErrorsNetworkMessage,
          icon: Icons.wifi_off,
          color: Colors.orange,
          canRetry: true,
          retryDelay: const Duration(seconds: 3),
          suggestions: [
            GchText.userRegisterErrorsNetworkSuggestion1,
            GchText.userRegisterErrorsNetworkSuggestion2,
            GchText.userRegisterErrorsNetworkSuggestion3,
          ],
        );

      case RegistrationErrorType.validation:
        // 对验证错误消息进行本地化处理
        final localizedMessage = originalMessage != null
            ? GchCuowuFanyi.bendihua(originalMessage)
            : GchText.userRegisterErrorsValidationMessage;
        return RegistrationErrorInfo(
          title: GchText.userRegisterErrorsValidationTitle,
          message: localizedMessage,
          icon: Icons.error_outline,
          color: Colors.red,
          canRetry: false,
          suggestions: [
            GchText.userRegisterErrorsValidationSuggestion1,
            GchText.userRegisterErrorsValidationSuggestion2,
            GchText.userRegisterErrorsValidationSuggestion3,
          ],
        );

      case RegistrationErrorType.server:
        return RegistrationErrorInfo(
          title: GchText.userRegisterErrorsServerTitle,
          message: GchText.userRegisterErrorsServerMessage,
          icon: Icons.cloud_off,
          color: Colors.red,
          canRetry: true,
          retryDelay: const Duration(seconds: 5),
          suggestions: [
            GchText.userRegisterErrorsServerSuggestion1,
            GchText.userRegisterErrorsServerSuggestion2,
          ],
        );

      case RegistrationErrorType.invalidCode:
        return RegistrationErrorInfo(
          title: GchText.userRegisterErrorsInvalidCodeTitle,
          message: GchText.userRegisterErrorsInvalidCodeMessage,
          icon: Icons.key_off,
          color: Colors.red,
          canRetry: false,
          suggestions: [
            GchText.userRegisterErrorsInvalidCodeSuggestion1,
            GchText.userRegisterErrorsInvalidCodeSuggestion2,
            GchText.userRegisterErrorsInvalidCodeSuggestion3,
          ],
        );

      case RegistrationErrorType.userExists:
        return RegistrationErrorInfo(
          title: GchText.userRegisterErrorsUserExistsTitle,
          message: GchText.userRegisterErrorsUserExistsMessage,
          icon: Icons.person_outline,
          color: Colors.blue,
          canRetry: false,
          actionText: GchText.userRegisterErrorsGoToLogin,
          suggestions: [
            GchText.userRegisterErrorsUserExistsSuggestion1,
            GchText.userRegisterErrorsUserExistsSuggestion2,
            GchText.userRegisterErrorsUserExistsSuggestion3,
          ],
        );

      case RegistrationErrorType.codeExpired:
        return RegistrationErrorInfo(
          title: GchText.userRegisterErrorsCodeExpiredTitle,
          message: GchText.userRegisterErrorsCodeExpiredMessage,
          icon: Icons.timer_off,
          color: Colors.orange,
          canRetry: false,
          actionText: GchText.userRegisterErrorsResend,
          suggestions: [
            GchText.userRegisterErrorsCodeExpiredSuggestion1,
            GchText.userRegisterErrorsCodeExpiredSuggestion2,
            GchText.userRegisterErrorsCodeExpiredSuggestion3,
          ],
        );

      case RegistrationErrorType.tooManyRequests:
        return RegistrationErrorInfo(
          title: GchText.userRegisterErrorsTooManyRequestsTitle,
          message: GchText.userRegisterErrorsTooManyRequestsMessage,
          icon: Icons.access_time,
          color: Colors.orange,
          canRetry: true,
          retryDelay: const Duration(minutes: 1),
          suggestions: [
            GchText.userRegisterErrorsTooManyRequestsSuggestion1,
            GchText.userRegisterErrorsTooManyRequestsSuggestion2,
            GchText.userRegisterErrorsTooManyRequestsSuggestion3,
          ],
        );

      case RegistrationErrorType.unknown:
        return RegistrationErrorInfo(
          title: GchText.userRegisterErrorsUnknownTitle,
          message: originalMessage ?? GchText.userRegisterErrorsUnknownMessage,
          icon: Icons.help_outline,
          color: Colors.grey,
          canRetry: true,
          retryDelay: const Duration(seconds: 3),
          suggestions: [
            GchText.userRegisterErrorsUnknownSuggestion1,
            GchText.userRegisterErrorsUnknownSuggestion2,
            GchText.userRegisterErrorsUnknownSuggestion3,
          ],
        );
    }
  }

  /// 显示错误对话框
  /// [] 翻译对象，用于获取本地化文本
  static Future<bool?> showErrorDialog(
    BuildContext context,
    RegistrationErrorInfo errorInfo, {
    VoidCallback? onRetry,
    VoidCallback? onAction,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.24.rh),
          ),
          title: Row(
            children: [
              Icon(
                errorInfo.icon,
                color: errorInfo.color,
                size: 18.ri,
              ),
              SizedBox(width: 11.25.rw),
              Expanded(
                child: Text(
                  errorInfo.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.rf,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                errorInfo.message,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13.rf,
                ),
              ),
              if (errorInfo.suggestions.isNotEmpty) ...[
                SizedBox(height: 16.24.rh),
                Text(
                  GchText.userRegisterErrorsCommonSuggestions,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.rf,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.12.rh),
                ...errorInfo.suggestions.map((suggestion) => Padding(
                  padding: EdgeInsets.only(bottom: 4.06.rh),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11.rf,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11.rf,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                GchText.userRegisterErrorsCommonCancel,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            if (errorInfo.actionText != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  onAction?.call();
                },
                child: Text(
                  errorInfo.actionText!,
                  style: const TextStyle(color: Color(0xFF5B8DEF)),
                ),
              ),
            if (errorInfo.canRetry)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  onRetry?.call();
                },
                child: Text(
                  GchText.userRegisterErrorsCommonRetry,
                  style: const TextStyle(color: Color(0xFF5B8DEF)),
                ),
              ),
          ],
        );
      },
    );
  }

  /// 显示简单的错误提示（使用统一的通知控制器）
  ///
  /// [notificationController] 统一的通知控制器
  /// [errorInfo] 错误信息
  /// [] 翻译对象，用于获取本地化文本
  /// [onRetry] 重试回调
  static void showErrorToast(
    GchSignalHub notificationController,
    RegistrationErrorInfo errorInfo, {
    VoidCallback? onRetry,
  }) {
    final message = '${errorInfo.title}: ${errorInfo.message}';

    if (errorInfo.canRetry && onRetry != null) {
      // 带重试按钮的通知
      notificationController.flashAction(
        message,
        actionText: GchText.userRegisterErrorsCommonRetry,
        callback: onRetry,
        duration: const Duration(seconds: 5),
      );
    } else {
      // 普通错误通知
      notificationController.flashError(
        message,
        duration: const Duration(seconds: 5),
      );
    }
  }

  /// 显示简单的错误提示（旧版本，使用 ScaffoldMessenger）
  ///
  /// @deprecated 请使用 [showErrorToast] 方法，使用统一的通知控制器
  @Deprecated('Use showErrorToast instead')
  static void showErrorSnackBar(
    BuildContext context,
    RegistrationErrorInfo errorInfo, {
    VoidCallback? onRetry,
  }) {
    // 先清除之前的 SnackBar
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              errorInfo.icon,
              color: Colors.white,
              size: 15.ri,
            ),
            SizedBox(width: 11.25.rw),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    errorInfo.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    errorInfo.message,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10.rf,
                    ),
                  ),
                ],
              ),
            ),
            // 关闭按钮
            IconButton(
              icon: Icon(Icons.close, color: Colors.white70, size: 15.ri),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        backgroundColor: errorInfo.color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.18.rh),
        ),
        dismissDirection: DismissDirection.horizontal,
        action: errorInfo.canRetry && onRetry != null
            ? SnackBarAction(
                label: GchText.userRegisterErrorsCommonRetry,
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        duration: Duration(
          seconds: errorInfo.canRetry ? 5 : 3,
        ),
      ),
    );
  }

  /// 获取错误的严重程度
  static ErrorSeverity getErrorSeverity(RegistrationErrorType errorType) {
    switch (errorType) {
      case RegistrationErrorType.validation:
      case RegistrationErrorType.invalidCode:
        return ErrorSeverity.warning;
        
      case RegistrationErrorType.network:
      case RegistrationErrorType.codeExpired:
      case RegistrationErrorType.tooManyRequests:
        return ErrorSeverity.error;
        
      case RegistrationErrorType.server:
      case RegistrationErrorType.unknown:
        return ErrorSeverity.critical;
        
      case RegistrationErrorType.userExists:
        return ErrorSeverity.info;
    }
  }

  /// 生成错误报告
  static Map<String, dynamic> generateErrorReport(
    RegistrationErrorType errorType,
    String? originalMessage, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    return {
      'errorType': errorType.toString(),
      'originalMessage': originalMessage,
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
      'severity': getErrorSeverity(errorType).toString(),
      'additionalData': additionalData,
    };
  }
}

/// 注册错误信息
class RegistrationErrorInfo {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final bool canRetry;
  final Duration? retryDelay;
  final String? actionText;
  final List<String> suggestions;

  const RegistrationErrorInfo({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.canRetry,
    this.retryDelay,
    this.actionText,
    this.suggestions = const [],
  });
}

/// 错误严重程度
enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

/// 错误恢复策略
class ErrorRecoveryStrategy {
  final String name;
  final String description;
  final VoidCallback action;
  final bool isAutomatic;
  final Duration? delay;

  const ErrorRecoveryStrategy({
    required this.name,
    required this.description,
    required this.action,
    this.isAutomatic = false,
    this.delay,
  });
}

/// 注册错误统计
class RegistrationErrorStats {
  final Map<RegistrationErrorType, int> _errorCounts = {};
  final Map<RegistrationErrorType, DateTime> _lastOccurrence = {};

  /// 记录错误
  void recordError(RegistrationErrorType errorType) {
    _errorCounts[errorType] = (_errorCounts[errorType] ?? 0) + 1;
    _lastOccurrence[errorType] = DateTime.now();
  }

  /// 获取错误次数
  int getErrorCount(RegistrationErrorType errorType) {
    return _errorCounts[errorType] ?? 0;
  }

  /// 获取最后错误时间
  DateTime? getLastOccurrence(RegistrationErrorType errorType) {
    return _lastOccurrence[errorType];
  }

  /// 是否频繁错误
  bool isFrequentError(RegistrationErrorType errorType, {int threshold = 3}) {
    return getErrorCount(errorType) >= threshold;
  }

  /// 清除统计
  void clear() {
    _errorCounts.clear();
    _lastOccurrence.clear();
  }

  /// 生成错误报告
  Map<String, dynamic> generateReport() {
    return {
      'errorCounts': _errorCounts.map((key, value) => MapEntry(key.toString(), value)),
      'lastOccurrence': _lastOccurrence.map((key, value) => MapEntry(key.toString(), value.toIso8601String())),
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }
}
