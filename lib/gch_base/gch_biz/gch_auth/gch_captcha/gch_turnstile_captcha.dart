// turnstile_captcha.dart
//
// Cloudflare Turnstile 验证码实现

import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:flutter/material.dart';
import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_captcha/gch_captcha_provider.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_captcha/gch_turnstile_widget.dart';

/// Turnstile 验证码
class TurnstileCaptcha implements Captcha {
  final TurnstileController _controller = TurnstileController();

  @override
  GchCaptchaType get type => GchCaptchaType.turnstile;

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

    TurnstileOverlay.show(
      context,
      controller: _controller,
      onTokenReceived: (token) {
        onSuccess(CaptchaResult(token: token));
      },
      onError: (error) {
        onError?.call(CaptchaError(error.message, code: error.code));
      },
      onExpired: onExpired,
      onCancel: onCancel,
    );
  }

  @override
  void reset() {
    try {
      _controller.refreshToken();
    } catch (_) {}
  }

  @override
  void dispose() {}
}
