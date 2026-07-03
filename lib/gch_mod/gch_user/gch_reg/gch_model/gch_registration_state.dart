// registration_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authtype_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_provider_interface.dart';

part 'gch_registration_state.freezed.dart';

/// 注册类型
enum RegisterType {
  email('邮箱注册'),
  phone('手机注册');

  const RegisterType(this.label);
  final String label;
}

/// 注册阶段
enum RegistrationPhase {
  /// 初始阶段 - 输入基本信息
  initial,
  
  /// 等待发送验证码
  sendingCode,
  
  /// 已发送验证码，等待用户输入
  codeSent,
  
  /// 验证中
  verifying,
  
  /// 注册完成
  completed,
  
  /// 错误状态
  error,
}

/// 注册错误类型
enum RegistrationErrorType {
  /// 网络错误
  network,
  
  /// 输入验证错误
  validation,
  
  /// 服务器错误
  server,
  
  /// 验证码错误
  invalidCode,
  
  /// 用户已存在
  userExists,
  
  /// 验证码过期
  codeExpired,
  
  /// 发送验证码过于频繁
  tooManyRequests,
  
  /// 未知错误
  unknown,
}

/// 注册状态
@freezed
abstract class RegistrationState with _$RegistrationState {
  const factory RegistrationState({
    /// 当前注册类型
    @Default(RegisterType.email) RegisterType registerType,
    
    /// 当前注册阶段
    @Default(RegistrationPhase.initial) RegistrationPhase phase,
    
    /// 邮箱地址
    String? email,
    
    /// 手机号码（包含国家代码）
    String? phone,
    
    /// 国家代码
    @Default('+86') String countryCode,
    
    /// 密码
    String? password,
    
    /// 验证码
    String? verificationCode,

    /// 是否已同意协议
    @Default(false) bool agreedToTerms,

    /// 邮箱倒计时秒数（0表示不在倒计时）
    @Default(0) int emailCountdownSeconds,

    /// 手机倒计时秒数（0表示不在倒计时）
    @Default(0) int phoneCountdownSeconds,

    /// 错误信息
    String? errorMessage,
    
    /// 错误类型
    RegistrationErrorType? errorType,
    
    /// 是否正在加载
    @Default(false) bool isLoading,
    
    /// 是否已经调用过signUp（标记用户已注册）
    @Default(false) bool hasSignedUp,
    
    /// 验证码发送时间
    DateTime? codeSentAt,
    
    /// 注册请求标识（用于验证一致性）
    String? registrationId,

    /// ✅ 新增: Turnstile 验证 token
    String? turnstileToken,

    /// 手机号是否通过 intl_phone_number_input 验证
    /// 由组件的 onInputValidated 回调更新
    @Default(false) bool isPhoneValid,

    /// 是否隐藏密码
    @Default(true) bool obscurePassword,
  }) = _RegistrationState;
  
  const RegistrationState._();
  
  /// 获取当前输入的标识符（邮箱或手机号）
  String? get currentIdentifier {
    switch (registerType) {
      case RegisterType.email:
        return email;
      case RegisterType.phone:
        return fullPhoneNumber;
    }
  }
  
  /// 获取完整的手机号（包含国家代码）
  String? get fullPhoneNumber {
    if (registerType == RegisterType.phone && phone != null) {
      return '$countryCode$phone';
    }
    return null;
  }
  
  /// 获取当前类型的倒计时秒数
  int get countdownSeconds {
    return registerType == RegisterType.email
        ? emailCountdownSeconds
        : phoneCountdownSeconds;
  }

  /// 是否可以发送验证码（不检查协议，协议检查在UI层处理以触发抖动提示）
  bool get canSendCode {
    return !isLoading &&
           countdownSeconds == 0 &&
           _hasValidInput();
  }

  /// 是否可以发送验证码（包含协议检查，用于完整验证）
  bool get canSendCodeWithTerms {
    return canSendCode && agreedToTerms;
  }
  
  /// 是否可以进行注册验证
  bool get canVerify {
    return !isLoading && 
           hasSignedUp && 
           verificationCode != null && 
           verificationCode!.isNotEmpty &&
           _hasValidInput() &&
           password != null &&
           password!.isNotEmpty;
  }
  
  /// 是否正在倒计时
  bool get isCountingDown => countdownSeconds > 0;
  
  /// 验证码是否可能已过期（超过5分钟）
  bool get isCodePossiblyExpired {
    if (codeSentAt == null) return false;
    return DateTime.now().difference(codeSentAt!).inMinutes >= 5;
  }
  
  /// 检查输入是否有效
  bool _hasValidInput() {
    switch (registerType) {
      case RegisterType.email:
        return email != null && _isValidEmail(email!);
      case RegisterType.phone:
        return phone != null && _isValidPhone(phone!);
    }
  }
  
  /// 验证邮箱格式
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }
  
  /// 验证手机号格式
  /// 使用 intl_phone_number_input 组件的验证结果 (isPhoneValid)
  bool _isValidPhone(String phone) {
    // 直接使用组件验证结果，由 onInputValidated 回调更新
    return isPhoneValid;
  }
  
  /// 获取AuthRequest用于注册
  AuthRequest toSignUpRequest() {
    switch (registerType) {
      case RegisterType.email:
        return AuthRequest.forSignUp(
          email: email,
          password: password,
        );
      case RegisterType.phone:
        return AuthRequest.forSignUp(
          phone: fullPhoneNumber,
          password: password,
        );
    }
  }
  
  /// 获取用于验证码验证的标识符
  String getVerificationIdentifier() {
    switch (registerType) {
      case RegisterType.email:
        return email!;
      case RegisterType.phone:
        return fullPhoneNumber!;
    }
  }
  
  /// 获取OTP类型
  OtpType getOtpType() {
    switch (registerType) {
      case RegisterType.email:
        return OtpType.email;
      case RegisterType.phone:
        return OtpType.sms;
    }
  }
}
