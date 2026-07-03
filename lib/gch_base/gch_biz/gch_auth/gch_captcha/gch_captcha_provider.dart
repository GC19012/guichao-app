// captcha_provider.dart
//
// 验证码抽象接口

import 'package:flutter/material.dart';
import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';

/// 验证码结果
class CaptchaResult {
  final String token;
  final String? sessionId;
  final String? sig;
  final String? sceneId;

  const CaptchaResult({
    required this.token,
    this.sessionId,
    this.sig,
    this.sceneId,
  });

  bool get isAliyun => sessionId != null || sceneId != null;

  Map<String, String> toMap() {
    if (isAliyun) {
      return {
        'captcha_token': token,
        if (sessionId != null) 'captcha_session_id': sessionId!,
        if (sig != null) 'captcha_sig': sig!,
        if (sceneId != null) 'captcha_scene_id': sceneId!,
      };
    }
    return {'cf-turnstile-response': token};
  }
}

/// 验证码错误
class CaptchaError implements Exception {
  final String message;
  final int? code;

  const CaptchaError(this.message, {this.code});

  @override
  String toString() => message;
}

/// 验证码接口
abstract class Captcha {
  GchCaptchaType get type;
  bool get isEnabled;

  void show(
    BuildContext context, {
    required void Function(CaptchaResult result) onSuccess,
    void Function(CaptchaError error)? onError,
    VoidCallback? onExpired,
    VoidCallback? onCancel,
  });

  void reset();
  void dispose();
}
