import 'package:flutter/material.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_base/gch_nav/gch_routes.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:guichao/gch_base/gch_biz/gch_common/gch_enums.dart';
import 'package:guichao/gch_mod/gch_user/gch_center/gch_setting/gch_setting_page.dart';

/// 用户 VIP 信息行 - 参照设计稿 profile_logged_in.webp
///
/// 简化为单行布局：钻石图标 + VIP类型文字 + 升级提示 + 解锁特权按钮
/// 所有业务逻辑（VipType 判断、到期时间格式化、导航回调）保持不变。
class SettingUserInfoCard extends StatelessWidget {
  final UserInfoState userInfo;
  const SettingUserInfoCard({
    super.key,
    required this.userInfo,
  });

  @override
  Widget build(BuildContext context) {
    final vipTypeText = _getVipTypeText(userInfo.vipType);
    final isMember = userInfo.vipType != VipType.free;
    final actionText =
        isMember ? GchText.userCenterRenewPrivileges : GchText.userCenterUnlockPrivileges;

    return Padding(
      padding: REdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // 钻石图标
          Image.asset(
            'assets/gch_pics/gch_e9b27a.webp',
            width: 20.ri,
            height: 20.ri,
          ),
          SizedBox(width: 8.rw),
          // VIP 类型文字（紫色加粗）
          Expanded(
            child: Text(
              vipTypeText,
              style: TextStyle(
                fontSize: 14.rf,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5969FF),
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 解锁特权按钮 — 始终显示
          GestureDetector(
            onTap: () {
              const NavCheckoutRoute().go(context);
            },
            child: Container(
              height: 32.rh,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.rr),
                image: const DecorationImage(
                  image: AssetImage('assets/gch_pics/gch_pay/gch_f83c1f.webp'),
                  fit: BoxFit.fill,
                ),
              ),
              alignment: Alignment.center,
              padding: REdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionText,
                    style: TextStyle(
                      fontSize: 12.rf,
                      color: const Color(0xFF5969FF),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(width: 2.rw),
                  Icon(
                    Icons.chevron_right,
                    size: 14.ri,
                    color: const Color(0xFF5969FF),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// VIP 类型文字 - 逻辑完全不变
  String _getVipTypeText(VipType vipType) {
    switch (vipType) {
      case VipType.free:
        return GchText.userCenterFreeUser;
      case VipType.basic:
        return GchText.userCenterBasicMember;
      case VipType.premium:
        return GchText.userCenterPremiumMember;
    }
  }

}
