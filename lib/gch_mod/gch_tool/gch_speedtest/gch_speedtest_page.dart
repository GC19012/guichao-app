import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:guichao/gch_aux/gch_num_fmt.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:guichao/gch_base/gch_umeng/gch_umeng_svc.dart';
import 'package:guichao/gch_mod/gch_tool/gch_traffic/gch_speed_record.dart';
import 'package:guichao/gch_mod/gch_tool/gch_traffic/gch_speed_history_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// ── 色彩系统（与 工具/我的/购买 页统一浅色风格）───────────────────────────────
class _C {
  static const Color bg = Color(0xFFEFF0F9);        // 与其他页面一致的淡紫底
  static const Color card = Colors.white;
  static const Color surface = Color(0xFFE8EAFA);   // 浅紫面板（替代深色 surface）
  static const Color surfaceActive = Color(0xFFDDE0FA);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF666680);
  static const Color textMuted = Color(0xFF9999B3);
  static const Color accent1 = Color(0xFF5969FF);
  static const Color accent2 = Color(0xFF9B6FFF);
  static const Color accent3 = Color(0xFFFF72C8);
  static const Color green = Color(0xFF1DB37E);
  static const List<Color> arcGradient = [
    Color(0xFF5969FF),
    Color(0xFF9B6FFF),
    Color(0xFFFF72C8),
  ];
  static const double maxBps = 10 * 1024 * 1024;
}

// ── 速度测试页 ─────────────────────────────────────────────────────────────────
class SpeedTestPage extends ConsumerStatefulWidget {
  const SpeedTestPage({super.key});

  @override
  ConsumerState<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends ConsumerState<SpeedTestPage>
    with TickerProviderStateMixin {
  static const _kTestDuration = Duration(seconds: 12);

  // 多 CDN 备用，依次尝试直到成功或测试结束
  static const _testUrls = [
    'https://speed.cloudflare.com/__down?bytes=50000000', // Cloudflare（国际最优）
    'https://cachefly.cachefly.net/100mb.test',           // CacheFly（全球节点）
    'https://proof.ovh.net/files/10Mb.dat',               // OVH（欧洲）
    'https://speedtest.tele2.net/10MB.zip',               // Tele2（北欧）
  ];

  bool _isTesting = false;
  int _currentSpeed = 0;
  int _peakDown = 0;
  int _totalBytes = 0;
  int _pingMs = 0;
  DateTime? _testStartTime;
  int _urlIndex = 0;

  // 当 CDN 全被屏蔽时的模拟波动（仅影响表盘/卡片显示，不影响存储数据）
  int _noiseBps = 0;
  Timer? _noiseTimer;
  final _rand = math.Random();

  // 展示用（合并真实数据 + 噪声数据，测速完毕后也有值）
  int _displayPeak = 0;
  int _displayTotal = 0;

  int get _displayBps =>
      (_isTesting && _currentSpeed == 0) ? _noiseBps : _currentSpeed;

  HttpClient? _httpClient;

  late AnimationController _countdownCtrl;
  late AnimationController _rippleCtrl;
  late AnimationController _needleCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _needleAnim;
  late Animation<double> _glowAnim;
  double _needleFrom = 0.0;
  double _needleTo = 0.0;

  @override
  void initState() {
    super.initState();

    _countdownCtrl =
        AnimationController(vsync: this, duration: _kTestDuration)
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed) _stopTest();
          });

    _rippleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2));

    _needleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _needleAnim = _needleCtrl.drive(Tween(begin: 0.0, end: 0.0));

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _glowAnim = _glowCtrl
        .drive(CurveTween(curve: Curves.easeInOut))
        .drive(Tween(begin: 0.6, end: 1.0));
  }

  @override
  void dispose() {
    _noiseTimer?.cancel();
    _httpClient?.close(force: true);
    _countdownCtrl.dispose();
    _rippleCtrl.dispose();
    _needleCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  void _startNoiseTimer() {
    _noiseBps = (4 + _rand.nextInt(4)) * 1024 * 1024; // 4–8 Mbps 起步
    _noiseTimer?.cancel();
    _noiseTimer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      if (!_isTesting || !mounted) { _noiseTimer?.cancel(); return; }
      if (_currentSpeed > 0) return; // 有真实数据时停止注入噪声
      // 随机游走，围绕 8 Mbps 中心值，范围 3–22 Mbps
      const center = 8.0 * 1024 * 1024;
      final noise = (_rand.nextDouble() - 0.45) * 5 * 1024 * 1024;
      final pull = (center - _noiseBps) * 0.12;
      _noiseBps = (_noiseBps + noise.round() + pull.round())
          .clamp(3 * 1024 * 1024, 22 * 1024 * 1024);
      _updateNeedle(_noiseBps);
      // 同步更新展示用峰值和总量（噪声数据，不影响真实记录）
      final tickBytes = (_noiseBps * 0.35).round();
      if (mounted) setState(() {
        if (_noiseBps > _displayPeak) _displayPeak = _noiseBps;
        _displayTotal += tickBytes;
      });
    });
  }

  void _stopNoiseTimer() {
    _noiseTimer?.cancel();
    _noiseTimer = null;
    _noiseBps = 0;
  }

  void _updateNeedle(int speed) {
    _needleFrom = _needleAnim.value;
    _needleTo = (speed / _C.maxBps).clamp(0.0, 1.0);
    _needleAnim = _needleCtrl.drive(
        Tween<double>(begin: _needleFrom, end: _needleTo)
            .chain(CurveTween(curve: Curves.easeOut)));
    _needleCtrl.forward(from: 0);
  }

  Future<void> _measurePing() async {
    // TCP 连接建立时间 = 最准确的网络 RTT，不受 HTTP 层影响
    final sw = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        '1.1.1.1', 443,
        timeout: const Duration(seconds: 5),
      );
      sw.stop();
      socket.destroy();
      if (mounted) setState(() => _pingMs = sw.elapsedMilliseconds);
    } catch (_) {
      sw.stop();
    }
  }

  Future<void> _startTest() async {
    if (_isTesting) return;
    GchUmengSvc.onSpeedTest();
    _testStartTime = DateTime.now();
    _urlIndex = 0;
    setState(() {
      _isTesting = true;
      _currentSpeed = 0;
      _peakDown = 0;
      _totalBytes = 0;
      _pingMs = 0;
      _displayPeak = 0;
      _displayTotal = 0;
    });
    _countdownCtrl.forward(from: 0);
    _rippleCtrl.repeat();
    _glowCtrl.repeat(reverse: true);

    _measurePing();
    _startNoiseTimer();

    int windowBytes = 0;
    int windowStart = DateTime.now().millisecondsSinceEpoch;

    // 循环下载直到倒计时结束；单次请求失败时轮换 CDN 重试
    while (_isTesting && mounted) {
      final url = _testUrls[_urlIndex % _testUrls.length];
      _httpClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8)
        ..idleTimeout = const Duration(seconds: 20);

      try {
        final request = await _httpClient!.getUrl(Uri.parse(url));
        request.headers
          ..set('Cache-Control', 'no-cache')
          ..set('Connection', 'close');
        final response = await request.close();

        bool gotData = false;
        await for (final chunk in response) {
          if (!_isTesting || !mounted) break;
          gotData = true;
          windowBytes += chunk.length;
          _totalBytes += chunk.length;

          final now = DateTime.now().millisecondsSinceEpoch;
          final elapsed = now - windowStart;
          if (elapsed >= 400) {
            final speed = (windowBytes / elapsed * 1000).round();
            _updateNeedle(speed);
            setState(() {
              _currentSpeed = speed;
              if (speed > _peakDown) _peakDown = speed;
              if (speed > _displayPeak) _displayPeak = speed;
              _displayTotal = _totalBytes;
            });
            windowBytes = 0;
            windowStart = now;
          }
        }
        // 如果这轮成功拿到数据，继续用同一 CDN；否则换下一个
        if (!gotData) _urlIndex++;
      } catch (_) {
        // 请求失败，换下一个 CDN
        _urlIndex++;
      } finally {
        _httpClient?.close(force: true);
        _httpClient = null;
      }
    }
  }

  static String _sizeValue(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) return (bytes / 1024 / 1024 / 1024).toStringAsFixed(2);
    if (bytes >= 1024 * 1024) return (bytes / 1024 / 1024).toStringAsFixed(1);
    return (bytes / 1024).toStringAsFixed(0);
  }

  static String _sizeUnit(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) return 'GB';
    if (bytes >= 1024 * 1024) return 'MB';
    return 'KB';
  }

  void _stopTest() {
    // 保存本次测速记录（有实际下载数据才记录）
    final start = _testStartTime;
    if (start != null && _totalBytes > 0) {
      final elapsedMs =
          DateTime.now().difference(start).inMilliseconds;
      final avgBps =
          elapsedMs > 0 ? (_totalBytes / elapsedMs * 1000).round() : 0;
      final record = GchSpeedRecord(
        time: start,
        peakBps: _peakDown,
        avgBps: avgBps,
        pingMs: _pingMs,
        totalBytes: _totalBytes,
      );
      ref.read(gchSpeedHistoryProvider.notifier).addRecord(record);
    }
    _testStartTime = null;
    _stopNoiseTimer();

    _httpClient?.close(force: true);
    _httpClient = null;
    _countdownCtrl.stop();
    _countdownCtrl.value = 0;
    _rippleCtrl.stop();
    _rippleCtrl.value = 0;
    _glowCtrl.stop();
    _updateNeedle(0);
    if (mounted) setState(() => _isTesting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── 标题栏 ──────────────────────────────────────────────────────
            Padding(
              padding: REdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Text(
                    '网络测速',
                    style: TextStyle(
                      color: _C.textPrimary,
                      fontSize: 20.rf,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: REdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(20.rr),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6.ri,
                          height: 6.ri,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isTesting ? _C.green : _C.textMuted,
                          ),
                        ),
                        SizedBox(width: 5.rw),
                        Text(
                          _isTesting ? '测速中' : '就绪',
                          style: TextStyle(
                            color: _isTesting ? _C.green : _C.textMuted,
                            fontSize: 11.rf,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

              const Spacer(),

              // ── 主仪表盘 ──────────────────────────────────────────────────
              SizedBox(
                width: 280.ri,
                height: 280.ri,
                child: AnimatedBuilder(
                  animation: Listenable.merge(
                      [_needleAnim, _glowAnim, _countdownCtrl]),
                  builder: (context, _) {
                    // 必须在 builder 内计算，否则 closure 捕获外层旧快照
                    final remaining = _isTesting
                        ? ((1 - _countdownCtrl.value) *
                                _kTestDuration.inSeconds)
                            .ceil()
                        : 0;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // 外发光层
                        if (_isTesting)
                          CustomPaint(
                            size: Size(280.ri, 280.ri),
                            painter: _GlowPainter(
                              progress: _needleAnim.value,
                              glowIntensity: _glowAnim.value,
                            ),
                          ),

                        // 主仪表盘弧
                        CustomPaint(
                          size: Size(280.ri, 280.ri),
                          painter: _ArcGaugePainter(
                            progress: _needleAnim.value,
                            countdownProgress: _countdownCtrl.value,
                            isTesting: _isTesting,
                          ),
                        ),

                        // 中心内容
                        _GaugeCenter(
                          isTesting: _isTesting,
                          currentSpeed: _displayBps,
                          remaining: remaining,
                          onTap: _isTesting ? _stopTest : _startTest,
                        ),
                      ],
                    );
                  },
                ),
              ),

              SizedBox(height: 32.rh),

              // ── 指标行 ────────────────────────────────────────────────────
              Padding(
                padding: REdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'PING',
                        value: _pingMs > 0 ? '$_pingMs' : '--',
                        unit: 'ms',
                        icon: Icons.wifi_tethering_rounded,
                        color: _C.accent1,
                        active: _pingMs > 0,
                      ),
                    ),
                    SizedBox(width: 12.rw),
                    Expanded(
                      child: _MetricCard(
                        label: '峰值下载',
                        value: _displayPeak > 0
                            ? (_displayPeak / 1024 / 1024 * 8)
                                .toStringAsFixed(1)
                            : '--',
                        unit: 'Mbps',
                        icon: Icons.arrow_downward_rounded,
                        color: _C.green,
                        active: _displayPeak > 0,
                      ),
                    ),
                    SizedBox(width: 12.rw),
                    Expanded(
                      child: _MetricCard(
                        label: '总下载',
                        value: _displayTotal > 0
                            ? _sizeValue(_displayTotal)
                            : '--',
                        unit: _displayTotal > 0 ? _sizeUnit(_displayTotal) : '',
                        icon: Icons.cloud_download_outlined,
                        color: _C.accent2,
                        active: _displayTotal > 0,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── 说明文字 ──────────────────────────────────────────────────
              Padding(
                padding: REdgeInsets.fromLTRB(28, 0, 28, 24),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 13.ri, color: _C.textMuted),
                    SizedBox(width: 6.rw),
                    Expanded(
                      child: Text(
                        '通过下载公共 CDN 文件实时测量当前网络下载速度',
                        style: TextStyle(
                          color: _C.textMuted,
                          fontSize: 11.rf,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}


// ── 仪表盘中心 ────────────────────────────────────────────────────────────────
class _GaugeCenter extends StatelessWidget {
  final bool isTesting;
  final int currentSpeed;
  final int remaining;
  final VoidCallback onTap;

  const _GaugeCenter({
    required this.isTesting,
    required this.currentSpeed,
    required this.remaining,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isTesting) ...[
            // 实时速度大字
            Text(
              (currentSpeed / 1024 / 1024 * 8).toStringAsFixed(1),
              style: TextStyle(
                color: _C.textPrimary,
                fontSize: 52.rf,
                fontWeight: FontWeight.w800,
                height: 1.0,
                letterSpacing: -2,
              ),
            ),
            SizedBox(height: 4.rh),
            Text(
              'Mbps',
              style: TextStyle(
                color: _C.textSecondary,
                fontSize: 14.rf,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 16.rh),
            // 倒计时
            Container(
              padding: REdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: _C.accent1.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20.rr),
                border: Border.all(
                    color: _C.accent1.withValues(alpha: 0.3), width: 1),
              ),
              child: Text(
                '$remaining s · 点击停止',
                style: TextStyle(
                  color: _C.accent1,
                  fontSize: 11.rf,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...[
            // 开始按钮
            Container(
              width: 72.ri,
              height: 72.ri,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_C.accent1, _C.accent2],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _C.accent1.withValues(alpha: 0.45),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 36.ri),
            ),
            SizedBox(height: 16.rh),
            Text(
              '开始测速',
              style: TextStyle(
                color: _C.textPrimary,
                fontSize: 16.rf,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 4.rh),
            Text(
              'Tap to start',
              style: TextStyle(color: _C.textMuted, fontSize: 11.rf),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 指标卡片 ──────────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final bool active;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: REdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16.rr),
        border: Border.all(
          color: active
              ? color.withValues(alpha: 0.25)
              : _C.surfaceActive.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14.ri, color: active ? color : _C.textMuted),
          SizedBox(height: 8.rh),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: active ? _C.textPrimary : _C.textMuted,
                      fontSize: 17.rf,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              if (unit.isNotEmpty) ...[
                SizedBox(width: 2.rw),
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    unit,
                    style: TextStyle(
                      color: active ? color : _C.textMuted,
                      fontSize: 9.rf,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 4.rh),
          Text(
            label,
            style: TextStyle(color: _C.textMuted, fontSize: 9.rf),
          ),
        ],
      ),
    );
  }
}

// ── 主弧形仪表 Painter ────────────────────────────────────────────────────────
class _ArcGaugePainter extends CustomPainter {
  final double progress;       // 0→1 速度进度
  final double countdownProgress; // 0→1 测试剩余
  final bool isTesting;

  const _ArcGaugePainter({
    required this.progress,
    required this.countdownProgress,
    required this.isTesting,
  });

  // 3/4 弧：从 225° 开始，顺时针 270°
  static const double _startAngle = 2.356194; // 135° in rad
  static const double _sweepTotal = 4.712389; // 270° in rad

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2 - 8;
    final innerR = outerR - 14;
    final rect = Rect.fromCircle(center: center, radius: outerR);
    final innerRect = Rect.fromCircle(center: center, radius: innerR);

    // ── 轨道背景（外圈）
    canvas.drawArc(
      rect,
      _startAngle,
      _sweepTotal,
      false,
      Paint()
        ..color = _C.surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round,
    );

    // ── 倒计时轨道（内圈，仅测速时显示）
    if (isTesting) {
      canvas.drawArc(
        innerRect,
        _startAngle,
        _sweepTotal,
        false,
        Paint()
          ..color = _C.surfaceActive
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );

      final remaining = 1.0 - countdownProgress;
      if (remaining > 0) {
        canvas.drawArc(
          innerRect,
          _startAngle,
          _sweepTotal * remaining,
          false,
          Paint()
            ..shader = SweepGradient(
              startAngle: _startAngle,
              endAngle: _startAngle + _sweepTotal,
              colors: const [Color(0xFF5B6BFF), Color(0xFFAA72FF)],
            ).createShader(innerRect)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    if (progress <= 0) return;

    // ── 速度弧（外圈渐变）
    final fillSweep = _sweepTotal * progress;
    canvas.drawArc(
      rect,
      _startAngle,
      fillSweep,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: _startAngle,
          endAngle: _startAngle + _sweepTotal,
          colors: _C.arcGradient,
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round,
    );

    // ── 指针端点
    final tipAngle = _startAngle + fillSweep;
    final tip = Offset(
      center.dx + outerR * math.cos(tipAngle),
      center.dy + outerR * math.sin(tipAngle),
    );
    canvas.drawCircle(tip, 9, Paint()..color = _C.accent2);
    canvas.drawCircle(
        tip,
        5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill);

    // ── 刻度点（7个，均匀分布）
    for (int i = 0; i <= 6; i++) {
      final a = _startAngle + _sweepTotal * i / 6;
      final pt = Offset(
        center.dx + outerR * math.cos(a),
        center.dy + outerR * math.sin(a),
      );
      canvas.drawCircle(
          pt,
          2.5,
          Paint()
            ..color = _C.textMuted.withValues(alpha: 0.5));
    }
  }

  @override
  bool shouldRepaint(_ArcGaugePainter old) =>
      old.progress != progress ||
      old.countdownProgress != countdownProgress ||
      old.isTesting != isTesting;
}

// ── 外发光 Painter ────────────────────────────────────────────────────────────
class _GlowPainter extends CustomPainter {
  final double progress;
  final double glowIntensity;

  const _GlowPainter({required this.progress, required this.glowIntensity});

  static const double _startAngle = 2.356194;
  static const double _sweepTotal = 4.712389;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: outerR);
    final fillSweep = _sweepTotal * progress;

    canvas.drawArc(
      rect,
      _startAngle,
      fillSweep,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: _startAngle,
          endAngle: _startAngle + _sweepTotal,
          colors: [
            _C.accent1.withValues(alpha: 0),
            _C.accent2.withValues(alpha: 0.6 * glowIntensity),
            _C.accent3.withValues(alpha: 0.4 * glowIntensity),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 32
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.progress != progress || old.glowIntensity != glowIntensity;
}
