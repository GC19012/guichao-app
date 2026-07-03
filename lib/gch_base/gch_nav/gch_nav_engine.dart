import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';
import 'package:guichao/gch_base/gch_umeng/gch_umeng_observer.dart';
import 'package:guichao/gch_base/gch_umeng/gch_umeng_svc.dart';
import 'package:guichao/gch_base/gch_prefs/gch_general_pref.dart';
import 'package:guichao/gch_base/gch_nav/gch_auth_gate.dart';
import 'package:guichao/gch_base/gch_nav/gch_routes.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authuser_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_providers/gch_auth_providers.dart';
import 'package:guichao/gch_base/gch_biz/gch_common/gch_enums.dart';
import 'package:guichao/gch_mod/gch_deeplink/gch_ctrl/gch_deep_link_notifier.dart';
import 'package:guichao/gch_aux/gch_common.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gch_nav_engine.g.dart';

final gchRootNavKey = GlobalKey<NavigatorState>();

/// 路由配置提供者
@riverpod
GoRouter gchNav(GchNavRef ref) {
  final notifier = ref.watch(routerListenableProvider.notifier);

  // 监听深链接
  final deepLink = ref.listen(
    deepLinkNotifierProvider,
    (_, next) async {
      if (next case AsyncData(value: _?)) {
        // 深链接直接跳转到主页（使用 Shell 路由）
        await ref.state.push(const NavMainHomeRoute().location);
      }
    },
  );

  // 监听OAuth重定向
  ref.listen(
    oAuthRedirectNotifierProvider,
    (_, next) {
      if (next != null) {
        ref.state.go(next);
      }
    },
  );

  // 处理初始深链接
  final initialLink = deepLink.read();
  // 🚀 默认初始页为主页（native splash 已足够，无需 Flutter splash）
  String initialLocation = const NavMainHomeRoute().location;
  if (initialLink case AsyncData(value: final _?)) {
    // 有深链接时直接跳转到主页（使用 Shell 路由）
    initialLocation = const NavMainHomeRoute().location;
  }

  final router = GoRouter(
    navigatorKey: gchRootNavKey,
    initialLocation: initialLocation,
    debugLogDiagnostics: GchNucleus.isDevMode,
    routes: [
      // 底部导航 Shell 路由（导航条只创建一次，不闪烁）
      $userNavShellRoute,
      $mobileWrapperRoute,
      $loginRoute,
      $registerRoute,
      $forgetPasswordRoute,
      $profileRoute,
      $userProfileRoute,
      $mainHomeRoute,
      $userPageRoute,
      $checkoutRoute,
      $orderListRoute,
      $userSettingRoute,
      $deleteAccountRoute,
      $passwordChangeRoute,
      $aboutUsRoute,
      $pprofDebugRoute,
    ],
    refreshListenable: notifier,
    redirect: notifier.redirect,
    // GchUmengObserver 只覆盖 root navigator，无法追踪 StatefulShellRoute
    // 内部的 Tab 切换。真正的全路径追踪由下方 routerDelegate 监听器完成。
    observers: [GchUmengObserver()],
    errorBuilder: (_, state) => ErrorPage(
      path: state.uri.path,
      error: state.error?.toString(),
    ),
  );

  // 通过 routerDelegate 监听所有路由变化（包括 Shell 内 Tab 切换），
  // 补全 GchUmengObserver 无法覆盖的 StatefulShellRoute 分支导航。
  String? trackedPage;
  void onRouteChanged() {
    try {
      final path = router.routerDelegate.currentConfiguration.uri.path;
      if (path == trackedPage) return;
      if (trackedPage != null) GchUmengSvc.onPageEnd(trackedPage!);
      trackedPage = path;
      GchUmengSvc.onPageStart(path);
    } catch (_) {}
  }
  router.routerDelegate.addListener(onRouteChanged);
  ref.onDispose(() {
    router.routerDelegate.removeListener(onRouteChanged);
    if (trackedPage != null) GchUmengSvc.onPageEnd(trackedPage!);
  });

  return router;
}

// ===== 标签页导航配置 =====
final tabLocations = [
  const HomeRoute().location,
  const ProxiesRoute().location,
  const UserSettingRoute().location,
  const LogsOverviewRoute().location,
  const AboutRoute().location,
];

int getCurrentIndex(BuildContext context) {
  final String location = GoRouterState.of(context).uri.path;
  if (location == const HomeRoute().location) return 0;
  var index = 0;
  for (final tab in tabLocations.sublist(1)) {
    index++;
    if (location.startsWith(tab)) return index;
  }
  return 0;
}

void switchTab(int index, BuildContext context) {
  assert(index >= 0 && index < tabLocations.length);
  final location = tabLocations[index];
  return context.go(location);
}

/// 路由监听器
@riverpod
class RouterListenable extends _$RouterListenable with GchAppLogger implements Listenable {
  VoidCallback? _routerListener;
  bool _introCompleted = false;

  @override
  void build() {
    _introCompleted = ref.watch(GchPrefs.introCompleted).valueOrNull ?? false;

    // 监听用户状态变化 - 使用来自auth_providers的正确的currentUserProvider
    ref.watch(currentUserProvider);

    ref.listenSelf((_, __) {
      loggy.debug("triggering listener");
      _routerListener?.call();
    });
  }

// ignore: avoid_build_context_in_providers
  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    final location = state.uri.path;
    
    // 定义在引导未完成时也可以访问的公开路由
    final publicRoutesDuringIntro = {
      '/intro',
      '/login',
      '/register', // 允许在引导未完成时访问注册页面
      '/forget-password', // 允许在引导未完成时访问忘记密码页面
      '/usermode',
      '/mainhome',
      '/user/setting',
      '/user/password-change', // 临时添加，方便调试权限问题
      '/user/delete-account', // 允许已登录用户删除账号
      '/user/about-us',
      '/checkout', // 允许访问会员购买页面
      '/orders',
      '/profile',
      '/app_proxy',
      '/pprof-debug', // Pprof 性能调试（Debug 模式）
      // Shell 路由（底部导航）
      '/nav/checkout',
      '/nav/home',
      '/nav/tool',
      '/nav/tool/worldclock',
      '/nav/tool/currency',
      '/nav/tool/emergency',
      '/nav/setting',
      '/nav/setting/about-us',
      '/nav/setting/support',
      '/nav/login',
      '/nav/register',
      '/nav/forget-password',
    };

    // 引导页重定向逻辑
    if (!_introCompleted) {
      if (publicRoutesDuringIntro.contains(location)) return null;
      return const NavLoginRoute().location;
    }

    // 引导已完成，检查登录状态
    // 获取用户状态（直接使用FutureProvider的future访问器）
    AuthUser? user;
    try {
      user = await ref.read(currentUserProvider.future);
      //loggy.debug("redirect: 获取用户信息成功，用户: ${user != null ? user.email : 'null'}，路径: $location");
    } catch (e) {
      // 如果获取用户信息失败，视为未登录
      //loggy.warning("redirect: 获取用户信息失败: $e，路径: $location");
      user = null;
    }

    if (user == null) {
      //loggy.info("redirect: 用户未登录，路径: $location");
      // 未登录用户只能访问公开路由
      if (publicRoutesDuringIntro.contains(location)) {
        //loggy.debug("redirect: 允许访问公开路由: $location");
        return null;
      }
      // 其他路由重定向到登录页面（使用 NavLoginRoute 确保有完整的 Shell 上下文）
      //loggy.info("redirect: 重定向到登录页面，来源路径: $location");
      return const NavLoginRoute().location;
    }

    // 已登录用户，进行权限检查
    //loggy.debug("redirect: 开始权限检查，用户: ${user.email}，路径: $location");
    final result = await GchAuthGuard.instance.canAccess(location, user);
    return result.when(
      allowed: () {
       // loggy.debug("redirect: 权限检查通过，路径: $location");
        return null;
      },
      denied: (reason, redirect) {
        //loggy.warning("redirect: 权限检查失败，原因: $reason，重定向到: $redirect，路径: $location");
        return redirect;
      },
    );
  }

  @override
  void addListener(VoidCallback listener) {
    _routerListener = listener;
  }

  @override
  void removeListener(VoidCallback listener) {
    _routerListener = null;
  }
}

/// 错误页面
class ErrorPage extends StatelessWidget {
  const ErrorPage({
    super.key,
    required this.path,
    this.error,
  });

  final String path;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('页面错误'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                '页面未找到',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '路径: $path',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  '错误: $error',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.go(const HomeRoute().location),
                    icon: const Icon(Icons.home),
                    label: const Text('返回首页'),
                  ),
                  if (GoRouter.of(context).canPop()) ...[
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () => context.safePop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('返回'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final permissionCheckProvider = FutureProvider.family<GchAuthResult, String>((ref, route) async {
  if (GchAuthGuard.instance.isPublicRoute(route)) {
    return const GchAllowed();
  }

  try {
    final user = await ref.watch(currentUserProvider.future);
    return GchAuthGuard.instance.canAccess(route, user);
  } catch (_) {
    return GchAuthGuard.instance.canAccess(route, null);
  }
});

/// 权限守卫组件 - 与新的 GchAuthGuard 集成
class PermissionGuard extends ConsumerWidget {
  const PermissionGuard({
    super.key,
    required this.child,
    required this.route,
    this.fallback = const SizedBox.shrink(),
    this.loading = const CircularProgressIndicator(),
  });

  final Widget child;
  final String route;
  final Widget fallback;
  final Widget loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permission = ref.watch(permissionCheckProvider(route));

    return permission.when(
      data: (result) => result.when(
        allowed: () => child,
        denied: (_, __) => fallback,
      ),
      loading: () => Center(child: loading),
      error: (_, __) => fallback,
    );
  }
}

/// 功能权限辅助类
class FeaturePermissionHelper {
  static const _featureRequirements = <String, VipType>{
    'vpn': VipType.free,
    'profiles': VipType.free,
    'advanced': VipType.basic,
    'logs': VipType.premium,
    'per_app': VipType.premium,
  };

  static bool hasFeaturePermission(AuthUser user, String feature) {
    final userLevel = user.currentVip;
    final requiredLevel = _featureRequirements[feature] ?? VipType.premium;
    return userLevel.canAccess(requiredLevel);
  }
}

/// 功能守卫组件
class FeatureGuard extends ConsumerWidget {
  const FeatureGuard({
    super.key,
    required this.child,
    required this.feature,
    this.fallback = const SizedBox.shrink(),
  });

  final Widget child;
  final String feature;
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return fallback;

        // 使用辅助类检查功能权限
        final hasPermission = FeaturePermissionHelper.hasFeaturePermission(user, feature);

        return hasPermission ? child : fallback;
      },
      loading: () => fallback,
      error: (_, __) => fallback,
    );
  }
}

/// 返回按钮处理扩展
extension BackButtonHandler on BuildContext {
  Future<bool> handleBackButton() async {
    final router = GoRouter.of(this);

    // 如果可以返回，则返回
    if (router.canPop()) {
      router.pop();
      return true;
    }

    // 否则回到首页或退出
    final currentLocation = GoRouterState.of(this).uri.path;
    if (currentLocation != '/') {
      router.go('/');
      return true;
    }

    // 已在首页，允许退出
    return false;
  }
}

/// 安全导航扩展
extension SafeNavigation on BuildContext {
  /// 安全导航到指定路由
  Future<void> safeGo(String location, {Object? extra}) async {
    final userAsync = ProviderScope.containerOf(this).read(currentUserProvider);
    final user = await userAsync.when(
      data: (user) => Future.value(user),
      loading: () => Future.value(null),
      error: (_, __) => Future.value(null),
    );
    
    final result = await GchAuthGuard.instance.canAccess(location, user);

    if (!mounted) return;

    result.when(
      allowed: () => go(location, extra: extra),
      denied: (_, redirect) => go(redirect, extra: extra),
    );
  }

  /// 安全推送路由
  Future<void> safePush(String location, {Object? extra}) async {
    final userAsync = ProviderScope.containerOf(this).read(currentUserProvider);
    final user = await userAsync.when(
      data: (user) => Future.value(user),
      loading: () => Future.value(null),
      error: (_, __) => Future.value(null),
    );
    
    final result = await GchAuthGuard.instance.canAccess(location, user);

    if (!mounted) return;

    result.when(
      allowed: () => push(location, extra: extra),
      denied: (_, redirect) => push(redirect, extra: extra),
    );
  }
}
