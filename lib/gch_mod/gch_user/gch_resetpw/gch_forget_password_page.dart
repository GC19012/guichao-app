import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:guichao/gch_mod/gch_user/gch_shared/gch_international_phone_input.dart';
import 'package:guichao/gch_base/gch_cuowu/gch_cuowu_fanyi.dart';
import 'package:guichao/gch_base/gch_signal/gch_signal_hub.dart';
import 'package:guichao/gch_base/gch_nav/gch_routes.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_captcha/gch_captcha.dart';
import 'package:guichao/gch_mod/gch_user/gch_resetpw/gch_model/gch_forget_password_state.dart';
import 'package:guichao/gch_mod/gch_user/gch_resetpw/gch_ctrl/gch_forget_password_notifier.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';

/// 忘记密码页面主题颜色（浅色主题，与 SettingPage 背景风格保持一致）
class _ForgetPasswordColors {
  static const Color background = Color(0xFFF1EFF9);
  static const Color inputBackground = Colors.white;
  static const Color primaryText = Color(0xFF333333);
  static const Color secondaryText = Color(0xFF999999);
  static const Color accentColor = Color(0xFF5969FF);
  static const Color gradientStart = Color(0xFF6B5FED);
  static const Color gradientEnd = Color(0xFF4A90E2);
}

class ForgetPasswordPage extends ConsumerStatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  ConsumerState<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends ConsumerState<ForgetPasswordPage> {
  // 独立的控制器，邮箱和手机分开
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Captcha 相关状态
  bool _captchaErrorShown = false;

  @override
  void initState() {
    super.initState();
    _setupInputListeners();
  }

  void _setupInputListeners() {
    _emailController.addListener(() {
      final notifier = ref.read(forgetPasswordNotifierProvider.notifier);
      notifier.updateEmail(_emailController.text);
    });

    _codeController.addListener(() {
      final notifier = ref.read(forgetPasswordNotifierProvider.notifier);
      notifier.updateVerificationCode(_codeController.text);
    });

    _passwordController.addListener(() {
      final notifier = ref.read(forgetPasswordNotifierProvider.notifier);
      notifier.updateNewPassword(_passwordController.text);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();

    try {
      final notifier = ref.read(forgetPasswordNotifierProvider.notifier);
      notifier.reset();
    } catch (e) {
      // 忽略错误
    }

    super.dispose();
  }

  void _showMessage(String message, {bool isError = true}) {
    final notificationController = ref.read(gchSignalHubProvider);
    if (isError) {
      notificationController.flashError(message);
    } else {
      notificationController.flashSuccess(message);
    }
  }

  /// 处理返回操作
  void _handleBack() {
    // 清理状态
    final notifier = ref.read(forgetPasswordNotifierProvider.notifier);
    notifier.reset();

    // 使用 GoRouter 的 canPop/pop 方法，而不是直接 go
    if (context.canPop()) {
      context.pop();
    } else {
      // 无法返回时，跳转到登录页面
      const NavLoginRoute().go(context);
    }
  }

  /// 处理输入类型切换
  void _handleToggleInputType() {
    final notifier = ref.read(forgetPasswordNotifierProvider.notifier);
    notifier.toggleInputType();

    // 清除验证码和密码输入
    _codeController.clear();
    _passwordController.clear();

    // 重置 captcha 状态
    setState(() {
      _captchaErrorShown = false;
    });
    notifier.setCaptchaToken(null);
  }

  /// 处理手机号输入变化
  void _onPhoneInputChanged(PhoneNumberData number) {
    final notifier = ref.read(forgetPasswordNotifierProvider.notifier);
    // 获取完整的国际格式手机号
    final fullPhone = number.phoneNumber ?? '';
    notifier.updatePhone(fullPhone);
    // 更新国家代码
    if (number.dialCode != null) {
      notifier.updateCountryCode(number.dialCode!);
    }
  }

  /// 处理手机号验证状态变更
  void _onPhoneValidated(bool isValid) {
    final notifier = ref.read(forgetPasswordNotifierProvider.notifier);
    notifier.updatePhoneValidation(isValid);
  }

  /// 开始 Captcha 流程
  Future<void> _startCaptchaFlow() async {
    final notifier = ref.read(forgetPasswordNotifierProvider.notifier);
    final state = ref.read(forgetPasswordNotifierProvider);

    // 检查基本条件
    if (!state.canSendCode) {
      if (state.currentIdentifier.isEmpty) {
        final errorCode = state.inputType == ForgetPasswordType.email
            ? 'email_required'
            : 'phone_required';
        _showMessage(GchCuowuFanyi.bendihua(errorCode));
      } else if (state.inputType == ForgetPasswordType.phone && !state.isPhoneValid) {
        // 手机号格式无效
        _showMessage(GchText.userLoginValidationPhoneInvalid);
      } else if (state.inputType == ForgetPasswordType.email) {
        // 邮箱格式无效
        _showMessage(GchText.userLoginValidationEmailInvalid);
      }
      return;
    }

    _captchaErrorShown = false;

    final captcha = CaptchaFactory.instance;
    if (!captcha.isEnabled) {
      // Captcha 未启用，直接发送验证码
      final result = await notifier.sendVerificationCode();
      if (result.success) {
        _showMessage(GchCuowuFanyi.bendihua(result.message), isError: false);
      } else {
        _showMessage(GchCuowuFanyi.bendihua(result.message));
      }
      return;
    }

    notifier.setCaptchaToken(null);

    if (!mounted) return;

    captcha.show(
      context,
      onSuccess: (captchaResult) async {
        await _handleCaptchaSuccess(captchaResult);
      },
      onExpired: () {
        notifier.setCaptchaToken(null);
      },
      onError: (error) {
        _handleCaptchaError(error);
      },
      onCancel: () {
        notifier.setCaptchaToken(null);
      },
    );
  }

  Future<void> _handleCaptchaSuccess(CaptchaResult captchaResult) async {
    final notifier = ref.read(forgetPasswordNotifierProvider.notifier);
    notifier.setCaptchaToken(captchaResult.token);

    final result = await notifier.sendVerificationCode();

    if (!mounted) return;

    setState(() {
      _captchaErrorShown = false;
    });

    if (result.success) {
      _showMessage(GchCuowuFanyi.bendihua(result.message), isError: false);
    } else {
      _showMessage(GchCuowuFanyi.bendihua(result.message));
    }
  }

  void _handleCaptchaError(CaptchaError error) {
    if (_captchaErrorShown) return;
    _captchaErrorShown = true;
    ref.read(forgetPasswordNotifierProvider.notifier).setCaptchaToken(null);

    Future.microtask(() {
      if (!mounted) return;

      String errorCode = 'captcha_failed';
      if (error.code == -1) {
        errorCode = error.message.contains('ERR_') ? 'network_error' : 'request_timeout';
      }

      _showMessage(GchCuowuFanyi.bendihua(errorCode));
    });
  }

  /// 处理重置密码
  Future<void> _handleResetPassword() async {
    final notifier = ref.read(forgetPasswordNotifierProvider.notifier);
    final result = await notifier.resetPassword();
    if (result.success) {
      _showMessage(GchText.userForgotResetSuccess, isError: false);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _handleBack();
        }
      });
    }
    // 错误消息由 ref.listen 统一处理，避免重复提示
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgetPasswordNotifierProvider);

    // 监听错误消息 - 只在 errorMessage 变化时显示，避免倒计时触发重复弹窗
    ref.listen<ForgetPasswordState>(forgetPasswordNotifierProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage!.isNotEmpty &&
          next.errorMessage != previous?.errorMessage) {
        final localizedMessage = GchCuowuFanyi.bendihua(next.errorMessage);
        _showMessage(localizedMessage, isError: true);
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: _ForgetPasswordColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // 顶部导航栏
              _buildHeader(state),
              // 主内容区域
              Expanded(
                child: SingleChildScrollView(
                  padding: REdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      SizedBox(height: 20.rh),
                      _buildTitle(),
                      SizedBox(height: 32.rh),
                      _buildForm(state),
                      SizedBox(height: 40.rh),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建页面头部
  Widget _buildHeader(ForgetPasswordState state) {
    return SizedBox(
      height: 56.rh,
      child: Padding(
        padding: REdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _handleBack,
              child: Icon(
                Icons.arrow_back_ios,
                color: _ForgetPasswordColors.primaryText,
                size: 20.ri,
              ),
            ),
            GestureDetector(
              onTap: _handleToggleInputType,
              child: Text(
                state.inputType == ForgetPasswordType.email
                    ? GchText.userForgotSwitchToPhone
                    : GchText.userForgotSwitchToEmail,
                style: TextStyle(
                  color: _ForgetPasswordColors.accentColor,
                  fontSize: 14.rf,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建页面标题
  Widget _buildTitle() {
    return Text(
      GchText.userForgotTitle,
      style: TextStyle(
        fontSize: 26.rf,
        fontWeight: FontWeight.w600,
        color: _ForgetPasswordColors.primaryText,
      ),
    );
  }

  /// 构建表单
  Widget _buildForm(ForgetPasswordState state) {
    return Column(
      children: [
        // 邮箱/手机号输入框（根据类型显示不同的输入框）
        if (state.inputType == ForgetPasswordType.email)
          _buildEmailInputField()
        else
          InternationalPhoneInput(
            textController: _phoneController,
            initialCountryCode: 'CN',
            hintText: GchText.userForgotPhoneHint,
            height: 56.rh,
            borderRadius: 28.ri,
            backgroundColor: _ForgetPasswordColors.inputBackground,
            textColor: _ForgetPasswordColors.primaryText,
            hintColor: _ForgetPasswordColors.secondaryText,
            onInputChanged: _onPhoneInputChanged,
            onInputValidated: _onPhoneValidated,
          ),

        SizedBox(height: 15.rh),

        // 验证码输入框
        _buildCodeInputField(
          controller: _codeController,
          hintText: GchText.userForgotCodeHint,
          onSendCode: _startCaptchaFlow,
          countdown: state.countdown,
          isLoading: state.isCodeSending,
        ),

        SizedBox(height: 15.rh),

        // 新密码输入框
        _buildPasswordField(
          controller: _passwordController,
          hintText: GchText.userForgotNewPasswordHint,
          isVisible: state.isPasswordVisible,
          onToggleVisibility: () {
            ref.read(forgetPasswordNotifierProvider.notifier).togglePasswordVisibility();
          },
        ),

        SizedBox(height: 32.rh),

        // 重置按钮
        _buildResetButton(
          text: GchText.userForgotReset,
          onPressed: _handleResetPassword,
          isLoading: state.isLoading,
        ),
      ],
    );
  }

  /// 构建邮箱输入框
  Widget _buildEmailInputField() {
    return Container(
      height: 56.rh,
      decoration: BoxDecoration(
        color: _ForgetPasswordColors.inputBackground,
        borderRadius: BorderRadius.circular(28.ri),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: REdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              fontSize: 14.rf,
              color: _ForgetPasswordColors.primaryText,
            ),
            decoration: InputDecoration(
              hintText: GchText.userForgotEmailHint,
              hintStyle: TextStyle(
                fontSize: 14.rf,
                color: _ForgetPasswordColors.secondaryText,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeInputField({
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onSendCode,
    required int countdown,
    required bool isLoading,
  }) {
    final isEnabled = countdown == 0 && !isLoading;

    return Container(
      height: 56.rh,
      decoration: BoxDecoration(
        color: _ForgetPasswordColors.inputBackground,
        borderRadius: BorderRadius.circular(28.ri),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 16.rw),
          Icon(
            Icons.message_outlined,
            color: _ForgetPasswordColors.secondaryText,
            size: 20.ri,
          ),
          SizedBox(width: 12.rw),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 14.rf,
                color: _ForgetPasswordColors.primaryText,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  fontSize: 14.rf,
                  color: _ForgetPasswordColors.secondaryText,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Container(
            width: 90.rw,
            height: 36.rh,
            margin: REdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: isEnabled
                  ? const LinearGradient(
                      colors: [_ForgetPasswordColors.gradientStart, _ForgetPasswordColors.gradientEnd],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: isEnabled ? null : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18.ri),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isEnabled ? onSendCode : null,
                borderRadius: BorderRadius.circular(18.ri),
                child: Center(
                  child: Text(
                    countdown > 0 ? '${countdown}s' : GchText.userLoginGetCode,
                    style: TextStyle(
                      fontSize: 12.rf,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
  }) {
    return Container(
      height: 56.rh,
      decoration: BoxDecoration(
        color: _ForgetPasswordColors.inputBackground,
        borderRadius: BorderRadius.circular(28.ri),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 16.rw),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: !isVisible,
              style: TextStyle(
                fontSize: 14.rf,
                color: _ForgetPasswordColors.primaryText,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  fontSize: 14.rf,
                  color: _ForgetPasswordColors.secondaryText,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggleVisibility,
            child: Padding(
              padding: REdgeInsets.symmetric(horizontal: 16),
              child: Image.asset(
                'assets/gch_pics/gch_a71ab1.webp',
                width: 20.ri,
                height: 20.ri,
                color: isVisible
                    ? _ForgetPasswordColors.accentColor
                    : _ForgetPasswordColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton({
    required String text,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: 48.72.rh,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.5.rr),
          image: const DecorationImage(
            image: AssetImage('assets/gch_pics/gch_e2992f.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 24.ri,
                  height: 24.ri,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _ForgetPasswordColors.accentColor,
                    ),
                  ),
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: 16.rf,
                    fontWeight: FontWeight.w500,
                    color: _ForgetPasswordColors.accentColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }
}
