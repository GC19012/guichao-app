import 'package:flutter/material.dart';
import 'package:guichao/gch_aux/gch_num_fmt.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:guichao/gch_mod/gch_tool/gch_traffic/gch_session_history_notifier.dart';
import 'package:guichao/gch_mod/gch_tool/gch_traffic/gch_session_record.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

class _C {
  static const Color bg = Color(0xFFF5F4FC);
  static const Color card = Colors.white;
  static const Color primary = Color(0xFF1A1A2E);
  static const Color secondary = Color(0xFF666680);
  static const Color tertiary = Color(0xFF9999B3);
  static const Color down = Color(0xFF3DD68C);
  static const Color up = Color(0xFF7C5CFF);
  static const Color accent = Color(0xFF5969FF);
}

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(gchSessionHistoryNotifierProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: const Color(0xFF333333), size: 20.ri),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '连接历史',
          style: TextStyle(color: const Color(0xFF333333), fontSize: 18.rf, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        actions: sessions.isEmpty
            ? null
            : [
                Center(
                  child: Text(
                    '共 ${sessions.length} 条',
                    style: TextStyle(color: _C.tertiary, fontSize: 13.rf),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_sweep_rounded,
                      color: _C.tertiary, size: 20.ri),
                  tooltip: '清空记录',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('清空连接历史'),
                        content: const Text('确定要删除全部连接记录吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(gchSessionHistoryNotifierProvider.notifier)
                                  .clearAll();
                              Navigator.of(context).pop();
                            },
                            child: Text('清空',
                                style: TextStyle(color: _C.accent)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(width: 4.rw),
              ],
      ),
      body: sessions.isEmpty
          ? const _EmptyState()
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: REdgeInsets.fromLTRB(20, 16, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: EdgeInsets.only(bottom: 10.rh),
                        child: _SessionCard(record: sessions[i], index: i),
                      ),
                      childCount: sessions.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final GchSessionRecord record;
  final int index;
  const _SessionCard({required this.record, required this.index});

  @override
  Widget build(BuildContext context) {
    final dur = record.duration;
    final durStr = dur.inHours > 0
        ? '${dur.inHours}h ${dur.inMinutes.remainder(60)}m'
        : dur.inMinutes > 0
            ? '${dur.inMinutes}m ${dur.inSeconds.remainder(60)}s'
            : '${dur.inSeconds}s';

    final startFmt = DateFormat('MM-dd HH:mm').format(record.startTime);
    final endFmt = DateFormat('HH:mm').format(record.endTime);

    return Container(
      padding: REdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16.rr),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间行
          Row(
            children: [
              Container(
                width: 32.ri,
                height: 32.ri,
                decoration: BoxDecoration(
                  color: _C.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.wifi_rounded, size: 16.ri, color: _C.accent),
              ),
              SizedBox(width: 10.rw),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$startFmt – $endFmt',
                      style: TextStyle(
                        color: _C.primary,
                        fontSize: 14.rf,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.rh),
                    Text(
                      '时长 $durStr',
                      style: TextStyle(color: _C.secondary, fontSize: 12.rf),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.rh),
          // 流量行
          Container(
            padding: REdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8FC),
              borderRadius: BorderRadius.circular(10.rr),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TrafficItem(
                  label: '下载',
                  value: record.downTotal.size(),
                  color: _C.down,
                  icon: Icons.arrow_downward_rounded,
                ),
                Container(width: 1, height: 28.rh, color: const Color(0xFFEEEEEE)),
                _TrafficItem(
                  label: '上传',
                  value: record.upTotal.size(),
                  color: _C.up,
                  icon: Icons.arrow_upward_rounded,
                ),
                Container(width: 1, height: 28.rh, color: const Color(0xFFEEEEEE)),
                _TrafficItem(
                  label: '合计',
                  value: (record.downTotal + record.upTotal).size(),
                  color: _C.tertiary,
                  icon: Icons.swap_vert_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrafficItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _TrafficItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12.ri, color: color),
            SizedBox(width: 3.rw),
            Text(
              label,
              style: TextStyle(color: _C.tertiary, fontSize: 11.rf),
            ),
          ],
        ),
        SizedBox(height: 4.rh),
        Text(
          value,
          style: TextStyle(
            color: _C.primary,
            fontSize: 13.rf,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 56.ri, color: const Color(0xFFDDDDDD)),
          SizedBox(height: 16.rh),
          Text(
            '暂无连接记录',
            style: TextStyle(
              color: const Color(0xFF999999),
              fontSize: 16.rf,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.rh),
          Text(
            '每次断开连接后自动保存',
            style: TextStyle(color: const Color(0xFFBBBBBB), fontSize: 13.rf),
          ),
        ],
      ),
    );
  }
}
