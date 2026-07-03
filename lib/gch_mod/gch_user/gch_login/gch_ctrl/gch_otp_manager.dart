import 'dart:async';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_manager.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_provider_interface.dart';

part 'gch_otp_manager.freezed.dart';

/// OTP类型枚举
enum OtpMethod {
  phone,
  email,
}

/// OTP状态
@freezed
abstract class OtpState with _$OtpState {
  const factory OtpState({
    @Default(0) int phoneCountdown,
    @Default(0) int emailCountdown,
    @Default(false) bool isPhoneSending,
    @Default(false) bool isEmailSending,
    String? lastPhoneNumber,
    String? lastEmail,
    String? lastError,
    String? turnstileToken,  // ✅ 新增: Turnstile 验证 token
  }) = _OtpState;

  const OtpState._();

  /// 是否可以发送手机验证码
  bool get canSendPhoneOtp => phoneCountdown == 0 && !isPhoneSending;

  /// 是否可以发送邮箱验证码
  bool get canSendEmailOtp => emailCountdown == 0 && !isEmailSending;

  /// 获取指定方式的倒计时
  int getCountdown(OtpMethod method) {
    return method == OtpMethod.phone ? phoneCountdown : emailCountdown;
  }

  /// 是否可以发送指定方式的验证码
  bool canSend(OtpMethod method) {
    return method == OtpMethod.phone ? canSendPhoneOtp : canSendEmailOtp;
  }

  /// 是否正在发送指定方式的验证码
  bool isSending(OtpMethod method) {
    return method == OtpMethod.phone ? isPhoneSending : isEmailSending;
  }
}

/// OTP管理器 - 纯业务逻辑类
class OtpManager {
  Timer? _phoneTimer;
  Timer? _emailTimer;
  
  final void Function(OtpState) _onStateChanged;
  OtpState _state = const OtpState();

  OtpManager({required void Function(OtpState) onStateChanged})
      : _onStateChanged = onStateChanged;

  OtpState get state => _state;

  void dispose() {
    _phoneTimer?.cancel();
    _emailTimer?.cancel();
  }

  /// 更新状态并通知监听器
  void _updateState(OtpState newState) {
    _state = newState;
    _onStateChanged(_state);
  }

  /// 开始手机号倒计时
  void _startPhoneCountdown() {
    _phoneTimer?.cancel();
    _updateState(_state.copyWith(phoneCountdown: 60));

    _phoneTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newCountdown = _state.phoneCountdown - 1;
      if (newCountdown <= 0) {
        timer.cancel();
        _phoneTimer = null;
        _updateState(_state.copyWith(phoneCountdown: 0));
      } else {
        _updateState(_state.copyWith(phoneCountdown: newCountdown));
      }
    });
  }

  /// 开始邮箱倒计时
  void _startEmailCountdown() {
    _emailTimer?.cancel();
    _updateState(_state.copyWith(emailCountdown: 60));

    _emailTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newCountdown = _state.emailCountdown - 1;
      if (newCountdown <= 0) {
        timer.cancel();
        _emailTimer = null;
        _updateState(_state.copyWith(emailCountdown: 0));
      } else {
        _updateState(_state.copyWith(emailCountdown: newCountdown));
      }
    });
  }

  /// 验证手机号格式
  bool validatePhoneNumber(String phone, String countryCode) {
    if (phone.isEmpty) return false;

    switch (countryCode) {
      case '+86': // 中国大陆
        return RegExp(r'^1[3-9]\d{9}$').hasMatch(phone);
      case '+1': // 美国/加拿大
        return RegExp(r'^[2-9]\d{2}[2-9]\d{2}\d{4}$').hasMatch(phone);
      case '+852': // 香港
        return RegExp(r'^[5-9]\d{7}$').hasMatch(phone);
      case '+886': // 台湾
        return RegExp(r'^09\d{8}$').hasMatch(phone);
      case '+65': // 新加坡
        return RegExp(r'^[89]\d{7}$').hasMatch(phone);
      case '+81': // 日本
        return RegExp(r'^[789]0\d{8}$').hasMatch(phone);
      case '+82': // 韩国
        return RegExp(r'^010\d{8}$').hasMatch(phone);
      case '+44': // 英国
        return RegExp(r'^7\d{9}$').hasMatch(phone);
      default:
        // 通用验证：6-15位数字
        return RegExp(r'^\d{6,15}$').hasMatch(phone);
    }
  }

  /// 验证邮箱格式
  bool validateEmail(String email) {
    if (email.isEmpty) return false;
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  /// 设置 Turnstile token
  void setTurnstileToken(String? token) {
    _updateState(_state.copyWith(turnstileToken: token));
  }

  void _clearTurnstileToken() {
    if (_state.turnstileToken != null) {
      _updateState(_state.copyWith(turnstileToken: null));
    }
  }

  /// 发送验证码
  Future<OtpSendResult> sendOtp({
    required AuthManager authManager,
    required OtpMethod method,
    required String identifier,
    String? countryCode,
    String? turnstileToken,  // ✅ 新增: Turnstile token 参数
  }) async {
    // 检查是否可以发送
    if (!state.canSend(method)) {
      return OtpSendResult.failure('otp_countdown_active');
    }

    // 先验证输入，避免用户因为格式错误浪费验证码机会
    final normalizedCountryCode = countryCode ?? '+86';
    if (method == OtpMethod.phone) {
      if (!validatePhoneNumber(identifier, normalizedCountryCode)) {
        return OtpSendResult.failure('phone_invalid');
      }
    } else {
      if (!validateEmail(identifier)) {
        return OtpSendResult.failure('email_address_invalid');
      }
    }

    // ✅ 获取 Turnstile token（手机和邮箱都需要）
    final effectiveToken = turnstileToken ?? _state.turnstileToken;
    if (effectiveToken == null || effectiveToken.isEmpty) {
      return OtpSendResult.failure('captcha_required');
    }

    // 更新发送状态
    if (method == OtpMethod.phone) {
      _updateState(_state.copyWith(isPhoneSending: true, lastError: null));
    } else {
      _updateState(_state.copyWith(isEmailSending: true, lastError: null));
    }

    try {
      // 发送验证码
      final fullIdentifier = method == OtpMethod.phone
          ? '$normalizedCountryCode$identifier'
          : identifier;

      final success = await authManager.sendOtp(
        fullIdentifier,
        type: method == OtpMethod.phone ? OtpType.sms : OtpType.email,
        captchaToken: effectiveToken,
      );

      if (success) {
        // 成功：开始倒计时，更新最后发送的号码/邮箱
        if (method == OtpMethod.phone) {
          _updateState(_state.copyWith(
            isPhoneSending: false,
            lastPhoneNumber: fullIdentifier,
          ));
          _startPhoneCountdown();
        } else {
          _updateState(_state.copyWith(
            isEmailSending: false,
            lastEmail: identifier,
          ));
          _startEmailCountdown();
        }

        final result = OtpSendResult.success(
          method == OtpMethod.phone ? 'otp_sent_phone' : 'otp_sent_email',
        );
        _clearTurnstileToken();
        return result;
      } else {
        // 失败
        final errorCode = method == OtpMethod.phone
            ? 'sms_send_failed'
            : 'otp_send_failed';

        _updateState(_state.copyWith(
          isPhoneSending: method == OtpMethod.phone ? false : _state.isPhoneSending,
          isEmailSending: method == OtpMethod.email ? false : _state.isEmailSending,
          lastError: errorCode,
        ));

        _clearTurnstileToken();
        return OtpSendResult.failure(errorCode);
      }
    } catch (e) {
      // 异常处理 - 传递原始错误消息让 GchCuowuFanyi 处理
      final errorMsg = e.toString();

      _updateState(_state.copyWith(
        isPhoneSending: method == OtpMethod.phone ? false : _state.isPhoneSending,
        isEmailSending: method == OtpMethod.email ? false : _state.isEmailSending,
        lastError: errorMsg,
      ));

      _clearTurnstileToken();
      return OtpSendResult.failure(errorMsg);
    }
  }
}

/// OTP发送结果
@freezed
abstract class OtpSendResult with _$OtpSendResult {
  const factory OtpSendResult.success(String message) = _OtpSendSuccess;
  const factory OtpSendResult.failure(String error) = _OtpSendFailure;

  const OtpSendResult._();

  bool get isSuccess => this is _OtpSendSuccess;
  bool get isFailure => this is _OtpSendFailure;

  String get message => when(
    success: (msg) => msg,
    failure: (error) => error,
  );
}
