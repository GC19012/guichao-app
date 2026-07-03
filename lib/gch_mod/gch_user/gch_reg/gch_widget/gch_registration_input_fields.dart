// registration_input_fields.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:guichao/gch_mod/gch_user/gch_shared/gch_international_phone_input.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_mod/gch_user/gch_reg/gch_model/gch_registration_state.dart';
import 'package:guichao/gch_mod/gch_user/gch_reg/gch_ctrl/gch_registration_notifier.dart';

/// 注册输入字段组件
class RegistrationInputFields extends ConsumerWidget {
  final RegistrationState state;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController codeController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onObscurePasswordToggled;
  final ValueChanged<String> onCountryCodeChanged;
  final ValueChanged<PhoneNumberData>? onPhoneNumberChanged;
  final ValueChanged<bool>? onPhoneValidated;
  final VoidCallback onSendCode;
  final VoidCallback onResendCode;

  const RegistrationInputFields({
    super.key,
    required this.state,
    required this.emailController,
    required this.phoneController,
    required this.codeController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onObscurePasswordToggled,
    required this.onCountryCodeChanged,
    this.onPhoneNumberChanged,
    this.onPhoneValidated,
    required this.onSendCode,
    required this.onResendCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(registrationNotifierProvider.notifier);
    return Column(
      children: [
        if (state.registerType == RegisterType.phone)
          _buildPhoneInputField()
        else
          _buildEmailInputField(),

        SizedBox(height: 16.24.rh),

        _buildVerificationCodeField(notifier),

        SizedBox(height: 16.24.rh),

        _buildPasswordField(),
      ],
    );
  }

  /// 构建邮箱输入字段
  Widget _buildEmailInputField() {
    return Container(
      height: 48.72.rh,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(22.5.rr),
      ),
      child: Row(
        children: [
          SizedBox(width: 15.rw),
          Expanded(
            child: TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(
                fontSize: 15.rf,
                color: const Color(0xFF333333),
              ),
              decoration: InputDecoration(
                hintText: GchText.userLoginEmailHint,
                hintStyle: TextStyle(
                  fontSize: 15.rf,
                  color: const Color(0xFFAAAAAA),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建手机号输入字段 - 使用 phone_form_field
  Widget _buildPhoneInputField() {
    return Container(
      height: 48.72.rh,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(22.5.rr),
      ),
      child: InternationalPhoneInput(
        textController: phoneController,
        initialCountryCode: 'CN',
        hintText: GchText.userLoginPhoneHint,
        hasError: state.errorType == RegistrationErrorType.validation &&
                  state.registerType == RegisterType.phone,
        height: 48.72.rh,
        borderRadius: 22.5.rr,
        backgroundColor: Colors.transparent,
        textColor: const Color(0xFF333333),
        hintColor: const Color(0xFFAAAAAA),
        autoValidateMode: AutovalidateMode.disabled,
        onInputChanged: (PhoneNumberData number) {
          if (number.dialCode != null) {
            onCountryCodeChanged(number.dialCode!);
          }
          onPhoneNumberChanged?.call(number);
        },
        onInputValidated: onPhoneValidated,
      ),
    );
  }

  /// 构建验证码输入字段
  Widget _buildVerificationCodeField(RegistrationNotifier notifier) {
    final isLoading = state.phase == RegistrationPhase.sendingCode;
    final canSend = state.canSendCode;
    final countdownText = notifier.countdownText();
    final isEnabled = canSend && !isLoading;

    return Container(
      height: 48.72.rh,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(22.5.rr),
      ),
      child: Row(
        children: [
          SizedBox(width: 15.rw),
          Icon(Icons.message_outlined, color: const Color(0xFF999999), size: 18.ri),
          SizedBox(width: 11.25.rw),
          Expanded(
            child: TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: TextStyle(
                fontSize: 15.rf,
                color: const Color(0xFF333333),
              ),
              decoration: InputDecoration(
                hintText: GchText.userLoginCodeHint,
                hintStyle: TextStyle(
                  fontSize: 15.rf,
                  color: const Color(0xFFAAAAAA),
                ),
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          GestureDetector(
            onTap: !isEnabled
                ? null
                : state.hasSignedUp
                    ? onResendCode
                    : onSendCode,
            child: Container(
              margin: EdgeInsets.only(right: 7.5.rw),
              width: 82.5.rw,
              height: 32.48.rh,
              decoration: isEnabled
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(16.24.rh),
                      image: const DecorationImage(
                        image: AssetImage('assets/gch_pics/gch_a05c0e.webp'),
                        fit: BoxFit.cover,
                      ),
                    )
                  : BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16.24.rh),
                    ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 12.ri,
                        height: 12.ri,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        countdownText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.rf,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建密码输入字段（带强度指示器）
  Widget _buildPasswordField() {
    final password = passwordController.text;
    final hasMinLength = password.length >= 8;
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final showIndicator = password.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48.72.rh,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(22.5.rr),
          ),
          child: Row(
            children: [
              SizedBox(width: 15.rw),
              Image.asset(
                'assets/gch_pics/gch_156fdd.webp',
                width: 18.ri,
                height: 18.ri,
              ),
              SizedBox(width: 7.5.rw),
              Expanded(
                child: TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: TextStyle(
                    fontSize: 15.rf,
                    color: const Color(0xFF333333),
                  ),
                  decoration: InputDecoration(
                    hintText: GchText.userLoginPasswordHint,
                    hintStyle: TextStyle(
                      fontSize: 15.rf,
                      color: const Color(0xFFAAAAAA),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              IconButton(
                icon: Image.asset(
                  'assets/gch_pics/gch_1dfc95.webp',
                  width: 18.ri,
                  height: 18.ri,
                ),
                onPressed: onObscurePasswordToggled,
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: showIndicator
              ? Padding(
                  padding: EdgeInsets.only(left: 18.75.rw, top: 8.12.rh),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPasswordRule(
                        GchText.userRegisterPasswordRuleLength,
                        hasMinLength,
                      ),
                      SizedBox(height: 4.06.rh),
                      _buildPasswordRule(
                        GchText.userRegisterPasswordRuleLetter,
                        hasLetter,
                      ),
                      SizedBox(height: 4.06.rh),
                      _buildPasswordRule(
                        GchText.userRegisterPasswordRuleDigit,
                        hasDigit,
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// 构建单条密码规则指示
  Widget _buildPasswordRule(String text, bool isSatisfied) {
    return Row(
      children: [
        Icon(
          isSatisfied ? Icons.check_circle : Icons.circle_outlined,
          size: 11.ri,
          color: isSatisfied ? const Color(0xFF34C759) : const Color(0xFFAAAAAA),
        ),
        SizedBox(width: 5.625.rw),
        Text(
          text,
          style: TextStyle(
            fontSize: 10.rf,
            color: isSatisfied ? const Color(0xFF34C759) : const Color(0xFFAAAAAA),
          ),
        ),
      ],
    );
  }
}
