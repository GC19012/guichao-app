import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:guichao/gch_mod/gch_user/gch_shared/gch_international_phone_input.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:guichao/gch_base/gch_cuowu/gch_cuowu_fanyi.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_base/gch_signal/gch_signal_hub.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_captcha/gch_captcha.dart';
import 'package:guichao/gch_mod/gch_user/gch_login/gch_ctrl/gch_otp_manager.dart';
import 'package:guichao/gch_mod/gch_user/gch_login/gch_ctrl/gch_otp_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// OTP 组件主题颜色（与 LoginPage 浅色主题保持一致）
class _OtpColors {
  static const Color inputBackground = Color(0xFFF5F5F5);
  static const Color hintText = Color(0xFFAAAAAA);
  static const Color inputText = Color(0xFF333333);
  static const Color iconColor = Color(0xFF999999);
}

/// OTP验证组件 - 纯UI组件，依赖外部状态管理
class OtpVerificationWidget extends HookConsumerWidget {
  final bool useEmail;
  final String selectedCountryCode;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController codeController;
  final ValueChanged<String> onCountryCodeChanged;
  final bool Function()? ensureAgreementChecked;
  /// 手机号验证状态回调 - 用于同步到父组件状态
  final ValueChanged<bool>? onPhoneValidated;
  /// 邮箱验证状态回调 - 用于同步到父组件状态
  final ValueChanged<bool>? onEmailValidated;
  /// 切换手机/邮箱回调
  final VoidCallback? onTogglePhoneEmail;
  /// 初始手机号验证状态 - 用于从父组件同步验证状态（解决tab切换时状态不同步问题）
  final bool initialPhoneValid;
  /// 初始邮箱验证状态 - 用于从父组件同步验证状态（解决tab切换时状态不同步问题）
  final bool initialEmailValid;

  const OtpVerificationWidget({
    super.key,
    required this.useEmail,
    required this.selectedCountryCode,
    required this.phoneController,
    required this.emailController,
    required this.codeController,
    required this.onCountryCodeChanged,
    this.ensureAgreementChecked,
    this.onPhoneValidated,
    this.onEmailValidated,
    this.onTogglePhoneEmail,
    this.initialPhoneValid = false,
    this.initialEmailValid = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otpState = ref.watch(otpNotifierProvider);
    final pendingRequest = useState<_PendingOtpRequest?>(null);
    final isMounted = useIsMounted();
    final captchaErrorShown = useState(false);
    final isPhoneValid = useState(initialPhoneValid);
    final isEmailValid = useState(initialEmailValid);

    final emailRegex = RegExp(
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
    );

    useEffect(() {
      void listener() {
        final text = emailController.text;
        final valid = text.isNotEmpty && emailRegex.hasMatch(text);
        isEmailValid.value = valid;
        onEmailValidated?.call(valid);
      }
      emailController.addListener(listener);
      return () => emailController.removeListener(listener);
    }, [emailController]);

    Future<void> handleCaptchaSuccess(CaptchaResult result) async {
      final request = pendingRequest.value;
      final notifier = ref.read(otpNotifierProvider.notifier);
      notifier.setTurnstileToken(result.token);

      if (request == null) return;

      pendingRequest.value = null;
      captchaErrorShown.value = false;

      OtpSendResult sendResult;
      if (request.method == OtpMethod.phone) {
        sendResult = await notifier.sendPhoneOtp(
          phoneNumber: request.identifier,
          countryCode: request.countryCode ?? selectedCountryCode,
          turnstileToken: result.token,
        );
      } else {
        sendResult = await notifier.sendEmailOtp(
          email: request.identifier,
          turnstileToken: result.token,
        );
      }

      _showMessage(context, ref, GchCuowuFanyi.bendihua(sendResult.message), sendResult.isSuccess);
    }

    Future<void> startCaptchaVerification() async {
      if (ensureAgreementChecked != null && !ensureAgreementChecked!()) {
        return;
      }
      final notifier = ref.read(otpNotifierProvider.notifier);
      final method = useEmail ? OtpMethod.email : OtpMethod.phone;
      final identifier = (method == OtpMethod.phone
              ? phoneController.text
              : emailController.text)
          .trim();

      if (pendingRequest.value != null) return;

      if (identifier.isEmpty) {
        _showMessage(
          context,
          ref,
          method == OtpMethod.phone
              ? GchText.userLoginPhoneHintText
              : GchText.userLoginEmailHintText,
          false,
        );
        return;
      }

      if (method == OtpMethod.phone) {
        if (!isPhoneValid.value) {
          _showMessage(context, ref, GchText.userLoginValidationPhoneInvalid, false);
          return;
        }
      } else {
        if (!isEmailValid.value) {
          _showMessage(context, ref, GchText.userLoginValidationEmailInvalid, false);
          return;
        }
      }

      pendingRequest.value = _PendingOtpRequest(
        method: method,
        identifier: identifier,
        countryCode: method == OtpMethod.phone ? selectedCountryCode : null,
      );

      final captcha = CaptchaFactory.instance;
      if (!captcha.isEnabled) {
        captchaErrorShown.value = false;
        OtpSendResult result;
        if (method == OtpMethod.phone) {
          result = await notifier.sendPhoneOtp(
            phoneNumber: identifier,
            countryCode: selectedCountryCode,
          );
        } else {
          result = await notifier.sendEmailOtp(email: identifier);
        }
        pendingRequest.value = null;
        _showMessage(context, ref, GchCuowuFanyi.bendihua(result.message), result.isSuccess);
        return;
      }

      captchaErrorShown.value = false;
      notifier.setTurnstileToken(null);

      captcha.show(
        context,
        onSuccess: (result) async {
          await handleCaptchaSuccess(result);
        },
        onExpired: () {
          notifier.setTurnstileToken(null);
          pendingRequest.value = null;
          _showMessage(context, ref, GchCuowuFanyi.bendihua('otp_expired'), false);
        },
        onError: (error) {
          notifier.setTurnstileToken(null);
          pendingRequest.value = null;
          if (!captchaErrorShown.value) {
            captchaErrorShown.value = true;
            String errorCode = 'captcha_failed';
            if (error.code == -1) {
              errorCode = error.message.contains('ERR_') ? 'network_error' : 'request_timeout';
            }
            Future.microtask(() {
              if (isMounted()) {
                _showMessage(context, ref, GchCuowuFanyi.bendihua(errorCode), false);
              }
            });
          }
        },
        onCancel: () {
          notifier.setTurnstileToken(null);
          pendingRequest.value = null;
        },
      );
    }

    return Column(
      children: [
        _buildIdentifierInput(context, isPhoneValid, isEmailValid),
        SizedBox(height: 16.24.rh),
        _buildOtpInput(
          context,
          ref,
          otpState,
          false,
          () => startCaptchaVerification(),
        ),
      ],
    );
  }

  Widget _buildIdentifierInput(
    BuildContext context,
    ValueNotifier<bool> isPhoneValid,
    ValueNotifier<bool> isEmailValid,
  ) {
    if (!useEmail) {
      return Container(
        height: 48.72.rh,
        decoration: BoxDecoration(
          color: _OtpColors.inputBackground,
          borderRadius: BorderRadius.circular(22.5.rr),
        ),
        child: Row(
          children: [
            Expanded(
              child: InternationalPhoneInput(
                textController: phoneController,
                initialCountryCode: 'CN',
                hintText: GchText.userLoginPhoneHintText,
                height: 48.72.rh,
                borderRadius: 22.5.rr,
                backgroundColor: Colors.transparent,
                textColor: _OtpColors.inputText,
                hintColor: _OtpColors.hintText,
                autoValidateMode: AutovalidateMode.disabled,
                errorMessage: GchText.userLoginValidationPhoneInvalid,
                onInputChanged: (PhoneNumberData number) {
                  if (number.dialCode != null) {
                    onCountryCodeChanged(number.dialCode!);
                  }
                },
                onInputValidated: (bool valid) {
                  isPhoneValid.value = valid;
                  onPhoneValidated?.call(valid);
                },
              ),
            ),
            if (onTogglePhoneEmail != null)
              _buildInlineSwitchButton(
                text: GchText.userLoginSwitchToEmail,
                onTap: onTogglePhoneEmail!,
              ),
          ],
        ),
      );
    } else {
      return Container(
        height: 48.72.rh,
        decoration: BoxDecoration(
          color: _OtpColors.inputBackground,
          borderRadius: BorderRadius.circular(22.5.rr),
        ),
        child: Row(
          children: [
            SizedBox(width: 15.rw),
            Expanded(
              child: TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(fontSize: 15.rf, color: _OtpColors.inputText),
                decoration: InputDecoration(
                  hintText: GchText.userLoginEmailHintText,
                  hintStyle: TextStyle(fontSize: 15.rf, color: _OtpColors.hintText),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (onTogglePhoneEmail != null)
              _buildInlineSwitchButton(
                text: GchText.userLoginSwitchToPhone,
                onTap: onTogglePhoneEmail!,
              ),
          ],
        ),
      );
    }
  }

  /// 切换手机/邮箱按钮（输入框内部，使用图片背景与 LoginPage 保持一致）
  Widget _buildInlineSwitchButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: REdgeInsets.only(right: 7.5),
        width: 82.5.rw,
        height: 32.48.rh,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.24.rr),
          image: const DecorationImage(
            image: AssetImage('assets/gch_pics/gch_a05c0e.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              fontSize: 13.rf,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpInput(
    BuildContext context,
    WidgetRef ref,
    OtpState otpState,
    bool isVerifying,
    VoidCallback startVerification,
  ) {
    final method = useEmail ? OtpMethod.email : OtpMethod.phone;
    final canSend = otpState.canSend(method);
    final countdown = otpState.getCountdown(method);
    final isSending = otpState.isSending(method);

    return Container(
      height: 48.72.rh,
      decoration: BoxDecoration(
        color: _OtpColors.inputBackground,
        borderRadius: BorderRadius.circular(22.5.rr),
      ),
      child: Row(
        children: [
          SizedBox(width: 15.rw),
          Icon(Icons.message_outlined, color: _OtpColors.iconColor, size: 18.ri),
          SizedBox(width: 11.25.rw),
          Expanded(
            child: TextField(
              controller: codeController,
              decoration: InputDecoration(
                hintText: GchText.userLoginCodeHintText,
                hintStyle: TextStyle(fontSize: 15.rf, color: _OtpColors.hintText),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(fontSize: 15.rf, color: _OtpColors.inputText),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          _buildOtpButton(
            context,
            ref,
            canSend,
            countdown,
            isSending,
            isVerifying,
            startVerification,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpButton(
    BuildContext context,
    WidgetRef ref,
    bool canSend,
    int countdown,
    bool isSending,
    bool isVerifying,
    VoidCallback startVerification,
  ) {
    final isEnabled = canSend && !isSending && !isVerifying;

    return GestureDetector(
      onTap: isEnabled ? startVerification : null,
      child: Container(
        margin: REdgeInsets.only(right: 7.5),
        width: 82.5.rw,
        height: 32.48.rh,
        decoration: isEnabled
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(16.24.rr),
                image: const DecorationImage(
                  image: AssetImage('assets/gch_pics/gch_a05c0e.webp'),
                  fit: BoxFit.cover,
                ),
              )
            : BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16.24.rr),
              ),
        child: Center(
          child: Text(
            _getButtonText(canSend, countdown, isSending, isVerifying),
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              fontSize: 13.rf,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  String _getButtonText(
    bool canSend,
    int countdown,
    bool isSending,
    bool isVerifying,
  ) {
    if (isSending) return GchText.userLoginSending;
    if (isVerifying) return GchText.userRegisterVerifying;
    if (canSend) return GchText.userLoginGetCode;
    return '${countdown}s';
  }

  void _showMessage(BuildContext context, WidgetRef ref, String message, bool isSuccess) {
    final notificationController = ref.read(gchSignalHubProvider);
    if (isSuccess) {
      notificationController.flashSuccess(message);
    } else {
      notificationController.flashInfo(message);
    }
  }
}

class _PendingOtpRequest {
  _PendingOtpRequest({
    required this.method,
    required this.identifier,
    this.countryCode,
  });

  final OtpMethod method;
  final String identifier;
  final String? countryCode;
}
