import 'package:flutter/material.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:guichao/gch_base/gch_biz/gch_common/gch_enums.dart';
import 'package:guichao/gch_base/gch_nav/gch_auth_gate.dart';
import 'package:guichao/gch_mod/gch_tool/gch_holiday/gch_holiday_data.dart';
import 'package:guichao/gch_mod/gch_tool/gch_history/gch_history_page.dart';
import 'package:guichao/gch_mod/gch_tool/gch_netdiag/gch_netdiag_page.dart';
import 'package:guichao/gch_mod/gch_tool/gch_visa/gch_visa_page.dart';
import 'package:guichao/gch_mod/gch_tool/gch_remit/gch_remit_page.dart';
import 'package:guichao/gch_mod/gch_tool/gch_saving/gch_saving_page.dart';
import 'package:guichao/gch_mod/gch_tool/gch_work/gch_work_page.dart';
import 'package:go_router/go_router.dart';
import 'package:guichao/gch_mod/gch_tool/gch_traffic/gch_traffic_page.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_providers/gch_auth_providers.dart';
import 'package:guichao/gch_base/gch_nav/gch_routes.dart';
import 'package:guichao/gch_base/gch_umeng/gch_umeng_svc.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ToolPage extends ConsumerWidget {
  const ToolPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userInfoProvider);

    return ColoredBox(
      color: const Color(0xFFF1EFF9),
      child: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: ListView(
                padding: EdgeInsets.only(bottom: 16.rh),
                children: [
          SizedBox(height: 16.rh),

          // ── 顶部导航栏 ─────────────────────────────────────────────────
          Padding(
            padding: REdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '工具',
                      style: TextStyle(
                        color: const Color(0xFF1A1A2E),
                        fontSize: 28.rf,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2.rh),
                    Text(
                      '留学生实用助手',
                      style: TextStyle(
                        color: const Color(0xFF9999B3),
                        fontSize: 13.rf,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 20.rh),

          // ── 节假日卡片 ─────────────────────────────────────────────────
          Padding(
            padding: REdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _HolidayCard(),
          ),

          // ── 留学工具 ────────────────────────────────────────────────────
          Padding(
            padding: REdgeInsets.fromLTRB(20, 28, 20, 14),
            child: Text(
              '留学工具',
              style: TextStyle(
                color: const Color(0xFF999AB5),
                fontSize: 12.rf,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),

          Padding(
            padding: REdgeInsets.fromLTRB(16, 0, 16, 0),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12.rw,
              mainAxisSpacing: 12.rh,
              childAspectRatio: 1.05,
              children: const [
                _ToolCard(
                  title: '时差时钟',
                  sub: '多城市时间对比',
                  color: Color(0xFF5B6CF8),
                  icon: Icons.public_rounded,
                  tag: 'worldclock',
                ),
                _ToolCard(
                  title: '汇率换算',
                  sub: '实时人民币汇率',
                  color: Color(0xFF2ECC9A),
                  icon: Icons.currency_exchange_rounded,
                  tag: 'currency',
                ),
                _ToolCard(
                  title: '急救电话',
                  sub: '留学常用号码',
                  color: Color(0xFFE53935),
                  icon: Icons.emergency_rounded,
                  tag: 'emergency',
                ),
                _ToolCard(
                  title: '速度测试',
                  sub: '带宽 · 延迟测速',
                  color: Color(0xFF26C6DA),
                  icon: Icons.speed_rounded,
                  tag: 'speedtest',
                ),
              ],
              // 留学工具：全部免费，无需登录
            ),
          ),

          // ── 网络工具 ────────────────────────────────────────────────────
          Padding(
            padding: REdgeInsets.fromLTRB(20, 28, 20, 14),
            child: Text(
              '网络工具',
              style: TextStyle(
                color: const Color(0xFF999AB5),
                fontSize: 12.rf,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),

          Padding(
            padding: REdgeInsets.fromLTRB(16, 0, 16, 0),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12.rw,
              mainAxisSpacing: 12.rh,
              childAspectRatio: 1.05,
              children: const [
                _ToolCard(
                  title: '测速记录',
                  sub: '历史速度报告',
                  color: Color(0xFF9B6FFF),
                  icon: Icons.history_rounded,
                  tag: 'traffic',
                  requiresVip: true,
                ),
                _ToolCard(
                  title: '网络诊断',
                  sub: '延迟 · DNS 检测',
                  color: Color(0xFFFF7043),
                  icon: Icons.wifi_tethering_rounded,
                  tag: 'netdiag',
                  requiresVip: true,
                ),
              ],
            ),
          ),

          // ── 增值功能 ────────────────────────────────────────────────────
          Padding(
            padding: REdgeInsets.fromLTRB(20, 28, 20, 14),
            child: Text(
              '增值功能',
              style: TextStyle(
                color: const Color(0xFF999AB5),
                fontSize: 12.rf,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),

          Padding(
            padding: REdgeInsets.fromLTRB(16, 0, 16, 0),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12.rw,
              mainAxisSpacing: 12.rh,
              childAspectRatio: 1.05,
              children: const [
                _ToolCard(
                  title: '签证提醒',
                  sub: '到期倒计时 · 推送通知',
                  color: Color(0xFF5969FF),
                  icon: Icons.document_scanner_rounded,
                  tag: 'visa',
                  requiresVip: true,
                ),
                _ToolCard(
                  title: '转账比价',
                  sub: 'Wise · 支付宝 · 银行',
                  color: Color(0xFF2ECC9A),
                  icon: Icons.compare_arrows_rounded,
                  tag: 'remit',
                  requiresVip: true,
                ),
                _ToolCard(
                  title: '省钱手册',
                  sub: '学生优惠 · 退税攻略',
                  color: Color(0xFFFF7043),
                  icon: Icons.local_offer_rounded,
                  tag: 'saving',
                  requiresVip: true,
                ),
                _ToolCard(
                  title: '打工计算器',
                  sub: '时薪 · 税后收入估算',
                  color: Color(0xFFFFB300),
                  icon: Icons.calculate_rounded,
                  tag: 'work',
                  requiresVip: true,
                ),
              ],
            ),
          ),

          SizedBox(height: 16.rh),
                ],
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// ── 节假日卡片（大卡片，内容丰富）────────────────────────────────────────────

class _HolidayCard extends StatelessWidget {
  const _HolidayCard();

  @override
  Widget build(BuildContext context) {
    final next = GchHolidayData.nextHoliday();
    if (next == null) return const SizedBox.shrink();

    final days = GchHolidayData.daysUntil(next);
    final isToday = days == 0;

    return GestureDetector(
      onTap: () {
        GchUmengSvc.onToolHolidayTap();
        const NavHolidayRoute().go(context);
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5B6CF8), Color(0xFF9B6FFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.rr),
        ),
        child: Stack(
          children: [
            // 装饰圆
            Positioned(
              right: -30.rw,
              top: -30.rh,
              child: Container(
                width: 140.ri,
                height: 140.ri,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 40.rw,
              bottom: -20.rh,
              child: Container(
                width: 80.ri,
                height: 80.ri,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            Padding(
              padding: REdgeInsets.fromLTRB(22, 22, 22, 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧内容
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标签
                        Container(
                          padding: REdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20.rr),
                          ),
                          child: Text(
                            '节假日',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.rf,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 14.rh),

                        // 主内容
                        if (!isToday) ...[
                          Text(
                            '距 ${next.name} 还有',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13.rf,
                            ),
                          ),
                          SizedBox(height: 4.rh),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$days',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 52.rf,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                  letterSpacing: -2,
                                ),
                              ),
                              SizedBox(width: 6.rw),
                              Padding(
                                padding: EdgeInsets.only(bottom: 6.rh),
                                child: Text(
                                  '天',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 20.rf,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            '今天是',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13.rf,
                            ),
                          ),
                          SizedBox(height: 6.rh),
                          Text(
                            next.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28.rf,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 4.rh),
                          Text(
                            '祝你节日快乐 🎉',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13.rf,
                            ),
                          ),
                        ],

                        SizedBox(height: 14.rh),

                        // 日期 + 农历
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 12.ri,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            SizedBox(width: 5.rw),
                            Text(
                              _dateStr(next.date, next.lunarDesc),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 12.rf,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 8.rh),

                        // 查看全年
                        Row(
                          children: [
                            Text(
                              '查看全年节假日',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12.rf,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 3.rw),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10.ri,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 右侧 emoji
                  Column(
                    children: [
                      SizedBox(height: 8.rh),
                      Text(next.emoji, style: TextStyle(fontSize: 64.rf)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateStr(DateTime date, String lunar) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final base = '${date.year}年$m月$d日';
    return lunar.isEmpty ? base : '$base · $lunar';
  }
}

// ── 工具卡片 ──────────────────────────────────────────────────────────────────

class _ToolCard extends ConsumerWidget {
  final String title;
  final String sub;
  final Color color;
  final IconData icon;
  final String tag;
  final bool requiresVip;

  const _ToolCard({
    required this.title,
    required this.sub,
    required this.color,
    required this.icon,
    required this.tag,
    this.requiresVip = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isLocked =
        requiresVip && (user == null || !user.currentVip.canAccess(VipType.basic));

    return GestureDetector(
      onTap: () => _onTap(context, ref, isLocked, user),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.rr),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isLocked ? 0.05 : 0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: REdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 图标 + 右上角锁标
            Stack(
              children: [
                Container(
                  width: 44.ri,
                  height: 44.ri,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isLocked ? 0.07 : 0.12),
                    borderRadius: BorderRadius.circular(13.rr),
                  ),
                  child: Icon(icon,
                      color: color.withValues(alpha: isLocked ? 0.4 : 1.0),
                      size: 22.ri),
                ),
                if (isLocked)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16.ri,
                      height: 16.ri,
                      decoration: BoxDecoration(
                        color: requiresVip
                            ? const Color(0xFFFFAB40)
                            : const Color(0xFF5969FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        requiresVip ? Icons.star_rounded : Icons.lock_rounded,
                        size: 9.ri,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isLocked
                        ? const Color(0xFF9999B3)
                        : const Color(0xFF1A1A2E),
                    fontSize: 14.rf,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3.rh),
                Text(
                  isLocked
                      ? (requiresVip ? '会员专属' : '登录后使用')
                      : sub,
                  style: TextStyle(
                    color: isLocked
                        ? (requiresVip
                            ? const Color(0xFFFFAB40)
                            : const Color(0xFF5969FF))
                        : const Color(0xFF9999B3),
                    fontSize: 11.rf,
                    fontWeight:
                        isLocked ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context, WidgetRef ref, bool isLocked, dynamic user) {
    GchUmengSvc.onToolItemTap(tag);

    if (isLocked) {
      _showAccessSheet(context, user == null);
      return;
    }

    // 速度测试直接切换到测速 tab
    if (tag == 'speedtest') {
      context.go(const NavMainHomeRoute().location);
      return;
    }
    // 留学工具走 go_router 子路由
    switch (tag) {
      case 'worldclock':
        context.go('/nav/tool/worldclock');
        return;
      case 'currency':
        context.go('/nav/tool/currency');
        return;
      case 'emergency':
        context.go('/nav/tool/emergency');
        return;
    }
    // 网络工具 + 增值功能 走 Navigator.push
    final Widget page = switch (tag) {
      'traffic' => const TrafficPage(),
      'netdiag' => const NetDiagPage(),
      'history' => const HistoryPage(),
      'visa'    => const GchVisaPage(),
      'remit'   => const GchRemitPage(),
      'saving'  => const GchSavingPage(),
      'work'    => const GchWorkPage(),
      _ => const SizedBox.shrink(),
    };
    final String routeName = switch (tag) {
      'traffic' => 'ToolTraffic',
      'netdiag' => 'ToolNetDiag',
      'history' => 'ToolHistory',
      'visa'    => 'ToolVisa',
      'remit'   => 'ToolRemit',
      'saving'  => 'ToolSaving',
      'work'    => 'ToolWork',
      _ => 'ToolUnknown',
    };
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => page,
        settings: RouteSettings(name: routeName),
      ),
    );
  }

  void _showAccessSheet(BuildContext context, bool needsLogin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccessSheet(
        title: title,
        icon: icon,
        color: color,
        needsLogin: needsLogin,
      ),
    );
  }
}

// ── 权限引导弹窗 ───────────────────────────────────────────────────────────────

class _AccessSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool needsLogin;

  const _AccessSheet({
    required this.title,
    required this.icon,
    required this.color,
    required this.needsLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: REdgeInsets.fromLTRB(12, 0, 12, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.rr),
      ),
      padding: REdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64.ri,
            height: 64.ri,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32.ri),
          ),
          SizedBox(height: 16.rh),
          Text(
            needsLogin ? '登录后使用「$title」' : '升级会员解锁「$title」',
            style: TextStyle(
              color: const Color(0xFF1A1A2E),
              fontSize: 17.rf,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.rh),
          Text(
            needsLogin
                ? '登录账号即可免费使用此功能'
                : '成为会员，解锁全部网络工具，畅享留学生活',
            style: TextStyle(
              color: const Color(0xFF9999B3),
              fontSize: 13.rf,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.rh),
          SizedBox(
            width: double.infinity,
            height: 50.rh,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: needsLogin
                    ? const Color(0xFF5969FF)
                    : const Color(0xFFFFAB40),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.rr),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                if (needsLogin) {
                  context.go('/nav/login');
                } else {
                  context.go('/nav/checkout');
                }
              },
              child: Text(
                needsLogin ? '立即登录' : '立即升级会员',
                style: TextStyle(
                  fontSize: 16.rf,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(height: 10.rh),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '暂不',
              style: TextStyle(
                color: const Color(0xFF9999B3),
                fontSize: 14.rf,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
