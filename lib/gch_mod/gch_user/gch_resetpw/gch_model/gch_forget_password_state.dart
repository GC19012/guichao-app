import 'package:freezed_annotation/freezed_annotation.dart';

part 'gch_forget_password_state.freezed.dart';

/// 忘记密码输入类型
enum ForgetPasswordType {
  email('邮箱'),
  phone('手机号');

  const ForgetPasswordType(this.label);
  final String label;
}

/// 忘记密码状态
@freezed
abstract class ForgetPasswordState with _$ForgetPasswordState {
  const factory ForgetPasswordState({
    @Default(ForgetPasswordType.email) ForgetPasswordType inputType,
    /// 邮箱输入（独立存储）
    @Default('') String email,
    /// 手机号输入（独立存储，不含国家代码）
    @Default('') String phone,
    /// 国家代码
    @Default('+86') String countryCode,
    /// 手机号验证状态（由 InternationalPhoneInput 组件验证）
    @Default(false) bool isPhoneValid,
    @Default('') String verificationCode,
    @Default('') String newPassword,
    @Default(false) bool isPasswordVisible,
    @Default(false) bool isLoading,
    @Default(false) bool isCodeSending,
    /// 邮箱验证码倒计时（独立）
    @Default(0) int emailCountdown,
    /// 手机验证码倒计时（独立）
    @Default(0) int phoneCountdown,
    /// Turnstile/Captcha token
    String? captchaToken,
    String? errorMessage,
  }) = _ForgetPasswordState;

  const ForgetPasswordState._();

  /// 获取当前类型的倒计时
  int get countdown => inputType == ForgetPasswordType.email
      ? emailCountdown
      : phoneCountdown;

  /// 获取当前标识符（完整格式）
  /// 注意：phone 字段存储的是 InternationalPhoneInput 返回的完整国际格式
  /// 例如：+8613812345678
  String get currentIdentifier {
    if (inputType == ForgetPasswordType.email) {
      return email.trim();
    } else {
      // phone 已经是完整的国际格式（由 InternationalPhoneInput 组件提供）
      return phone.trim();
    }
  }

  /// 是否正在倒计时
  bool get isCountingDown => countdown > 0;

  /// 是否可以发送验证码
  bool get canSendCode {
    if (isCodeSending || isCountingDown) return false;
    if (inputType == ForgetPasswordType.email) {
      return email.trim().isNotEmpty;
    } else {
      return phone.trim().isNotEmpty && isPhoneValid;
    }
  }
}