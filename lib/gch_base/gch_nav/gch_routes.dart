import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guichao/gch_base/gch_nav/gch_nav_engine.dart';
import 'package:guichao/gch_base/gch_biz/gch_user/gch_view/gch_user_view.dart';
import 'package:guichao/gch_mod/gch_shared/gch_adaptive_root_scaffold.dart';
import 'package:guichao/gch_mod/gch_log/gch_browse/gch_logs_overview_page.dart';
import 'package:guichao/gch_mod/gch_user/gch_shared/gch_nav_shell_scaffold.dart';
import 'package:guichao/gch_mod/gch_user/gch_resetpw/gch_forget_password_page.dart';
import 'package:guichao/gch_mod/gch_user/gch_login/gch_login_page.dart';
import 'package:guichao/gch_mod/gch_user/gch_order/gch_order_list_page.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_checkout_list_page.dart';
import 'package:guichao/gch_mod/gch_user/gch_reg/gch_register_page.dart';
import 'package:guichao/gch_mod/gch_tool/gch_speedtest/gch_speedtest_page.dart';
import 'package:guichao/gch_mod/gch_user/gch_center/gch_profile/gch_profile_page.dart'
    as user_center;
import 'package:guichao/gch_mod/gch_user/gch_center/gch_setting/gch_about_us_page.dart';
import 'package:guichao/gch_mod/gch_user/gch_chat/gch_support_page.dart';
import 'package:guichao/gch_mod/gch_user/gch_center/gch_setting/gch_delete_account_page.dart';
import 'package:guichao/gch_mod/gch_user/gch_center/gch_setting/gch_password_change_page.dart';
import 'package:guichao/gch_mod/gch_user/gch_center/gch_setting/gch_pprof_debug_page.dart';
import 'package:guichao/gch_mod/gch_user/gch_center/gch_setting/gch_setting_page.dart';
import 'package:guichao/gch_mod/gch_tool/gch_tool_page.dart';
import 'package:guichao/gch_mod/gch_tool/gch_holiday/gch_holiday_page.dart';
import 'package:guichao/gch_mod/gch_tool/gch_worldclock/gch_worldclock_page.dart';
import 'package:guichao/gch_mod/gch_tool/gch_currency/gch_currency_page.dart';
import 'package:guichao/gch_mod/gch_tool/gch_emergency/gch_emergency_page.dart';

part 'gch_routes.g.dart';

// ===== 底部导航 Shell 路由 =====
// 各分支的 Navigator Key
final _purchaseBranchKey = GlobalKey<NavigatorState>(debugLabel: 'purchaseBranch');
final _accelerationBranchKey = GlobalKey<NavigatorState>(debugLabel: 'accelerationBranch');
final _toolBranchKey = GlobalKey<NavigatorState>(debugLabel: 'toolBranch');
final _moreBranchKey = GlobalKey<NavigatorState>(debugLabel: 'moreBranch');

/// 用户模块底部导航 Shell 路由
///
/// 三个分支：购买、加速、更多
/// 导航条只创建一次，切换时不重建
@TypedStatefulShellRoute<UserNavShellRoute>(
  branches: [
    // Branch 0: 购买
    TypedStatefulShellBranch<PurchaseBranch>(
      routes: [
        TypedGoRoute<NavCheckoutRoute>(
          path: '/nav/checkout',
          name: NavCheckoutRoute.name,
        ),
      ],
    ),
    // Branch 1: 加速
    TypedStatefulShellBranch<AccelerationBranch>(
      routes: [
        TypedGoRoute<NavMainHomeRoute>(
          path: '/nav/home',
          name: NavMainHomeRoute.name,
        ),
        TypedGoRoute<NavLoginRoute>(
          path: '/nav/login',
          name: NavLoginRoute.name,
        ),
        TypedGoRoute<NavRegisterRoute>(
          path: '/nav/register',
          name: NavRegisterRoute.name,
        ),
        TypedGoRoute<NavForgetPasswordRoute>(
          path: '/nav/forget-password',
          name: NavForgetPasswordRoute.name,
        ),
      ],
    ),
    // Branch 2: 工具
    TypedStatefulShellBranch<ToolBranch>(
      routes: [
        TypedGoRoute<NavToolRoute>(
          path: '/nav/tool',
          name: NavToolRoute.name,
          routes: [
            TypedGoRoute<NavHolidayRoute>(
              path: 'holiday',
              name: NavHolidayRoute.name,
            ),
            TypedGoRoute<NavWorldClockRoute>(
              path: 'worldclock',
              name: NavWorldClockRoute.name,
            ),
            TypedGoRoute<NavCurrencyRoute>(
              path: 'currency',
              name: NavCurrencyRoute.name,
            ),
            TypedGoRoute<NavEmergencyRoute>(
              path: 'emergency',
              name: NavEmergencyRoute.name,
            ),
          ],
        ),
      ],
    ),
    // Branch 3: 更多
    TypedStatefulShellBranch<MoreBranch>(
      routes: [
        TypedGoRoute<NavSettingRoute>(
          path: '/nav/setting',
          name: NavSettingRoute.name,
          routes: [
            TypedGoRoute<NavOrderListRoute>(
              path: 'orders',
              name: NavOrderListRoute.name,
            ),
            TypedGoRoute<NavProfileRoute>(
              path: 'profile',
              name: NavProfileRoute.name,
            ),
            TypedGoRoute<NavPasswordChangeRoute>(
              path: 'password-change',
              name: NavPasswordChangeRoute.name,
            ),
            TypedGoRoute<NavAboutUsRoute>(
              path: 'about-us',
              name: NavAboutUsRoute.name,
            ),
            TypedGoRoute<NavSupportRoute>(
              path: 'support',
              name: NavSupportRoute.name,
            ),
            TypedGoRoute<NavDeleteAccountRoute>(
              path: 'delete-account',
              name: NavDeleteAccountRoute.name,
            ),
          ],
        ),
      ],
    ),
  ],
)
class UserNavShellRoute extends StatefulShellRouteData {
  const UserNavShellRoute();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return NavShellScaffold(navigationShell: navigationShell);
  }
}

// 分支定义
class PurchaseBranch extends StatefulShellBranchData {
  const PurchaseBranch();
  static final GlobalKey<NavigatorState> $navigatorKey = _purchaseBranchKey;
}

class AccelerationBranch extends StatefulShellBranchData {
  const AccelerationBranch();
  static final GlobalKey<NavigatorState> $navigatorKey = _accelerationBranchKey;
}

class ToolBranch extends StatefulShellBranchData {
  const ToolBranch();
  static final GlobalKey<NavigatorState> $navigatorKey = _toolBranchKey;
}

class MoreBranch extends StatefulShellBranchData {
  const MoreBranch();
  static final GlobalKey<NavigatorState> $navigatorKey = _moreBranchKey;
}

// ===== Shell 内的路由实现 =====

// -- 工具分支 --
class NavToolRoute extends GoRouteData {
  const NavToolRoute();
  static const name = 'NavTool';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const NoTransitionPage(name: name, child: ToolPage());
  }
}

class NavHolidayRoute extends GoRouteData {
  const NavHolidayRoute();
  static const name = 'NavHoliday';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(name: name, child: HolidayPage());
  }
}

class NavWorldClockRoute extends GoRouteData {
  const NavWorldClockRoute();
  static const name = 'NavWorldClock';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(name: name, child: GchWorldClockPage());
  }
}

class NavCurrencyRoute extends GoRouteData {
  const NavCurrencyRoute();
  static const name = 'NavCurrency';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(name: name, child: GchCurrencyPage());
  }
}

class NavEmergencyRoute extends GoRouteData {
  const NavEmergencyRoute();
  static const name = 'NavEmergency';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(name: name, child: GchEmergencyPage());
  }
}

// -- 购买分支 --
class NavCheckoutRoute extends GoRouteData {
  const NavCheckoutRoute();
  static const name = 'NavCheckout';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const NoTransitionPage(name: name, child: CheckoutPage());
  }
}

// -- 加速分支 --
class NavMainHomeRoute extends GoRouteData {
  const NavMainHomeRoute();
  static const name = 'NavMainHome';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const NoTransitionPage(name: name, child: SpeedTestPage());
  }
}

class NavLoginRoute extends GoRouteData {
  const NavLoginRoute();
  static const name = 'NavLogin';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(name: name, child: LoginPage());
  }
}

class NavRegisterRoute extends GoRouteData {
  const NavRegisterRoute();
  static const name = 'NavRegister';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(name: name, child: RegisterPage());
  }
}

class NavForgetPasswordRoute extends GoRouteData {
  const NavForgetPasswordRoute();
  static const name = 'NavForgetPassword';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(name: name, child: ForgetPasswordPage());
  }
}

// -- 更多分支 --
class NavSettingRoute extends GoRouteData {
  const NavSettingRoute();
  static const name = 'NavSetting';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const NoTransitionPage(name: name, child: SettingPage());
  }
}

class NavOrderListRoute extends GoRouteData {
  const NavOrderListRoute();
  static const name = 'NavOrderList';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(name: name, child: OrderListPage());
  }
}

class NavProfileRoute extends GoRouteData {
  const NavProfileRoute();
  static const name = 'NavProfile';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(name: name, child: user_center.ProfilePage());
  }
}

class NavPasswordChangeRoute extends GoRouteData {
  const NavPasswordChangeRoute();
  static const name = 'NavPasswordChange';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(name: name, child: PasswordChangePage());
  }
}

class NavAboutUsRoute extends GoRouteData {
  const NavAboutUsRoute();
  static const name = 'NavAboutUs';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(name: name, child: AboutUsPage());
  }
}

class NavSupportRoute extends GoRouteData {
  const NavSupportRoute();
  static const name = 'NavSupport';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(name: name, child: SupportPage());
  }
}

class NavDeleteAccountRoute extends GoRouteData {
  const NavDeleteAccountRoute();
  static const name = 'NavDeleteAccount';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(name: name, child: DeleteAccountPage());
  }
}

/// 淡入淡出页面过渡（用于底部导航切换）
class FadeTransitionPage<T> extends CustomTransitionPage<T> {
  const FadeTransitionPage({
    required super.child,
    super.name,
    super.key,
  }) : super(
          transitionDuration: const Duration(milliseconds: 200),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: _fadeTransitionBuilder,
        );

  static Widget _fadeTransitionBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}

final GlobalKey<NavigatorState>? _dynamicRootKey = gchRootNavKey;
// ===== 手机端路由结构 =====
@TypedShellRoute<MobileWrapperRoute>(
  routes: [
    TypedGoRoute<HomeRoute>(
      path: "/",
      name: HomeRoute.name,
      routes: [
        TypedGoRoute<LogsOverviewRoute>(
          path: "logs",
          name: LogsOverviewRoute.name,
        ),
        TypedGoRoute<AboutRoute>(
          path: "about",
          name: AboutRoute.name,
        ),
      ],
    ),
    TypedGoRoute<ProxiesRoute>(
      path: "/proxies",
      name: ProxiesRoute.name,
    ),
  ],
)
class MobileWrapperRoute extends ShellRouteData {
  const MobileWrapperRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) {
    return AdaptiveRootScaffold(navigator);
  }
}


// ===== 独立全屏路由 =====
@TypedGoRoute<LoginRoute>(path: "/login", name: LoginRoute.name)
class LoginRoute extends GoRouteData {
  const LoginRoute({this.redirectTo});
  final String? redirectTo;
  static const name = "Login";

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return MaterialPage(
      fullscreenDialog: true,
      name: name,
      child: LoginPage(redirectTo: redirectTo),
    );
  }
}

@TypedGoRoute<RegisterRoute>(path: "/register", name: RegisterRoute.name)
class RegisterRoute extends GoRouteData {
  const RegisterRoute();
  static const name = "Register";

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(
      fullscreenDialog: true,
      name: name,
      child: RegisterPage(),
    );
  }
}

@TypedGoRoute<ForgetPasswordRoute>(path: "/forget-password", name: ForgetPasswordRoute.name)
class ForgetPasswordRoute extends GoRouteData {
  const ForgetPasswordRoute();
  static const name = "ForgetPassword";

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(
      fullscreenDialog: true,
      name: name,
      child: ForgetPasswordPage(),
    );
  }
}

@TypedGoRoute<PprofDebugRoute>(path: "/pprof-debug", name: PprofDebugRoute.name)
class PprofDebugRoute extends GoRouteData {
  const PprofDebugRoute();
  static const name = "PprofDebug";

  static final GlobalKey<NavigatorState>? $parentNavigatorKey = _dynamicRootKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(
      fullscreenDialog: true,
      name: name,
      child: PprofDebugPage(),
    );
  }
}

@TypedGoRoute<ProfileRoute>(path: "/profile", name: ProfileRoute.name)
class ProfileRoute extends GoRouteData {
  const ProfileRoute();
  static const name = "profile";

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(
      fullscreenDialog: true,
      name: name,
      child: SpeedTestPage(),
    );
  }
}

@TypedGoRoute<UserProfileRoute>(path: "/userprofile", name: UserProfileRoute.name)
class UserProfileRoute extends GoRouteData {
  const UserProfileRoute();
  static const name = "userprofile";

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(
      fullscreenDialog: true,
      name: name,
      child: user_center.ProfilePage(),
    );
  }
}

@TypedGoRoute<MainHomeRoute>(path: "/mainhome", name: MainHomeRoute.name)
class MainHomeRoute extends GoRouteData {
  const MainHomeRoute();
  static const name = "MainHome";

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    // 底部导航页面使用淡入淡出切换
    return const FadeTransitionPage(
      name: name,
      child: SpeedTestPage(),
    );
  }
}


@TypedGoRoute<UserPageRoute>(path: "/user", name: UserPageRoute.name)
class UserPageRoute extends GoRouteData {
  const UserPageRoute();
  static const name = "UserPage";
  
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(
      fullscreenDialog: true,
      name: name,
      child: UserView(),
    );
  }
}

@TypedGoRoute<CheckoutRoute>(path: "/checkout", name: CheckoutRoute.name)
class CheckoutRoute extends GoRouteData {
  const CheckoutRoute();
  static const name = "Checkout";

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    // 底部导航页面使用淡入淡出切换
    return const FadeTransitionPage(
      name: name,
      child: CheckoutPage(),
    );
  }
}

@TypedGoRoute<OrderListRoute>(path: "/orders", name: OrderListRoute.name)
class OrderListRoute extends GoRouteData {
  const OrderListRoute();
  static const name = "OrderList";

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(
      fullscreenDialog: true,
      name: name,
      child: OrderListPage(),
    );
  }
}

@TypedGoRoute<UserSettingRoute>(path: "/user/setting", name: UserSettingRoute.name)
class UserSettingRoute extends GoRouteData {
  const UserSettingRoute();
  static const name = "UserSetting";

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    // 底部导航页面使用淡入淡出切换
    return const FadeTransitionPage(
      name: name,
      child: SettingPage(),
    );
  }
}

@TypedGoRoute<PasswordChangeRoute>(path: "/user/password-change", name: PasswordChangeRoute.name)
class PasswordChangeRoute extends GoRouteData {
  const PasswordChangeRoute();
  static const name = "PasswordChange";

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(
      fullscreenDialog: true,
      name: name,
      child: PasswordChangePage(),
    );
  }
}

@TypedGoRoute<AboutUsRoute>(path: "/user/about-us", name: AboutUsRoute.name)
class AboutUsRoute extends GoRouteData {
  const AboutUsRoute();
  static const name = "AboutUs";

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(
      fullscreenDialog: true,
      name: name,
      child: AboutUsPage(),
    );
  }
}

@TypedGoRoute<DeleteAccountRoute>(path: "/user/delete-account", name: DeleteAccountRoute.name)
class DeleteAccountRoute extends GoRouteData {
  const DeleteAccountRoute();
  static const name = "DeleteAccount";

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(
      fullscreenDialog: true,
      name: name,
      child: DeleteAccountPage(),
    );
  }
}

// ===== 共享页面路由实现 =====
class HomeRoute extends GoRouteData {
  const HomeRoute();
  static const name = "Home";

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    // 底部导航页面使用淡入淡出切换
    return const FadeTransitionPage(
      name: name,
      child: SpeedTestPage(),
    );
  }
}

class ProxiesRoute extends GoRouteData {
  const ProxiesRoute();
  static const name = "Proxies";

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    // TODO: ProxiesOverviewPage 已删除，使用 ProxyNodePage 替代
    return const NoTransitionPage(
      name: name,
      child: SpeedTestPage(),
    );
  }
}


class ProfileDetailsRoute extends GoRouteData {
  const ProfileDetailsRoute(this.id);
  final String id;
  static const name = "Profile Details";

  static final GlobalKey<NavigatorState> $parentNavigatorKey = gchRootNavKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    // TODO: ProfileDetailsPage 已删除，暂时使用 ProfilePage 替代
    return const MaterialPage(
      fullscreenDialog: true,
      name: name,
      child: user_center.ProfilePage(),
    );
  }
}

class LogsOverviewRoute extends GoRouteData {
  const LogsOverviewRoute();
  static const name = "Logs";

  static final GlobalKey<NavigatorState>? $parentNavigatorKey = _dynamicRootKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(name: name, child: LogsOverviewPage());
  }
}





class AboutRoute extends GoRouteData {
  const AboutRoute();
  static const name = "About";

  static final GlobalKey<NavigatorState>? $parentNavigatorKey = _dynamicRootKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(name: name, child: AboutUsPage());
  }
}