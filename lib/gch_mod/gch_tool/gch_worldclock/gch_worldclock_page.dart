import 'dart:async';
import 'package:flutter/material.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';

// ── 颜色常量 ────────────────────────────────────────────────────────────────────
const _bg = Color(0xFFF1EFF9);
const _card = Colors.white;
const _accent = Color(0xFF5969FF);
const _textPrimary = Color(0xFF1A1A2E);
const _textSecondary = Color(0xFF666680);
const _textMuted = Color(0xFF9999B3);

// ── 城市时区数据 ─────────────────────────────────────────────────────────────────
class _CityTZ {
  final String city;
  final String country;
  final String flag;
  // DST-aware: 夏令时 offset 和标准时 offset（小时，带0.5支持半小时区）
  // 简单策略：北半球夏令时 3月第2周日～11月第1周日；南半球 10月第1周日～4月第1周日
  final double stdOffset;   // UTC 标准时差（小时）
  final double dstOffset;   // UTC 夏令时差（小时，无夏令时 == stdOffset）
  final bool southernHemisphere; // 南半球夏令时规则

  const _CityTZ(
    this.city,
    this.country,
    this.flag,
    this.stdOffset,
    this.dstOffset, {
    this.southernHemisphere = false,
  });
}

const _cities = [
  _CityTZ('北京', '中国', '🇨🇳', 8, 8),
  _CityTZ('香港', '中国香港', '🇭🇰', 8, 8),
  _CityTZ('新加坡', '新加坡', '🇸🇬', 8, 8),
  _CityTZ('东京', '日本', '🇯🇵', 9, 9),
  _CityTZ('首尔', '韩国', '🇰🇷', 9, 9),
  _CityTZ('悉尼', '澳大利亚', '🇦🇺', 10, 11, southernHemisphere: true),
  _CityTZ('伦敦', '英国', '🇬🇧', 0, 1),
  _CityTZ('巴黎', '法国', '🇫🇷', 1, 2),
  _CityTZ('纽约', '美国', '🇺🇸', -5, -4),
  _CityTZ('洛杉矶', '美国', '🇺🇸', -8, -7),
  _CityTZ('多伦多', '加拿大', '🇨🇦', -5, -4),
  _CityTZ('温哥华', '加拿大', '🇨🇦', -8, -7),
];

// ── DST 判断 ─────────────────────────────────────────────────────────────────────
bool _isDst(_CityTZ tz, DateTime utcNow) {
  if (tz.stdOffset == tz.dstOffset) return false;

  final year = utcNow.year;
  if (tz.southernHemisphere) {
    // 南半球：10月第1周日 ～ 4月第1周日
    final dstStart = _nthSundayOf(year, 10, 1);
    final dstEnd = _nthSundayOf(year, 4, 1);
    // 跨年：10月到12月 或 1月到4月
    return utcNow.isAfter(dstStart) || utcNow.isBefore(dstEnd);
  } else {
    // 北半球：3月第2周日 ～ 11月第1周日
    final dstStart = _nthSundayOf(year, 3, 2);
    final dstEnd = _nthSundayOf(year, 11, 1);
    return utcNow.isAfter(dstStart) && utcNow.isBefore(dstEnd);
  }
}

DateTime _nthSundayOf(int year, int month, int n) {
  var d = DateTime.utc(year, month, 1);
  var sundays = 0;
  while (true) {
    if (d.weekday == DateTime.sunday) {
      sundays++;
      if (sundays == n) return d;
    }
    d = d.add(const Duration(days: 1));
  }
}

double _currentOffset(_CityTZ tz, DateTime utcNow) {
  return _isDst(tz, utcNow) ? tz.dstOffset : tz.stdOffset;
}

// ── 北京 UTC offset ────────────────────────────────────────────────────────────
const double _bjOffset = 8.0;

// ── 适合通话判断（本地时间 7:00 ~ 22:00）──────────────────────────────────────
bool _isGoodTime(int hour) => hour >= 7 && hour < 22;

// ── 页面 ────────────────────────────────────────────────────────────────────────
class GchWorldClockPage extends StatefulWidget {
  const GchWorldClockPage({super.key});

  @override
  State<GchWorldClockPage> createState() => _GchWorldClockPageState();
}

class _GchWorldClockPageState extends State<GchWorldClockPage> {
  Timer? _timer;
  DateTime _utcNow = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _utcNow = DateTime.now().toUtc());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime _timeFor(_CityTZ tz) {
    final offset = _currentOffset(tz, _utcNow);
    final h = offset.truncate();
    final m = ((offset - h) * 60).round();
    return _utcNow.add(Duration(hours: h, minutes: m));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          '世界时钟',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 17.rf,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: _textPrimary),
      ),
      body: Column(
        children: [
          // 提示条
          Padding(
            padding: REdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 12.ri, color: _accent.withValues(alpha: 0.7)),
                SizedBox(width: 5.rw),
                Expanded(
                  child: Text(
                    '绿点代表当地适合通话（07:00–22:00）· 时区已考虑夏令时',
                    style: TextStyle(
                      color: _accent.withValues(alpha: 0.8),
                      fontSize: 11.rf,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.rh),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: 32.rh),
              children: _cities.map((tz) {
                final cityTime = _timeFor(tz);
                return _CityCard(
                  tz: tz,
                  cityTime: cityTime,
                  utcNow: _utcNow,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 城市卡片 ─────────────────────────────────────────────────────────────────────
class _CityCard extends StatelessWidget {
  final _CityTZ tz;
  final DateTime cityTime;
  final DateTime utcNow;

  const _CityCard({
    required this.tz,
    required this.cityTime,
    required this.utcNow,
  });

  String? _diffLabel() {
    final offset = _currentOffset(tz, utcNow);
    final diffHours = offset - _bjOffset;
    if (diffHours == 0) return null;

    final sign = diffHours > 0 ? '+' : '-';
    final absH = diffHours.abs().truncate();
    final absM = ((diffHours.abs() - absH) * 60).round();
    if (absM == 0) return '与北京差 $sign${absH}h';
    return '与北京差 $sign${absH}h${absM}m';
  }

  @override
  Widget build(BuildContext context) {
    final hh = cityTime.hour.toString().padLeft(2, '0');
    final mm = cityTime.minute.toString().padLeft(2, '0');
    final month = cityTime.month.toString().padLeft(2, '0');
    final day = cityTime.day.toString().padLeft(2, '0');
    final diffLabel = _diffLabel();
    final isBeijing = tz.city == '北京';
    final good = _isGoodTime(cityTime.hour);
    final isNight = cityTime.hour >= 22 || cityTime.hour < 6;
    final offset = _currentOffset(tz, utcNow);
    final diffHours = offset - _bjOffset;

    return Container(
      margin: REdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: isBeijing
            ? const Color(0xFF5969FF)
            : _card,
        borderRadius: BorderRadius.circular(14.rr),
        boxShadow: [
          BoxShadow(
            color: isBeijing
                ? const Color(0xFF5969FF).withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isBeijing ? 16 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: REdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // 国旗 + 通话指示点
            Stack(
              children: [
                Text(tz.flag, style: TextStyle(fontSize: 26.rf)),
                if (!isBeijing)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 9.ri,
                      height: 9.ri,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: good
                            ? const Color(0xFF2ECC71)
                            : const Color(0xFFCCCCCC),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12.rw),

            // 城市 + 国家
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tz.city,
                        style: TextStyle(
                          color: isBeijing ? Colors.white : _textPrimary,
                          fontSize: 15.rf,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isBeijing) ...[
                        SizedBox(width: 6.rw),
                        Container(
                          padding:
                              REdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6.rr),
                          ),
                          child: Text(
                            '本地',
                            style: TextStyle(
                                color: Colors.white, fontSize: 10.rf),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.rh),
                  Row(
                    children: [
                      Text(
                        tz.country,
                        style: TextStyle(
                          color: isBeijing
                              ? Colors.white.withValues(alpha: 0.7)
                              : _textSecondary,
                          fontSize: 12.rf,
                        ),
                      ),
                      if (!isBeijing && diffLabel != null) ...[
                        SizedBox(width: 6.rw),
                        Text(
                          diffLabel,
                          style: TextStyle(
                            color: diffHours > 0
                                ? const Color(0xFF2ECC71)
                                : const Color(0xFFFF7043),
                            fontSize: 10.rf,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // 时间 + 日期 + 通话提示
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!isBeijing && isNight)
                      Padding(
                        padding: EdgeInsets.only(right: 4.rw),
                        child: Icon(
                          Icons.nights_stay_rounded,
                          size: 12.ri,
                          color: isBeijing
                              ? Colors.white.withValues(alpha: 0.6)
                              : _textMuted,
                        ),
                      ),
                    Text(
                      '$hh:$mm',
                      style: TextStyle(
                        color: isBeijing ? Colors.white : _accent,
                        fontSize: 22.rf,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.rh),
                Text(
                  '$month/$day',
                  style: TextStyle(
                    color: isBeijing
                        ? Colors.white.withValues(alpha: 0.65)
                        : _textMuted,
                    fontSize: 11.rf,
                  ),
                ),
                if (!isBeijing) ...[
                  SizedBox(height: 3.rh),
                  Text(
                    good ? '可通话 ✓' : '休息中',
                    style: TextStyle(
                      color: good
                          ? const Color(0xFF2ECC71)
                          : _textMuted,
                      fontSize: 10.rf,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
