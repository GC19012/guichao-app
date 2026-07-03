// captcha.dart
//
// 验证码统一入口

import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_captcha/gch_aliyun_captcha.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_captcha/gch_captcha_provider.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_captcha/gch_turnstile_captcha.dart';

export 'gch_aliyun_captcha.dart';
export 'gch_captcha_provider.dart';
export 'gch_turnstile_captcha.dart';

/// 验证码工厂
class CaptchaFactory {
  CaptchaFactory._();

  static Captcha? _instance;

  /// 获取验证码实例
  static Captcha get instance {
    _instance ??= _create();
    return _instance!;
  }

  /// 重置实例
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }

  static Captcha _create() {
    final config = GchNucleus.captcha;
    switch (config.type) {
      case GchCaptchaType.aliyun:
        return AliyunCaptcha();
      case GchCaptchaType.turnstile:
        return TurnstileCaptcha();
    }
  }
}
