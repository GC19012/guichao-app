import 'package:flutter/material.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_base/gch_nav/gch_routes.dart';
import 'package:guichao/gch_base/gch_umeng/gch_umeng_svc.dart';
import 'package:guichao/gch_mod/gch_user/gch_center/gch_setting/gch_setting_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// 设置页菜单 —— 2×N 圆角卡片宫格，卡片背景沿用「登录按钮」同款 webp
/// 已登录 / 未登录复用同一套卡片视觉，仅菜单项差异。
class SettingMenuList extends StatelessWidget {
  final bool isLoggedIn;
  final WidgetRef ref;
  final UserInfoState? userInfo;

  const SettingMenuList({
    super.key,
    required this.isLoggedIn,
    required this.ref,
    this.userInfo,
  });

  // 注销账号专用红色
  static const Color _deleteRed = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final items =
        isLoggedIn ? _loggedInItems(context) : _loggedOutItems(context);
    return _buildCardGrid(items);
  }

  /// 已登录菜单项：购买记录 / 服务条款 / 隐私政策 / 关于我们 / 注销账号 / 密码修改(条件)
  List<_MenuCardData> _loggedInItems(BuildContext context) {
    final items = <_MenuCardData>[
      _MenuCardData(
        icon: Icons.receipt_long_outlined,
        title: GchText.userCenterPurchaseRecord,
        onTap: () { GchUmengSvc.onProfileModuleTap('orders'); const NavOrderListRoute().go(context); },
      ),
      _MenuCardData(
        icon: Icons.headset_mic_outlined,
        title: '技术支持',
        onTap: () { GchUmengSvc.onProfileModuleTap('support'); const NavSupportRoute().go(context); },
      ),
      _MenuCardData(
        icon: Icons.privacy_tip_outlined,
        title: GchText.aboutPrivacyPolicy,
        onTap: () { GchUmengSvc.onProfileModuleTap('privacy'); launchUrl(Uri.parse('https://example.com/privacyA.html'), mode: LaunchMode.inAppBrowserView); },
      ),
      _MenuCardData(
        icon: Icons.info_outline,
        title: GchText.userCenterAboutUs,
        onTap: () { GchUmengSvc.onProfileModuleTap('about'); const NavAboutUsRoute().go(context); },
      ),
      _MenuCardData(
        icon: Icons.person_remove_outlined,
        title: GchText.userSettingDeleteAccount,
        titleColor: _deleteRed,
        iconColor: _deleteRed,
        onTap: () { GchUmengSvc.onProfileModuleTap('delete_account'); const NavDeleteAccountRoute().go(context); },
      ),
    ];

    // 密码修改 —— 条件显示（和旧逻辑一致）
    if (userInfo != null) {
      final passwordItem = _buildPasswordChangeItem(context, userInfo!);
      if (passwordItem != null) {
        items.add(passwordItem);
      }
    }
    return items;
  }

  /// 未登录菜单项：购买记录 / 成为会员 / 隐私政策 / 关于我们
  List<_MenuCardData> _loggedOutItems(BuildContext context) {
    return <_MenuCardData>[
      _MenuCardData(
        icon: Icons.receipt_long_outlined,
        title: GchText.userCenterPurchaseRecord,
        onTap: () { GchUmengSvc.onProfileModuleTap('orders'); const NavOrderListRoute().go(context); },
      ),
      _MenuCardData(
        icon: Icons.workspace_premium_outlined,
        title: GchText.userPayTitle,
        onTap: () { GchUmengSvc.onProfileModuleTap('checkout'); const NavCheckoutRoute().go(context); },
      ),
      _MenuCardData(
        icon: Icons.privacy_tip_outlined,
        title: GchText.aboutPrivacyPolicy,
        onTap: () { GchUmengSvc.onProfileModuleTap('privacy'); launchUrl(Uri.parse('https://example.com/privacyA.html'), mode: LaunchMode.inAppBrowserView); },
      ),
      _MenuCardData(
        icon: Icons.info_outline,
        title: GchText.userCenterAboutUs,
        onTap: () { GchUmengSvc.onProfileModuleTap('about'); const NavAboutUsRoute().go(context); },
      ),
    ];
  }

  /// 密码修改条件 —— 完全沿用旧逻辑
  _MenuCardData? _buildPasswordChangeItem(
      BuildContext context, UserInfoState userInfo) {
    if (!userInfo.isAuthenticated ||
        (userInfo.email == null && userInfo.phone == null)) {
      return null;
    }
    final authType = userInfo.authType;
    final showPasswordChange = authType == null ||
        authType == 'email' ||
        authType == 'password' ||
        authType == 'phone';
    if (!showPasswordChange) return null;

    return _MenuCardData(
      icon: Icons.lock_outline,
      title: GchText.userCenterSetPassword,
      onTap: () { GchUmengSvc.onProfileModuleTap('password_change'); const NavPasswordChangeRoute().go(context); },
    );
  }

  /// 2 列卡片宫格（任意行数）
  Widget _buildCardGrid(List<_MenuCardData> items) {
    const columnCount = 2;
    final rows = <List<int>>[];
    for (int i = 0; i < items.length; i += columnCount) {
      final end = (i + columnCount > items.length) ? items.length : i + columnCount;
      rows.add(List.generate(end - i, (j) => i + j));
    }

    return Padding(
      padding: REdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final rowIndices = entry.value;
          final isLastRow = entry.key == rows.length - 1;

          final children = <Widget>[];
          for (int k = 0; k < rowIndices.length; k++) {
            if (k > 0) children.add(SizedBox(width: 12.rw));
            children.add(Expanded(child: _MenuCard(data: items[rowIndices[k]])));
          }
          final emptySlots = columnCount - rowIndices.length;
          for (int s = 0; s < emptySlots; s++) {
            children.add(SizedBox(width: 12.rw));
            children.add(const Expanded(child: SizedBox()));
          }

          return Padding(
            padding: EdgeInsets.only(bottom: isLastRow ? 0 : 12.rh),
            child: Row(children: children),
          );
        }).toList(),
      ),
    );
  }
}

/// 卡片数据
class _MenuCardData {
  final IconData icon;
  final String title;
  final Color? titleColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const _MenuCardData({
    required this.icon,
    required this.title,
    this.titleColor,
    this.iconColor,
    required this.onTap,
  });
}

/// 菜单卡片 —— 登录按钮同款 webp 背景，矮卡（88rh）
class _MenuCard extends StatelessWidget {
  final _MenuCardData data;

  const _MenuCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 88.rh,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.rr),
          image: const DecorationImage(
            image: AssetImage('assets/gch_pics/gch_e2992f.webp'),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5969FF).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              data.icon,
              size: 24.ri,
              color: data.iconColor ?? const Color(0xFF5969FF),
            ),
            SizedBox(height: 6.rh),
            Text(
              data.title,
              style: TextStyle(
                fontSize: 13.rf,
                color: data.titleColor ?? const Color(0xFF333333),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
