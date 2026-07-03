import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guichao/gch_bootstrap.dart';
import 'package:guichao/gch_base/gch_store/gch_kv/gch_kv_prefs.dart';
import 'package:guichao/gch_base/gch_store/gch_storage/gch_manager.dart';
import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';

/// 启动崩溃边界 - 专门处理应用启动阶段的错误
class GchBootWall extends StatefulWidget {
  const GchBootWall({
    super.key,
    required this.error,
    required this.stackTrace,
    required this.onRetry,
    required this.progressTracker,
    this.maxGlobalRetries = 5,
    this.currentGlobalRetry = 0,
  });

  final Object error;
  final StackTrace stackTrace;
  final Future<void> Function() onRetry;
  final BootstrapProgressTracker progressTracker;

  /// 全局最大重试次数（跨整个应用生命周期）
  final int maxGlobalRetries;

  /// 当前全局重试次数
  final int currentGlobalRetry;

  @override
  State<GchBootWall> createState() => _GchBootWallState();
}

class _GchBootWallState extends State<GchBootWall> {
  bool _isRetrying = false;
  bool _isCleaning = false;
  bool _autoRestartInProgress = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  Timer? _autoRestartTimer;
  int _autoRestartSecondsLeft = 5;
  bool _autoRestartScheduled = false;

  /// 自动重启失败次数 - 用于防止自动重启无限循环
  int _autoRestartFailCount = 0;
  static const int _maxAutoRestartFails = 2;

  /// 是否已达到最终失败状态（不再自动重启）
  bool _reachedFinalFailure = false;

  @override
  void dispose() {
    _cancelAutoRestartTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061428),
      body: SafeArea(
        child: ValueListenableBuilder<BootstrapProgressState>(
          valueListenable: widget.progressTracker.notifier,
          builder: (context, progress, _) {
            // 只有在未达到最终失败状态时才调度自动重启
            if (_retryCount >= _maxRetries &&
                !_autoRestartScheduled &&
                !_isRetrying &&
                !_reachedFinalFailure) {
              _scheduleAutoRestart();
            }
            return _buildContent(progress);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BootstrapProgressState progress) {
    final stepException = widget.error is BootstrapStepException ? widget.error as BootstrapStepException : null;
    final failedStepName = stepException?.stepName ?? progress.failedStep?.name;
    final failedReason = stepException?.originalError.toString() ?? progress.failedStep?.error?.toString();
    final recentSteps = _recentSteps(progress);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF061428),
            Color(0xFF091E34),
            Color(0xFF102D53),
            Color(0xFF0A1C38),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildStatusCard(failedStepName, failedReason),
                const SizedBox(height: 24),
                if (recentSteps.isNotEmpty) _buildTimelineCard(recentSteps),
                const SizedBox(height: 24),
                _buildActionSection(),
                if (GchNucleus.isDevMode) ...[
                  const SizedBox(height: 24),
                  _buildDebugInfo(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
            gradient: const LinearGradient(
              colors: [Color(0x3327C9FF), Color(0x1911A1F0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            Icons.shield_moon_outlined,
            color: Colors.white,
            size: 56,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '启动管家正在协助恢复',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w300,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '我们已经记录异常并准备重新启动服务',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusCard(String? failedStepName, String? failedReason) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x33112244),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            failedStepName != null ? '当前停留在：$failedStepName' : '当前阶段：未知',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            failedReason ?? '我们会在后台继续收集更多信息。',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '已尝试：$_retryCount / $_maxRetries',
            style: TextStyle(
              color: Colors.orangeAccent.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(List<BootstrapStepRecord> steps) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0x22112244),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '启动诊断',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ...steps.map(_buildStepTile),
        ],
      ),
    );
  }

  Widget _buildStepTile(BootstrapStepRecord step) {
    final color = switch (step.status) {
      BootstrapStepStatus.success => Colors.lightGreenAccent,
      BootstrapStepStatus.failed => Colors.orangeAccent,
      BootstrapStepStatus.running => Colors.cyanAccent,
      BootstrapStepStatus.pending => Colors.white70,
    };
    final icon = switch (step.status) {
      BootstrapStepStatus.success => Icons.check_circle_outline,
      BootstrapStepStatus.failed => Icons.error_outline,
      BootstrapStepStatus.running => Icons.timelapse,
      BootstrapStepStatus.pending => Icons.radio_button_unchecked,
    };
    final duration = step.duration?.inMilliseconds;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.name,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (duration != null)
                  Text(
                    '耗时 ${duration}ms',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                if (step.error != null)
                  Text(
                    step.error.toString(),
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    if (_isRetrying) {
      final statusText = _autoRestartInProgress
          ? '正在自动重新启动…'
          : _isCleaning
              ? '正在清理缓存并重试…'
              : '正在重试启动…';
      return Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
          ),
          const SizedBox(height: 16),
          Text(
            statusText,
            style: const TextStyle(color: Colors.cyanAccent, fontSize: 16),
          ),
        ],
      );
    }

    if (_retryCount >= _maxRetries) {
      // 已达到最终失败状态，显示退出选项
      if (_reachedFinalFailure) {
        return Column(
          children: [
            const Text(
              '多次重试均已失败，建议重启设备或重新安装应用',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: _buildActionButton(
                label: '退出应用',
                onPressed: _handleExit,
                isPrimary: false,
              ),
            ),
          ],
        );
      }
      // 还有自动重启机会
      return Column(
        children: [
          Text(
            '我们将在 $_autoRestartSecondsLeft 秒后尝试自动重启应用'
            '（第 ${_autoRestartFailCount + 1}/$_maxAutoRestartFails 次）',
            style: const TextStyle(color: Colors.white70, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(
              label: '立即退出',
              onPressed: _handleExit,
              isPrimary: false,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: _buildActionButton(
                label: '重试启动',
                onPressed: _handleRetry,
                isPrimary: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                label: '清理缓存后重试',
                onPressed: _handleCleanAndRetry,
                isPrimary: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            label: '退出应用',
            onPressed: _handleExit,
            isPrimary: false,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: isPrimary
            ? const LinearGradient(
                colors: [Color(0xFF1DE9B6), Color(0xFF00ACC1)],
              )
            : null,
        border: isPrimary ? null : Border.all(color: Colors.white30),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: Colors.tealAccent.withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isPrimary ? Colors.white : Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDebugInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bug_report, size: 16, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Text(
                'DEBUG INFO',
                style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            widget.error.toString(),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Colors.white70,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRetry() async {
    if (_isRetrying || _retryCount >= _maxRetries) return;
    _cancelAutoRestartTimer();
    setState(() {
      _isRetrying = true;
      _isCleaning = false;
      _retryCount++;
    });
    await _restartApp(clean: false);
  }

  Future<void> _handleCleanAndRetry() async {
    if (_isRetrying || _retryCount >= _maxRetries) return;
    _cancelAutoRestartTimer();
    setState(() {
      _isRetrying = true;
      _isCleaning = true;
      _retryCount++;
    });
    await _restartApp(clean: true);
  }

  Future<void> _restartApp({required bool clean, bool automatic = false}) async {
    try {
      if (clean) {
        await GchKvPrefs.shutdown();
        await GchStorageManager.gchShutdown();
      }
      resetBootstrapState(disposeContainer: false, clearAbort: false);
      await widget.onRetry();
    } catch (error, stackTrace) {
      if (GchNucleus.isDevMode) {
        debugPrint('🔴 启动重试失败: $error');
        debugPrint('🔴 堆栈: $stackTrace');
      }
      if (!mounted) return;

      setState(() {
        _isRetrying = false;
        _isCleaning = false;
        if (automatic) {
          _autoRestartInProgress = false;
          _autoRestartFailCount++;
        }
      });

      if (automatic) {
        // 检查自动重启失败次数，防止无限循环
        if (_autoRestartFailCount >= _maxAutoRestartFails) {
          _reachedFinalFailure = true;
          _showFinalError();
        } else {
          // 还有自动重启机会，继续调度
          _scheduleAutoRestart();
        }
      } else if (_retryCount >= _maxRetries) {
        _showFinalError();
      }
    }
  }

  void _handleExit() {
    _cancelAutoRestartTimer();
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }

  void _showFinalError() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111C3E),
        title: const Text(
          '无法启动应用',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '我们已多次尝试但仍未成功。\n建议执行以下操作：\n\n'
          '1. 重启设备\n'
          '2. 清除应用数据\n'
          '3. 重新安装应用\n'
          '4. 联系技术支持并附上日志',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: _handleExit,
            child: const Text('退出', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  void _scheduleAutoRestart() {
    // 安全检查：如果已达到最终失败状态或已调度，不再调度
    if (_autoRestartScheduled || _reachedFinalFailure) return;

    // 检查全局重试次数限制
    if (widget.currentGlobalRetry >= widget.maxGlobalRetries) {
      _reachedFinalFailure = true;
      return;
    }

    // 检查自动重启失败次数
    if (_autoRestartFailCount >= _maxAutoRestartFails) {
      _reachedFinalFailure = true;
      return;
    }

    // ✅ 防止 Timer 泄漏：创建新 timer 前先取消可能存在的旧 timer
    _autoRestartTimer?.cancel();

    _autoRestartSecondsLeft = 5;
    _autoRestartScheduled = true;
    _autoRestartTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _autoRestartSecondsLeft = (_autoRestartSecondsLeft - 1).clamp(0, 5).toInt();
      });
      if (_autoRestartSecondsLeft == 0) {
        timer.cancel();
        _autoRestartScheduled = false;
        _autoRestartTimer = null;
        _performAutoRestart();
      }
    });
  }

  void _performAutoRestart() {
    // 安全检查：防止无限循环
    if (_isRetrying || _reachedFinalFailure) return;

    // 再次检查自动重启失败次数
    if (_autoRestartFailCount >= _maxAutoRestartFails) {
      _reachedFinalFailure = true;
      _showFinalError();
      return;
    }

    setState(() {
      _isRetrying = true;
      _autoRestartInProgress = true;
    });
    _autoRestartScheduled = false;
    _autoRestartTimer = null;
    _restartApp(clean: false, automatic: true);
  }

  void _cancelAutoRestartTimer() {
    _autoRestartTimer?.cancel();
    _autoRestartTimer = null;
    _autoRestartScheduled = false;
    _autoRestartSecondsLeft = 5;
  }

  List<BootstrapStepRecord> _recentSteps(BootstrapProgressState progress) {
    final entries = <BootstrapStepRecord>[];
    entries.addAll(progress.history);
    if (progress.currentStep != null) {
      entries.add(progress.currentStep!);
    }
    if (entries.length > 6) {
      entries.removeRange(0, entries.length - 6);
    }
    return entries.reversed.toList();
  }
}
