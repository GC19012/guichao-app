// apple_auth_native.dart - iOS Apple Sign-In

import 'package:guichao/gch_base/gch_ink/gch_ink.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_providers/gch_apple_auth_interface.dart';
import 'package:guichao/gch_aux/gch_auth_crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Apple 原生认证实现 - iOS
class AppleAuthNative implements AppleAuthInterface {
  AppleAuthNative._();

  static AppleAuthNative? _instance;
  static AppleAuthNative get instance => _instance ??= AppleAuthNative._();

  // iOS 原生支持 Apple Sign-In
  @override
  bool get isSupported => true;

  @override
  Future<AppleAuthResult> signIn() async {
    GchInk.app.debug('[AppleAuthNative] signIn 开始');

    if (!isSupported) {
      GchInk.app.warning('[AppleAuthNative] 当前平台不支持 Apple Sign-In');
      return AppleAuthResult.unsupported();
    }

    try {
      GchInk.app.debug('[AppleAuthNative] 检查 Apple Sign-In 可用性...');
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        GchInk.app.error('[AppleAuthNative] Apple Sign-In 在当前设备上不可用');
        return AppleAuthResult.error('Apple Sign-In 在当前设备上不可用');
      }

      // 生成 nonce 用于安全验证
      final (:rawNonce, :hashedNonce) = AuthCryptoHelper.createNonceWithHash();

      GchInk.app.debug('[AppleAuthNative] 调用 SignInWithApple.getAppleIDCredential...');

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      GchInk.app.info('[AppleAuthNative] Apple 凭证获取成功'
          '\n  - userIdentifier: ${credential.userIdentifier}'
          '\n  - email: ${credential.email}'
          '\n  - givenName: ${credential.givenName}'
          '\n  - familyName: ${credential.familyName}'
          '\n  - hasIdentityToken: ${credential.identityToken != null}'
          '\n  - identityToken 长度: ${credential.identityToken?.length ?? 0}'
          '\n  - authorizationCode 长度: ${credential.authorizationCode.length}');

      return AppleAuthResult.success(
        idToken: credential.identityToken ?? '',
        authorizationCode: credential.authorizationCode,
        accessToken: credential.authorizationCode, // Apple 使用授权码作为访问凭证
        rawNonce: rawNonce, // 返回原始 nonce 给 Supabase 使用
      );

    } catch (e, stackTrace) {
      GchInk.app.error('[AppleAuthNative] Apple Sign-In 异常', e, stackTrace);

      if (e is SignInWithAppleAuthorizationException) {
        GchInk.app.error('[AppleAuthNative] AuthorizationException:'
            '\n  - code: ${e.code}'
            '\n  - message: ${e.message}');

        switch (e.code) {
          case AuthorizationErrorCode.canceled:
            GchInk.app.info('[AppleAuthNative] 用户取消了登录');
            return AppleAuthResult.cancelled();
          case AuthorizationErrorCode.failed:
            return AppleAuthResult.error('Apple Sign-In 认证失败: ${e.message}');
          case AuthorizationErrorCode.invalidResponse:
            return AppleAuthResult.error('Apple Sign-In 响应无效: ${e.message}');
          case AuthorizationErrorCode.notHandled:
            return AppleAuthResult.error('Apple Sign-In 请求未处理: ${e.message}');
          case AuthorizationErrorCode.unknown:
          default:
            return AppleAuthResult.error('Apple Sign-In 未知错误: ${e.message}');
        }
      }
      return AppleAuthResult.error('Apple Sign-In 失败: $e');
    }
  }

  @override
  Future<void> signOut() async {
    // Apple Sign-In 不需要显式登出，因为它是基于授权的
    // 用户可以在系统设置中撤销权限
  }
}
