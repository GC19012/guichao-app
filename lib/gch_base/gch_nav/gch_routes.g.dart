// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gch_routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
      $userNavShellRoute,
      $mobileWrapperRoute,
      $loginRoute,
      $registerRoute,
      $forgetPasswordRoute,
      $pprofDebugRoute,
      $profileRoute,
      $userProfileRoute,
      $mainHomeRoute,
      $userPageRoute,
      $checkoutRoute,
      $orderListRoute,
      $userSettingRoute,
      $passwordChangeRoute,
      $aboutUsRoute,
      $deleteAccountRoute,
    ];

RouteBase get $userNavShellRoute => StatefulShellRouteData.$route(
      factory: $UserNavShellRouteExtension._fromState,
      branches: [
        StatefulShellBranchData.$branch(
          navigatorKey: PurchaseBranch.$navigatorKey,
          routes: [
            GoRouteData.$route(
              path: '/nav/checkout',
              name: 'NavCheckout',
              factory: $NavCheckoutRouteExtension._fromState,
            ),
          ],
        ),
        StatefulShellBranchData.$branch(
          navigatorKey: AccelerationBranch.$navigatorKey,
          routes: [
            GoRouteData.$route(
              path: '/nav/home',
              name: 'NavMainHome',
              factory: $NavMainHomeRouteExtension._fromState,
            ),
            GoRouteData.$route(
              path: '/nav/login',
              name: 'NavLogin',
              factory: $NavLoginRouteExtension._fromState,
            ),
            GoRouteData.$route(
              path: '/nav/register',
              name: 'NavRegister',
              factory: $NavRegisterRouteExtension._fromState,
            ),
            GoRouteData.$route(
              path: '/nav/forget-password',
              name: 'NavForgetPassword',
              factory: $NavForgetPasswordRouteExtension._fromState,
            ),
          ],
        ),
        StatefulShellBranchData.$branch(
          navigatorKey: ToolBranch.$navigatorKey,
          routes: [
            GoRouteData.$route(
              path: '/nav/tool',
              name: 'NavTool',
              factory: $NavToolRouteExtension._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'holiday',
                  name: 'NavHoliday',
                  factory: $NavHolidayRouteExtension._fromState,
                ),
                GoRouteData.$route(
                  path: 'worldclock',
                  name: 'NavWorldClock',
                  factory: $NavWorldClockRouteExtension._fromState,
                ),
                GoRouteData.$route(
                  path: 'currency',
                  name: 'NavCurrency',
                  factory: $NavCurrencyRouteExtension._fromState,
                ),
                GoRouteData.$route(
                  path: 'emergency',
                  name: 'NavEmergency',
                  factory: $NavEmergencyRouteExtension._fromState,
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranchData.$branch(
          navigatorKey: MoreBranch.$navigatorKey,
          routes: [
            GoRouteData.$route(
              path: '/nav/setting',
              name: 'NavSetting',
              factory: $NavSettingRouteExtension._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'orders',
                  name: 'NavOrderList',
                  factory: $NavOrderListRouteExtension._fromState,
                ),
                GoRouteData.$route(
                  path: 'profile',
                  name: 'NavProfile',
                  factory: $NavProfileRouteExtension._fromState,
                ),
                GoRouteData.$route(
                  path: 'password-change',
                  name: 'NavPasswordChange',
                  factory: $NavPasswordChangeRouteExtension._fromState,
                ),
                GoRouteData.$route(
                  path: 'about-us',
                  name: 'NavAboutUs',
                  factory: $NavAboutUsRouteExtension._fromState,
                ),
                GoRouteData.$route(
                  path: 'support',
                  name: 'NavSupport',
                  factory: $NavSupportRouteExtension._fromState,
                ),
                GoRouteData.$route(
                  path: 'delete-account',
                  name: 'NavDeleteAccount',
                  factory: $NavDeleteAccountRouteExtension._fromState,
                ),
              ],
            ),
          ],
        ),
      ],
    );

extension $UserNavShellRouteExtension on UserNavShellRoute {
  static UserNavShellRoute _fromState(GoRouterState state) =>
      const UserNavShellRoute();
}

extension $NavCheckoutRouteExtension on NavCheckoutRoute {
  static NavCheckoutRoute _fromState(GoRouterState state) =>
      const NavCheckoutRoute();

  String get location => GoRouteData.$location(
        '/nav/checkout',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $NavMainHomeRouteExtension on NavMainHomeRoute {
  static NavMainHomeRoute _fromState(GoRouterState state) =>
      const NavMainHomeRoute();

  String get location => GoRouteData.$location(
        '/nav/home',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $NavLoginRouteExtension on NavLoginRoute {
  static NavLoginRoute _fromState(GoRouterState state) => const NavLoginRoute();

  String get location => GoRouteData.$location(
        '/nav/login',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $NavRegisterRouteExtension on NavRegisterRoute {
  static NavRegisterRoute _fromState(GoRouterState state) =>
      const NavRegisterRoute();

  String get location => GoRouteData.$location(
        '/nav/register',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $NavForgetPasswordRouteExtension on NavForgetPasswordRoute {
  static NavForgetPasswordRoute _fromState(GoRouterState state) =>
      const NavForgetPasswordRoute();

  String get location => GoRouteData.$location(
        '/nav/forget-password',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $NavSettingRouteExtension on NavSettingRoute {
  static NavSettingRoute _fromState(GoRouterState state) =>
      const NavSettingRoute();

  String get location => GoRouteData.$location(
        '/nav/setting',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $NavOrderListRouteExtension on NavOrderListRoute {
  static NavOrderListRoute _fromState(GoRouterState state) =>
      const NavOrderListRoute();

  String get location => GoRouteData.$location(
        '/nav/setting/orders',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $NavProfileRouteExtension on NavProfileRoute {
  static NavProfileRoute _fromState(GoRouterState state) =>
      const NavProfileRoute();

  String get location => GoRouteData.$location(
        '/nav/setting/profile',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $NavPasswordChangeRouteExtension on NavPasswordChangeRoute {
  static NavPasswordChangeRoute _fromState(GoRouterState state) =>
      const NavPasswordChangeRoute();

  String get location => GoRouteData.$location(
        '/nav/setting/password-change',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $NavAboutUsRouteExtension on NavAboutUsRoute {
  static NavAboutUsRoute _fromState(GoRouterState state) =>
      const NavAboutUsRoute();

  String get location => GoRouteData.$location(
        '/nav/setting/about-us',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $NavSupportRouteExtension on NavSupportRoute {
  static NavSupportRoute _fromState(GoRouterState state) =>
      const NavSupportRoute();

  String get location => GoRouteData.$location(
        '/nav/setting/support',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $NavDeleteAccountRouteExtension on NavDeleteAccountRoute {
  static NavDeleteAccountRoute _fromState(GoRouterState state) =>
      const NavDeleteAccountRoute();

  String get location => GoRouteData.$location(
        '/nav/setting/delete-account',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $NavToolRouteExtension on NavToolRoute {
  static NavToolRoute _fromState(GoRouterState state) => const NavToolRoute();

  String get location => GoRouteData.$location(
        '/nav/tool',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $NavHolidayRouteExtension on NavHolidayRoute {
  static NavHolidayRoute _fromState(GoRouterState state) =>
      const NavHolidayRoute();

  String get location => GoRouteData.$location(
        '/nav/tool/holiday',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $NavWorldClockRouteExtension on NavWorldClockRoute {
  static NavWorldClockRoute _fromState(GoRouterState state) =>
      const NavWorldClockRoute();

  String get location => GoRouteData.$location(
        '/nav/tool/worldclock',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $NavCurrencyRouteExtension on NavCurrencyRoute {
  static NavCurrencyRoute _fromState(GoRouterState state) =>
      const NavCurrencyRoute();

  String get location => GoRouteData.$location(
        '/nav/tool/currency',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $NavEmergencyRouteExtension on NavEmergencyRoute {
  static NavEmergencyRoute _fromState(GoRouterState state) =>
      const NavEmergencyRoute();

  String get location => GoRouteData.$location(
        '/nav/tool/emergency',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $mobileWrapperRoute => ShellRouteData.$route(
      factory: $MobileWrapperRouteExtension._fromState,
      routes: [
        GoRouteData.$route(
          path: '/',
          name: 'Home',
          factory: $HomeRouteExtension._fromState,
          routes: [
            GoRouteData.$route(
              path: 'logs',
              name: 'Logs',
              parentNavigatorKey: LogsOverviewRoute.$parentNavigatorKey,
              factory: $LogsOverviewRouteExtension._fromState,
            ),
            GoRouteData.$route(
              path: 'about',
              name: 'About',
              parentNavigatorKey: AboutRoute.$parentNavigatorKey,
              factory: $AboutRouteExtension._fromState,
            ),
          ],
        ),
        GoRouteData.$route(
          path: '/proxies',
          name: 'Proxies',
          factory: $ProxiesRouteExtension._fromState,
        ),
      ],
    );

extension $MobileWrapperRouteExtension on MobileWrapperRoute {
  static MobileWrapperRoute _fromState(GoRouterState state) =>
      const MobileWrapperRoute();
}

extension $HomeRouteExtension on HomeRoute {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  String get location => GoRouteData.$location(
        '/',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $LogsOverviewRouteExtension on LogsOverviewRoute {
  static LogsOverviewRoute _fromState(GoRouterState state) =>
      const LogsOverviewRoute();

  String get location => GoRouteData.$location(
        '/logs',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $AboutRouteExtension on AboutRoute {
  static AboutRoute _fromState(GoRouterState state) => const AboutRoute();

  String get location => GoRouteData.$location(
        '/about',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $ProxiesRouteExtension on ProxiesRoute {
  static ProxiesRoute _fromState(GoRouterState state) => const ProxiesRoute();

  String get location => GoRouteData.$location(
        '/proxies',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}


RouteBase get $loginRoute => GoRouteData.$route(
      path: '/login',
      name: 'Login',
      factory: $LoginRouteExtension._fromState,
    );

extension $LoginRouteExtension on LoginRoute {
  static LoginRoute _fromState(GoRouterState state) => LoginRoute(
        redirectTo: state.uri.queryParameters['redirect-to'],
      );

  String get location => GoRouteData.$location(
        '/login',
        queryParams: {
          if (redirectTo != null) 'redirect-to': redirectTo,
        },
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $registerRoute => GoRouteData.$route(
      path: '/register',
      name: 'Register',
      factory: $RegisterRouteExtension._fromState,
    );

extension $RegisterRouteExtension on RegisterRoute {
  static RegisterRoute _fromState(GoRouterState state) => const RegisterRoute();

  String get location => GoRouteData.$location(
        '/register',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $forgetPasswordRoute => GoRouteData.$route(
      path: '/forget-password',
      name: 'ForgetPassword',
      factory: $ForgetPasswordRouteExtension._fromState,
    );

extension $ForgetPasswordRouteExtension on ForgetPasswordRoute {
  static ForgetPasswordRoute _fromState(GoRouterState state) =>
      const ForgetPasswordRoute();

  String get location => GoRouteData.$location(
        '/forget-password',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $pprofDebugRoute => GoRouteData.$route(
      path: '/pprof-debug',
      name: 'PprofDebug',
      parentNavigatorKey: PprofDebugRoute.$parentNavigatorKey,
      factory: $PprofDebugRouteExtension._fromState,
    );

extension $PprofDebugRouteExtension on PprofDebugRoute {
  static PprofDebugRoute _fromState(GoRouterState state) =>
      const PprofDebugRoute();

  String get location => GoRouteData.$location(
        '/pprof-debug',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $profileRoute => GoRouteData.$route(
      path: '/profile',
      name: 'profile',
      factory: $ProfileRouteExtension._fromState,
    );

extension $ProfileRouteExtension on ProfileRoute {
  static ProfileRoute _fromState(GoRouterState state) => const ProfileRoute();

  String get location => GoRouteData.$location(
        '/profile',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $userProfileRoute => GoRouteData.$route(
      path: '/userprofile',
      name: 'userprofile',
      factory: $UserProfileRouteExtension._fromState,
    );

extension $UserProfileRouteExtension on UserProfileRoute {
  static UserProfileRoute _fromState(GoRouterState state) =>
      const UserProfileRoute();

  String get location => GoRouteData.$location(
        '/userprofile',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $mainHomeRoute => GoRouteData.$route(
      path: '/mainhome',
      name: 'MainHome',
      factory: $MainHomeRouteExtension._fromState,
    );

extension $MainHomeRouteExtension on MainHomeRoute {
  static MainHomeRoute _fromState(GoRouterState state) => const MainHomeRoute();

  String get location => GoRouteData.$location(
        '/mainhome',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $userPageRoute => GoRouteData.$route(
      path: '/user',
      name: 'UserPage',
      factory: $UserPageRouteExtension._fromState,
    );

extension $UserPageRouteExtension on UserPageRoute {
  static UserPageRoute _fromState(GoRouterState state) => const UserPageRoute();

  String get location => GoRouteData.$location(
        '/user',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $checkoutRoute => GoRouteData.$route(
      path: '/checkout',
      name: 'Checkout',
      factory: $CheckoutRouteExtension._fromState,
    );

extension $CheckoutRouteExtension on CheckoutRoute {
  static CheckoutRoute _fromState(GoRouterState state) => const CheckoutRoute();

  String get location => GoRouteData.$location(
        '/checkout',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $orderListRoute => GoRouteData.$route(
      path: '/orders',
      name: 'OrderList',
      factory: $OrderListRouteExtension._fromState,
    );

extension $OrderListRouteExtension on OrderListRoute {
  static OrderListRoute _fromState(GoRouterState state) =>
      const OrderListRoute();

  String get location => GoRouteData.$location(
        '/orders',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $userSettingRoute => GoRouteData.$route(
      path: '/user/setting',
      name: 'UserSetting',
      factory: $UserSettingRouteExtension._fromState,
    );

extension $UserSettingRouteExtension on UserSettingRoute {
  static UserSettingRoute _fromState(GoRouterState state) =>
      const UserSettingRoute();

  String get location => GoRouteData.$location(
        '/user/setting',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $passwordChangeRoute => GoRouteData.$route(
      path: '/user/password-change',
      name: 'PasswordChange',
      factory: $PasswordChangeRouteExtension._fromState,
    );

extension $PasswordChangeRouteExtension on PasswordChangeRoute {
  static PasswordChangeRoute _fromState(GoRouterState state) =>
      const PasswordChangeRoute();

  String get location => GoRouteData.$location(
        '/user/password-change',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $aboutUsRoute => GoRouteData.$route(
      path: '/user/about-us',
      name: 'AboutUs',
      factory: $AboutUsRouteExtension._fromState,
    );

extension $AboutUsRouteExtension on AboutUsRoute {
  static AboutUsRoute _fromState(GoRouterState state) => const AboutUsRoute();

  String get location => GoRouteData.$location(
        '/user/about-us',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $deleteAccountRoute => GoRouteData.$route(
      path: '/user/delete-account',
      name: 'DeleteAccount',
      factory: $DeleteAccountRouteExtension._fromState,
    );

extension $DeleteAccountRouteExtension on DeleteAccountRoute {
  static DeleteAccountRoute _fromState(GoRouterState state) =>
      const DeleteAccountRoute();

  String get location => GoRouteData.$location(
        '/user/delete-account',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}
