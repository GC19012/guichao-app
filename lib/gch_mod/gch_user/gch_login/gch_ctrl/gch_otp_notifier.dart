import 'package:guichao/gch_base/gch_biz/gch_wire/gch_appprovider.dart';
import 'package:guichao/gch_mod/gch_user/gch_login/gch_ctrl/gch_otp_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gch_otp_notifier.g.dart';

/// OTP状态管理的Riverpod Notifier
@riverpod
class OtpNotifier extends _$OtpNotifier {
  OtpManager? _otpManager;

  @override
  OtpState build() {
    // 初始化OTP管理器
    _otpManager = OtpManager(
      onStateChanged: (newState) {
        // 当业务逻辑状态改变时，更新Riverpod状态
        state = newState;
      },
    );

    // 确保在dispose时清理资源
    ref.onDispose(() {
      _otpManager?.dispose();
    });

    return const OtpState();
  }

  /// 设置 Turnstile token
  void setTurnstileToken(String? token) {
    _otpManager?.setTurnstileToken(token);
  }

  /// 发送手机验证码
  Future<OtpSendResult> sendPhoneOtp({
    required String phoneNumber,
    required String countryCode,
    String? turnstileToken,  // ✅ 新增: Turnstile token
  }) async {
    final authManager = await ref.read(AppProvider.auth.manager.future);

    return await _otpManager!.sendOtp(
      authManager: authManager,
      method: OtpMethod.phone,
      identifier: phoneNumber,
      countryCode: countryCode,
      turnstileToken: turnstileToken,  // ✅ 传递 token
    );
  }

  /// 发送邮箱验证码
  Future<OtpSendResult> sendEmailOtp({
    required String email,
    String? turnstileToken,  // ✅ 新增: Turnstile token
  }) async {
    final authManager = await ref.read(AppProvider.auth.manager.future);

    return await _otpManager!.sendOtp(
      authManager: authManager,
      method: OtpMethod.email,
      identifier: email,
      turnstileToken: turnstileToken,  // ✅ 传递 token
    );
  }

  /// 验证手机号格式
  bool validatePhoneNumber(String phone, String countryCode) {
    return _otpManager?.validatePhoneNumber(phone, countryCode) ?? false;
  }

  /// 验证邮箱格式
  bool validateEmail(String email) {
    return _otpManager?.validateEmail(email) ?? false;
  }

  /// 清除错误状态
  void clearError() {
    if (_otpManager != null) {
      state = state.copyWith(lastError: null);
    }
  }

  /// 重置指定方式的倒计时（用于测试或特殊情况）
  void resetCountdown(OtpMethod method) {
    if (_otpManager != null) {
      if (method == OtpMethod.phone) {
        state = state.copyWith(phoneCountdown: 0);
      } else {
        state = state.copyWith(emailCountdown: 0);
      }
    }
  }
}
