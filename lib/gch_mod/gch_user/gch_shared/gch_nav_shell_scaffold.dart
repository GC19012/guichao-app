import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:guichao/gch_mod/gch_user/gch_shared/gch_user_bottom_navigation.dart';

/// 平台检测工具
abstract class PlatformDetector {
  static bool? _isIOS26Cached;

  /// 检测是否为 iOS 26+
  static bool get isIOS26OrHigher {
    if (_isIOS26Cached != null) return _isIOS26Cached!;

    if (!Platform.isIOS) {
      _isIOS26Cached = false;
      return false;
    }

    try {
      final version = Platform.operatingSystemVersion;
      final match = RegExp(r'Version (\d+)').firstMatch(version);
      if (match != null) {
        _isIOS26Cached = int.parse(match.group(1)!) >= 26;
        return _isIOS26Cached!;
      }
    } catch (_) {}

    _isIOS26Cached = false;
    return false;
  }
}

/// 导航 Shell 容器
///
/// 用于 StatefulShellRoute，提供持久化的导航条：
/// - iOS 26+: Stack 布局，Liquid Glass 浮动导航条
/// - iOS <26 / Android: 标准 Scaffold.bottomNavigationBar
class NavShellScaffold extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  /// 当前活跃的分支索引（静态变量，供子页面判断可见性）
  /// - 0: 购买
  /// - 1: 加速（首页）
  /// - 2: 工具
  /// - 3: 更多（设置）
  static int currentTabIndex = 1;

  const NavShellScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<NavShellScaffold> createState() => _NavShellScaffoldState();
}

class _NavShellScaffoldState extends ConsumerState<NavShellScaffold> {
  /// 显示底部导航的分支根路径（二级页面不显示）
  static const Set<String> _tabRootPaths = {
    '/nav/checkout',
    '/nav/home',
    '/nav/tool',
    '/nav/setting',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 预缓存主页 & 购买页共用背景图，避免首次进入时出现黑色闪烁
    precacheImage(const AssetImage('assets/gch_pics/gch_e532f7.webp'), context);
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    final branchIndex = navigationShell.currentIndex;
    // 分支索引 → 显示索引（3个tab: 购买、加速、更多）
    final currentIndex = NavTabIndex.branchToDisplay(branchIndex);

    // 更新静态变量（保留分支索引，供子页面使用）
    NavShellScaffold.currentTabIndex = branchIndex;

    final router = GoRouter.of(context);
    // 监听 routerDelegate：StatefulShellBranch 内 .push() 也会触发通知，
    // 比 routeInformationProvider 更可靠。
    // 仅使用 Offstage 切换可见性，不改变 Scaffold 的 bottomNavigationBar 结构，
    // 避免键盘弹出时因结构变化导致子页焦点丢失、键盘反复弹回。
    final scaffold = ListenableBuilder(
      listenable: router.routerDelegate,
      builder: (context, _) {
        final path = router.routerDelegate.currentConfiguration.uri.path;
        final branchVisible =
            NavTabIndex.displayToBranch.contains(navigationShell.currentIndex);
        final showBottomNav = branchVisible && _tabRootPaths.contains(path);
        return Scaffold(
          // body 一直延伸到屏幕底部，让子页的背景图铺满 tab 栏浮动胶囊周围区域
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: navigationShell,
          bottomNavigationBar: Offstage(
            offstage: !showBottomNav,
            child: UserBottomNavigation(
              currentIndex: currentIndex,
              onTap: _onTap,
            ),
          ),
        );
      },
    );

    return scaffold;
  }

  void _onTap(int displayIndex) {
    // 显示索引 → 路由分支索引
    final branchIndex = NavTabIndex.displayToBranch[displayIndex];
    final navigationShell = widget.navigationShell;
    // goBranch 会保持各分支的导航状态
    navigationShell.goBranch(
      branchIndex,
      // 如果已经在当前分支，点击则回到分支根页面
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }
}
