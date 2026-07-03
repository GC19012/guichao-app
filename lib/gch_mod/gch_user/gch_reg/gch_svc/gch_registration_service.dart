// registration_service.dart
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_manager.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_provider_interface.dart';
import 'package:guichao/gch_mod/gch_user/gch_reg/gch_model/gch_registration_state.dart';

/// 注册服务 - 处理完整的注册流程
class RegistrationService {
  final AuthManager _authManager;
  final _uuid = const Uuid();
  

  RegistrationService(this._authManager);

  /// 发送验证码（首次注册）
  ///
  /// 该方法使用signInWithOtp直接发送验证码，无需密码
  /// Supabase会自动创建用户（如果不存在）
  ///
  /// 返回结果:
  /// - success: 是否成功
  /// - message: 结果消息
  /// - registrationId: 注册会话ID，用于后续验证
  Future<RegistrationResult> sendVerificationCode({
    required RegisterType type,
    required String identifier,
    String? password,  // 密码现在是可选的，不在此步骤使用
    String? countryCode,
    String? turnstileToken,  // ✅ 新增: Turnstile token
  }) async {
    // ✅ 新增: 验证 Turnstile token（将来在后端验证）
    // 注意：实际的 token 验证应该在 Supabase Edge Function 中进行
    // 这里只是前端的基本检查
    if (turnstileToken == null || turnstileToken.isEmpty) {
      return RegistrationResult.failure(
        message: 'captcha_failed',
        errorType: RegistrationErrorType.validation,
      );
    }
    try {
      // 生成注册会话ID
      final registrationId = _uuid.v4();
      final formattedIdentifier = _formatIdentifier(
        type,
        identifier,
        countryCode: countryCode,
      );

      // 直接使用signInWithOtp发送验证码
      // Supabase会自动创建用户账号（如果不存在）
      final otpType = type == RegisterType.email ? OtpType.email : OtpType.sms;
      final otpSent = await _authManager.sendOtp(
        formattedIdentifier,
        type: otpType,
        captchaToken: turnstileToken,
      );

      if (otpSent) {
        return RegistrationResult.success(
          message: type == RegisterType.email ? 'otp_sent_email' : 'otp_sent_phone',
          registrationId: registrationId,
        );
      } else {
        return RegistrationResult.failure(
          message: 'sms_send_failed',
          errorType: RegistrationErrorType.network,
        );
      }
    } catch (e) {
      return RegistrationResult.failure(
        message: e.toString(),
        errorType: RegistrationErrorType.unknown,
      );
    }
  }

  /// 重新发送验证码
  /// 对于已注册用户，直接调用sendOtp
  Future<RegistrationResult> resendVerificationCode({
    required RegisterType type,
    required String identifier,
    required String registrationId,
  }) async {
    try {
      final otpType = type == RegisterType.email ? OtpType.email : OtpType.sms;
      final formattedIdentifier = _formatIdentifier(type, identifier);
      final success = await _authManager.sendOtp(formattedIdentifier, type: otpType);

      if (success) {
        return RegistrationResult.success(
          message: 'otp_resent',
          registrationId: registrationId,
        );
      } else {
        return RegistrationResult.failure(
          message: 'over_sms_send_rate_limit',
          errorType: RegistrationErrorType.tooManyRequests,
        );
      }
    } catch (e) {
      return RegistrationResult.failure(
        message: e.toString(),
        errorType: RegistrationErrorType.unknown,
      );
    }
  }

  /// 验证验证码并完成注册
  /// 该方法验证用户输入的验证码，成功后更新用户密码完成注册流程
  Future<RegistrationResult> verifyCodeAndCompleteRegistration({
    required RegisterType type,
    required String identifier,
    required String verificationCode,
    required String registrationId,
    String? password,  // 添加密码参数用于更新
  }) async {
    try {
      // 验证码格式检查
      if (verificationCode.length != 6 || !RegExp(r'^\d{6}$').hasMatch(verificationCode)) {
        return RegistrationResult.failure(
          message: 'validation_failed',
          errorType: RegistrationErrorType.validation,
        );
      }

      // 调用验证OTP
      final otpType = type == RegisterType.email ? OtpType.email : OtpType.sms;
      final formattedIdentifier = _formatIdentifier(type, identifier);
      final result = await _authManager.verifyOtp(formattedIdentifier, verificationCode, type: otpType);

      if (result.isSuccess) {
        // OTP验证成功后，如果有密码则必须成功设置密码
        if (password != null && password.isNotEmpty) {
          final passwordUpdateSuccess = await _authManager.updateUserPassword(password);
          if (!passwordUpdateSuccess) {
            // 密码更新失败，注册流程失败
            return RegistrationResult.failure(
              message: 'unexpected_failure',
              errorType: RegistrationErrorType.server,
            );
          }
        }

        return RegistrationResult.success(
          message: 'signup_success_verify',
          registrationId: registrationId,
          user: result.user,
          token: result.token,
        );
      } else {
        // 使用错误码判断具体错误类型
        final errorType = _mapErrorType(result.errorCode);
        final errorMessage = _mapErrorMessage(result.errorCode);
        return RegistrationResult.failure(
          message: errorMessage,
          errorType: errorType,
        );
      }
    } catch (e) {
      // 传递原始异常消息，让 GchCuowuFanyi 提取错误码
      // 如果无法识别则回退到 unexpected_failure
      final errorStr = e.toString().toLowerCase();
      String errorMessage = 'unexpected_failure';
      RegistrationErrorType errorType = RegistrationErrorType.unknown;

      if (errorStr.contains('otp') || errorStr.contains('token') || errorStr.contains('invalid')) {
        errorMessage = 'otp_expired';
        errorType = RegistrationErrorType.invalidCode;
      } else if (errorStr.contains('network') || errorStr.contains('connection')) {
        errorMessage = 'network_error';
        errorType = RegistrationErrorType.network;
      } else if (errorStr.contains('rate') || errorStr.contains('too many')) {
        errorMessage = 'over_request_rate_limit';
        errorType = RegistrationErrorType.tooManyRequests;
      }

      return RegistrationResult.failure(
        message: errorMessage,
        errorType: errorType,
      );
    }
  }

  String _formatIdentifier(
    RegisterType type,
    String identifier, {
    String? countryCode,
  }) {
    final trimmed = identifier.trim();
    if (type == RegisterType.phone) {
      if (trimmed.startsWith('+')) {
        return trimmed;
      }
      final prefix = countryCode ?? '+86';
      if (trimmed.startsWith(prefix)) {
        return trimmed;
      }
      return '$prefix$trimmed';
    }
    return trimmed;
  }

  /// 验证输入数据
  ///
  /// @param requirePassword 是否需要验证密码（获取验证码时不需要，注册时需要）
  /// @param isPhoneValid 手机号是否通过 intl_phone_number_input 组件验证
  /// 返回错误码列表，UI层负责本地化
  RegistrationValidationResult validateRegistrationData({
    required RegisterType type,
    required String identifier,
    String? password,
    required bool agreedToTerms,
    bool requirePassword = false,
    bool isPhoneValid = false,  // 由 intl_phone_number_input 组件的 onInputValidated 提供
  }) {
    final errors = <String>[];

    // 检查协议同意
    if (!agreedToTerms) {
      errors.add('agreement_required');
    }

    // 验证标识符
    if (identifier.isEmpty) {
      errors.add(type == RegisterType.email ? 'email_required' : 'phone_required');
    } else {
      final validationError = _validateIdentifier(type, identifier, isPhoneValid: isPhoneValid);
      if (validationError != null) {
        errors.add(validationError);
      }
    }

    // 只在需要时验证密码（注册时验证，获取验证码时不验证）
    if (requirePassword && password != null) {
      final passwordError = _validatePassword(password);
      if (passwordError != null) {
        errors.add(passwordError);
      }
    }

    return RegistrationValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// 验证标识符格式
  ///
  /// 对于手机号，使用 intl_phone_number_input 组件的验证结果
  /// 返回错误码，UI层负责本地化
  String? _validateIdentifier(RegisterType type, String identifier, {bool isPhoneValid = false}) {
    switch (type) {
      case RegisterType.email:
        return _validateEmail(identifier);
      case RegisterType.phone:
        // 使用 intl_phone_number_input 组件的验证结果
        // 该组件基于 libphonenumber，支持全球所有国家的手机号验证
        if (!isPhoneValid) {
          return 'phone_invalid';
        }
        return null;
    }
  }

  /// 验证邮箱格式
  /// 返回错误码，UI层负责本地化
  String? _validateEmail(String email) {
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      return 'email_address_invalid';
    }
    return null;
  }

  /// 验证密码强度
  /// 返回错误码，UI层负责本地化
  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return 'password_required';
    }
    if (password.length < 8) {
      return 'weak_password';
    }
    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(password)) {
      return 'weak_password';
    }
    return null;
  }


  /// 映射错误类型
  RegistrationErrorType _mapErrorType(AuthErrorCode? errorCode) {
    switch (errorCode) {
      case AuthErrorCode.networkError:
        return RegistrationErrorType.network;
      case AuthErrorCode.userAlreadyExists:
        return RegistrationErrorType.userExists;
      case AuthErrorCode.tooManyRequests:
        return RegistrationErrorType.tooManyRequests;
      case AuthErrorCode.invalidInput:
        return RegistrationErrorType.validation;
      case AuthErrorCode.invalidVerificationCode:
        return RegistrationErrorType.invalidCode;
      case AuthErrorCode.serverError:
        return RegistrationErrorType.server;
      case null:
      case AuthErrorCode.unknown:
      default:
        return RegistrationErrorType.unknown;
    }
  }

  /// 根据错误码返回对应的错误消息码
  String _mapErrorMessage(AuthErrorCode? errorCode) {
    switch (errorCode) {
      case AuthErrorCode.networkError:
        return 'network_error';
      case AuthErrorCode.userAlreadyExists:
        return 'user_already_exists';
      case AuthErrorCode.tooManyRequests:
        return 'over_request_rate_limit';
      case AuthErrorCode.invalidInput:
        return 'validation_failed';
      case AuthErrorCode.invalidVerificationCode:
        return 'otp_expired';
      case AuthErrorCode.serverError:
        return 'unexpected_failure';
      case null:
      case AuthErrorCode.unknown:
      default:
        return 'unexpected_failure';
    }
  }

}

/// 注册结果
class RegistrationResult {
  final bool success;
  final String message;
  final String? registrationId;
  final RegistrationErrorType? errorType;
  final dynamic user;
  final String? token;
  final bool isExistingUser;

  const RegistrationResult({
    required this.success,
    required this.message,
    this.registrationId,
    this.errorType,
    this.user,
    this.token,
    this.isExistingUser = false,
  });

  factory RegistrationResult.success({
    required String message,
    String? registrationId,
    dynamic user,
    String? token,
    bool isExistingUser = false,
  }) {
    return RegistrationResult(
      success: true,
      message: message,
      registrationId: registrationId,
      user: user,
      token: token,
      isExistingUser: isExistingUser,
    );
  }

  factory RegistrationResult.failure({
    required String message,
    required RegistrationErrorType errorType,
  }) {
    return RegistrationResult(
      success: false,
      message: message,
      errorType: errorType,
    );
  }
}

/// 注册验证结果
class RegistrationValidationResult {
  final bool isValid;
  final List<String> errors;

  const RegistrationValidationResult({
    required this.isValid,
    required this.errors,
  });

  String? get firstError => errors.isNotEmpty ? errors.first : null;
}
