import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:guichao/gch_mod/gch_user/gch_shared/gch_international_phone_input.dart';

part 'gch_login_state.freezed.dart';

/// 登录类型枚举
enum LoginType {
  /// 账号密码登录（手机/邮箱通过Tab切换）
  account,
  /// 验证码登录
  code,
}

/// 登录状态模型
@freezed
abstract class LoginState with _$LoginState {
  const factory LoginState({
    /// 当前登录类型
    @Default(LoginType.account) LoginType currentType,
    /// 账号登录是否使用手机（true=手机，false=邮箱）
    @Default(true) bool usePhoneForAccount,
    /// 验证码登录是否使用手机（true=手机，false=邮箱）
    @Default(true) bool usePhoneForCode,
    /// 选中的国家代码
    @Default('+86') String selectedCountryCode,
    /// 当前手机号信息
    PhoneNumberData? currentPhoneNumber,
    /// 手机号是否通过验证
    @Default(false) bool isPhoneValid,
    /// 邮箱是否通过验证
    @Default(false) bool isEmailValid,
    /// 是否同意协议
    @Default(false) bool isAgreementChecked,
    /// 是否隐藏密码
    @Default(true) bool obscurePassword,
    /// 错误消息
    String? errorMessage,
    /// 是否正在进行 OAuth 登录
    @Default(false) bool isOauthSigningIn,
    /// OAuth 登录状态消息
    @Default('') String oauthSignInStatusMessage,
    /// 是否正在登录
    @Default(false) bool isLoading,
  }) = _LoginState;

  const LoginState._();

  /// 当前登录类型是否使用手机
  bool get usePhone => currentType == LoginType.account
      ? usePhoneForAccount
      : usePhoneForCode;

  /// 验证码登录时是否使用邮箱
  bool get useEmailForCode => !usePhoneForCode;
}
