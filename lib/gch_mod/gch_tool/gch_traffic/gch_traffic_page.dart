import 'package:flutter/material.dart';
import 'package:guichao/gch_aux/gch_num_fmt.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:guichao/gch_mod/gch_tool/gch_traffic/gch_speed_record.dart';
import 'package:guichao/gch_mod/gch_tool/gch_traffic/gch_speed_history_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

class _C {
  static const Color bg = Color(0xFFF5F4FC);
  static const Color card = Colors.white;
  static const Color primary = Color(0xFF1A1A2E);
  static const Color secondary = Color(0xFF666680);
  static const Color tertiary = Color(0xFF9999B3);
  static const Color accent = Color(0xFF5969FF);
  static const Color green = Color(0xFF3DD68C);
  static const Color orange = Color(0xFFFF9A3E);
}

class TrafficPage extends ConsumerWidget {
  const TrafficPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(gchSpeedHistoryProvider);
    final count = history.length;
    final bestBps = count > 0
        ? history.map((r) => r.peakBps).reduce((a, b) => a > b ? a : b)
        : 0;
    final avgBps = count > 0
        ? (history.map((r) => r.avgBps).reduce((a, b) => a + b) / count)
            .round()
        : 0;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: const Color(0xFF333333), size: 20.ri),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '测速记录',
          style: TextStyle(
            color: const Color(0xFF333333),
            fontSize: 18.rf,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (count > 0)
            TextButton(
              onPressed: () => _confirmClear(context, ref),
              child: Text(
                '清除',
                style: TextStyle(color: _C.accent, fontSize: 14.rf),
              ),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: 8.rh)),
          SliverToBoxAdapter(
            child: Padding(
              padding: REdgeInsets.symmetric(horizontal: 20),
              child: _SummaryCard(
                  count: count, bestBps: bestBps, avgBps: avgBps),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 24.rh)),
          if (history.isEmpty)
            const SliverFillRemaining(child: _EmptyState())
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: REdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Text(
                  '历史记录',
                  style: TextStyle(
                    color: const Color(0xFF999AB5),
                    fontSize: 12.rf,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: REdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: EdgeInsets.only(bottom: 10.rh),
                    child: _SpeedCard(record: history[i]),
                  ),
                  childCount: history.length,
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(child: SizedBox(height: 100.rh)),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('清除记录'),
        content: const Text('确定要清除所有测速记录吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('清除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(gchSpeedHistoryProvider.notifier).clearAll();
    }
  }
}

// ── 汇总卡片 ───────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final int count;
  final int bestBps;
  final int avgBps;
  const _SummaryCard(
      {required this.count, required this.bestBps, required this.avgBps});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: REdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5969FF), Color(0xFF9B6FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.rr),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5969FF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: REdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20.rr),
                ),
                child: Text(
                  '测速统计',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.rf,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              Icon(Icons.speed_rounded,
                  color: Colors.white.withValues(alpha: 0.6), size: 20.ri),
            ],
          ),
          SizedBox(height: 20.rh),
          Row(
            children: [
              Expanded(
                  child: _SummaryItem(label: '测速次数', value: '$count 次')),
              Container(
                  width: 1,
                  height: 40.rh,
                  color: Colors.white.withValues(alpha: 0.2)),
              Expanded(
                  child:
                      _SummaryItem(label: '最佳下载', value: bestBps.speed())),
              Container(
                  width: 1,
                  height: 40.rh,
                  color: Colors.white.withValues(alpha: 0.2)),
              Expanded(
                  child:
                      _SummaryItem(label: '平均下载', value: avgBps.speed())),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.rf,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 4.rh),
        Text(
          label,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7), fontSize: 11.rf),
        ),
      ],
    );
  }
}

// ── 空状态 ─────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80.ri,
            height: 80.ri,
            decoration: BoxDecoration(
              color: _C.accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.speed_rounded,
                size: 40.ri, color: _C.accent.withValues(alpha: 0.4)),
          ),
          SizedBox(height: 20.rh),
          Text(
            '暂无测速记录',
            style: TextStyle(
              color: _C.primary,
              fontSize: 16.rf,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.rh),
          Text(
            '去"测速"标签页进行一次测试吧',
            style: TextStyle(color: _C.tertiary, fontSize: 13.rf),
          ),
        ],
      ),
    );
  }
}

// ── 单条记录卡片 ───────────────────────────────────────────────────────────────

class _SpeedCard extends StatelessWidget {
  final GchSpeedRecord record;
  const _SpeedCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MM-dd HH:mm');

    return Container(
      padding: REdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16.rr),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42.ri,
            height: 42.ri,
            decoration: BoxDecoration(
              color: _C.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.rr),
            ),
            child: Icon(Icons.speed_rounded, color: _C.accent, size: 22.ri),
          ),
          SizedBox(width: 12.rw),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fmt.format(record.time),
                  style: TextStyle(
                    color: _C.primary,
                    fontSize: 13.rf,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3.rh),
                Text(
                  '下载 ${record.totalBytes.size()}',
                  style: TextStyle(color: _C.tertiary, fontSize: 11.rf),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.arrow_downward_rounded,
                      size: 11.ri, color: _C.green),
                  SizedBox(width: 3.rw),
                  Text(
                    record.peakBps.speed(),
                    style: TextStyle(
                      color: _C.green,
                      fontSize: 13.rf,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (record.pingMs > 0) ...[
                SizedBox(height: 4.rh),
                Row(
                  children: [
                    Icon(Icons.network_ping_rounded,
                        size: 11.ri, color: _C.orange),
                    SizedBox(width: 3.rw),
                    Text(
                      '${record.pingMs} ms',
                      style: TextStyle(
                        color: _C.orange,
                        fontSize: 11.rf,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
