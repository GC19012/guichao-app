// aliyun_captcha.dart
//
// 阿里云验证码实现

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_captcha/gch_captcha_provider.dart';

/// 阿里云验证码
class AliyunCaptcha implements Captcha {
  @override
  GchCaptchaType get type => GchCaptchaType.aliyun;

  @override
  bool get isEnabled => GchNucleus.captcha.isEnabled;

  @override
  void show(
    BuildContext context, {
    required void Function(CaptchaResult result) onSuccess,
    void Function(CaptchaError error)? onError,
    VoidCallback? onExpired,
    VoidCallback? onCancel,
  }) {
    if (!isEnabled) {
      onSuccess(const CaptchaResult(token: ''));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: onCancel != null,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => _AliyunDialog(
        onSuccess: (result) {
          Navigator.of(ctx).pop();
          Future.microtask(() => onSuccess(result));
        },
        onError: (error) {
          Navigator.of(ctx).pop();
          onError?.call(error);
        },
        onCancel: onCancel != null
            ? () {
                Navigator.of(ctx).pop();
                onCancel();
              }
            : null,
      ),
    );
  }

  @override
  void reset() {}

  @override
  void dispose() {}
}

class _AliyunDialog extends StatefulWidget {
  final void Function(CaptchaResult result) onSuccess;
  final void Function(CaptchaError error)? onError;
  final VoidCallback? onCancel;

  const _AliyunDialog({
    required this.onSuccess,
    this.onError,
    this.onCancel,
  });

  @override
  State<_AliyunDialog> createState() => _AliyunDialogState();
}

class _AliyunDialogState extends State<_AliyunDialog> {
  InAppWebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    _timeout = Timer(const Duration(seconds: 30), _onTimeout);
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  void _onTimeout() {
    if (_isLoading && mounted) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      widget.onError?.call(const CaptchaError('验证码加载超时', code: -1));
    }
  }

  String _buildHtml() {
    final config = GchNucleus.captcha;
    return '''
<!DOCTYPE html>
<html lang="zh">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>安全验证</title>
    <script>
        window.AliyunCaptchaConfig = {
            region: "cn",
            prefix: "${config.aliyunPrefix}",
        };
    </script>
    <script type="text/javascript" src="https://o.alicdn.com/captcha-frontend/aliyunCaptcha/AliyunCaptcha.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body {
            width: 100%;
            height: 100%;
            background: #DAE4FF;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        #captcha-element {
            width: 100%;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        #captcha-button { display: none; }
    </style>
</head>
<body>
<div id="captcha-element"></div>
<div id="captcha-button"></div>

<script>
    var captcha;

    function initCaptcha() {
        try {
            window.initAliyunCaptcha({
                SceneId: '${config.aliyunSceneId}',
                mode: 'embed',
                element: '#captcha-element',
                button: '#captcha-button',
                success: onSuccess,
                fail: onFail,
                getInstance: getInstance,
                slideStyle: {
                    width: 320,
                    height: 40,
                },
                language: '${config.aliyunLang}',
            });
        } catch (e) {
            console.error('initCaptcha error:', e);
            if (window.flutter_inappwebview) {
                window.flutter_inappwebview.callHandler('onError', e.toString());
            }
        }
    }

    function getInstance(instance) {
        captcha = instance;
    }

    // 验证成功回调
    function onSuccess(captchaVerifyParam) {
        console.log('验证成功:', captchaVerifyParam);
        if (window.flutter_inappwebview) {
            window.flutter_inappwebview.callHandler('onSuccess', captchaVerifyParam);
        }
    }

    // 验证失败回调
    function onFail(result) {
        console.error('验证失败:', result);
        if (window.flutter_inappwebview) {
            window.flutter_inappwebview.callHandler('onFail', result || '验证失败');
        }
    }

    // 页面加载完成后初始化
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initCaptcha);
    } else {
        initCaptcha();
    }
</script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 容器宽度：屏幕宽度 - 边距，最小380px，最大500px
    final containerWidth = (screenWidth - 32).clamp(380.0, 500.0);

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: containerWidth,
          height: 220,
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
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '安全验证',
                      style: TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.onCancel != null)
                      GestureDetector(
                        onTap: widget.onCancel,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.close, color: Color(0xFF999999), size: 20),
                        ),
                      ),
                  ],
                ),
              ),
              // WebView 容器
              Expanded(
                child: Stack(
                  children: [
                    InAppWebView(
                      initialData: InAppWebViewInitialData(
                        data: _buildHtml(),
                        baseUrl: WebUri('https://captcha.aliyuncs.com'),
                        mimeType: 'text/html',
                        encoding: 'utf-8',
                      ),
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,
                        transparentBackground: true,
                        supportZoom: false,
                        disableHorizontalScroll: true,
                        disableVerticalScroll: true,
                        useWideViewPort: true,
                        loadWithOverviewMode: true,
                        isInspectable: kDebugMode,
                      ),
                      onWebViewCreated: (controller) {
                        _controller = controller;
                        // 注册JS回调处理器
                        controller.addJavaScriptHandler(
                          handlerName: 'onSuccess',
                          callback: (List<dynamic> args) {
                            _timeout?.cancel();
                            if (args.isNotEmpty) {
                              widget.onSuccess(CaptchaResult(
                                token: args[0].toString(),
                              ));
                            }
                            return null;
                          },
                        );
                        controller.addJavaScriptHandler(
                          handlerName: 'onError',
                          callback: (List<dynamic> args) {
                            _timeout?.cancel();
                            if (mounted) {
                              setState(() {
                                _hasError = true;
                                _isLoading = false;
                              });
                            }
                            widget.onError?.call(CaptchaError(
                              args.isNotEmpty ? args[0].toString() : '验证码加载失败',
                            ));
                            return null;
                          },
                        );
                        controller.addJavaScriptHandler(
                          handlerName: 'onFail',
                          callback: (List<dynamic> args) {
                            // 验证失败时不关闭弹窗，让用户重试
                            // SDK会自动刷新验证码
                            debugPrint('验证码验证失败: ${args.isNotEmpty ? args[0] : "未知错误"}');
                            return null;
                          },
                        );
                      },
                      onLoadStop: (controller, url) {
                        _timeout?.cancel();
                        if (mounted) {
                          setState(() => _isLoading = false);
                        }
                      },
                      onReceivedError: (controller, request, error) {
                        if (mounted) {
                          setState(() {
                            _hasError = true;
                            _isLoading = false;
                          });
                        }
                      },
                    ),
                    if (_isLoading && !_hasError)
                      Container(
                        color: const Color(0xFFDAE4FF),
                        child: const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Color(0xFF6366F1)),
                            ),
                          ),
                        ),
                      ),
                    if (_hasError)
                      Container(
                        color: Colors.white,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
                              const SizedBox(height: 12),
                              const Text(
                                '加载失败',
                                style: TextStyle(color: Color(0xFF999999), fontSize: 15),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _hasError = false;
                                    _isLoading = true;
                                  });
                                  _controller?.reload();
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFF5F5F5),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                ),
                                child: const Text('重试', style: TextStyle(color: Color(0xFF6366F1))),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
