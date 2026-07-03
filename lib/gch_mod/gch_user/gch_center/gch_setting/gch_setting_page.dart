import 'package:flutter/material.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_base/gch_nav/gch_routes.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_providers/gch_auth_providers.dart';
import 'package:guichao/gch_base/gch_biz/gch_common/gch_enums.dart';
import 'package:guichao/gch_mod/gch_user/gch_center/gch_setting/gch_widget/gch_setting_gradient_button.dart';
import 'package:guichao/gch_mod/gch_user/gch_center/gch_setting/gch_widget/gch_setting_logout_dialog.dart';
import 'package:guichao/gch_mod/gch_user/gch_center/gch_setting/gch_widget/gch_setting_menu_list.dart';
import 'package:guichao/gch_mod/gch_user/gch_center/gch_setting/gch_widget/gch_setting_user_info_card.dart';
import 'package:guichao/gch_mod/gch_user/gch_center/gch_setting/gch_widget/gch_user_avatar_section.dart';
import 'package:guichao/gch_aux/gch_nav_ext.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 用户信息状态类型别名
typedef UserInfoState = ({
  bool isAuthenticated,
  String? email,
  String? phone,
  String gcSeq,
  VipType vipType,
  DateTime? expiredAt,
  String? authType,
  String? name,
  String? nickname,
});

/// 设置页面 - 参照设计稿 profile_guest/profile_logged_in.webp
///
/// 单列 + 版心约束 + 可滚动，横竖屏共用一套布局。
/// 通过 Center > ConstrainedBox(maxWidth) 保证版心居中对齐，
/// 横屏时内容不会铺满全屏，而是与竖屏保持一致的窄版心。
///
/// 业务逻辑完全不变，所有 Provider 监听、路由导航、对话框触发保持原样。
class SettingPage extends ConsumerStatefulWidget {
  const SettingPage({super.key});

  /// 版心最大宽度 — 始终基于短边，横竖屏一致
  static double get _maxContentWidth {
    final shortSide =
        WidgetsBinding.instance.platformDispatcher.views.first.physicalSize
            .shortestSide /
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    return shortSide;
  }

  @override
  ConsumerState<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<SettingPage> {
  @override
  void initState() {
    super.initState();
    // 每次进入个人中心刷新用户信息，拉取最新 VIP 状态与过期时间
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(userInfoProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userInfoAsync = ref.watch(userInfoProvider);

    return DefaultTextStyle(
      style: const TextStyle(decoration: TextDecoration.none),
      child: Container(
        color: const Color(0xffF1EFF9),
        child: SafeArea(
          child: userInfoAsync.when(
            data: (userInfo) => userInfo.isAuthenticated
                ? _SettingLoggedInView(userInfo: userInfo)
                : _SettingLoggedOutView(),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _SettingLoggedOutView(),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 已登录视图 — 简化线性布局，参照设计稿 profile_logged_in.webp
// ---------------------------------------------------------------------------

class _SettingLoggedInView extends ConsumerWidget {
  final UserInfoState userInfo;

  const _SettingLoggedInView({required this.userInfo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _SettingAppBar(),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: SettingPage._maxContentWidth,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // 用户头像区域
                    UserAvatarSection(
                      userId: userInfo.gcSeq,
                      email: userInfo.email,
                      phone: userInfo.phone,
                      isAuthenticated: true,
                      authType: userInfo.authType,
                      name: userInfo.name,
                      nickname: userInfo.nickname,
                      vipType: userInfo.vipType,
                      expiredAt: userInfo.expiredAt,
                    ),
                    SizedBox(height: 8.rh),
                    // VIP 信息行（简化为一行）
                    SettingUserInfoCard(
                      userInfo: userInfo,
                    ),
                    SizedBox(height: 20.rh),
                    // 菜单宫格区域
                    SettingMenuList(
                      isLoggedIn: true,
                      ref: ref,
                      userInfo: userInfo,
                    ),
                    // 退出登录按钮
                    Padding(
                      padding: REdgeInsets.only(
                          top: 30, left: 25, right: 25, bottom: 20),
                      child: SettingGradientButton(
                        text: GchText.userCenterLogout,
                        onTap: () {
                          SettingLogoutDialog.show(context, ref);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 未登录视图 — 简化线性布局，参照设计稿 profile_guest.webp
// ---------------------------------------------------------------------------

class _SettingLoggedOutView extends ConsumerWidget {
  const _SettingLoggedOutView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _SettingAppBar(),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: SettingPage._maxContentWidth,
              ),
              // 未登录态底部充满：LayoutBuilder + 最小高度约束 +
              // IntrinsicHeight + Spacer，让登录按钮始终贴底、中间被推满
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // 用户头像区域（未登录态）
                            UserAvatarSection(
                              userId: 'GC00000000',
                              isAuthenticated: false,
                              onTap: () =>
                                  const NavLoginRoute().go(context),
                            ),
                            SizedBox(height: 8.rh),
                            // VIP 推广行 — 钻石图标 + 紫色文字
                            Padding(
                              padding:
                                  REdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/gch_pics/gch_e9b27a.webp',
                                    width: 20.ri,
                                    height: 20.ri,
                                  ),
                                  SizedBox(width: 8.rw),
                                  Flexible(
                                    child: Text(
                                      GchText.userCenterUpgradeToEnjoy,
                                      style: TextStyle(
                                        fontSize: 14.rf,
                                        color: const Color(0xFF5969FF),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20.rh),
                            // 菜单宫格区域
                            SettingMenuList(
                              isLoggedIn: false,
                              ref: ref,
                            ),
                            // 弹性间距：把登录按钮推到底
                            const Spacer(),
                            // 登录按钮 —— 贴底显示
                            Padding(
                              padding: REdgeInsets.only(
                                left: 25,
                                right: 25,
                                bottom: 20,
                                top: 12,
                              ),
                              child: SettingGradientButton(
                                text: GchText.userCenterLogin,
                                onTap: () {
                                  const NavLoginRoute().go(context);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// AppBar — 不变
// ---------------------------------------------------------------------------

/// 设置页面顶部导航栏
class _SettingAppBar extends StatelessWidget {
  const _SettingAppBar();

  @override
  Widget build(BuildContext context) {
    final canGoBack = context.canSafelyPop();

    return SizedBox(
      height: 28.rh,
      child: Row(
        children: [
          if (canGoBack)
            IconButton(
              onPressed: () => context.safePop(),
              icon: Icon(
                Icons.arrow_back_ios,
                size: 20.ri,
                color: const Color(0xFF333333),
              ),
            )
          else
            SizedBox(width: 48.rw),
          // 顶部"我的"标题已按需求隐藏（保留左右占位维持对称布局）
          const Expanded(child: SizedBox.shrink()),
          SizedBox(width: 48.rw),
        ],
      ),
    );
  }
}
