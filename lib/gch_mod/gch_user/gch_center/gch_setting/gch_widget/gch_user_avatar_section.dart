import 'package:flutter/material.dart';
import 'package:guichao/gch_base/gch_biz/gch_common/gch_enums.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

/// 用户头像区域 - 参照参考页面 profile_page.dart 使用圆形 webp 头像图片
class UserAvatarSection extends ConsumerWidget {
  final String userId;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final VoidCallback? onTap;
  final bool isAuthenticated;
  final String? authType;
  final String? name;
  final String? nickname;
  final VipType? vipType;
  final DateTime? expiredAt;

  const UserAvatarSection({
    super.key,
    required this.userId,
    this.email,
    this.phone,
    this.avatarUrl,
    this.onTap,
    this.isAuthenticated = true,
    this.authType,
    this.name,
    this.nickname,
    this.vipType,
    this.expiredAt,
  });

  // 浅色主题颜色 - 标题深色，次要信息灰色
  static const Color _titleDark = Color(0xFF333333);
  static const Color _subtitleGray = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: REdgeInsets.fromLTRB(28, 0, 28, 16),
        child: Row(
          children: [
            // 用户头像 - 圆形 webp 图片，与参考页面一致
            ClipOval(
              child: Image.asset(
                'assets/gch_pics/gch_5e35dd.webp',
                width: 60.ri,
                height: 60.ri,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 12.rw),
            Expanded(
              child: _buildUserInfo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    if (isAuthenticated) {
      // 已登录，显示用户信息
      final contactWidgets = <Widget>[];

      if (email != null && email!.isNotEmpty) {
        contactWidgets.add(
          Text(
            '${GchText.userCenterEmailLabel}$email',
            style: TextStyle(
              color: _subtitleGray,
              fontSize: 13.rf,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }

      // 显示手机号（如果不为空）
      if (phone != null && phone!.isNotEmpty) {
        if (contactWidgets.isNotEmpty) {
          contactWidgets.add(SizedBox(height: 4.rh));
        }
        contactWidgets.add(
          Text(
            '${GchText.userCenterPhoneLabel}$phone',
            style: TextStyle(
              color: _subtitleGray,
              fontSize: 13.rf,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }

      // 如果都为空，显示"未设置"
      if (contactWidgets.isEmpty) {
        contactWidgets.add(
          Text(
            GchText.userCenterNotSet,
            style: TextStyle(
              color: _subtitleGray,
              fontSize: 13.rf,
            ),
          ),
        );
      }

      // 会员到期时间 - 在手机号下方额外一行，仅会员用户显示
      final vipExpiryLine = _buildVipExpiryLine();
      if (vipExpiryLine != null) {
        contactWidgets
          ..add(SizedBox(height: 4.rh))
          ..add(vipExpiryLine);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${GchText.userCenterHomeNumberLabel}$userId',
            style: TextStyle(
              color: _titleDark,
              fontSize: 16.rf,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.rh),
          ...contactWidgets,
        ],
      );
    } else {
      // 未登录，显示登录/注册提示
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            GchText.userCenterLoginOrRegister,
            style: TextStyle(
              fontSize: 16.rf,
              color: _titleDark,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 6.rh),
          Text(
            GchText.userCenterLoginToExperience,
            style: TextStyle(
              fontSize: 13.rf,
              color: _subtitleGray,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }
  }

  /// 会员到期时间 - 仅显示年月日，单行不换行；非会员返回 null
  Widget? _buildVipExpiryLine() {
    final type = vipType;
    if (type == null || type == VipType.free) return null;
    final expiry = expiredAt;
    final suffix = expiry == null
        ? GchText.userCenterPermanentValid
        : DateFormat('yyyy/MM/dd').format(expiry.toLocal());
    final text = '${GchText.userCenterVipExpiryTime}$suffix';
    return Text(
      text,
      style: TextStyle(
        color: _subtitleGray,
        fontSize: 13.rf,
      ),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    );
  }
}
