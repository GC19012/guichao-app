// resilient_auth_wrapper.dart

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authtype_model.dart';
import 'package:guichao/gch_base/gch_ink/gch_ink.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_provider_interface.dart';

/// 弹性认证包装器 - 提供错误处理和重试机制
class ResilientAuthWrapper implements AuthProvider {
  final AuthProvider _innerProvider;
  final RetryConfig _retryConfig;
  final CircuitBreakerConfig _circuitBreakerConfig;
  
  late final CircuitBreaker _circuitBreaker;
  final Map<String, RateLimiter> _rateLimiters = {};
  
  ResilientAuthWrapper({
    required AuthProvider innerProvider,
    RetryConfig? retryConfig,
    CircuitBreakerConfig? circuitBreakerConfig,
  }) : _innerProvider = innerProvider,
       _retryConfig = retryConfig ?? const RetryConfig(),
       _circuitBreakerConfig = circuitBreakerConfig ?? const CircuitBreakerConfig() {
    _circuitBreaker = CircuitBreaker(_circuitBreakerConfig);
  }
  
  @override
  String get providerId => '${_innerProvider.providerId}_resilient';
  
  @override
  String get providerName => '${_innerProvider.providerName} (Resilient)';
  
  @override
  Set<AuthType> get supportedAuthTypes => _innerProvider.supportedAuthTypes;
  
  @override
  bool get isInitialized => _innerProvider.isInitialized && _circuitBreaker.state != CircuitBreakerState.open;
  
  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    await _withResilience(() => _innerProvider.initialize(config));
  }
  
  @override
  Future<bool> isAvailable() async {
    if (_circuitBreaker.state == CircuitBreakerState.open) {
      return false;
    }
    return await _innerProvider.isAvailable();
  }
  
  @override
  Future<void> dispose() async {
    await _innerProvider.dispose();
    _rateLimiters.clear();
  }
  
  /// 执行带有弹性机制的操作
  Future<T> _withResilience<T>(Future<T> Function() operation, {String? operationKey}) async {
    // 检查熔断器状态
    if (_circuitBreaker.state == CircuitBreakerState.open) {
      throw AuthException.circuitBreakerOpen();
    }
    
    // 检查速率限制
    if (operationKey != null) {
      final rateLimiter = _getRateLimiter(operationKey);
      if (!await rateLimiter.allowRequest()) {
        throw AuthException.rateLimitExceeded();
      }
    }
    
    return await _executeWithRetry(operation);
  }
  
  /// 执行重试逻辑
  Future<T> _executeWithRetry<T>(Future<T> Function() operation) async {
    int attempt = 0;
    Exception? lastException;
    
    while (attempt < _retryConfig.maxAttempts) {
      try {
        final result = await operation();
        _circuitBreaker.recordSuccess();
        return result;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        attempt++;
        
        if (!_shouldRetry(lastException, attempt)) {
          _circuitBreaker.recordFailure();
          rethrow;
        }
        
        if (attempt < _retryConfig.maxAttempts) {
          final delay = _calculateDelay(attempt);
          GchInk.app.debug('Auth operation failed (attempt $attempt), retrying in ${delay.inMilliseconds}ms: $e');
          await Future.delayed(delay);
        }
      }
    }
    
    _circuitBreaker.recordFailure();
    throw AuthException.maxRetriesExceeded(lastException);
  }
  
  /// 判断是否应该重试
  bool _shouldRetry(Exception exception, int attempt) {
    if (attempt >= _retryConfig.maxAttempts) {
      return false;
    }
    
    // 永不重试的错误类型
    if (exception is AuthException) {
      switch (exception.type) {
        case AuthExceptionType.invalidCredentials:
        case AuthExceptionType.userNotFound:
        case AuthExceptionType.invalidToken:
        case AuthExceptionType.rateLimitExceeded:
        case AuthExceptionType.circuitBreakerOpen:
          return false;
        default:
          break;
      }
    }
    
    // 网络相关错误可以重试
    if (exception is SocketException ||
        exception is TimeoutException ||
        exception is HttpException) {
      return true;
    }
    
    // 检查错误消息
    final message = exception.toString().toLowerCase();
    if (message.contains('network') ||
        message.contains('timeout') ||
        message.contains('connection') ||
        message.contains('server error') ||
        message.contains('5')) {
      return true;
    }
    
    return false;
  }
  
  /// 计算退避延迟
  Duration _calculateDelay(int attempt) {
    switch (_retryConfig.backoffStrategy) {
      case BackoffStrategy.linear:
        return _retryConfig.baseDelay * attempt;
      case BackoffStrategy.exponential:
        return _retryConfig.baseDelay * pow(2, attempt - 1);
      case BackoffStrategy.exponentialWithJitter:
        final exponentialDelay = _retryConfig.baseDelay * pow(2, attempt - 1);
        final jitter = Random().nextDouble() * 0.1; // 10% jitter
        return exponentialDelay * (1 + jitter);
    }
  }
  
  /// 获取速率限制器
  RateLimiter _getRateLimiter(String key) {
    return _rateLimiters.putIfAbsent(key, () => RateLimiter());
  }
}

/// 认证异常
class AuthException implements Exception {
  final AuthExceptionType type;
  final String message;
  final Exception? innerException;
  final DateTime timestamp;
  
  
  AuthException(this.type, this.message, [this.innerException])
      : timestamp = DateTime.now();
  
  factory AuthException.networkError([Exception? inner]) =>
      AuthException(AuthExceptionType.networkError, 'Network error occurred', inner);
  
  factory AuthException.timeout([Exception? inner]) =>
      AuthException(AuthExceptionType.timeout, 'Operation timed out', inner);
  
  factory AuthException.invalidCredentials([Exception? inner]) =>
      AuthException(AuthExceptionType.invalidCredentials, 'Invalid credentials', inner);
  
  factory AuthException.userNotFound([Exception? inner]) =>
      AuthException(AuthExceptionType.userNotFound, 'User not found', inner);
  
  factory AuthException.invalidToken([Exception? inner]) =>
      AuthException(AuthExceptionType.invalidToken, 'Invalid or expired token', inner);
  
  factory AuthException.rateLimitExceeded([Exception? inner]) =>
      AuthException(AuthExceptionType.rateLimitExceeded, 'Rate limit exceeded', inner);
  
  factory AuthException.circuitBreakerOpen([Exception? inner]) =>
      AuthException(AuthExceptionType.circuitBreakerOpen, 'Circuit breaker is open', inner);
  
  factory AuthException.maxRetriesExceeded([Exception? inner]) =>
      AuthException(AuthExceptionType.maxRetriesExceeded, 'Maximum retries exceeded', inner);
  
  factory AuthException.providerUnavailable([Exception? inner]) =>
      AuthException(AuthExceptionType.providerUnavailable, 'Authentication provider unavailable', inner);
  
  @override
  String toString() => 'AuthException($type): $message${innerException != null ? ' - ${innerException.toString()}' : ''}';
}

/// 认证异常类型
enum AuthExceptionType {
  networkError,
  timeout,
  invalidCredentials,
  userNotFound,
  invalidToken,
  rateLimitExceeded,
  circuitBreakerOpen,
  maxRetriesExceeded,
  providerUnavailable,
  unknown,
}

/// 重试配置
class RetryConfig {
  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final BackoffStrategy backoffStrategy;
  
  const RetryConfig({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffStrategy = BackoffStrategy.exponentialWithJitter,
  });
}

/// 退避策略
enum BackoffStrategy {
  linear,
  exponential,
  exponentialWithJitter,
}

/// 熔断器配置
class CircuitBreakerConfig {
  final int failureThreshold;
  final Duration timeout;
  final int successThreshold;
  
  const CircuitBreakerConfig({
    this.failureThreshold = 5,
    this.timeout = const Duration(minutes: 1),
    this.successThreshold = 3,
  });
}

/// 熔断器状态
enum CircuitBreakerState {
  closed,
  open,
  halfOpen,
}

/// 熔断器实现
class CircuitBreaker {
  final CircuitBreakerConfig config;
  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _lastFailureTime;
  
  CircuitBreaker(this.config);
  
  CircuitBreakerState get state => _state;
  
  void recordSuccess() {
    _failureCount = 0;
    if (_state == CircuitBreakerState.halfOpen) {
      _successCount++;
      if (_successCount >= config.successThreshold) {
        _state = CircuitBreakerState.closed;
        _successCount = 0;
      }
    }
  }
  
  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    
    if (_state == CircuitBreakerState.halfOpen) {
      _state = CircuitBreakerState.open;
      _successCount = 0;
    } else if (_failureCount >= config.failureThreshold) {
      _state = CircuitBreakerState.open;
    }
  }
  
  bool canExecute() {
    if (_state == CircuitBreakerState.closed) {
      return true;
    }
    
    if (_state == CircuitBreakerState.open) {
      if (_lastFailureTime != null &&
          DateTime.now().difference(_lastFailureTime!) > config.timeout) {
        _state = CircuitBreakerState.halfOpen;
        return true;
      }
      return false;
    }
    
    // halfOpen state
    return true;
  }
}

/// 速率限制器
class RateLimiter {
  final int maxRequests;
  final Duration window;
  final List<DateTime> _requests = [];
  
  RateLimiter({
    this.maxRequests = 10,
    this.window = const Duration(minutes: 1),
  });
  
  Future<bool> allowRequest() async {
    final now = DateTime.now();
    
    // 清理过期的请求记录
    _requests.removeWhere((time) => now.difference(time) > window);
    
    if (_requests.length < maxRequests) {
      _requests.add(now);
      return true;
    }
    
    return false;
  }
}

/// 统一弹性认证提供者 - 支持所有认证类型
class ResilientProvider extends ResilientAuthWrapper 
    implements CredentialAuthProvider, OtpAuthProvider, OAuthProvider {
  final AuthProvider _provider;
  
  ResilientProvider({
    required AuthProvider provider,
    super.retryConfig,
    super.circuitBreakerConfig,
  }) : _provider = provider,
       super(innerProvider: provider);

  // CredentialAuthProvider 实现
  @override
  Future<AuthResult> signInWithCredential(AuthRequest request) async {
    final credentialProvider = _provider as CredentialAuthProvider;
    return await _withResilience(
      () => credentialProvider.signInWithCredential(request),
      operationKey: 'signInWithCredential',
    );
  }
  
  @override
  Future<AuthResult> signUpWithCredential(AuthRequest request) async {
    final credentialProvider = _provider as CredentialAuthProvider;
    return await _withResilience(
      () => credentialProvider.signUpWithCredential(request),
      operationKey: 'signUpWithCredential',
    );
  }
  
  @override
  Future<bool> resetPassword(String identifier) async {
    final credentialProvider = _provider as CredentialAuthProvider;
    return await _withResilience(
      () => credentialProvider.resetPassword(identifier),
      operationKey: 'resetPassword',
    );
  }
  
  @override
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    final credentialProvider = _provider as CredentialAuthProvider;
    return await _withResilience(
      () => credentialProvider.changePassword(oldPassword, newPassword),
      operationKey: 'changePassword',
    );
  }

  // OtpAuthProvider 实现
  @override
  Future<bool> sendOtp(
    String identifier, {
    OtpType type = OtpType.email,
    String? captchaToken,
    bool shouldCreateUser = true,
  }) async {
    final otpProvider = _provider as OtpAuthProvider;
    return await _withResilience(
      () => otpProvider.sendOtp(
        identifier,
        type: type,
        captchaToken: captchaToken,
        shouldCreateUser: shouldCreateUser,
      ),
      operationKey: 'sendOtp',
    );
  }
  
  @override
  Future<AuthResult> verifyOtp(String identifier, String code, {OtpType type = OtpType.email}) async {
    final otpProvider = _provider as OtpAuthProvider;
    return await _withResilience(
      () => otpProvider.verifyOtp(identifier, code, type: type),
      operationKey: 'verifyOtp',
    );
  }

  // OAuthProvider 实现
  @override
  Future<AuthResult> signInWithOAuth({
    String? authCode,
    String? idToken,
    String? accessToken,
    String? redirectUrl,
    Map<String, dynamic>? extraParams,
  }) async {
    final oauthProvider = _provider as OAuthProvider;
    return await _withResilience(
      () => oauthProvider.signInWithOAuth(
        authCode: authCode,
        idToken: idToken,
        accessToken: accessToken,
        redirectUrl: redirectUrl,
        extraParams: extraParams,
      ),
      operationKey: 'signInWithOAuth',
    );
  }
  
  @override
  Future<String?> getAuthorizationUrl({
    required String redirectUrl,
    List<String>? scopes,
    Map<String, String>? extraParams,
  }) async {
    final oauthProvider = _provider as OAuthProvider;
    return await _withResilience(
      () => oauthProvider.getAuthorizationUrl(
        redirectUrl: redirectUrl,
        scopes: scopes,
        extraParams: extraParams,
      ),
      operationKey: 'getAuthorizationUrl',
    );
  }
}