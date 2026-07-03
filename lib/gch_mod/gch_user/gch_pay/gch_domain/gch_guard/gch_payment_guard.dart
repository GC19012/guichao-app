import 'package:flutter/foundation.dart';

/// Payment Guard - Concurrency Control
///
/// Responsibilities:
/// 1. Payment lock (prevent duplicate payments)
/// 2. Debounce (prevent rapid clicks)
/// 3. Concurrent request control
///
/// Design: Singleton pattern for process-level lock management
class PaymentGuard {
  PaymentGuard._();
  static final PaymentGuard instance = PaymentGuard._();

  // ========== Configuration ==========

  /// Debounce interval
  static const Duration debounceInterval = Duration(milliseconds: 200);

  /// Lock timeout
  static const Duration lockTimeout = Duration(minutes: 3);

  // ========== State ==========

  /// Global payment locks (process-level)
  /// Key format: "userId:productId:providerCode"
  final Map<String, DateTime> _locks = {};

  /// Last tap time (for debounce)
  DateTime? _lastTapTime;

  /// Current lock key
  String? _currentLockKey;

  // ========== Debounce ==========

  /// Check if should debounce (returns true if should block)
  bool shouldDebounce() {
    final now = DateTime.now();
    if (_lastTapTime != null) {
      final elapsed = now.difference(_lastTapTime!);
      if (elapsed < debounceInterval) {
        debugPrint('⚠️ Debounce: blocking tap within ${elapsed.inMilliseconds}ms');
        return true;
      }
    }
    _lastTapTime = now;
    return false;
  }

  /// Reset debounce timer
  void resetDebounce() {
    _lastTapTime = null;
  }

  // ========== Payment Lock ==========

  /// Generate lock key
  String generateLockKey({
    required String userId,
    required String productId,
    required String providerCode,
  }) {
    return '$userId:$productId:${providerCode.toLowerCase()}';
  }

  /// Try to acquire payment lock
  /// Returns true if lock acquired successfully
  bool tryAcquireLock(String lockKey) {
    _cleanupExpiredLocks();

    final existingLockTime = _locks[lockKey];
    if (existingLockTime != null) {
      final elapsed = DateTime.now().difference(existingLockTime);
      if (elapsed < lockTimeout) {
        debugPrint('🔒 Payment lock exists: $lockKey (${elapsed.inSeconds}s/${lockTimeout.inSeconds}s)');
        return false;
      }
    }

    _locks[lockKey] = DateTime.now();
    _currentLockKey = lockKey;
    debugPrint('🔓 Payment lock acquired: $lockKey');
    return true;
  }

  /// Release current payment lock
  void releaseLock() {
    if (_currentLockKey != null) {
      _locks.remove(_currentLockKey);
      debugPrint('🔓 Payment lock released: $_currentLockKey');
      _currentLockKey = null;
    }
  }

  /// Release specific lock
  void releaseLockByKey(String lockKey) {
    _locks.remove(lockKey);
    if (_currentLockKey == lockKey) {
      _currentLockKey = null;
    }
    debugPrint('🔓 Payment lock released: $lockKey');
  }

  /// Check if a lock exists
  bool hasLock(String lockKey) {
    _cleanupExpiredLocks();
    return _locks.containsKey(lockKey);
  }

  /// Get current lock key
  String? get currentLockKey => _currentLockKey;

  /// Check if currently locked
  bool get isLocked => _currentLockKey != null;

  // ========== Private Methods ==========

  /// Cleanup expired locks
  void _cleanupExpiredLocks() {
    final now = DateTime.now();
    _locks.removeWhere((key, lockTime) {
      final expired = now.difference(lockTime) > lockTimeout;
      if (expired) {
        debugPrint('🧹 Expired lock removed: $key');
      }
      return expired;
    });
  }

  /// Force cleanup all locks (for testing/emergency)
  void forceCleanup() {
    _locks.clear();
    _currentLockKey = null;
    _lastTapTime = null;
    debugPrint('🧹 All payment locks force cleaned');
  }
}

/// Payment Guard Result
class PaymentGuardResult {
  final bool allowed;
  final PaymentGuardRejection? rejection;

  const PaymentGuardResult.allowed() : allowed = true, rejection = null;
  const PaymentGuardResult.rejected(this.rejection) : allowed = false;

  bool get isRejected => !allowed;
}

/// Payment Guard Rejection Reason
enum PaymentGuardRejection {
  debounced,
  locked,
  processing,
}

extension PaymentGuardRejectionX on PaymentGuardRejection {
  String get message {
    switch (this) {
      case PaymentGuardRejection.debounced:
        return 'Please wait before trying again';
      case PaymentGuardRejection.locked:
        return 'Payment is being processed';
      case PaymentGuardRejection.processing:
        return 'Another payment is in progress';
    }
  }
}
