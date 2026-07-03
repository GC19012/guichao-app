// turnstile_widget.dart

import 'dart:async';

import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:flutter/material.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_captcha/gch_turnstile_config.dart';

/// Cloudflare Turnstile 验证码组件
///
/// 使用方法:
/// ```dart
/// GuichaoTurnstileWidget(
///   onTokenReceived: (token) {
///     print('Token: $token');
///     // 将 token 发送到后端进行验证
///   },
///   onError: (error) {
///     print('Error: $error');
///   },
/// )
/// ```
class GuichaoTurnstileWidget extends StatelessWidget {
  /// Token 接收回调（验证成功）
  final void Function(String token) onTokenReceived;

  /// 错误回调
  final void Function(TurnstileException error)? onError;

  /// 验证过期回调
  final VoidCallback? onExpired;

  /// 控制器（用于手动重置验证码）
  final TurnstileController? controller;

  /// 自定义主题
  final TurnstileTheme? theme;

  /// 自定义尺寸
  final TurnstileSize? size;

  const GuichaoTurnstileWidget({
    super.key,
    required this.onTokenReceived,
    this.onError,
    this.onExpired,
    this.controller,
    this.theme,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    // 如果禁用了 Turnstile，返回空白占位符
    if (!TurnstileConfig.isEnabled) {
      debugPrint('⚠️ Turnstile 已禁用');
      return const SizedBox.shrink();
    }

    debugPrint('🔧 构建 CloudflareTurnstile 组件, siteKey: ${TurnstileConfig.getSiteKey()}');

    return CloudflareTurnstile(
      siteKey: TurnstileConfig.getSiteKey(),
      baseUrl: TurnstileConfig.baseUrl,
      options: TurnstileOptions(
        theme: theme ?? _getThemeFromContext(context),
        size: size ?? TurnstileSize.normal,
      ),
      controller: controller,
      onTokenReceived: (token) {
        debugPrint('🎫 CloudflareTurnstile onTokenReceived 触发: ${token.substring(0, 20)}...');
        onTokenReceived(token);
      },
      onTokenExpired: () {
        debugPrint('⏳ CloudflareTurnstile onTokenExpired 触发');
        onExpired?.call();
      },
      onError: (error) {
        debugPrint('🚫 CloudflareTurnstile onError 触发: ${error.message} (${error.code})');
        onError?.call(error);
      },
    );
  }

  /// 根据当前主题获取 Turnstile 主题
  TurnstileTheme _getThemeFromContext(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? TurnstileTheme.dark
        : TurnstileTheme.light;
  }
}

/// Turnstile 验证管理器
///
/// 提供便捷方法来管理 Turnstile 验证流程
class TurnstileManager {
  final TurnstileController controller = TurnstileController();

  /// 重置验证码
  void reset() {
    try {
      controller.refreshToken();
    } catch (error) {
      final isLateInit = error.runtimeType.toString().contains('LateInitializationError');
      if (!isLateInit) {
        rethrow;
      }
      debugPrint('Turnstile controller not ready: $error');
    }
  }

  /// 释放资源
  void dispose() {
    // Turnstile controller 不需要手动 dispose
  }
}

/// 带标题的 Turnstile 组件
///
/// 包含一个标题和 Turnstile 验证码
class TurnstileSection extends StatelessWidget {
  final String? title;
  final void Function(String token) onTokenReceived;
  final void Function(TurnstileException error)? onError;
  final VoidCallback? onExpired;
  final TurnstileController? controller;

  const TurnstileSection({
    super.key,
    this.title,
    required this.onTokenReceived,
    this.onError,
    this.onExpired,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (!TurnstileConfig.isEnabled) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE0E0E0),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: GuichaoTurnstileWidget(
            onTokenReceived: onTokenReceived,
            onError: onError,
            onExpired: onExpired,
            controller: controller,
          ),
        ),
      ],
    );
  }
}

/// Turnstile 遮罩层组件
///
/// 在验证期间显示为全屏遮罩，阻止其他交互
class TurnstileOverlay extends StatefulWidget {
  final void Function(String token) onTokenReceived;
  final void Function(TurnstileException error)? onError;
  final VoidCallback? onExpired;
  final VoidCallback? onCancel;
  final TurnstileController? controller;

  const TurnstileOverlay({
    super.key,
    required this.onTokenReceived,
    this.onError,
    this.onExpired,
    this.onCancel,
    this.controller,
  });

  @override
  State<TurnstileOverlay> createState() => _TurnstileOverlayState();

  /// 显示 Turnstile 遮罩层
  static void show(
    BuildContext context, {
    required void Function(String token) onTokenReceived,
    void Function(TurnstileException error)? onError,
    VoidCallback? onExpired,
    VoidCallback? onCancel,
    TurnstileController? controller,
  }) {
    debugPrint('📱 显示 Turnstile Overlay');
    showDialog(
      context: context,
      barrierDismissible: onCancel != null,
      barrierColor: Colors.transparent,
      builder: (dialogContext) => TurnstileOverlay(
        onTokenReceived: (token) {
          debugPrint('✨ Overlay onTokenReceived 回调触发');
          // 验证成功后立即关闭对话框
          Navigator.of(dialogContext).pop();
          debugPrint('🚪 关闭对话框');
          // 延迟一帧执行回调，确保对话框已完全关闭
          Future.microtask(() {
            debugPrint('🎯 执行外部 onTokenReceived 回调');
            onTokenReceived(token);
          });
        },
        onError: (error) {
          debugPrint('💥 Overlay onError 回调触发: ${error.message}');
          // 错误时也关闭对话框
          Navigator.of(dialogContext).pop();
          debugPrint('🚪 关闭对话框 (错误)');
          onError?.call(error);
        },
        onExpired: () {
          debugPrint('⌛ Overlay onExpired 回调触发');
          // 过期时也关闭对话框
          Navigator.of(dialogContext).pop();
          debugPrint('🚪 关闭对话框 (过期)');
          onExpired?.call();
        },
        onCancel: onCancel != null
            ? () {
                debugPrint('❌ Overlay onCancel 回调触发');
                Navigator.of(dialogContext).pop();
                debugPrint('🚪 关闭对话框 (取消)');
                onCancel();
              }
            : null,
        controller: controller,
      ),
    );
  }
}

class _TurnstileOverlayState extends State<TurnstileOverlay> {
  bool _isLoading = true;
  bool _showTimeoutHint = false;
  bool _hasError = false;
  bool _tokenReceived = false;
  bool _autoRetried = false;
  int _retryKey = 0;

  Timer? _loadingTimer;
  Timer? _hintTimer;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    debugPrint('🎯 Turnstile Overlay 初始化');
    _startTimers();
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  void _cancelTimers() {
    _loadingTimer?.cancel();
    _hintTimer?.cancel();
    _timeoutTimer?.cancel();
  }

  void _startTimers() {
    _cancelTimers();
    _loadingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _isLoading && !_hasError) {
        debugPrint('⏰ 2秒计时器触发 - 隐藏loading, tokenReceived: $_tokenReceived');
        setState(() { _isLoading = false; });
      }
    });
    _hintTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && !_hasError && !_tokenReceived) {
        debugPrint('⏰ 8秒计时器触发 - 显示慢速提示, tokenReceived: $_tokenReceived');
        setState(() { _showTimeoutHint = true; });
      }
    });
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && !_hasError && !_tokenReceived) {
        debugPrint('⏰ 30秒超时触发 - tokenReceived: $_tokenReceived, hasError: $_hasError');
        _handleTimeout();
      } else {
        debugPrint('⏰ 30秒计时器触发但不执行超时 - tokenReceived: $_tokenReceived, hasError: $_hasError, mounted: $mounted');
      }
    });
  }

  void _handleTokenReceived(String token) {
    debugPrint('✅ Turnstile Token 接收: ${token.substring(0, 20)}...');
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = false;
        _tokenReceived = true;
      });
    }
    debugPrint('📤 调用 onTokenReceived 回调');
    widget.onTokenReceived(token);
  }

  void _handleError(TurnstileException error) {
    debugPrint('❌ Turnstile 错误: ${error.message} (code: ${error.code})');
    // First failure: silently rebuild the WebView in place (warm-up retry).
    // Keeps the dialog open — no dismiss/reopen animation race on iOS.
    if (!_autoRetried && mounted) {
      _autoRetried = true;
      debugPrint('🔄 Turnstile 首次错误，静默重试 WebView');
      setState(() {
        _isLoading = true;
        _hasError = false;
        _showTimeoutHint = false;
        _retryKey++;
      });
      _startTimers();
      return;
    }
    // Second failure: show error and dismiss.
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        debugPrint('📤 调用 onError 回调');
        widget.onError?.call(error);
      }
    });
  }

  void _handleTimeout() {
    debugPrint('⏱️ 处理超时 - hasError: $_hasError, tokenReceived: $_tokenReceived');
    if (_hasError) {
      debugPrint('⏱️ 已有错误,跳过超时处理');
      return;
    }

    setState(() {
      _hasError = true;
    });

    // 创建超时错误 - code是整数类型,使用-1表示超时
    final timeoutError = TurnstileException(
      '验证超时,请检查网络连接后重试',
      code: -1, // 使用-1表示超时错误
    );

    debugPrint('📤 调用超时 onError 回调');
    widget.onError?.call(timeoutError);
  }

  @override
  Widget build(BuildContext context) {
    if (!TurnstileConfig.isEnabled) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.black.withOpacity(0.5),
      child: SafeArea(
        child: Stack(
          children: [
            // 点击遮罩取消
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onCancel,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
            // 验证组件居中显示
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFDAE4FF),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '安全验证',
                          style: TextStyle(
                            color: Color(0xFF333333),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.onCancel != null)
                          IconButton(
                            onPressed: widget.onCancel,
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF999999),
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!_hasError) ...[
                      const Text(
                        '为确保账号安全，请完成人机验证',
                        style: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_showTimeoutHint) ...[
                        const SizedBox(height: 8),
                        const Text(
                          '网络加载较慢，请稍候...',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ] else ...[
                      const Text(
                        '验证组件加载失败，请重试',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '可能原因：网络连接不稳定或设备不支持',
                        style: TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Turnstile容器 - 固定高度保持布局稳定
                    SizedBox(
                      height: 160, // 固定高度，防止布局抖动
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Turnstile 组件（始终渲染，除非有错误）
                          if (!_hasError)
                            GuichaoTurnstileWidget(
                              key: ValueKey(_retryKey),
                              onTokenReceived: _handleTokenReceived,
                              onError: _handleError,
                              onExpired: widget.onExpired,
                              controller: widget.controller,
                            ),
                          // 加载指示器（仅在加载时显示，覆盖在Turnstile上方）
                          if (_isLoading && !_hasError)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDAE4FF).withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    '正在加载验证组件...',
                                    style: TextStyle(
                                      color: Color(0xFF999999),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // 错误图标
                          if (_hasError)
                            Container(
                              padding: const EdgeInsets.all(40),
                              child: const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.redAccent,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
