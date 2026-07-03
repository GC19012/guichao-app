// turnstile_config.dart

import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';

/// Cloudflare Turnstile 配置
class TurnstileConfig {
  TurnstileConfig._();

  static GchCaptchaConfig get _captcha => GchNucleus.captcha;

  static String get siteKey => _captcha.turnstileSiteKey;
  static String get baseUrl => _captcha.turnstileBaseUrl;
  static String get mode => 'non-interactive';
  static String get theme => 'auto';
  static String get size => 'normal';
  static String get responseFieldName => 'cf-turnstile-response';
  static bool get isTestMode => false;

  static String getSiteKey() => siteKey;
  static bool get isEnabled => _captcha.isEnabled && _captcha.type == GchCaptchaType.turnstile;
}
