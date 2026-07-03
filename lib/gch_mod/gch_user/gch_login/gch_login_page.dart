import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:guichao/gch_mod/gch_user/gch_shared/gch_international_phone_input.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:guichao/gch_base/gch_signal/gch_signal_hub.dart';
import 'package:guichao/gch_base/gch_nav/gch_routes.dart';
import 'package:guichao/gch_mod/gch_user/gch_login/gch_ctrl/gch_login_notifier.dart';
import 'package:guichao/gch_mod/gch_user/gch_login/gch_model/gch_login_state.dart';
import 'package:guichao/gch_mod/gch_user/gch_login/gch_widget/gch_otp_verification_widget.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_base/gch_umeng/gch_umeng_svc.dart';
import 'package:guichao/gch_mod/gch_deeplink/gch_ctrl/gch_deep_link_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 登录页面主题颜色
class _LoginColors {
  static const Color inputBackground = Color(0xFFF5F5F5);
  static const Color activeTabText = Color(0xFF333333);
  static const Color inactiveTabText = Color(0xFF9A98AA);
  static const Color registerTextColor = Color(0xFF6366F1);
  static const Color forgotPasswordColor = Color(0xFF5969FF);
  static const Color agreementLinkColor = Color(0xFF6366F1);
  static const Color hintColor = Color(0xFFAAAAAA);
  static const Color dividerColor = Color(0xFFE0E0E0);
  /// OAuth overlay — 与 MainHomePage 面板风格一致
  static const Color overlayBackdrop = Color(0x801A2332);
  static const Color overlayLinkColor = Color(0xFF8D9CFF);
}

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.redirectTo});
  final String? redirectTo;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // UI 控制器
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  TabController? _tabController;
  ProviderSubscription<String?>? _oAuthRedirectSub;
  late final AnimationController _overlayRotationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _overlayRotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _phoneController.addListener(_onPhoneChanged);
    _emailController.addListener(_onEmailChanged);
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(_onTabChanged);

    // 每次进入页面时重置登录状态（恢复默认手机模式）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loginNotifierProvider.notifier).resetState();
    });

    // 监听 OAuth 重定向
    _oAuthRedirectSub = ref.listenManual(oAuthRedirectNotifierProvider, (previous, next) {
      if (next != null && mounted) {
        _handleAuthRedirect(next);
      }
    });
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _phoneController.removeListener(_onPhoneChanged);
    _tabController?.removeListener(_onTabChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _oAuthRedirectSub?.close();
    _tabController?.dispose();
    _overlayRotationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App lifecycle resumed — no special handling needed
    }
  }

  // ============================================================
  // 事件处理 - 委托给 Notifier
  // ============================================================

  void _onTabChanged() {
    final notifier = ref.read(loginNotifierProvider.notifier);
    notifier.setLoginType(LoginType.values[_tabController!.index]);
  }

  void _onEmailChanged() {
    final notifier = ref.read(loginNotifierProvider.notifier);
    final result = notifier.validateEmail(_emailController.text);

    if (_emailController.text.isEmpty) {
      notifier.updateEmailValidation(false);
      return;
    }

    if (!result.isValid) {
      String? errorMsg;
      if (result.errorMessage == 'emailInvalid') {
        errorMsg = GchText.userLoginValidationEmailInvalid;
      } else if (result.errorMessage == 'emailDomainSuggestion' && result.suggestedDomain != null) {
        errorMsg = GchText.userLoginValidationEmailDomainSuggestion.replaceAll('{}', result.suggestedDomain!);
      }
      notifier.updateEmailValidation(false, errorMessage: errorMsg);
    } else {
      notifier.updateEmailValidation(true);
    }
  }

  void _onPhoneChanged() {
    final notifier = ref.read(loginNotifierProvider.notifier);
    final filtered = notifier.filterPhoneDigits(_phoneController.text);

    if (filtered != _phoneController.text) {
      _phoneController.value = TextEditingValue(
        text: filtered,
        selection: TextSelection.collapsed(offset: filtered.length),
      );
      return;
    }

    notifier.clearError();
  }

  void _handleAuthRedirect(String redirectPath) {
    _showSuccessMessage(GchText.userLoginSuccessLoginSuccess);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _navigateAfterLogin(redirectPath);
    });
  }

  // ============================================================
  // 登录处理
  // ============================================================

  /// 校验协议勾选：未勾选时弹出统一 Toast 提示并返回 false
  bool _checkAgreement() {
    final state = ref.read(loginNotifierProvider);
    if (!state.isAgreementChecked) {
      ref.read(gchSignalHubProvider).flashInfo(GchText.userPayPleaseAgreeTerms);
      return false;
    }
    return true;
  }

  Future<void> _handleLogin() async {
    GchUmengSvc.onLoginTap();
    // 点击登录按钮先收起键盘
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_checkAgreement()) return;
    final notifier = ref.read(loginNotifierProvider.notifier);
    final state = ref.read(loginNotifierProvider);

    LoginResult result;

    if (state.currentType == LoginType.account) {
      result = await notifier.loginWithPassword(
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      result = await notifier.loginWithOtp(
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
      );
    }

    if (!mounted) return;

    if (result.success) {
      GchUmengSvc.onLogin('', provider: 'password');
      _navigateAfterLogin(result.redirectPath);
    } else if (result.errorMessage != null) {
      _showErrorMessage(result.errorMessage!);
    }
  }

  Future<void> _handleAppleLogin() async {
    if (!_checkAgreement()) return;
    final notifier = ref.read(loginNotifierProvider.notifier);

    final result = await notifier.loginWithApple();

    if (!mounted) return;

    if (result.success) {
      GchUmengSvc.onLogin('', provider: 'apple');
      _showSuccessMessage(GchText.userLoginSuccessAppleLoginSuccess);
      _navigateAfterLogin(null);
    } else if (result.errorMessage != null) {
      _showErrorMessage(result.errorMessage!);
    }
  }

  // ============================================================
  // 导航和消息
  // ============================================================

  void _navigateAfterLogin(String? redirectPath) {
    final targetPath = widget.redirectTo ?? redirectPath;
    if (targetPath != null && targetPath.isNotEmpty) {
      context.go(targetPath);
    } else {
      const NavMainHomeRoute().go(context);
    }
  }

  void _handleBackNavigation() {
    // 使用 GoRouter 的 canPop/pop 方法，而不是 Navigator
    if (context.canPop()) {
      context.pop();
    } else {
      const NavMainHomeRoute().go(context);
    }
  }

  void _showErrorMessage(String message) {
    final notificationController = ref.read(gchSignalHubProvider);
    notificationController.flashError(message, duration: const Duration(seconds: 3));
  }

  void _showSuccessMessage(String message) {
    final notificationController = ref.read(gchSignalHubProvider);
    notificationController.flashSuccess(message);
  }

  void _openTermsOfService() {
    launchUrl(
      Uri.parse('https://example.com/terms.html'),
      mode: LaunchMode.inAppBrowserView,
    );
  }

  void _openPrivacyPolicy() {
    launchUrl(
      Uri.parse('https://example.com/privacyA.html'),
      mode: LaunchMode.inAppBrowserView,
    );
  }

  /// 账号登录切换手机/邮箱
  void _togglePhoneEmailForAccount() {
    final notifier = ref.read(loginNotifierProvider.notifier);
    notifier.togglePhoneEmailForAccount();

    // 清空账号登录相关输入框
    _emailController.clear();
    _phoneController.clear();
    _passwordController.clear();
  }

  /// 验证码登录切换手机/邮箱（独立于账号登录）
  void _togglePhoneEmailForCode() {
    final notifier = ref.read(loginNotifierProvider.notifier);
    notifier.togglePhoneEmailForCode();

    // 清空验证码登录相关输入框
    _emailController.clear();
    _phoneController.clear();
    _codeController.clear();
  }

  /// 切换手机/邮箱按钮（输入框内部右侧，使用图片背景）
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

  // ============================================================
  // UI 构建
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginNotifierProvider);
    _updateOverlayAnimation(loginState.isOauthSigningIn);

    return DefaultTextStyle(
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
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: _buildBody(loginState),
                    ),
                  ],
                ),
                if (loginState.isOauthSigningIn)
                  _buildOauthSignInOverlay(loginState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 44.rh,
      padding: REdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleBackNavigation,
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

  Widget _buildBody(LoginState loginState) {
    final showApple = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: REdgeInsets.symmetric(horizontal: 22.5),
                child: Column(
                  children: [
                    SizedBox(height: 8.12.rh),
                    _buildLogo(),
                    SizedBox(height: 16.24.rh),
                    _buildTabBar(loginState),
                    SizedBox(height: 16.24.rh),
                    _buildLoginForm(loginState),
                    SizedBox(height: 8.12.rh),
                    _buildForgotPassword(),
                    SizedBox(height: 16.24.rh),
                    _buildLoginButton(),
                    SizedBox(height: 12.18.rh),
                    _buildRegisterButton(),
                    SizedBox(height: 20.rh),
                    _buildAgreementRow(loginState),
                    SizedBox(height: 24.rh),
                    _buildDivider(),
                    SizedBox(height: 24.rh),
                    _buildSocialLoginSection(loginState, showApple),
                    SizedBox(height: 24.rh + MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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

  /// Tab 栏 - 左对齐文字 + 图片指示器风格
  Widget _buildTabBar(LoginState loginState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildTab(GchText.userLoginAccountLogin, 0),
        SizedBox(width: 22.5.rw),
        _buildTab(GchText.userLoginCodeLogin, 1),
      ],
    );
  }

  /// 单个 Tab 项
  Widget _buildTab(String label, int index) {
    final isActive = _tabController?.index == index;
    return GestureDetector(
      onTap: () {
        _tabController?.animateTo(index);
      },
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16.rf,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? _LoginColors.activeTabText : _LoginColors.inactiveTabText,
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

  Widget _buildLoginForm(LoginState loginState) {
    switch (loginState.currentType) {
      case LoginType.account:
        return _buildAccountLoginForm(loginState);
      case LoginType.code:
        return OtpVerificationWidget(
          useEmail: loginState.useEmailForCode,
          selectedCountryCode: loginState.selectedCountryCode,
          phoneController: _phoneController,
          emailController: _emailController,
          codeController: _codeController,
          onCountryCodeChanged: (String countryCode) {
            ref.read(loginNotifierProvider.notifier).updateCountryCode(countryCode);
          },
          // 获取验证码不强制勾选协议，协议校验只保留在最终登录提交时
          ensureAgreementChecked: () => true,
          onPhoneValidated: (bool isValid) {
            ref.read(loginNotifierProvider.notifier).updatePhoneValidation(isValid);
          },
          onEmailValidated: (bool isValid) {
            ref.read(loginNotifierProvider.notifier).updateEmailValidation(isValid);
          },
          onTogglePhoneEmail: _togglePhoneEmailForCode,
          initialPhoneValid: loginState.isPhoneValid,
          initialEmailValid: loginState.isEmailValid,
        );
    }
  }

  Widget _buildAccountLoginForm(LoginState loginState) {
    return Column(
      children: [
        // 手机号/邮箱输入框（内置切换按钮）
        if (loginState.usePhoneForAccount) ...[
          Container(
            height: 48.72.rh,
            decoration: BoxDecoration(
              color: _LoginColors.inputBackground,
              borderRadius: BorderRadius.circular(22.5.rr),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InternationalPhoneInput(
                    textController: _phoneController,
                    initialCountryCode: 'CN',
                    hintText: GchText.userLoginPhoneHint,
                    height: 48.72.rh,
                    borderRadius: 22.5.rr,
                    backgroundColor: Colors.transparent,
                    autoValidateMode: AutovalidateMode.disabled,
                    errorMessage: GchText.userLoginValidationPhoneInvalid,
                    textColor: const Color(0xFF333333),
                    hintColor: _LoginColors.hintColor,
                    onInputChanged: (PhoneNumberData number) {
                      ref.read(loginNotifierProvider.notifier).updatePhoneNumber(number);
                    },
                    onInputValidated: (bool isValid) {
                      ref.read(loginNotifierProvider.notifier).updatePhoneValidation(isValid);
                    },
                  ),
                ),
                _buildInlineSwitchButton(
                  text: GchText.userLoginSwitchToEmail,
                  onTap: _togglePhoneEmailForAccount,
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            height: 48.72.rh,
            decoration: BoxDecoration(
              color: _LoginColors.inputBackground,
              borderRadius: BorderRadius.circular(22.5.rr),
            ),
            child: Row(
              children: [
                SizedBox(width: 15.rw),
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(fontSize: 15.rf, color: const Color(0xFF333333)),
                    decoration: InputDecoration(
                      hintText: GchText.userLoginEmailHint,
                      hintStyle: TextStyle(fontSize: 15.rf, color: _LoginColors.hintColor),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                _buildInlineSwitchButton(
                  text: GchText.userLoginSwitchToPhone,
                  onTap: _togglePhoneEmailForAccount,
                ),
              ],
            ),
          ),
        ],

        SizedBox(height: 16.24.rh),

        // 密码输入框（带锁图标）
        Container(
          height: 48.72.rh,
          decoration: BoxDecoration(
            color: _LoginColors.inputBackground,
            borderRadius: BorderRadius.circular(22.5.rr),
          ),
          child: Row(
            children: [
              SizedBox(width: 15.rw),
              Image.asset(
                'assets/gch_pics/gch_156fdd.webp',
                width: 18.rf,
                height: 18.rf,
              ),
              SizedBox(width: 7.5.rw),
              Expanded(
                child: TextField(
                  controller: _passwordController,
                  obscureText: loginState.obscurePassword,
                  style: TextStyle(fontSize: 15.rf, color: const Color(0xFF333333)),
                  decoration: InputDecoration(
                    hintText: GchText.userLoginPasswordHint,
                    hintStyle: TextStyle(fontSize: 15.rf, color: _LoginColors.hintColor),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              IconButton(
                icon: Image.asset(
                  'assets/gch_pics/gch_1dfc95.webp',
                  width: 18.rf,
                  height: 18.rf,
                ),
                onPressed: () {
                  ref.read(loginNotifierProvider.notifier).togglePasswordVisibility();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 忘记密码 - 独立一行右对齐
  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => const ForgetPasswordRoute().go(context),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          GchText.userLoginForgotPassword,
          style: TextStyle(fontSize: 13.rf, color: _LoginColors.forgotPasswordColor),
        ),
      ),
    );
  }

  /// 登录按钮 - 与"我的"页 SettingGradientButton 同款背景
  Widget _buildLoginButton() {
    final loginState = ref.watch(loginNotifierProvider);

    return GestureDetector(
      onTap: loginState.isLoading ? null : _handleLogin,
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
          child: loginState.isLoading
              ? SizedBox(
                  width: 18.rf,
                  height: 18.rf,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5969FF)),
                  ),
                )
              : Text(
                  GchText.userLoginLoginBtn,
                  style: TextStyle(
                    fontSize: 16.rf,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5969FF),
                  ),
                ),
        ),
      ),
    );
  }

  /// 注册按钮 - 图片背景
  Widget _buildRegisterButton() {
    return GestureDetector(
      onTap: () => const NavRegisterRoute().go(context),
      child: Container(
        width: double.infinity,
        height: 48.72.rh,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.5.rr),
          image: const DecorationImage(
            image: AssetImage('assets/gch_pics/gch_954b5f.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Text(
            GchText.userLoginRegisterBtn,
            style: TextStyle(
              fontSize: 16.rf,
              fontWeight: FontWeight.w400,
              color: _LoginColors.registerTextColor,
            ),
          ),
        ),
      ),
    );
  }

  /// 协议复选框 - 居中独立行
  Widget _buildAgreementRow(LoginState loginState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 扩大可点击区域至 36rf，但图片素材保持 15rf 不变
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            ref.read(loginNotifierProvider.notifier).toggleAgreement();
          },
          child: SizedBox(
            width: 36.rf,
            height: 36.rf,
            child: Center(
              child: loginState.isAgreementChecked
                  ? Image.asset(
                      'assets/gch_pics/gch_ede35d.webp',
                      width: 15.rf,
                      height: 15.rf,
                    )
                  : Container(
                      width: 15.rf,
                      height: 15.rf,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey[400]!,
                          width: 1.5,
                        ),
                      ),
                    ),
            ),
          ),
        ),

        Flexible(
          child: GestureDetector(
            onTap: () {
              ref.read(loginNotifierProvider.notifier).toggleAgreement();
            },
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14.rf, color: Colors.grey),
                children: [
                  TextSpan(text: GchText.userLoginAgreePrefix),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: _openTermsOfService,
                      child: Text(
                        GchText.userLoginTerms,
                        style: TextStyle(fontSize: 14.rf, color: _LoginColors.agreementLinkColor),
                      ),
                    ),
                  ),
                  TextSpan(text: GchText.userCommonAnd),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: _openPrivacyPolicy,
                      child: Text(
                        GchText.userLoginPrivacy,
                        style: TextStyle(fontSize: 14.rf, color: _LoginColors.agreementLinkColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 其他登录方式分割线
  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: _LoginColors.dividerColor)),
        Padding(
          padding: REdgeInsets.symmetric(horizontal: 11.25),
          child: Text(
            GchText.userLoginOtherLogin,
            style: TextStyle(color: Colors.grey[500], fontSize: 13.rf),
          ),
        ),
        const Expanded(child: Divider(color: _LoginColors.dividerColor)),
      ],
    );
  }

  /// 第三方登录区域
  Widget _buildSocialLoginSection(LoginState loginState, bool showApple) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showApple)
          _buildSocialLoginButton(
            'assets/gch_pics/gch_d6bd89.webp',
            _handleAppleLogin,
            isDisabled: loginState.isOauthSigningIn,
          ),
      ],
    );
  }

  /// 单个社交登录按钮 - 圆形白色背景 + 阴影
  Widget _buildSocialLoginButton(
    String imagePath,
    VoidCallback onTap, {
    bool isDisabled = false,
  }) {
    final bool disableTap = isDisabled;
    return GestureDetector(
      onTap: disableTap ? null : onTap,
      child: Opacity(
        opacity: disableTap ? 0.4 : 1,
        child: Container(
          width: 50.rw,
          height: 50.rh,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10.rh,
                offset: Offset(0, 3.rh),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              imagePath,
              width: 36.rw,
              height: 36.rh,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOauthSignInOverlay(LoginState loginState) {
    return Positioned.fill(
      child: Container(
        color: _LoginColors.overlayBackdrop,
        child: Center(
          child: Container(
            margin: REdgeInsets.symmetric(horizontal: 45),
            padding: REdgeInsets.symmetric(horizontal: 30, vertical: 28.42),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x338D9CFF),
                  Color(0x33A29BFE),
                ],
              ),
              borderRadius: BorderRadius.circular(18.75.rr),
              border: Border.all(
                color: const Color(0xB3FFFFFF),
                width: 0.8,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 8,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 41.25.rw,
                  height: 41.25.rw,
                  child: RotationTransition(
                    turns: _overlayRotationController,
                    child: Icon(
                      Icons.autorenew_rounded,
                      size: 28.ri,
                      color: _LoginColors.overlayLinkColor,
                    ),
                  ),
                ),
                SizedBox(height: 20.3.rh),
                Text(
                  loginState.oauthSignInStatusMessage.isNotEmpty
                      ? loginState.oauthSignInStatusMessage
                      : GchText.userLoginLoggingIn,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xE6FFFFFF),
                    fontSize: 11.rf,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateOverlayAnimation(bool shouldAnimate) {
    if (shouldAnimate) {
      if (!_overlayRotationController.isAnimating) {
        _overlayRotationController.repeat();
      }
    } else {
      if (_overlayRotationController.isAnimating) {
        _overlayRotationController.stop();
      }
      _overlayRotationController.reset();
    }
  }
}
