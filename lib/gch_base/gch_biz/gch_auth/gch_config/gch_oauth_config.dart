/// OAuth重定向配置
class OAuthConfig {
  OAuthConfig._();

  /// 获取重定向URL
  static String? getRedirectUrl(String provider, {String? customRedirectPath}) {
    const String scheme = 'guichao';

    // 支持自定义重定向路径
    String path;
    if (customRedirectPath != null) {
      path = customRedirectPath;
    } else {
      // 根据不同的 provider 设置默认路径
      if (provider == 'email' || provider == 'phone') {
        path = '/nav/home';  // 邮箱/手机登录成功后跳转到主页
      } else if (provider == 'reset-password') {
        path = '/reset-callback';  // 重置密码回调
      } else {
        path = '/checkout';  // Apple 等 OAuth 默认到 checkout
      }
    }

    return '$scheme://auth-callback$path';
  }

  /// 从回调URL提取重定向路径
  static String? extractRedirectPath(String callbackUrl) {
    if (!callbackUrl.contains('auth-callback')) return null;

    final uri = Uri.tryParse(callbackUrl);
    if (uri == null) return null;

    // 提取auth-callback后的路径
    final path = uri.path;
    if (path.startsWith('/auth-callback')) {
      final redirectPath = path.substring('/auth-callback'.length);
      return redirectPath.isEmpty ? '/nav/home' : redirectPath;
    }

    return null;
  }
}
