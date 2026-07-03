// 应用内购买错误处理辅助函数
// 从 google_apple_pay_provider.dart 提取，保持所有逻辑不变

// ============================================================================
// 错误异常类
// ============================================================================

/// 用户取消购买异常
///
/// 当检测到用户主动取消购买流程时抛出此异常，
/// 与 [isUserCancelledError] 函数配合使用。
class UserCancelledException implements Exception {
  final String message;

  const UserCancelledException([this.message = '用户取消了购买']);

  @override
  String toString() => 'UserCancelledException: $message';
}

// ============================================================================
// 错误检查辅助函数（消除重复的字符串匹配逻辑）
// ============================================================================

/// 检查是否为网络错误
bool isNetworkError(String errorStr) {
  return errorStr.contains('networkerror') ||
      errorStr.contains('network_error') ||
      errorStr.contains('network error') ||
      errorStr.contains('socketexception') ||
      errorStr.contains('unable to connect') ||
      errorStr.contains('connection failed') ||
      errorStr.contains('no internet') ||
      errorStr.contains('unreachable') ||
      errorStr.contains('host lookup') ||
      errorStr.contains('网络错误');
}

/// 检查是否为服务不可用错误
bool isServiceUnavailableError(String errorStr) {
  return errorStr.contains('serviceunavailable') ||
      errorStr.contains('service_unavailable') ||
      errorStr.contains('service unavailable') ||
      errorStr.contains('billing_unavailable') ||
      errorStr.contains('bilingunavailable') ||
      errorStr.contains('play services') ||
      errorStr.contains('服务不可用');
}

/// 检查是否为超时错误
bool isTimeoutError(String errorStr) {
  return errorStr.contains('servicetimeout') ||
      errorStr.contains('service_timeout') ||
      errorStr.contains('timeout') ||
      errorStr.contains('timed out') ||
      errorStr.contains('超时');
}

/// 检查是否为服务断开错误
bool isServiceDisconnectedError(String errorStr) {
  return errorStr.contains('servicedisconnected') ||
      errorStr.contains('service_disconnected') ||
      errorStr.contains('disconnected');
}

/// 检查是否为用户取消错误
bool isUserCancelledError(String errorStr) {
  return errorStr.contains('user_canceled') ||
      errorStr.contains('usercanceled') ||
      errorStr.contains('cancelled by user') ||
      errorStr.contains('storekit2_purchase_cancelled') ||
      errorStr.contains('purchase_cancelled') ||
      errorStr.contains('cancelled by the user');
}

/// 应用商店初始化错误类型
enum StoreInitError {
  none,           // 无错误
  networkError,   // 网络错误
  serviceUnavailable, // 服务不可用
  serviceTimeout, // 服务超时
  serviceDisconnected, // 服务断开
  billingUnavailable, // Billing服务不可用
  unknown,        // 未知错误
}

/// 应用商店初始化结果
class StoreInitResult {
  final bool success;
  final StoreInitError error;
  final String? errorMessage;
  final String? errorDetails;

  const StoreInitResult({
    required this.success,
    this.error = StoreInitError.none,
    this.errorMessage,
    this.errorDetails,
  });

  factory StoreInitResult.ok() => const StoreInitResult(success: true);

  factory StoreInitResult.failed(StoreInitError error, String message, [String? details]) {
    return StoreInitResult(
      success: false,
      error: error,
      errorMessage: message,
      errorDetails: details,
    );
  }

  /// 是否为网络/服务相关错误
  bool get isNetworkOrServiceError =>
      error == StoreInitError.networkError ||
      error == StoreInitError.serviceUnavailable ||
      error == StoreInitError.serviceTimeout ||
      error == StoreInitError.serviceDisconnected ||
      error == StoreInitError.billingUnavailable;
}
