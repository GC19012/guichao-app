import 'package:flutter/material.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_base/gch_umeng/gch_umeng_svc.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// ============================================================================
// 常量定义
// ============================================================================

/// 导航栏相关常量（响应式）
abstract class _NavBarConstants {
  /// 检测 tablet: shortestSide >= 600 (标准 Flutter 断点)
  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= 600;
  }

  /// 图标尺寸：iPad 1.5x (36), iPhone (24)
  static double iconSize(BuildContext context) {
    return isTablet(context) ? 36.0 : 24.0;
  }

}

/// 导航项索引枚举（显示顺序：购买、加速、工具、更多）
enum NavTabIndex {
  purchase(0),
  acceleration(1),
  tool(2),
  more(3);

  final int value;
  const NavTabIndex(this.value);

  static NavTabIndex? fromValue(int value) {
    return NavTabIndex.values.where((e) => e.value == value).firstOrNull;
  }

  /// 显示索引 → 路由分支索引
  static const List<int> displayToBranch = [0, 1, 2, 3]; // 购买=branch0, 加速=branch1, 工具=branch2, 更多=branch3

  /// 路由分支索引 → 显示索引
  static int branchToDisplay(int branchIndex) {
    final idx = displayToBranch.indexOf(branchIndex);
    return idx >= 0 ? idx : NavTabIndex.acceleration.value;
  }
}

// ============================================================================
// 导航图标类型（Sealed Class）
// ============================================================================

/// 导航项图标的类型安全表示
sealed class NavItemIcon {
  const NavItemIcon();

  Widget build(BuildContext context, bool isActive, Color activeColor, Color inactiveColor);
}

/// 使用图片资源的图标
class AssetNavIcon extends NavItemIcon {
  final String inactive;
  final String active;

  const AssetNavIcon({required this.inactive, required this.active});

  @override
  Widget build(BuildContext context, bool isActive, Color activeColor, Color inactiveColor) {
    final size = _NavBarConstants.iconSize(context);
    return Image.asset(
      isActive ? active : inactive,
      width: size,
      height: size,
      color: isActive ? activeColor : inactiveColor,
      colorBlendMode: BlendMode.srcIn,
    );
  }
}

/// 使用 IconData 的图标
class IconDataNavIcon extends NavItemIcon {
  final IconData inactive;
  final IconData active;

  const IconDataNavIcon({required this.inactive, required this.active});

  @override
  Widget build(BuildContext context, bool isActive, Color activeColor, Color inactiveColor) {
    final size = _NavBarConstants.iconSize(context);
    return Icon(
      isActive ? active : inactive,
      size: size,
      color: isActive ? activeColor : inactiveColor,
    );
  }
}

// ============================================================================
// 导航项配置
// ============================================================================

/// 导航项配置数据类
class _NavItemConfig {
  final NavTabIndex tab;
  final String Function() labelGetter;
  final NavItemIcon icon;
  final bool isCenterButton;

  const _NavItemConfig({
    required this.tab,
    required this.labelGetter,
    required this.icon,
    this.isCenterButton = false,
  });

  String getLabel() => labelGetter();
}

/// 导航项配置表（顺序：购买、加速、更多）
abstract class _NavItemConfigs {
  static const List<_NavItemConfig> items = [
    _NavItemConfig(
      tab: NavTabIndex.purchase,
      labelGetter: _purchaseLabel,
      icon: AssetNavIcon(
        inactive: 'assets/gch_pics/gch_pay/gch_c329d2.webp',
        active: 'assets/gch_pics/gch_pay/gch_c329d2.webp',
      ),
    ),
    _NavItemConfig(
      tab: NavTabIndex.acceleration,
      labelGetter: _accelerationLabel,
      icon: AssetNavIcon(
        inactive: 'assets/gch_pics/gch_nav/gch_e325c7.webp',
        active: 'assets/gch_pics/gch_nav/gch_9729ff.webp',
      ),
      isCenterButton: true,
    ),
    _NavItemConfig(
      tab: NavTabIndex.tool,
      labelGetter: _toolLabel,
      icon: const IconDataNavIcon(
        inactive: Icons.widgets_outlined,
        active: Icons.widgets,
      ),
    ),
    _NavItemConfig(
      tab: NavTabIndex.more,
      labelGetter: _moreLabel,
      icon: AssetNavIcon(
        inactive: 'assets/gch_pics/gch_nav/gch_3002ee.webp',
        active: 'assets/gch_pics/gch_nav/gch_9bf5ea.webp',
      ),
    ),
  ];

  // 静态函数引用，支持 const 构造
  static String _accelerationLabel() => GchText.userNavAcceleration;
  static String _purchaseLabel() => GchText.userNavPurchase;
  static String _toolLabel() => GchText.userNavTool;
  static String _moreLabel() => GchText.userNavMore;
}

// ============================================================================
// 主组件
// ============================================================================

/// 用户模块底部导航栏
///
/// 使用标准 Material BottomNavigationBar。
/// 由 NavShellScaffold 使用，通过 onTap 回调切换分支。
class UserBottomNavigation extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const UserBottomNavigation({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _CustomNavBar(
      currentIndex: currentIndex,
      onItemTap: _handleTap,
    );
  }

  void _handleTap(int index) {
    final tab = NavTabIndex.fromValue(index);
    if (tab != null) {
      GchUmengSvc.onTabTap(tab.name);
    }
    if (index != currentIndex) {
      onTap?.call(index);
    }
  }
}

// ============================================================================
// 自定义导航条
// ============================================================================

/// 浮动圆角底部导航条
///
/// 采用胶囊样式：外边距 + 大圆角 + 阴影，跨 iOS 版本统一视觉。
class _CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemTap;

  const _CustomNavBar({
    required this.currentIndex,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = theme.bottomNavigationBarTheme;
    final bgColor = navTheme.backgroundColor ?? theme.colorScheme.surface;
    final selectedColor = navTheme.selectedItemColor ?? theme.colorScheme.primary;
    final unselectedColor = navTheme.unselectedItemColor ??
        theme.colorScheme.onSurfaceVariant;

    return SafeArea(
      top: false,
      child: Padding(
        padding: REdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Material(
          elevation: 8,
          color: bgColor,
          shadowColor: Colors.black.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(32.rr),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 64.rh,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int i = 0; i < _NavItemConfigs.items.length; i++)
                  _NavItem(
                    config: _NavItemConfigs.items[i],
                    isActive: currentIndex == i,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    label: _NavItemConfigs.items[i].getLabel(),
                    onTap: () => onItemTap(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavItemConfig config;
  final bool isActive;
  final Color selectedColor;
  final Color unselectedColor;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.config,
    required this.isActive,
    required this.selectedColor,
    required this.unselectedColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28.rr),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            config.icon.build(context, isActive, selectedColor, unselectedColor),
            SizedBox(height: 2.rh),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.rf,
                color: isActive ? selectedColor : unselectedColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
