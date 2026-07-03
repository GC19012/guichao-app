// forget_password_notifier.dart
//
// 密码重置逻辑（支持 Email 和 Phone）
// 流程：sendOtp → verifyOtp（建立session） → updateUser（修改密码）
//
// 技术栈：Flutter + AuthManager中间层
// 重要约束：
// - 不自动创建账号（shouldCreateUser: false）
// - updateUser 必须在 verifyOtp 成功后调用
// - session 由 SDK 自动管理

import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:guichao/gch_mod/gch_user/gch_resetpw/gch_model/gch_forget_password_state.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_base/gch_ink/gch_ink.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_providers/gch_auth_providers.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_provider_interface.dart';

part 'gch_forget_password_notifier.g.dart';

/// 密码重置错误类型
enum PasswordResetError {
  /// 用户不存在
  userNotFound,
  /// 验证码错误
  invalidOtp,
  /// 验证码已过期
  otpExpired,
  /// Session 未建立
  noSession,
  /// 网络错误
  networkError,
  /// 请求过于频繁
  rateLimited,
  /// 未知错误
  unknown,
}

/// 密码重置结果
class PasswordResetResult {
  final bool success;
  final String? message;
  final PasswordResetError? error;

  const PasswordResetResult._({
    required this.success,
    this.message,
    this.error,
  });

  factory PasswordResetResult.success([String? message]) =>
      PasswordResetResult._(success: true, message: message);

  factory PasswordResetResult.failure(PasswordResetError error, String message) =>
      PasswordResetResult._(success: false, message: message, error: error);
}

@riverpod
class ForgetPasswordNotifier extends _$ForgetPasswordNotifier {
  Timer? _emailCountdownTimer;
  Timer? _phoneCountdownTimer;

  @override
  ForgetPasswordState build() {
    ref.onDispose(() {
      _emailCountdownTimer?.cancel();
      _phoneCountdownTimer?.cancel();
    });

    return const ForgetPasswordState();
  }

  // ============================================================
  // 公开方法：状态更新
  // ============================================================

  /// 切换输入类型（邮箱/手机号）
  /// 保留各自的输入和倒计时，不清空数据
  void toggleInputType() {
    state = state.copyWith(
      inputType: state.inputType == ForgetPasswordType.email
          ? ForgetPasswordType.phone
          : ForgetPasswordType.email,
      errorMessage: null,
    );
  }

  /// 更新邮箱
  void updateEmail(String value) {
    state = state.copyWith(email: value, errorMessage: null);
  }

  /// 更新手机号（完整国际格式，由 InternationalPhoneInput 组件提供）
  void updatePhone(String value) {
    state = state.copyWith(phone: value, errorMessage: null);
  }

  /// 更新国家代码
  void updateCountryCode(String value) {
    state = state.copyWith(countryCode: value, errorMessage: null);
  }

  /// 更新手机号验证状态（由 InternationalPhoneInput 组件回调）
  void updatePhoneValidation(bool isValid) {
    state = state.copyWith(isPhoneValid: isValid, errorMessage: null);
  }

  /// 更新验证码
  void updateVerificationCode(String code) {
    state = state.copyWith(verificationCode: code, errorMessage: null);
  }

  /// 更新新密码
  void updateNewPassword(String password) {
    state = state.copyWith(newPassword: password, errorMessage: null);
  }

  /// 切换密码可见性
  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  /// 设置 Captcha token
  void setCaptchaToken(String? token) {
    state = state.copyWith(captchaToken: token);
  }

  // ============================================================
  // 核心方法：密码重置流程
  // ============================================================

  /// 步骤1：发送验证码
  ///
  /// 使用 AuthManager.sendOtp 发送验证码到邮箱或手机
  /// - shouldCreateUser: false - 不自动创建用户，如果用户不存在则报错
  /// - captchaToken: 人机验证token（如果启用了captcha）
  /// 返回错误码，UI层负责本地化
  Future<PasswordResetResult> sendVerificationCode() async {
    // 1. 验证输入
    if (!state.canSendCode) {
      final errorCode = state.inputType == ForgetPasswordType.email
          ? 'email_required'
          : 'phone_required';
      return PasswordResetResult.failure(PasswordResetError.unknown, errorCode);
    }

    final identifier = state.currentIdentifier;
    if (identifier.isEmpty) {
      final errorCode = state.inputType == ForgetPasswordType.email
          ? 'email_required'
          : 'phone_required';
      state = state.copyWith(errorMessage: errorCode);
      return PasswordResetResult.failure(PasswordResetError.unknown, errorCode);
    }

    // 2. 验证格式
    if (state.inputType == ForgetPasswordType.email) {
      if (!_isValidEmail(identifier)) {
        state = state.copyWith(errorMessage: 'email_address_invalid');
        return PasswordResetResult.failure(
          PasswordResetError.unknown,
          'email_address_invalid',
        );
      }
    } else {
      if (!state.isPhoneValid) {
        state = state.copyWith(errorMessage: 'phone_invalid');
        return PasswordResetResult.failure(
          PasswordResetError.unknown,
          'phone_invalid',
        );
      }
    }

    // 3. 开始发送
    state = state.copyWith(isCodeSending: true, errorMessage: null);

    try {
      GchInk.app.info('Sending password reset OTP: $identifier');

      // 获取 AuthManager
      final authManager = await ref.read(authManagerProvider.future);

      // 通过 AuthManager 发送 OTP
      // shouldCreateUser: false - 密码重置不应创建新用户
      final otpType = state.inputType == ForgetPasswordType.email
          ? OtpType.email
          : OtpType.sms;

      final success = await authManager.sendOtp(
        identifier,
        type: otpType,
        captchaToken: state.captchaToken,
        shouldCreateUser: false, // 重要：密码重置不创建新用户
      );

      if (!success) {
        GchInk.app.error('Send OTP failed');
        state = state.copyWith(errorMessage: 'user_not_found');
        return PasswordResetResult.failure(
          PasswordResetError.userNotFound,
          'user_not_found',
        );
      }

      GchInk.app.info('OTP sent successfully');

      // 4. 开始倒计时
      _startCountdown();

      final successCode = state.inputType == ForgetPasswordType.email
          ? 'otp_sent_email'
          : 'otp_sent_phone';
      return PasswordResetResult.success(successCode);
    } catch (e) {
      GchInk.app.error('Send OTP failed', e);
      final result = _handleException(e);
      state = state.copyWith(errorMessage: result.message);
      return result;
    } finally {
      state = state.copyWith(isCodeSending: false);
      // 使用后清除 captcha token
      _consumeCaptchaToken();
    }
  }

  /// 步骤2：验证验证码并修改密码
  ///
  /// 流程：
  /// 1. 调用 verifyOtp 验证验证码（成功后会自动建立 session）
  /// 2. 调用 updateUserPassword 更新密码（需要 session）
  Future<PasswordResetResult> resetPassword() async {
    // 1. 验证输入
    if (!_validateInputs()) {
      return PasswordResetResult.failure(
        PasswordResetError.unknown,
        state.errorMessage ?? 'validation_failed',
      );
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final identifier = state.currentIdentifier;
      final code = state.verificationCode.trim();
      final newPassword = state.newPassword.trim();

      GchInk.app.info('Starting OTP verification: $identifier');

      // 获取 AuthManager
      final authManager = await ref.read(authManagerProvider.future);

      // 2. 验证 OTP（这会同时建立 session）
      final otpType = state.inputType == ForgetPasswordType.email
          ? OtpType.email
          : OtpType.sms;

      final verifyResult = await authManager.verifyOtp(
        identifier,
        code,
        type: otpType,
      );

      // 3. 检查验证结果
      if (!verifyResult.isSuccess) {
        GchInk.app.error('OTP verification failed: ${verifyResult.errorMessage}');
        final result = _handleAuthErrorCode(verifyResult.errorCode, verifyResult.errorMessage);
        state = state.copyWith(errorMessage: result.message);
        return result;
      }

      GchInk.app.info('OTP verified, session established');

      // 4. 更新密码（使用刚建立的 session）
      final updateSuccess = await authManager.updateUserPassword(newPassword);

      if (!updateSuccess) {
        GchInk.app.error('Password update failed');
        state = state.copyWith(errorMessage: 'unexpected_failure');
        return PasswordResetResult.failure(
          PasswordResetError.unknown,
          'unexpected_failure',
        );
      }

      GchInk.app.info('Password reset successful');

      // 5. 重置状态
      reset();

      return PasswordResetResult.success('password_reset_success');
    } catch (e) {
      GchInk.app.error('Password reset failed', e);
      final result = _handleException(e);
      state = state.copyWith(errorMessage: result.message);
      return result;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// 重置状态
  void reset() {
    _emailCountdownTimer?.cancel();
    _phoneCountdownTimer?.cancel();
    state = const ForgetPasswordState();
  }

  /// 获取倒计时文本
  String countdownText() {
    if (state.isCountingDown) {
      return '${GchText.userLoginResend} (${state.countdown}s)';
    } else {
      return GchText.userLoginGetCode;
    }
  }

  // ============================================================
  // 私有方法
  // ============================================================

  /// 验证邮箱格式
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email.trim());
  }

  /// 验证所有输入
  bool _validateInputs() {
    final identifier = state.currentIdentifier;

    if (identifier.isEmpty) {
      final errorCode = state.inputType == ForgetPasswordType.email
          ? 'email_required'
          : 'phone_required';
      state = state.copyWith(errorMessage: errorCode);
      return false;
    }

    if (state.inputType == ForgetPasswordType.email && !_isValidEmail(identifier)) {
      state = state.copyWith(errorMessage: 'email_address_invalid');
      return false;
    }

    if (state.inputType == ForgetPasswordType.phone && !state.isPhoneValid) {
      state = state.copyWith(errorMessage: 'phone_invalid');
      return false;
    }

    if (state.verificationCode.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'otp_required');
      return false;
    }

    if (state.verificationCode.trim().length < 6) {
      state = state.copyWith(errorMessage: 'otp_invalid_length');
      return false;
    }

    if (state.newPassword.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'password_required');
      return false;
    }

    if (state.newPassword.trim().length < 6) {
      state = state.copyWith(errorMessage: 'weak_password');
      return false;
    }

    return true;
  }

  /// 处理 AuthErrorCode
  PasswordResetResult _handleAuthErrorCode(AuthErrorCode? errorCode, String? errorMessage) {
    switch (errorCode) {
      case AuthErrorCode.userNotFound:
        return PasswordResetResult.failure(
          PasswordResetError.userNotFound,
          'user_not_found',
        );
      case AuthErrorCode.invalidVerificationCode:
        return PasswordResetResult.failure(
          PasswordResetError.invalidOtp,
          'otp_expired',
        );
      case AuthErrorCode.tooManyRequests:
        return PasswordResetResult.failure(
          PasswordResetError.rateLimited,
          'over_request_rate_limit',
        );
      case AuthErrorCode.networkError:
        return PasswordResetResult.failure(
          PasswordResetError.networkError,
          'network_error',
        );
      default:
        return PasswordResetResult.failure(
          PasswordResetError.unknown,
          errorMessage ?? 'unexpected_failure',
        );
    }
  }

  /// 处理异常
  PasswordResetResult _handleException(dynamic e) {
    final message = e.toString().toLowerCase();

    // 用户不存在
    if (message.contains('user not found') ||
        message.contains('no user found') ||
        message.contains('signups not allowed') ||
        message.contains('otp disabled')) {
      return PasswordResetResult.failure(
        PasswordResetError.userNotFound,
        'user_not_found',
      );
    }

    // 验证码错误
    if (message.contains('invalid') && message.contains('otp') ||
        message.contains('token has expired or is invalid') ||
        message.contains('invalid token')) {
      return PasswordResetResult.failure(
        PasswordResetError.invalidOtp,
        'otp_expired',
      );
    }

    // 验证码过期
    if (message.contains('expired') || message.contains('otp has expired')) {
      return PasswordResetResult.failure(
        PasswordResetError.otpExpired,
        'otp_expired',
      );
    }

    // 请求频率限制
    if (message.contains('rate limit') ||
        message.contains('too many requests') ||
        message.contains('429')) {
      return PasswordResetResult.failure(
        PasswordResetError.rateLimited,
        'over_request_rate_limit',
      );
    }

    // Session 未建立
    if (message.contains('not authenticated') ||
        message.contains('session') ||
        message.contains('jwt')) {
      return PasswordResetResult.failure(
        PasswordResetError.noSession,
        'session_expired',
      );
    }

    // 网络错误
    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout')) {
      return PasswordResetResult.failure(
        PasswordResetError.networkError,
        'network_error',
      );
    }

    // 未知错误 - 传递原始消息让 GchCuowuFanyi 处理
    return PasswordResetResult.failure(
      PasswordResetError.unknown,
      e.toString(),
    );
  }

  /// 消费 Captcha token（使用后清除）
  void _consumeCaptchaToken() {
    if (state.captchaToken != null) {
      state = state.copyWith(captchaToken: null);
    }
  }

  /// 开始倒计时（根据当前类型选择对应的倒计时器）
  void _startCountdown() {
    if (state.inputType == ForgetPasswordType.email) {
      _startEmailCountdown();
    } else {
      _startPhoneCountdown();
    }
  }

  /// 开始邮箱倒计时
  void _startEmailCountdown() {
    state = state.copyWith(emailCountdown: 60);
    _emailCountdownTimer?.cancel();
    _emailCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // ✅ 守卫检查：确保 provider 仍然存活
      try {
        if (!ref.exists(forgetPasswordNotifierProvider)) {
          timer.cancel();
          return;
        }
        if (state.emailCountdown <= 1) {
          timer.cancel();
          state = state.copyWith(emailCountdown: 0);
        } else {
          state = state.copyWith(emailCountdown: state.emailCountdown - 1);
        }
      } catch (e) {
        timer.cancel();
      }
    });
  }

  /// 开始手机倒计时
  void _startPhoneCountdown() {
    state = state.copyWith(phoneCountdown: 60);
    _phoneCountdownTimer?.cancel();
    _phoneCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // ✅ 守卫检查：确保 provider 仍然存活
      try {
        if (!ref.exists(forgetPasswordNotifierProvider)) {
          timer.cancel();
          return;
        }
        if (state.phoneCountdown <= 1) {
          timer.cancel();
          state = state.copyWith(phoneCountdown: 0);
        } else {
          state = state.copyWith(phoneCountdown: state.phoneCountdown - 1);
        }
      } catch (e) {
        timer.cancel();
      }
    });
  }
}
