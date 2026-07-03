import 'dart:async';
import 'package:guichao/gch_mod/gch_user/gch_shared/gch_international_phone_input.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authtype_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_provider_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_wire/gch_appprovider.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_base/gch_cuowu/gch_cuowu_fanyi.dart';
import 'package:guichao/gch_mod/gch_user/gch_login/gch_model/gch_login_state.dart';

part 'gch_login_notifier.g.dart';

/// 登录结果
class LoginResult {
  final bool success;
  final String? errorMessage;
  final String? redirectPath;

  const LoginResult._({
    required this.success,
    this.errorMessage,
    this.redirectPath,
  });

  factory LoginResult.success([String? redirectPath]) =>
      LoginResult._(success: true, redirectPath: redirectPath);

  factory LoginResult.failure(String message) =>
      LoginResult._(success: false, errorMessage: message);
}

/// 邮箱验证结果
class EmailValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? suggestedDomain;

  const EmailValidationResult({
    required this.isValid,
    this.errorMessage,
    this.suggestedDomain,
  });
}

/// 登录业务逻辑 Notifier
@riverpod
class LoginNotifier extends _$LoginNotifier {
  /// 常见邮箱域名拼写错误映射
  static const _commonDomainTypos = {
    'gmal.com': 'gmail.com',
    'gamil.com': 'gmail.com',
    'gmial.com': 'gmail.com',
    'gmaill.com': 'gmail.com',
    'hotmal.com': 'hotmail.com',
    'hotmai.com': 'hotmail.com',
    'hotnail.com': 'hotmail.com',
    'otmail.com': 'hotmail.com',
    '163.con': '163.com',
    'qq.con': 'qq.com',
  };

  /// 邮箱验证正则
  static final _emailRegex = RegExp(
    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
  );

  @override
  LoginState build() {
    return const LoginState();
  }

  // ============================================================
  // 状态更新方法
  // ============================================================

  /// 重置状态到初始值（每次进入页面时调用）
  void resetState() {
    state = const LoginState();
  }

  /// 切换登录类型
  void setLoginType(LoginType type) {
    state = state.copyWith(currentType: type);
  }

  /// 切换账号登录的手机/邮箱模式（独立）
  void togglePhoneEmailForAccount() {
    state = state.copyWith(
      usePhoneForAccount: !state.usePhoneForAccount,
      errorMessage: null,
      isPhoneValid: false,
      isEmailValid: false,
    );
  }

  /// 切换验证码登录的手机/邮箱模式（独立）
  void togglePhoneEmailForCode() {
    state = state.copyWith(
      usePhoneForCode: !state.usePhoneForCode,
      errorMessage: null,
      isPhoneValid: false,
      isEmailValid: false,
    );
  }

  /// 更新国家代码
  void updateCountryCode(String countryCode) {
    state = state.copyWith(selectedCountryCode: countryCode);
  }

  /// 更新当前手机号信息
  void updatePhoneNumber(PhoneNumberData? phoneNumber) {
    if (phoneNumber != null) {
      state = state.copyWith(
        currentPhoneNumber: phoneNumber,
        selectedCountryCode: phoneNumber.dialCode ?? state.selectedCountryCode,
      );
    }
  }

  /// 更新手机号验证状态
  void updatePhoneValidation(bool isValid) {
    state = state.copyWith(isPhoneValid: isValid);
  }

  /// 更新邮箱验证状态
  void updateEmailValidation(bool isValid, {String? errorMessage}) {
    state = state.copyWith(
      isEmailValid: isValid,
      errorMessage: errorMessage,
    );
  }

  /// 切换协议同意状态
  void toggleAgreement() {
    state = state.copyWith(isAgreementChecked: !state.isAgreementChecked);
  }

  /// 确保协议被选中
  void ensureAgreementChecked() {
    if (!state.isAgreementChecked) {
      state = state.copyWith(isAgreementChecked: true);
    }
  }

  /// 切换密码可见性
  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  /// 设置错误消息
  void setErrorMessage(String? message) {
    state = state.copyWith(errorMessage: message);
  }

  /// 清除错误消息
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// 设置 OAuth 登录状态
  void setOauthSigningIn(bool isSigningIn, {String statusMessage = ''}) {
    state = state.copyWith(
      isOauthSigningIn: isSigningIn,
      oauthSignInStatusMessage: statusMessage,
    );
  }

  /// 设置加载状态
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  // ============================================================
  // 验证方法
  // ============================================================

  /// 验证邮箱格式
  EmailValidationResult validateEmail(String email) {
    if (email.isEmpty) {
      return const EmailValidationResult(isValid: false);
    }

    if (!_emailRegex.hasMatch(email)) {
      return const EmailValidationResult(
        isValid: false,
        errorMessage: 'emailInvalid',
      );
    }

    // 检查常见域名拼写错误
    final domain = email.split('@').last.toLowerCase();
    if (_commonDomainTypos.containsKey(domain)) {
      return EmailValidationResult(
        isValid: false,
        errorMessage: 'emailDomainSuggestion',
        suggestedDomain: _commonDomainTypos[domain],
      );
    }

    return const EmailValidationResult(isValid: true);
  }

  /// 过滤手机号非数字字符
  String filterPhoneDigits(String phone) {
    if (phone.isNotEmpty && !RegExp(r'^\d+$').hasMatch(phone)) {
      return phone.replaceAll(RegExp(r'[^\d]'), '');
    }
    return phone;
  }

  // ============================================================
  // 登录业务逻辑
  // ============================================================

  /// 账号密码登录
  Future<LoginResult> loginWithPassword({
    required String phone,
    required String email,
    required String password,
  }) async {
    ensureAgreementChecked();

    // 验证输入
    if (state.usePhone) {
      if (phone.isEmpty) {
        return LoginResult.failure(GchText.userLoginPhoneHint);
      }
      if (!state.isPhoneValid) {
        return LoginResult.failure(GchText.userLoginValidationPhoneInvalid);
      }
    } else {
      if (email.isEmpty) {
        return LoginResult.failure(GchText.userLoginEmailHint);
      }
      if (!state.isEmailValid) {
        return LoginResult.failure(GchText.userLoginValidationEmailInvalid);
      }
    }

    if (password.isEmpty) {
      return LoginResult.failure(GchText.userLoginPasswordHint);
    }

    try {
      final authManager = await ref.read(AppProvider.auth.manager.future);
      AuthResult result;

      if (state.usePhone) {
        final fullPhone = '${state.selectedCountryCode}$phone';
        result = await authManager.signIn(AuthRequest.withPhone(
          phone: fullPhone,
          password: password,
        ));
      } else {
        result = await authManager.signIn(AuthRequest.withEmail(
          email: email,
          password: password,
        ));
      }

      if (result.isSuccess) {
        return LoginResult.success();
      } else {
        return LoginResult.failure(
          GchCuowuFanyi.bendihua(result.errorMessage),
        );
      }
    } catch (e) {
      return LoginResult.failure(
        GchCuowuFanyi.bendihua(e.toString()),
      );
    }
  }

  /// 验证码登录
  Future<LoginResult> loginWithOtp({
    required String phone,
    required String email,
    required String code,
  }) async {
    ensureAgreementChecked();

    if (state.useEmailForCode) {
      // 邮箱验证码登录
      if (email.isEmpty || code.isEmpty) {
        return LoginResult.failure(GchText.userLoginValidationEmailRequired);
      }
      if (!state.isEmailValid) {
        return LoginResult.failure(GchText.userLoginValidationEmailInvalid);
      }

      try {
        final authManager = await ref.read(AppProvider.auth.manager.future);
        final result = await authManager.verifyOtp(
          email,
          code,
          type: OtpType.email,
        );

        if (result.isSuccess) {
          return LoginResult.success();
        } else {
          return LoginResult.failure(
            GchCuowuFanyi.bendihua(result.errorMessage),
          );
        }
      } catch (e) {
        return LoginResult.failure(
          GchCuowuFanyi.bendihua(e.toString()),
        );
      }
    } else {
      // 手机验证码登录
      if (phone.isEmpty || code.isEmpty) {
        return LoginResult.failure(GchText.userLoginValidationPhoneRequired);
      }
      if (!state.isPhoneValid) {
        return LoginResult.failure(GchText.userLoginValidationPhoneInvalid);
      }

      try {
        final authManager = await ref.read(AppProvider.auth.manager.future);
        final fullPhone = '${state.selectedCountryCode}$phone';
        final result = await authManager.verifyOtp(
          fullPhone,
          code,
          type: OtpType.sms,
        );

        if (result.isSuccess) {
          return LoginResult.success();
        } else {
          return LoginResult.failure(
            GchCuowuFanyi.bendihua(result.errorMessage),
          );
        }
      } catch (e) {
        return LoginResult.failure(
          GchCuowuFanyi.bendihua(e.toString()),
        );
      }
    }
  }

  /// 统一的 OAuth 登录方法
  Future<LoginResult> loginWithOAuth({
    required String providerId,
    Map<String, String>? extraParams,
    Duration? timeout,
  }) async {
    try {
      final authManager = await ref.read(AppProvider.auth.manager.future);

      Future<AuthResult> authFuture = authManager.signInWithOAuth(
        providerId: providerId,
        extraParams: extraParams,
      );

      // 如果指定了超时时间
      if (timeout != null) {
        authFuture = authFuture.timeout(
          timeout,
          onTimeout: () {
            throw TimeoutException(GchText.serverErrorsRequestTimeout);
          },
        );
      }

      final result = await authFuture;

      if (result.isSuccess) {
        return LoginResult.success();
      } else {
        // 检查是否是用户取消操作（包含美式 canceled 和英式 cancelled 拼写）
        final errorMsg = result.errorMessage ?? '';
        if (errorMsg.contains('sign_in_canceled') ||
            errorMsg.contains('canceled') ||
            errorMsg.contains('cancelled') ||
            errorMsg.contains('CANCELED')) {
          // 用户取消登录，静默处理（不显示错误消息）
          return const LoginResult._(success: false, errorMessage: null);
        }
        return LoginResult.failure(
          GchCuowuFanyi.bendihua(errorMsg),
        );
      }
    } on TimeoutException catch (_) {
      return LoginResult.failure(GchText.serverErrorsRequestTimeout);
    } catch (e) {
      final errorString = e.toString();

      // 用户取消登录，静默处理（包含美式 canceled 和英式 cancelled 拼写）
      if (errorString.contains('sign_in_canceled') ||
          errorString.contains('canceled') ||
          errorString.contains('cancelled') ||
          errorString.contains('CANCELED')) {
        return const LoginResult._(success: false, errorMessage: null);
      }

      return LoginResult.failure(
        GchCuowuFanyi.bendihua(errorString),
      );
    }
  }

  /// Apple 登录
  Future<LoginResult> loginWithApple() {
    setOauthSigningIn(true, statusMessage: GchText.userLoginLoggingIn);

    return loginWithOAuth(
      providerId: 'supabase_resilient',
      extraParams: {'provider': 'apple'},
    ).whenComplete(() {
      setOauthSigningIn(false);
    });
  }

}
