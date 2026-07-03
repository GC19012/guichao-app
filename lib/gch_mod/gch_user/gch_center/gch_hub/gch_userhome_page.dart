import 'package:flutter/material.dart';
import 'package:guichao/gch_mod/gch_user/gch_center/gch_hub/gch_userhome_card.dart';
import 'package:guichao/gch_mod/gch_user/gch_center/gch_hub/gch_userhome_list_item.dart';
import 'package:guichao/gch_mod/gch_user/gch_shared/gch_user_theme_colors.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final userInfoProvider = Provider<UserInfo>((ref) {
  // TODO: 替换为实际数据获取逻辑
  return const UserInfo(
    avatarUrl: '',
    name: '陈志远',
    uid: '672737237',
    vipLevel: '钻石会员',
    vipExpire: '2024年12月31日到期',
  );
});

class UserInfo {
  final String avatarUrl;
  final String name;
  final String uid;
  final String vipLevel;
  final String vipExpire;
  const UserInfo({
    required this.avatarUrl,
    required this.name,
    required this.uid,
    required this.vipLevel,
    required this.vipExpire,
  });
}

class UserHomePage extends ConsumerWidget {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userInfoProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black38,
        elevation: 0,
        title: Text('个人中心', style: TextStyle(fontSize: 16.rf, color: UserThemeColors.primaryText)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: 刷新逻辑
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // 头部卡片
            Padding(
              padding: REdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: UserHomeCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28.rr,
                      backgroundColor: UserThemeColors.primaryText,
                      backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                      child: user.avatarUrl.isEmpty ? Icon(Icons.person, size: 28.ri, color: const Color(0xFFB0B8C1)) : null,
                    ),
                    SizedBox(width: 8.rw),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${user.name}(UID:${user.uid})', style: TextStyle(fontSize: 15.rf, color: UserThemeColors.primaryText, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                          SizedBox(height: 2.rh),
                          // Text('UID:${user.uid}', style: const TextStyle(fontSize: 13, color: UserThemeColors.primaryText70)),
                          SizedBox(height: 6.rh),
                          Row(
                            children: [
                              Container(
                                padding: REdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: UserThemeColors.info.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10.rr),
                                ),
                                child: Text(user.vipLevel, style: TextStyle(fontSize: 12.rf, color: const Color(0xFF1f4068))),
                              ),
                              SizedBox(width: 6.rw),
                              Expanded(child: Text(user.vipExpire, style: TextStyle(fontSize: 12.rf, color: UserThemeColors.primaryText70), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 账户管理
            _SectionCard(
              title: '账户管理',
              children: [
                UserHomeListItem(icon: Icons.account_balance_wallet, title: '我的余额', onTap: () {}),
                UserHomeListItem(icon: Icons.receipt_long, title: '账单明细', onTap: () {}),
                UserHomeListItem(icon: Icons.credit_card, title: '银行卡管理', onTap: () {}),
              ],
            ),
            // 常用功能
            _SectionCard(
              title: '常用功能',
              children: [
                UserHomeListItem(icon: Icons.settings, title: '个人资料设置', onTap: () {}),
                UserHomeListItem(icon: Icons.notifications, title: '消息通知', onTap: () {}),
                UserHomeListItem(icon: Icons.location_on, title: '地址管理', onTap: () {}),
              ],
            ),
            // 更多服务

          ],
        ),
      ),
    );
  }
}

// 卡片分组组件，带阴影和高光
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: REdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 8,
        shadowColor: Colors.blueAccent.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.rr)),
        color: UserThemeColors.primaryText.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.rr),
            gradient: LinearGradient(
              colors: [Colors.black45, Colors.indigo.withOpacity(0.9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: REdgeInsets.only(left: 16, top: 12, bottom: 4),
                child: Text(title, style: TextStyle(fontSize: 11.rf, color: Colors.grey, fontWeight: FontWeight.w500)),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
