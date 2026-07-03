import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:guichao/gch_base/gch_umeng/gch_umeng_svc.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class _C {
  static const Color bg = Color(0xFFF1F7FF);
  static const Color card = Colors.white;
  static const Color primary = Color(0xFF1A1A2E);
  static const Color secondary = Color(0xFF666680);
  static const Color tertiary = Color(0xFF9999B3);
  static const Color accent = Color(0xFF0088E0);
  static const Color pass = Color(0xFF3DD68C);
  static const Color fail = Color(0xFFFF4D6D);
  static const Color pending = Color(0xFFFFAA00);
}

enum _CheckStatus { idle, running, pass, fail }

class _DiagResult {
  final String name;
  final String detail;
  final String? subDetail;
  final _CheckStatus status;
  const _DiagResult(this.name, this.detail, this.status, {this.subDetail});
}

// 5 个步骤的初始占位名称（idle）
const _kSteps = [
  '网络连通性',
  'DNS 解析',
  '国内节点延迟',
  '境外节点延迟',
  '服务连通性',
];

List<_DiagResult> _idleSlots() => _kSteps
    .map((n) => _DiagResult(n, '等待检测', _CheckStatus.idle))
    .toList();

// ── 真实诊断逻辑 ──────────────────────────────────────────────────────────────

Future<_DiagResult> _checkConnectivity() async {
  try {
    final results = await Connectivity().checkConnectivity();
    final hasWifi = results.contains(ConnectivityResult.wifi);
    final hasCellular = results.contains(ConnectivityResult.mobile);
    final hasEthernet = results.contains(ConnectivityResult.ethernet);
    final hasAny = hasWifi ||
        hasCellular ||
        hasEthernet ||
        results.any((r) => r != ConnectivityResult.none);

    if (!hasAny) {
      return const _DiagResult('网络连通性', '无网络连接', _CheckStatus.fail);
    }

    String? localIp;
    try {
      final interfaces =
          await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            localIp = addr.address;
            break;
          }
        }
        if (localIp != null) break;
      }
    } catch (_) {}

    bool tcpOk = false;
    try {
      final socket = await Socket.connect('223.5.5.5', 53,
          timeout: const Duration(seconds: 2));
      socket.destroy();
      tcpOk = true;
    } catch (_) {}

    final type = hasWifi ? 'WiFi' : (hasCellular ? '移动数据' : '以太网');
    final detail = tcpOk ? '$type 连接正常 · TCP 已验证' : '$type 连接正常';
    return _DiagResult('网络连通性', detail, _CheckStatus.pass,
        subDetail: localIp != null ? '本地 IP: $localIp' : null);
  } catch (_) {
    return const _DiagResult('网络连通性', '检测失败', _CheckStatus.fail);
  }
}

Future<_DiagResult> _checkDns() async {
  const host = 'api.example.com';
  final sw = Stopwatch()..start();
  try {
    final addresses =
        await InternetAddress.lookup(host).timeout(const Duration(seconds: 4));
    sw.stop();
    if (addresses.isEmpty) {
      return const _DiagResult('DNS 解析', '解析结果为空', _CheckStatus.fail);
    }
    final ip = addresses.first.address;
    return _DiagResult(
      'DNS 解析',
      '解析成功 · ${sw.elapsedMilliseconds} ms',
      _CheckStatus.pass,
      subDetail: '→ $ip',
    );
  } on TimeoutException {
    return const _DiagResult('DNS 解析', '解析超时 (>4000 ms)', _CheckStatus.fail);
  } catch (_) {
    return const _DiagResult('DNS 解析', '解析失败', _CheckStatus.fail);
  }
}

Future<_DiagResult> _checkDomesticLatency() async {
  const targets = [
    ('223.5.5.5', 53, '阿里 DNS'),
    ('114.114.114.114', 53, '国内 DNS'),
  ];
  final items = <(String, int?)>[];
  for (final (host, port, label) in targets) {
    final sw = Stopwatch()..start();
    try {
      final socket = await Socket.connect(host, port,
          timeout: const Duration(seconds: 3));
      sw.stop();
      socket.destroy();
      items.add((label, sw.elapsedMilliseconds));
    } catch (_) {
      items.add((label, null));
    }
  }
  final reachable = items.where((r) => r.$2 != null).toList();
  if (reachable.isEmpty) {
    return const _DiagResult('国内节点延迟', '节点不可达', _CheckStatus.fail);
  }
  final avg =
      reachable.map((r) => r.$2!).reduce((a, b) => a + b) ~/ reachable.length;
  final quality =
      avg < 50 ? '极低' : avg < 100 ? '良好' : avg < 200 ? '一般' : '较高';
  final sub = items
      .map((r) => r.$2 != null ? '${r.$1}: ${r.$2}ms' : '${r.$1}: 超时')
      .join(' · ');
  return _DiagResult('国内节点延迟', '均值 ${avg}ms · 延迟$quality',
      _CheckStatus.pass,
      subDetail: sub);
}

Future<_DiagResult> _checkInternationalLatency() async {
  const targets = [
    ('8.8.8.8', 53, 'Google DNS'),
    ('1.1.1.1', 53, 'Cloudflare'),
  ];
  final items = <(String, int?)>[];
  for (final (host, port, label) in targets) {
    final sw = Stopwatch()..start();
    try {
      final socket = await Socket.connect(host, port,
          timeout: const Duration(seconds: 4));
      sw.stop();
      socket.destroy();
      items.add((label, sw.elapsedMilliseconds));
    } catch (_) {
      items.add((label, null));
    }
  }
  final reachable = items.where((r) => r.$2 != null).toList();
  if (reachable.isEmpty) {
    return const _DiagResult('境外节点延迟', '节点不可达', _CheckStatus.fail);
  }
  final avg =
      reachable.map((r) => r.$2!).reduce((a, b) => a + b) ~/ reachable.length;
  final quality =
      avg < 100 ? '良好' : avg < 200 ? '一般' : avg < 400 ? '较高' : '过高';
  final sub = items
      .map((r) => r.$2 != null ? '${r.$1}: ${r.$2}ms' : '${r.$1}: 超时')
      .join(' · ');
  return _DiagResult('境外节点延迟', '均值 ${avg}ms · 延迟$quality',
      _CheckStatus.pass,
      subDetail: sub);
}

Future<_DiagResult> _checkServiceConnectivity() async {
  const host = 'api.example.com';
  const port = 443;
  final sw = Stopwatch()..start();
  try {
    final socket = await Socket.connect(host, port,
        timeout: const Duration(seconds: 5));
    sw.stop();
    socket.destroy();
    return _DiagResult(
      '服务连通性',
      '端口 $port 可达 · ${sw.elapsedMilliseconds} ms',
      _CheckStatus.pass,
      subDetail: '服务器:$port',
    );
  } catch (_) {
    return const _DiagResult(
      '服务连通性',
      '服务不可达',
      _CheckStatus.fail,
      subDetail: '服务器:443',
    );
  }
}

// ── 页面 ──────────────────────────────────────────────────────────────────────

class NetDiagPage extends ConsumerStatefulWidget {
  const NetDiagPage({super.key});

  @override
  ConsumerState<NetDiagPage> createState() => _NetDiagPageState();
}

class _NetDiagPageState extends ConsumerState<NetDiagPage>
    with TickerProviderStateMixin {
  bool _isRunning = false;
  bool _started = false;
  // 5 个槽，空 = 初始，非空 = 诊断后
  List<_DiagResult> _slots = _idleSlots();
  int _currentStep = -1; // 0-4 正在跑，-1 未开始或已完成

  late AnimationController _spinCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // 运行单步并保证至少 minMs 的感知时长
  Future<_DiagResult> _runStep(
      Future<_DiagResult> Function() fn, int minMs) async {
    final t0 = DateTime.now().millisecondsSinceEpoch;
    final result = await fn();
    final spent = DateTime.now().millisecondsSinceEpoch - t0;
    final remain = minMs - spent;
    if (remain > 0) await Future.delayed(Duration(milliseconds: remain));
    return result;
  }

  Future<void> _runDiag() async {
    if (_isRunning) return;
    GchUmengSvc.onToolNetDiagRun();
    setState(() {
      _isRunning = true;
      _started = true;
      _slots = _idleSlots();
      _currentStep = 0;
    });
    _spinCtrl.repeat();

    final checks = <Future<_DiagResult> Function()>[
      _checkConnectivity,
      _checkDns,
      _checkDomesticLatency,
      _checkInternationalLatency,
      _checkServiceConnectivity,
    ];
    // 每步最小感知时长（ms）
    const minDelays = [700, 1000, 950, 1100, 800];

    for (int i = 0; i < checks.length; i++) {
      // 先把当前槽置为 running
      setState(() {
        _currentStep = i;
        _slots = List.from(_slots)
          ..[i] = _DiagResult(_kSteps[i], '正在分析...', _CheckStatus.running);
      });

      final result = await _runStep(checks[i], minDelays[i]);
      if (!mounted) return;

      setState(() {
        _slots = List.from(_slots)..[i] = result;
        _currentStep = i + 1;
      });

      // 步与步之间短暂停顿，增加节奏感
      if (i < checks.length - 1) {
        await Future.delayed(const Duration(milliseconds: 120));
      }
    }

    _spinCtrl.stop();
    if (mounted) {
      setState(() {
        _isRunning = false;
        _currentStep = -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = !_isRunning && _started;
    final allPass =
        done && _slots.every((r) => r.status == _CheckStatus.pass);
    final hasFail = done && _slots.any((r) => r.status == _CheckStatus.fail);
    final passCount =
        _slots.where((r) => r.status == _CheckStatus.pass).length;

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
          '网络诊断',
          style: TextStyle(
              color: const Color(0xFF333333),
              fontSize: 18.rf,
              fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: REdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _HeroCard(
                isRunning: _isRunning,
                started: _started,
                allPass: allPass,
                hasFail: hasFail,
                passCount: passCount,
                totalSteps: _kSteps.length,
                currentStep: _currentStep,
                spinCtrl: _spinCtrl,
                onTap: _runDiag,
              ),
            ),
          ),
          if (_started) ...[
            SliverToBoxAdapter(child: SizedBox(height: 20.rh)),
            SliverToBoxAdapter(
              child: Padding(
                padding: REdgeInsets.symmetric(horizontal: 20),
                child: _ResultList(
                  slots: _slots,
                  currentStep: _currentStep,
                  pulseCtrl: _pulseCtrl,
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(child: SizedBox(height: 100.rh)),
        ],
      ),
    );
  }
}

// ── 主卡片 ────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final bool isRunning;
  final bool started;
  final bool allPass;
  final bool hasFail;
  final int passCount;
  final int totalSteps;
  final int currentStep;
  final AnimationController spinCtrl;
  final VoidCallback onTap;

  const _HeroCard({
    required this.isRunning,
    required this.started,
    required this.allPass,
    required this.hasFail,
    required this.passCount,
    required this.totalSteps,
    required this.currentStep,
    required this.spinCtrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = !isRunning && started;
    final statusColor = isDone
        ? (allPass ? _C.pass : (hasFail ? _C.fail : _C.pending))
        : _C.accent;

    return Container(
      padding: REdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(24.rr),
        boxShadow: [
          BoxShadow(
            color: _C.accent.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── 旋转图标 ──────────────────────────────────────────────────
          SizedBox(
            width: 100.ri,
            height: 100.ri,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100.ri,
                  height: 100.ri,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withValues(alpha: 0.1),
                  ),
                ),
                if (isRunning)
                  AnimatedBuilder(
                    animation: spinCtrl,
                    builder: (_, __) => Transform.rotate(
                      angle: spinCtrl.value * 2 * math.pi,
                      child: Container(
                        width: 90.ri,
                        height: 90.ri,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _C.accent.withValues(alpha: 0.25),
                            width: 2.5,
                          ),
                        ),
                        child: CustomPaint(painter: _ArcPainter(_C.accent)),
                      ),
                    ),
                  ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Icon(
                    isDone
                        ? (allPass
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded)
                        : (isRunning
                            ? Icons.wifi_find_rounded
                            : Icons.wifi_tethering_rounded),
                    key: ValueKey(isRunning ? 'run' : (isDone ? 'done' : 'idle')),
                    size: 44.ri,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.rh),

          // ── 标题 ──────────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              isDone
                  ? (allPass ? '诊断完成 · 网络正常' : '诊断完成 · 发现问题')
                  : (isRunning
                      ? '正在检测 ${currentStep + 1} / $totalSteps'
                      : '点击开始网络诊断'),
              key: ValueKey(isRunning ? currentStep : isDone),
              style: TextStyle(
                color: _C.primary,
                fontSize: 16.rf,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          SizedBox(height: 6.rh),
          Text(
            '检测网络连通性、DNS 解析、节点延迟等指标',
            style: TextStyle(color: _C.secondary, fontSize: 13.rf),
          ),

          // ── 进度条 ────────────────────────────────────────────────────
          if (started) ...[
            SizedBox(height: 16.rh),
            LayoutBuilder(builder: (_, bc) {
              final fraction = totalSteps > 0
                  ? (isDone ? 1.0 : passCount / totalSteps)
                  : 0.0;
              return Container(
                height: 4.rh,
                width: bc.maxWidth,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    width: bc.maxWidth * fraction,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [
                          isDone && hasFail ? _C.fail : _C.accent,
                          isDone && allPass ? _C.pass : _C.accent,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],

          SizedBox(height: started ? 16.rh : 20.rh),

          // ── 按钮 ──────────────────────────────────────────────────────
          GestureDetector(
            onTap: isRunning ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: REdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: isRunning ? const Color(0xFFEEEEEE) : null,
                borderRadius: BorderRadius.circular(50),
                image: isRunning
                    ? null
                    : const DecorationImage(
                        image: AssetImage('assets/gch_pics/gch_e2992f.webp'),
                        fit: BoxFit.cover,
                      ),
              ),
              child: Text(
                isRunning
                    ? '检测中...'
                    : (isDone ? '重新检测' : '一键检测'),
                style: TextStyle(
                  color: isRunning ? _C.tertiary : const Color(0xFF5969FF),
                  fontSize: 15.rf,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 弧形 Painter ──────────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  final Color color;
  const _ArcPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -math.pi / 2,
      math.pi * 0.7,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── 结果列表 ──────────────────────────────────────────────────────────────────

class _ResultList extends StatelessWidget {
  final List<_DiagResult> slots;
  final int currentStep;
  final AnimationController pulseCtrl;

  const _ResultList({
    required this.slots,
    required this.currentStep,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(18.rr),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: slots.asMap().entries.map((e) {
          final idx = e.key;
          final r = e.value;
          final isActive = r.status == _CheckStatus.running;
          final isLast = idx == slots.length - 1;

          return Column(
            children: [
              _DiagRow(
                result: r,
                index: idx,
                isActive: isActive,
                pulseCtrl: pulseCtrl,
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.black.withValues(alpha: 0.05),
                  indent: 20.rw,
                  endIndent: 20.rw,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DiagRow extends StatelessWidget {
  final _DiagResult result;
  final int index;
  final bool isActive;
  final AnimationController pulseCtrl;

  const _DiagRow({
    required this.result,
    required this.index,
    required this.isActive,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(result.status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isActive
            ? _C.accent.withValues(alpha: 0.04)
            : Colors.transparent,
        borderRadius: index == 0
            ? BorderRadius.vertical(top: Radius.circular(18.rr))
            : (index == 4
                ? BorderRadius.vertical(bottom: Radius.circular(18.rr))
                : BorderRadius.zero),
      ),
      padding: REdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧图标
          Padding(
            padding: EdgeInsets.only(top: 1.rh),
            child: SizedBox(
              width: 36.ri,
              height: 36.ri,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: _buildIcon(color),
              ),
            ),
          ),

          SizedBox(width: 12.rw),

          // 右侧文本
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题行：名称 + 右侧 "检测中" 标签
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        result.name,
                        style: TextStyle(
                          color: result.status == _CheckStatus.idle
                              ? _C.tertiary
                              : _C.primary,
                          fontSize: 14.rf,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isActive)
                      AnimatedBuilder(
                        animation: pulseCtrl,
                        builder: (_, __) => Opacity(
                          opacity: 0.5 + 0.5 * pulseCtrl.value,
                          child: Container(
                            padding:
                                REdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _C.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '检测中',
                              style: TextStyle(
                                  color: _C.accent,
                                  fontSize: 10.rf,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // 详情区：AnimatedSize 实现高度动画
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                  alignment: Alignment.topLeft,
                  child: result.status == _CheckStatus.idle
                      ? SizedBox(height: 0, width: double.infinity)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4.rh),
                            Text(
                              result.detail,
                              style: TextStyle(
                                  color: isActive ? _C.accent : _C.secondary,
                                  fontSize: 12.rf),
                            ),
                            if (result.subDetail != null &&
                                !isActive) ...[
                              SizedBox(height: 3.rh),
                              Text(
                                result.subDetail!,
                                style: TextStyle(
                                    color: _C.tertiary, fontSize: 11.rf),
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(Color color) {
    switch (result.status) {
      case _CheckStatus.idle:
        return Container(
          key: const ValueKey('idle'),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF0F0F0),
          ),
          child: Center(
            child: Text(
              '0${index + 1}',
              style: TextStyle(
                  color: _C.tertiary,
                  fontSize: 11.rf,
                  fontWeight: FontWeight.w700),
            ),
          ),
        );
      case _CheckStatus.running:
        return AnimatedBuilder(
          key: const ValueKey('running'),
          animation: pulseCtrl,
          builder: (_, __) => Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.accent.withValues(alpha: 0.1 + 0.1 * pulseCtrl.value),
            ),
            child: Icon(Icons.radar_rounded, size: 18.ri, color: _C.accent),
          ),
        );
      default:
        return Container(
          key: ValueKey(result.status),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
          ),
          child: Icon(
            result.status == _CheckStatus.pass
                ? Icons.check_rounded
                : Icons.close_rounded,
            size: 18.ri,
            color: color,
          ),
        );
    }
  }

  Color _statusColor(_CheckStatus s) => switch (s) {
        _CheckStatus.pass => _C.pass,
        _CheckStatus.fail => _C.fail,
        _CheckStatus.running => _C.accent,
        _CheckStatus.idle => _C.tertiary,
      };
}
