import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:guichao/gch_base/gch_signal/gch_signal_hub.dart';
import 'package:guichao/gch_base/gch_nav/gch_routes.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_captcha/gch_captcha.dart';
import 'package:guichao/gch_mod/gch_user/gch_reg/gch_model/gch_registration_state.dart';
import 'package:guichao/gch_mod/gch_user/gch_reg/gch_ctrl/gch_registration_notifier.dart';
import 'package:guichao/gch_mod/gch_user/gch_reg/gch_widget/gch_registration_input_fields.dart';
import 'package:guichao/gch_mod/gch_user/gch_reg/gch_widget/gch_registration_buttons.dart';
import 'package:guichao/gch_mod/gch_user/gch_reg/gch_widget/gch_registration_agreement_section.dart';
import 'package:guichao/gch_mod/gch_user/gch_reg/gch_widget/gch_social_login_section.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_base/gch_umeng/gch_umeng_svc.dart';
import 'package:url_launcher/url_launcher.dart';

/// 生产级注册页面
///
/// 功能特性：
/// - 完整的注册流程管理
/// - 严格的输入验证
/// - 智能错误处理和恢复
/// - 防重复提交保护
/// - 用户体验优化
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

enum _RegistrationPendingAction { send, resend }

class _RegisterPageState extends ConsumerState<RegisterPage> {
  // 输入控制器
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  // 协议区域的 GlobalKey，用于触发抖动
  final _agreementKey = GlobalKey<RegistrationAgreementSectionState>();

  // Captcha 流程状态
  _RegistrationPendingAction? _pendingAction;
  bool _captchaErrorShown = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();

    try {
      final notifier = ref.read(registrationNotifierProvider.notifier);
      notifier.reset();
    } catch (e) {
      // 忽略错误
    }

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _setupInputListeners();
  }

  /// 设置输入监听器
  void _setupInputListeners() {
    _emailController.addListener(() {
      final notifier = ref.read(registrationNotifierProvider.notifier);
      notifier.updateEmail(_emailController.text);
    });

    _phoneController.addListener(() {
      final notifier = ref.read(registrationNotifierProvider.notifier);
      notifier.updatePhone(_phoneController.text);
    });

    _codeController.addListener(() {
      final notifier = ref.read(registrationNotifierProvider.notifier);
      notifier.updateVerificationCode(_codeController.text);
    });

    _passwordController.addListener(() {
      final notifier = ref.read(registrationNotifierProvider.notifier);
      notifier.updatePassword(_passwordController.text);
    });
  }

  /// 处理注册类型切换
  void _onRegisterTypeSwitched(RegisterType type) {
    final notifier = ref.read(registrationNotifierProvider.notifier);
    notifier.switchRegisterType(type);
    setState(() {
      _pendingAction = null;
      _captchaErrorShown = false;
    });

    _emailController.clear();
    _phoneController.clear();
    _codeController.clear();
    _passwordController.clear();
  }

  Future<void> _startCaptchaFlow(_RegistrationPendingAction action) async {
    final notifier = ref.read(registrationNotifierProvider.notifier);
    _captchaErrorShown = false;

    final captcha = CaptchaFactory.instance;
    if (!captcha.isEnabled) {
      if (action == _RegistrationPendingAction.send) {
        await notifier.sendVerificationCode();
      } else {
        await notifier.resendVerificationCode();
      }
      if (mounted) {
        setState(() => _pendingAction = null);
      }
      _handleRegistrationFeedback();
      return;
    }

    setState(() {
      _pendingAction = action;
      _captchaErrorShown = false;
    });
    notifier.setTurnstileToken(null);

    if (!mounted) return;

    captcha.show(
      context,
      onSuccess: (result) async {
        await _handleCaptchaSuccess(result);
      },
      onExpired: () {
        notifier.setTurnstileToken(null);
        if (mounted) setState(() => _pendingAction = null);
      },
      onError: (error) {
        _handleCaptchaError(error);
        if (mounted) setState(() => _pendingAction = null);
      },
      onCancel: () {
        notifier.setTurnstileToken(null);
        if (mounted) setState(() => _pendingAction = null);
      },
    );
  }

  Future<void> _handleCaptchaSuccess(CaptchaResult result) async {
    final action = _pendingAction;
    if (action == null) return;

    final notifier = ref.read(registrationNotifierProvider.notifier);
    notifier.setTurnstileToken(result.token);

    if (action == _RegistrationPendingAction.send) {
      await notifier.sendVerificationCode();
    } else {
      await notifier.resendVerificationCode();
    }

    if (!mounted) return;

    setState(() {
      _pendingAction = null;
      _captchaErrorShown = false;
    });

    _handleRegistrationFeedback();
  }

  void _handleCaptchaError(CaptchaError error) {
    if (_captchaErrorShown) return;
    _captchaErrorShown = true;
    ref.read(registrationNotifierProvider.notifier).setTurnstileToken(null);

    Future.microtask(() {
      if (!mounted) return;

      String msg = GchText.serverErrorsCaptchaFailed;
      if (error.code == -1) {
        msg = error.message.contains('ERR_')
            ? GchText.serverErrorsNetworkError
            : GchText.serverErrorsRequestTimeout;
      }

      final notificationController = ref.read(gchSignalHubProvider);
      notificationController.flashError(msg, duration: const Duration(seconds: 4));
    });
  }

  /// 处理国家代码变更
  void _onCountryCodeChanged(String countryCode) {
    final notifier = ref.read(registrationNotifierProvider.notifier);
    notifier.updateCountryCode(countryCode);
  }

  /// 处理手机号验证状态变更
  void _onPhoneValidated(bool isValid) {
    final notifier = ref.read(registrationNotifierProvider.notifier);
    notifier.updatePhoneValidation(isValid);
  }

  /// 处理协议同意状态切换
  void _onTermsAgreementToggled() {
    final notifier = ref.read(registrationNotifierProvider.notifier);
    notifier.toggleTermsAgreement();
  }

  /// 打开服务条款页面
  void _openTermsOfService() {
    launchUrl(
      Uri.parse('https://example.com/terms.html'),
      mode: LaunchMode.inAppBrowserView,
    );
  }

  /// 打开隐私政策页面
  void _openPrivacyPolicy() {
    launchUrl(
      Uri.parse('https://example.com/privacyA.html'),
      mode: LaunchMode.inAppBrowserView,
    );
  }

  /// 校验协议勾选：未勾选时弹出统一 Toast 提示并返回 false
  bool _checkAgreement() {
    final state = ref.read(registrationNotifierProvider);
    if (!state.agreedToTerms) {
      ref.read(gchSignalHubProvider).flashInfo(GchText.userPayPleaseAgreeTerms);
      return false;
    }
    return true;
  }


  /// 处理发送验证码 - 不强制要求先勾选协议，协议校验放到最终注册提交时
  Future<void> _onSendVerificationCode() async {
    final state = ref.read(registrationNotifierProvider);

    if (!state.canSendCode) {
      _handleRegistrationFeedback();
      return;
    }

    await _startCaptchaFlow(_RegistrationPendingAction.send);
  }

  /// 处理重新发送验证码
  Future<void> _onResendVerificationCode() async {
    final state = ref.read(registrationNotifierProvider);
    if (!state.hasSignedUp || state.isCountingDown) {
      return;
    }
    await _startCaptchaFlow(_RegistrationPendingAction.resend);
  }

  /// 处理注册验证
  Future<void> _onVerifyAndRegister() async {
    GchUmengSvc.onRegisterTap();
    if (!_checkAgreement()) return;
    final notifier = ref.read(registrationNotifierProvider.notifier);
    final success = await notifier.verifyAndCompleteRegistration();

    if (success) {
      GchUmengSvc.onRegisterSuccess();
      _navigateToMainHome();
    } else {
      _handleRegistrationFeedback();
    }
  }

  /// 处理注册反馈
  void _handleRegistrationFeedback() {
    final state = ref.read(registrationNotifierProvider);
    final errorInfo = ref.read(registrationNotifierProvider.notifier).getErrorInfo();
    final notificationController = ref.read(gchSignalHubProvider);

    if (errorInfo != null) {
      if (errorInfo.canRetry) {
        notificationController.flashAction(
          '${errorInfo.title}: ${errorInfo.message}',
          actionText: GchText.userRegisterErrorsCommonRetry,
          callback: () {
            switch (state.phase) {
              case RegistrationPhase.initial:
                _onSendVerificationCode();
                break;
              case RegistrationPhase.codeSent:
                _onResendVerificationCode();
                break;
              case RegistrationPhase.verifying:
                _onVerifyAndRegister();
                break;
              default:
                break;
            }
          },
          duration: const Duration(seconds: 5),
        );
      } else {
        notificationController.flashError(
          '${errorInfo.title}: ${errorInfo.message}',
          duration: const Duration(seconds: 5),
        );
      }
    } else if (state.phase == RegistrationPhase.codeSent && !state.isLoading) {
      _showSuccessMessage(GchText.userRegisterCodeSent);
    }
  }

  /// 显示成功消息
  void _showSuccessMessage(String message) {
    final notificationController = ref.read(gchSignalHubProvider);
    notificationController.flashSuccess(message);
  }

  /// 导航到主页面
  void _navigateToMainHome() {
    const NavMainHomeRoute().go(context);
  }

  /// 返回登录页面（安全处理生命周期）
  void _navigateBackToLogin() {
    if (!mounted) return;

    final notifier = ref.read(registrationNotifierProvider.notifier);
    notifier.reset();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        const NavLoginRoute().go(context);
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && mounted) {
          _navigateBackToLogin();
        }
      },
      child: DefaultTextStyle(
        style: const TextStyle(decoration: TextDecoration.none),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/gch_pics/gch_e532f7.webp'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 22.5.rw),
                              child: Column(
                                children: [
                                  SizedBox(height: 8.12.rh),
                                  _buildLogo(),
                                  SizedBox(height: 24.36.rh),
                                  _buildRegistrationForm(),
                                  SizedBox(height: 24.36.rh),
                                  _buildDivider(),
                                  SizedBox(height: 12.18.rh),
                                  _buildSocialLoginSection(),
                                  SizedBox(height: 16.24.rh),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  /// 构建页面头部 - 返回按钮与 LoginPage 同款
  Widget _buildHeader() {
    return Container(
      height: 44.rh,
      padding: REdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _navigateBackToLogin,
        child: Padding(
          padding: REdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Icon(
            Icons.arrow_back_ios,
            color: Colors.grey,
            size: 18.ri,
          ),
        ),
      ),
    );
  }

  /// Logo 区域 - 自适应尺寸
  Widget _buildLogo() {
    return FractionallySizedBox(
      widthFactor: 0.3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.rr),
        child: Image.asset(
          'assets/gch_pics/gch_brand/gch_logo_bird.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// Tab 栏 - 左对齐文字 + 图片指示器风格（与 LoginPage 一致）
  Widget _buildTabBar(RegistrationState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildTab(GchText.userRegisterEmailRegister, RegisterType.email, state.registerType),
        SizedBox(width: 22.5.rw),
        _buildTab(GchText.userRegisterPhoneRegister, RegisterType.phone, state.registerType),
      ],
    );
  }

  /// 单个 Tab 项
  Widget _buildTab(String label, RegisterType type, RegisterType currentType) {
    final isActive = currentType == type;
    return GestureDetector(
      onTap: () => _onRegisterTypeSwitched(type),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16.rf,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? const Color(0xFF333333) : const Color(0xFF9A98AA),
            ),
          ),
          if (isActive)
            Image.asset(
              'assets/gch_pics/gch_113a26.webp',
              width: 37.5.rw,
              height: 5.684.rh,
              fit: BoxFit.contain,
            )
          else
            SizedBox(height: 5.684.rh),
        ],
      ),
    );
  }

  /// 其他登录方式分割线
  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 11.25.rw),
          child: Text(
            GchText.userLoginOtherLogin,
            style: TextStyle(color: Colors.grey[500], fontSize: 13.rf),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
      ],
    );
  }

  /// 构建注册表单
  Widget _buildRegistrationForm() {
    return Consumer(builder: (context, ref, child) {
      final state = ref.watch(registrationNotifierProvider);

      return Column(
        children: [
          _buildTabBar(state),
          SizedBox(height: 24.36.rh),

          RegistrationInputFields(
            state: state,
            emailController: _emailController,
            phoneController: _phoneController,
            codeController: _codeController,
            passwordController: _passwordController,
            obscurePassword: state.obscurePassword,
            onObscurePasswordToggled: () {
              ref.read(registrationNotifierProvider.notifier).togglePasswordVisibility();
            },
            onCountryCodeChanged: _onCountryCodeChanged,
            onPhoneValidated: _onPhoneValidated,
            onSendCode: _onSendVerificationCode,
            onResendCode: _onResendVerificationCode,
          ),
          SizedBox(height: 16.24.rh),

          RegistrationAgreementSection(
            key: _agreementKey,
            agreed: state.agreedToTerms,
            onToggle: _onTermsAgreementToggled,
            onUserAgreementTap: _openTermsOfService,
            onPrivacyPolicyTap: _openPrivacyPolicy,
          ),
          SizedBox(height: 32.48.rh),

          RegistrationButtons(
            state: state,
            onRegister: _onVerifyAndRegister,
          ),
        ],
      );
    });
  }


  /// 构建社交登录区域
  Widget _buildSocialLoginSection() {
    return SocialLoginSection(onCheckAgreement: _checkAgreement);
  }
}
