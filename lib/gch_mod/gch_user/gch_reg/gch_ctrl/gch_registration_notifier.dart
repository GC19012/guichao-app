// registration_notifier.dart
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_base/gch_biz/gch_wire/gch_appprovider.dart';
import 'package:guichao/gch_mod/gch_user/gch_reg/gch_model/gch_registration_state.dart';
import 'package:guichao/gch_mod/gch_user/gch_reg/gch_svc/gch_registration_service.dart';
import 'package:guichao/gch_mod/gch_user/gch_reg/gch_svc/gch_countdown_timer.dart';
import 'package:guichao/gch_mod/gch_user/gch_reg/gch_svc/gch_registration_error_handler.dart';

part 'gch_registration_notifier.g.dart';

/// 注册状态通知器
/// 
/// 管理整个注册流程的状态，包括输入验证、验证码发送、倒计时和最终验证
@riverpod
class RegistrationNotifier extends _$RegistrationNotifier {
  late RegistrationService _registrationService;
  late VerificationCountdownTimer _emailCountdownTimer;
  late VerificationCountdownTimer _phoneCountdownTimer;
  late RegistrationErrorStats _errorStats;
  Timer? _debounceTimer;

  /// 防抖延迟时间
  static const Duration _debounceDelay = Duration(milliseconds: 500);

  @override
  RegistrationState build() {
    // 初始化服务
    _initializeServices();

    // 注册资源清理
    ref.onDispose(() {
      _emailCountdownTimer.dispose();
      _phoneCountdownTimer.dispose();
      _debounceTimer?.cancel();
    });

    // 返回初始状态
    return const RegistrationState();
  }

  /// 初始化服务
  Future<void> _initializeServices() async {
    final authManager = await ref.read(AppProvider.auth.manager.future);
    _registrationService = RegistrationService(authManager);
    _errorStats = RegistrationErrorStats();

    // 初始化邮箱倒计时器
    _emailCountdownTimer = VerificationCountdownTimer()
      ..onTick = (remainingSeconds) {
        state = state.copyWith(emailCountdownSeconds: remainingSeconds);
      }
      ..onComplete = () {
        state = state.copyWith(emailCountdownSeconds: 0);
      };

    // 初始化手机倒计时器
    _phoneCountdownTimer = VerificationCountdownTimer()
      ..onTick = (remainingSeconds) {
        state = state.copyWith(phoneCountdownSeconds: remainingSeconds);
      }
      ..onComplete = () {
        state = state.copyWith(phoneCountdownSeconds: 0);
      };
  }

  /// 获取当前类型的倒计时器
  VerificationCountdownTimer get _currentCountdownTimer {
    return state.registerType == RegisterType.email
        ? _emailCountdownTimer
        : _phoneCountdownTimer;
  }

  /// 切换注册类型
  void switchRegisterType(RegisterType type) {
    if (state.registerType != type) {
      // 清除之前的输入和状态，但保留各自的倒计时
      state = state.copyWith(
        registerType: type,
        email: type == RegisterType.email ? state.email : null,
        phone: type == RegisterType.phone ? state.phone : null,
        phase: RegistrationPhase.initial,
        hasSignedUp: false,
        errorMessage: null,
        errorType: null,
        verificationCode: null,
        registrationId: null,
        codeSentAt: null,
        turnstileToken: null,
      );
      // 注意：不取消倒计时，保留各自独立的倒计时状态
    }
  }

  /// 更新邮箱（立即更新状态，确保按钮响应）
  void updateEmail(String email) {
    state = state.copyWith(
      email: email,
      errorMessage: null,
      errorType: null,
    );
  }

  /// 更新手机号（立即更新状态，确保按钮响应）
  void updatePhone(String phone) {
    state = state.copyWith(
      phone: phone,
      errorMessage: null,
      errorType: null,
    );
  }

  /// 更新国家代码
  void updateCountryCode(String countryCode) {
    state = state.copyWith(
      countryCode: countryCode,
      errorMessage: null,
      errorType: null,
    );
    _validateInput();
  }

  /// 更新手机号验证状态
  /// 由 InternationalPhoneInput 组件的 onInputValidated 回调调用
  void updatePhoneValidation(bool isValid) {
    state = state.copyWith(
      isPhoneValid: isValid,
      errorMessage: null,
      errorType: null,
    );
  }

  /// 更新密码
  void updatePassword(String password) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      state = state.copyWith(
        password: password,
        errorMessage: null,
        errorType: null,
      );
      _validateInput();
    });
  }

  /// 更新验证码
  void updateVerificationCode(String code) {
    state = state.copyWith(
      verificationCode: code,
      errorMessage: null,
      errorType: null,
    );
  }

  /// 切换协议同意状态
  void toggleTermsAgreement() {
    state = state.copyWith(
      agreedToTerms: !state.agreedToTerms,
      errorMessage: null,
      errorType: null,
    );
  }

  /// 切换密码可见性
  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  /// ✅ 新增: 设置 Turnstile token
  void setTurnstileToken(String? token) {
    state = state.copyWith(turnstileToken: token);
  }

  void _consumeTurnstileToken() {
    if (state.turnstileToken != null) {
      state = state.copyWith(turnstileToken: null);
    }
  }

  /// 验证输入数据
  void _validateInput() {
    final identifier = state.currentIdentifier ?? '';
    // 输入阶段不强制验证密码与协议，协议在最终注册提交时校验
    final validation = _registrationService.validateRegistrationData(
      type: state.registerType,
      identifier: identifier,
      password: state.password,
      agreedToTerms: true,
      requirePassword: false,
      isPhoneValid: state.isPhoneValid,
    );

    if (!validation.isValid && identifier.isNotEmpty) {
      _setError(
        validation.firstError ?? GchText.userLoginErrorsLoginFailed,
        RegistrationErrorType.validation,
      );
    }
  }

  /// 发送验证码
  Future<void> sendVerificationCode() async {
    if (!state.canSendCode) {
      return;
    }

    // 获取验证码只验证标识符，不要求先勾选协议（协议在最终注册提交时校验）
    final identifier = state.currentIdentifier!;
    final validation = _registrationService.validateRegistrationData(
      type: state.registerType,
      identifier: identifier,
      password: null,
      agreedToTerms: true, // 绕过协议检查
      requirePassword: false,
      isPhoneValid: state.isPhoneValid,
    );

    if (!validation.isValid) {
      _setError(
        validation.firstError ?? GchText.userLoginAgreeError,
        RegistrationErrorType.validation,
      );
      return;
    }

    // 检查 Turnstile token
    if (state.turnstileToken == null || state.turnstileToken!.isEmpty) {
      _setError('captcha_required', RegistrationErrorType.validation);
      return;
    }

    // 设置发送状态
    state = state.copyWith(
      phase: RegistrationPhase.sendingCode,
      isLoading: true,
      errorMessage: null,
      errorType: null,
    );

    try {
      // ✅ 调用注册服务发送验证码（传递 Turnstile token）
      final result = await _registrationService.sendVerificationCode(
        type: state.registerType,
        identifier: identifier,
        password: null,  // 此时不传递密码
        countryCode: state.countryCode,
        turnstileToken: state.turnstileToken,  // ✅ 传递 Turnstile token
      );

      if (result.success) {
        // 成功发送验证码
        state = state.copyWith(
          phase: RegistrationPhase.codeSent,
          isLoading: false,
          hasSignedUp: true,
          registrationId: result.registrationId,
          codeSentAt: DateTime.now(),
          errorMessage: null,
          errorType: null,
        );

        // 开始倒计时
        _currentCountdownTimer.startVerificationCountdown();
      } else {
        // 发送失败
        _setError(result.message, result.errorType!);
        _errorStats.recordError(result.errorType!);
        
        state = state.copyWith(
          phase: RegistrationPhase.initial,
          isLoading: false,
        );
      }
    } catch (e) {
      _setError('${GchText.userPayErrorsNetworkError}: $e', RegistrationErrorType.unknown);
      _errorStats.recordError(RegistrationErrorType.unknown);

      state = state.copyWith(
        phase: RegistrationPhase.initial,
        isLoading: false,
      );
    }
    _consumeTurnstileToken();
  }

  /// 重新发送验证码
  Future<void> resendVerificationCode() async {
    if (!state.hasSignedUp || state.isCountingDown) {
      return;
    }

    if (state.turnstileToken == null || state.turnstileToken!.isEmpty) {
      _setError('captcha_required', RegistrationErrorType.validation);
      _errorStats.recordError(RegistrationErrorType.validation);
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      errorType: null,
    );

    try {
      final result = await _registrationService.resendVerificationCode(
        type: state.registerType,
        identifier: state.currentIdentifier!,
        registrationId: state.registrationId!,
      );

      if (result.success) {
        state = state.copyWith(
          isLoading: false,
          codeSentAt: DateTime.now(),
        );

        // 重新开始倒计时
        _currentCountdownTimer.startVerificationCountdown();
      } else {
        _setError(result.message, result.errorType!);
        _errorStats.recordError(result.errorType!);
        
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      _setError('${GchText.userPayErrorsNetworkError}: $e', RegistrationErrorType.unknown);
      _errorStats.recordError(RegistrationErrorType.unknown);

      state = state.copyWith(isLoading: false);
    }
    _consumeTurnstileToken();
  }

  /// 验证并完成注册
  Future<bool> verifyAndCompleteRegistration() async {
    if (!state.canVerify) {
      return false;
    }

    // 注册时验证密码
    final passwordValidation = _registrationService.validateRegistrationData(
      type: state.registerType,
      identifier: state.currentIdentifier!,
      password: state.password,
      agreedToTerms: state.agreedToTerms,
      requirePassword: true,  // 注册时必须验证密码
      isPhoneValid: state.isPhoneValid,  // 传递手机号验证状态
    );

    if (!passwordValidation.isValid) {
      _setError(
        passwordValidation.firstError ?? GchText.userRegisterPasswordRule,
        RegistrationErrorType.validation,
      );
      return false;
    }

    state = state.copyWith(
      phase: RegistrationPhase.verifying,
      isLoading: true,
      errorMessage: null,
      errorType: null,
    );

    try {
      // 验证OTP并更新密码
      final result = await _registrationService.verifyCodeAndCompleteRegistration(
        type: state.registerType,
        identifier: state.currentIdentifier!,
        verificationCode: state.verificationCode!,
        registrationId: state.registrationId!,
        password: state.password,  // 传递密码用于更新
      );

      if (result.success) {
        state = state.copyWith(
          phase: RegistrationPhase.completed,
          isLoading: false,
        );

        // 取消倒计时
        _currentCountdownTimer.cancel();
        
        return true;
      } else {
        _setError(result.message, result.errorType!);
        _errorStats.recordError(result.errorType!);
        
        state = state.copyWith(
          phase: RegistrationPhase.codeSent,
          isLoading: false,
        );
        
        return false;
      }
    } catch (e) {
      _setError('${GchText.userPayErrorsNetworkError}: $e', RegistrationErrorType.unknown);
      _errorStats.recordError(RegistrationErrorType.unknown);

      state = state.copyWith(
        phase: RegistrationPhase.error,
        isLoading: false,
      );

      return false;
    }
  }

  /// 设置错误
  void _setError(String message, RegistrationErrorType errorType) {
    state = state.copyWith(
      errorMessage: message,
      errorType: errorType,
      phase: RegistrationPhase.error,
    );
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(
      errorMessage: null,
      errorType: null,
      phase: state.hasSignedUp ? RegistrationPhase.codeSent : RegistrationPhase.initial,
    );
  }

  /// 重置状态
  void reset() {
    _currentCountdownTimer.cancel();
    _errorStats.clear();
    _debounceTimer?.cancel();
    
    state = const RegistrationState();
  }

  /// 获取错误信息
  /// [] 翻译对象，用于获取本地化文本
  RegistrationErrorInfo? getErrorInfo() {
    if (state.errorType == null || state.errorMessage == null) {
      return null;
    }

    return RegistrationErrorHandler.handleError(
      state.errorType!,
      state.errorMessage,
      context: 'registration_flow',
    );
  }

  /// 是否频繁错误
  bool isFrequentError(RegistrationErrorType errorType) {
    return _errorStats.isFrequentError(errorType);
  }

  /// 获取剩余倒计时文本
  /// 倒计时过程中只显示秒数，不再叠加"重新发送"前缀
  String countdownText() {
    if (state.isCountingDown) {
      return '${state.countdownSeconds}s';
    } else if (state.hasSignedUp) {
      return GchText.userLoginResend;
    } else {
      return GchText.userLoginGetCode;
    }
  }

  /// 获取注册按钮文本
  String registerButtonText() {
    switch (state.phase) {
      case RegistrationPhase.initial:
        return GchText.userRegisterRegisterBtn;
      case RegistrationPhase.sendingCode:
        return GchText.userLoginSending;
      case RegistrationPhase.codeSent:
        return GchText.userRegisterVerifyBtn;
      case RegistrationPhase.verifying:
        return GchText.userRegisterVerifying;
      case RegistrationPhase.completed:
        return GchText.userRegisterComplete;
      case RegistrationPhase.error:
        return state.hasSignedUp ? GchText.userRegisterVerifyBtn : GchText.userRegisterRegisterBtn;
    }
  }
  // 注意：资源清理已在 build() 方法中通过 ref.onDispose() 处理
}

