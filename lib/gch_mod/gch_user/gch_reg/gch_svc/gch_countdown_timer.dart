// countdown_timer.dart
import 'dart:async';

/// 倒计时管理器
/// 
/// 提供精确的倒计时功能，支持暂停、恢复和取消
class CountdownTimer {
  Timer? _timer;
  late int _remainingSeconds;
  late int _initialSeconds;
  bool _isActive = false;
  bool _isPaused = false;

  /// 倒计时更新回调
  void Function(int remainingSeconds)? onTick;

  /// 倒计时完成回调
  void Function()? onComplete;

  /// 倒计时取消回调
  void Function()? onCancel;

  CountdownTimer({
    this.onTick,
    this.onComplete,
    this.onCancel,
  });

  /// 开始倒计时
  /// 
  /// [seconds] 倒计时总秒数
  void start(int seconds) {
    if (_isActive) {
      cancel();
    }

    _initialSeconds = seconds;
    _remainingSeconds = seconds;
    _isActive = true;
    _isPaused = false;

    // 立即触发一次回调
    onTick?.call(_remainingSeconds);

    _startTimer();
  }

  /// 暂停倒计时
  void pause() {
    if (_isActive && !_isPaused) {
      _timer?.cancel();
      _isPaused = true;
    }
  }

  /// 恢复倒计时
  void resume() {
    if (_isActive && _isPaused) {
      _isPaused = false;
      _startTimer();
    }
  }

  /// 取消倒计时
  void cancel() {
    if (_isActive) {
      _timer?.cancel();
      _isActive = false;
      _isPaused = false;
      onCancel?.call();
    }
  }

  /// 重置倒计时
  void reset() {
    cancel();
    _remainingSeconds = _initialSeconds;
    onTick?.call(_remainingSeconds);
  }

  /// 添加时间
  void addTime(int seconds) {
    if (_isActive) {
      _remainingSeconds += seconds;
      onTick?.call(_remainingSeconds);
    }
  }

  /// 减少时间
  void reduceTime(int seconds) {
    if (_isActive) {
      _remainingSeconds = (_remainingSeconds - seconds).clamp(0, _remainingSeconds);
      onTick?.call(_remainingSeconds);
      
      if (_remainingSeconds <= 0) {
        _complete();
      }
    }
  }

  /// 开始内部定时器
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        onTick?.call(_remainingSeconds);
      } else {
        _complete();
      }
    });
  }

  /// 完成倒计时
  void _complete() {
    _timer?.cancel();
    _isActive = false;
    _isPaused = false;
    onComplete?.call();
  }

  /// 获取剩余秒数
  int get remainingSeconds => _remainingSeconds;

  /// 获取初始秒数
  int get initialSeconds => _initialSeconds;

  /// 是否正在运行
  bool get isActive => _isActive && !_isPaused;

  /// 是否已暂停
  bool get isPaused => _isPaused;

  /// 是否已完成
  bool get isCompleted => !_isActive && _remainingSeconds <= 0;

  /// 进度百分比 (0.0 - 1.0)
  double get progress {
    if (_initialSeconds <= 0) return 1.0;
    return 1.0 - (_remainingSeconds / _initialSeconds);
  }

  /// 格式化显示时间 (MM:SS)
  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 简单格式显示 (仅秒数)
  String get simpleFormat => '${_remainingSeconds}s';

  /// 销毁定时器
  void dispose() {
    cancel();
    onTick = null;
    onComplete = null;
    onCancel = null;
  }
}

/// 验证码倒计时管理器
/// 
/// 专门用于验证码发送的倒计时，包含重发逻辑
class VerificationCountdownTimer extends CountdownTimer {
  static const int defaultDuration = 60; // 默认60秒
  
  /// 是否可以重发
  bool get canResend => !isActive && !isPaused;

  /// 获取重发按钮文本
  String get resendButtonText {
    if (isActive) {
      return '(${simpleFormat})';
    } else if (remainingSeconds <= 0) {
      return '重新发送';
    } else {
      return '获取验证码';
    }
  }

  /// 开始验证码倒计时
  void startVerificationCountdown({
    int duration = defaultDuration,
    void Function()? onCanResend,
  }) {
    super.onComplete = onCanResend;
    start(duration);
  }

  /// 重新发送验证码
  /// 
  /// 返回是否可以重发
  bool attemptResend() {
    if (canResend) {
      startVerificationCountdown();
      return true;
    }
    return false;
  }
}

/// 倒计时工具类
class CountdownUtils {
  /// 格式化秒数为 MM:SS 格式
  static String formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// 格式化秒数为简单格式
  static String formatSimple(int seconds) {
    if (seconds >= 60) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      if (remainingSeconds == 0) {
        return '${minutes}分钟';
      } else {
        return '${minutes}分${remainingSeconds}秒';
      }
    } else {
      return '${seconds}秒';
    }
  }

  /// 检查是否在冷却期内
  static bool isInCooldown(DateTime? lastSentTime, int cooldownSeconds) {
    if (lastSentTime == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(lastSentTime).inSeconds;
    return difference < cooldownSeconds;
  }

  /// 获取剩余冷却时间
  static int getRemainingCooldown(DateTime? lastSentTime, int cooldownSeconds) {
    if (lastSentTime == null) return 0;
    
    final now = DateTime.now();
    final difference = now.difference(lastSentTime).inSeconds;
    return (cooldownSeconds - difference).clamp(0, cooldownSeconds);
  }

  /// 计算倒计时进度
  static double calculateProgress(int current, int total) {
    if (total <= 0) return 1.0;
    return (total - current) / total;
  }
}