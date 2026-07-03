import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';

const _bg = Color(0xFFF1EFF9);
const _accent = Color(0xFF5969FF);
const _card = Colors.white;
const _textPrimary = Color(0xFF1A1A2E);
const _textSecondary = Color(0xFF666680);
const _textMuted = Color(0xFF9999B3);
const _green = Color(0xFF2ECC9A);
const _orange = Color(0xFFFF9800);
const _red = Color(0xFFE53935);

// ─── 数据模型 ──────────────────────────────────────────────────────────────────

class _Region {
  final String name;
  final double taxRate; // 地区附加税率（如美国州税）
  const _Region(this.name, this.taxRate);
}

class _Country {
  final String name;
  final String flag;
  final String currency;
  final String symbol;
  final String visaName;
  final int weeklyLimit;       // 打工时限（小时/周）
  final bool limitIsFortnightly; // 是否以两周为单位（澳洲48h/2周）
  final String limitNote;
  final double baseTaxRate;    // 国家基础有效税率估算
  final double ficaExempt;     // 额外免缴项（F1免FICA = 7.65%）
  final double minWage;        // 最低时薪（当地货币）
  final List<_Region> regions;
  final String taxNote;

  const _Country({
    required this.name,
    required this.flag,
    required this.currency,
    required this.symbol,
    required this.visaName,
    required this.weeklyLimit,
    this.limitIsFortnightly = false,
    required this.limitNote,
    required this.baseTaxRate,
    this.ficaExempt = 0,
    required this.minWage,
    this.regions = const [],
    required this.taxNote,
  });

  int get displayLimit => limitIsFortnightly ? weeklyLimit ~/ 2 : weeklyLimit;
}

// ─── 国家数据（税率为学生收入区间的简化有效税率估算）─────────────────────────────

const _countries = [
  _Country(
    name: '美国',
    flag: '🇺🇸',
    currency: 'USD',
    symbol: '\$',
    visaName: 'F1 / OPT',
    weeklyLimit: 20,
    limitNote: '校内兼职最多 20h/周；暑假可全职；OPT/CPT 另行计算',
    baseTaxRate: 0.10,   // 联邦有效税率（\$20k-40k 年收入，扣除标准扣除额后）
    ficaExempt: 0.0765,  // F1 免缴 Social Security + Medicare
    minWage: 7.25,
    regions: [
      _Region('加利福尼亚 CA', 0.062),
      _Region('纽约 NY', 0.060),
      _Region('德克萨斯 TX', 0.000),
      _Region('佛罗里达 FL', 0.000),
      _Region('华盛顿 WA', 0.000),
      _Region('马萨诸塞 MA', 0.050),
      _Region('伊利诺伊 IL', 0.0495),
      _Region('宾夕法尼亚 PA', 0.031),
      _Region('俄亥俄 OH', 0.040),
      _Region('密歇根 MI', 0.043),
      _Region('新泽西 NJ', 0.035),
      _Region('弗吉尼亚 VA', 0.058),
      _Region('北卡罗来纳 NC', 0.053),
      _Region('乔治亚 GA', 0.055),
      _Region('明尼苏达 MN', 0.069),
    ],
    taxNote: 'F1 学生免缴 FICA（Social Security + Medicare = 7.65%），税后比普通雇员高',
  ),
  _Country(
    name: '英国',
    flag: '🇬🇧',
    currency: 'GBP',
    symbol: '£',
    visaName: 'Tier 4 / Student',
    weeklyLimit: 20,
    limitNote: '上课期间最多 20h/周；学期假期可全职（含暑期）',
    baseTaxRate: 0.12, // 含 National Insurance，扣除 £12,570 免税额后
    minWage: 11.44,
    regions: [_Region('全国统一', 0.0)],
    taxNote: '个人免税额 £12,570/年；超出部分 20% 所得税 + 12% NI；年收入<£12,570 基本免税',
  ),
  _Country(
    name: '澳洲',
    flag: '🇦🇺',
    currency: 'AUD',
    symbol: 'A\$',
    visaName: 'Student Visa (500)',
    weeklyLimit: 48,
    limitIsFortnightly: true,
    limitNote: '每两周最多 48 小时（=约 24h/周）；学期结束后可全职',
    baseTaxRate: 0.15, // A\$18k-45k 区间含 Medicare Levy，临时居民有豁免
    minWage: 23.23,
    regions: [_Region('全国统一', 0.0)],
    taxNote: '免税起点 A\$18,200；超出部分 19% 所得税；临时签证通常豁免 2% Medicare Levy',
  ),
  _Country(
    name: '加拿大',
    flag: '🇨🇦',
    currency: 'CAD',
    symbol: 'C\$',
    visaName: 'Study Permit',
    weeklyLimit: 20,
    limitNote: '上课期间最多 20h/周；指定假期（冬/夏）可全职',
    baseTaxRate: 0.15, // 联邦税率15%（基本个人免税额约 C\$15,705 以上部分）
    minWage: 17.30,
    regions: [
      _Region('安大略 ON', 0.0505),
      _Region('不列颠哥伦比亚 BC', 0.0506),
      _Region('魁北克 QC', 0.14),
      _Region('阿尔伯塔 AB', 0.10),
      _Region('曼尼托巴 MB', 0.108),
      _Region('萨斯喀彻温 SK', 0.105),
    ],
    taxNote: '联邦 + 省税合计；CPP/EI 另需缴纳约 4.5%；总有效税率约 22–30%',
  ),
  _Country(
    name: '日本',
    flag: '🇯🇵',
    currency: 'JPY',
    symbol: '¥',
    visaName: '留学签证',
    weeklyLimit: 28,
    limitNote: '打工许可证最多 28h/周；暑假长假期间最多 40h/周',
    baseTaxRate: 0.05, // 所得税（初年度免地方税，年收入 ¥200万以内5%）
    minWage: 1004.0,  // 全国平均，各都道府县略有不同
    regions: [
      _Region('东京', 0.10),
      _Region('神奈川', 0.10),
      _Region('大阪', 0.10),
      _Region('愛知', 0.10),
      _Region('福冈', 0.10),
      _Region('其他地区', 0.10),
    ],
    taxNote: '年收入 ¥200万以下所得税约 5%；住民税（约 10%）入住第二年起征收',
  ),
  _Country(
    name: '新加坡',
    flag: '🇸🇬',
    currency: 'SGD',
    symbol: 'S\$',
    visaName: 'Student Pass',
    weeklyLimit: 16,
    limitNote: '大多数学生签证最多 16h/周（部分学校允许 20h）',
    baseTaxRate: 0.02, // S\$20,000 以下 0%，以上 2%
    minWage: 0,        // 新加坡无全国最低工资
    regions: [_Region('全国统一', 0.0)],
    taxNote: '年收入 S\$20,000 以下免税；S\$20,000–S\$30,000 税率 2%；整体税负较低',
  ),
  _Country(
    name: '韩国',
    flag: '🇰🇷',
    currency: 'KRW',
    symbol: '₩',
    visaName: 'D-2 留学签',
    weeklyLimit: 25,
    limitNote: '课余时间最多 25h/周（语言研修 D-4 签证限 10h）',
    baseTaxRate: 0.06, // 소득세 6%（₩1,400万以内）
    minWage: 9860.0,
    regions: [_Region('全国统一', 0.0)],
    taxNote: '年收入 ₩1,400万以下所得税 6%；另需缴纳约 4 大保险（约 9%）',
  ),
];

// ─── 计算逻辑 ──────────────────────────────────────────────────────────────────

class _CalcResult {
  final double grossWeekly;
  final double grossMonthly;
  final double grossAnnual;
  final double taxMonthly;
  final double netMonthly;
  final double netAnnual;
  final double effectiveTaxRate;

  const _CalcResult({
    required this.grossWeekly,
    required this.grossMonthly,
    required this.grossAnnual,
    required this.taxMonthly,
    required this.netMonthly,
    required this.netAnnual,
    required this.effectiveTaxRate,
  });
}

_CalcResult _calculate(
    _Country country, _Region? region, double hourly, double hoursPerWeek) {
  final grossWeekly = hourly * hoursPerWeek;
  final grossMonthly = grossWeekly * 52 / 12;
  final grossAnnual = grossMonthly * 12;

  // 综合税率 = 基础税率 + 地区税率 - 免缴项
  double rate = country.baseTaxRate + (region?.taxRate ?? 0) - country.ficaExempt;
  // 日本：第一年地方税豁免，所以 baseTaxRate 已含所得税，region 税率代表地方税
  // 对于日本，第一年不计地方税
  if (country.currency == 'JPY') rate = country.baseTaxRate; // 简化：仅所得税

  // 确保税率在合理范围
  rate = rate.clamp(0.0, 0.5);

  // 免税额抵扣（简化：将免税额转为税率调整，已在 baseTaxRate 中隐含）
  final taxMonthly = grossMonthly * rate;
  final netMonthly = grossMonthly - taxMonthly;
  final netAnnual = netMonthly * 12;

  return _CalcResult(
    grossWeekly: grossWeekly,
    grossMonthly: grossMonthly,
    grossAnnual: grossAnnual,
    taxMonthly: taxMonthly,
    netMonthly: netMonthly,
    netAnnual: netAnnual,
    effectiveTaxRate: rate,
  );
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class GchWorkPage extends StatefulWidget {
  const GchWorkPage({super.key});

  @override
  State<GchWorkPage> createState() => _PageState();
}

class _PageState extends State<GchWorkPage> {
  _Country _country = _countries[0];
  _Region? _region;
  final _wageCtrl = TextEditingController();
  double _hours = 20;
  double _hourlyWage = 0;

  @override
  void initState() {
    super.initState();
    _region = _country.regions.isNotEmpty ? _country.regions.first : null;
    _wageCtrl.addListener(() {
      final v = double.tryParse(_wageCtrl.text) ?? 0;
      if (v != _hourlyWage) setState(() => _hourlyWage = v);
    });
  }

  @override
  void dispose() {
    _wageCtrl.dispose();
    super.dispose();
  }

  void _selectCountry(_Country c) {
    setState(() {
      _country = c;
      _region = c.regions.isNotEmpty ? c.regions.first : null;
      _hours = c.displayLimit.toDouble();
      _wageCtrl.clear();
      _hourlyWage = 0;
    });
  }

  bool get _overLimit {
    if (_country.limitIsFortnightly) return _hours * 2 > _country.weeklyLimit;
    return _hours > _country.weeklyLimit;
  }

  _CalcResult? get _result {
    if (_hourlyWage <= 0) return null;
    return _calculate(_country, _region, _hourlyWage, _hours);
  }

  String _fmt(double v) {
    if (_country.currency == 'JPY' || _country.currency == 'KRW') {
      return v.toStringAsFixed(0);
    }
    return v.toStringAsFixed(2);
  }

  String _fmtShort(double v) {
    if (_country.currency == 'JPY' || _country.currency == 'KRW') {
      if (v >= 10000) return '${(v / 10000).toStringAsFixed(1)}万';
      return v.toStringAsFixed(0);
    }
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          title: Text('打工收入计算器',
              style: TextStyle(
                  color: _textPrimary, fontSize: 17.rf, fontWeight: FontWeight.w600)),
          iconTheme: const IconThemeData(color: _textPrimary),
          centerTitle: true,
        ),
        body: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.rw, vertical: 8.rh),
          children: [
            // 国家选择
            _CountrySelector(
              selected: _country,
              onChanged: _selectCountry,
            ),
            SizedBox(height: 16.rh),

            // 签证信息
            _VisaBadge(country: _country),
            SizedBox(height: 16.rh),

            // 输入卡片
            _InputCard(
              country: _country,
              region: _region,
              wageCtrl: _wageCtrl,
              hours: _hours,
              overLimit: _overLimit,
              onRegionChanged: (r) => setState(() => _region = r),
              onHoursChanged: (v) => setState(() => _hours = v),
            ),
            SizedBox(height: 16.rh),

            // 结果卡片
            if (result != null) ...[
              _ResultCard(
                country: _country,
                result: result,
                hours: _hours,
                fmtShort: _fmtShort,
                fmt: _fmt,
              ),
              SizedBox(height: 16.rh),
              _TaxBreakdown(
                country: _country,
                region: _region,
                result: result,
                fmt: _fmt,
              ),
              SizedBox(height: 16.rh),
            ] else ...[
              _Placeholder(),
              SizedBox(height: 16.rh),
            ],

            // 注意事项
            _NotesCard(country: _country),
            SizedBox(height: 16.rh),

            // 免责
            Padding(
              padding: REdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '⚠️ 以上数据为简化估算，税率因个人情况而异。实际税额以当地税务局规定为准，建议咨询专业税务顾问。',
                style: TextStyle(color: _textMuted, fontSize: 11.rf, height: 1.6),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
          ],
        ),
      ),
    );
  }
}

// ─── CountrySelector ──────────────────────────────────────────────────────────

class _CountrySelector extends StatelessWidget {
  final _Country selected;
  final ValueChanged<_Country> onChanged;
  const _CountrySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42.rh,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _countries.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.rw),
        itemBuilder: (_, i) {
          final c = _countries[i];
          final active = c.name == selected.name;
          return GestureDetector(
            onTap: () => onChanged(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: REdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? _accent : _card,
                borderRadius: BorderRadius.circular(21.rr),
                boxShadow: [
                  BoxShadow(
                    color: active
                        ? _accent.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: active ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(c.flag, style: TextStyle(fontSize: 16.rf)),
                  SizedBox(width: 6.rw),
                  Text(c.name,
                      style: TextStyle(
                        color: active ? Colors.white : _textSecondary,
                        fontSize: 13.rf,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── VisaBadge ────────────────────────────────────────────────────────────────

class _VisaBadge extends StatelessWidget {
  final _Country country;
  const _VisaBadge({required this.country});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: REdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.rr),
        border: Border.all(color: _accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.badge_rounded, size: 16.ri, color: _accent),
          SizedBox(width: 10.rw),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(country.visaName,
                        style: TextStyle(
                          color: _accent,
                          fontSize: 13.rf,
                          fontWeight: FontWeight.w700,
                        )),
                    SizedBox(width: 8.rw),
                    Container(
                      padding: REdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _accent,
                        borderRadius: BorderRadius.circular(8.rr),
                      ),
                      child: Text(
                        country.limitIsFortnightly
                            ? '${country.weeklyLimit}h / 两周'
                            : '${country.weeklyLimit}h / 周',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.rf,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.rh),
                Text(country.limitNote,
                    style: TextStyle(
                        color: _accent.withValues(alpha: 0.8), fontSize: 11.rf, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── InputCard ────────────────────────────────────────────────────────────────

class _InputCard extends StatelessWidget {
  final _Country country;
  final _Region? region;
  final TextEditingController wageCtrl;
  final double hours;
  final bool overLimit;
  final ValueChanged<_Region?> onRegionChanged;
  final ValueChanged<double> onHoursChanged;

  const _InputCard({
    required this.country,
    required this.region,
    required this.wageCtrl,
    required this.hours,
    required this.overLimit,
    required this.onRegionChanged,
    required this.onHoursChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: REdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16.rr),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 地区选择（美国/加拿大/日本）
          if (country.regions.length > 1) ...[
            Text('所在州 / 省',
                style: TextStyle(color: _textMuted, fontSize: 12.rf, fontWeight: FontWeight.w500)),
            SizedBox(height: 8.rh),
            DropdownButtonFormField<_Region>(
              value: region,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8F8FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.rr),
                  borderSide: BorderSide.none,
                ),
                contentPadding: REdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              style: TextStyle(color: _textPrimary, fontSize: 13.rf),
              dropdownColor: _card,
              items: country.regions
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                  .toList(),
              onChanged: onRegionChanged,
            ),
            SizedBox(height: 16.rh),
            Divider(height: 1, color: const Color(0xFFF0F0F8)),
            SizedBox(height: 16.rh),
          ],

          // 时薪输入
          Text('时薪（${country.symbol}/${country.currency}）',
              style: TextStyle(color: _textMuted, fontSize: 12.rf, fontWeight: FontWeight.w500)),
          SizedBox(height: 8.rh),
          Container(
            padding: REdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8FC),
              borderRadius: BorderRadius.circular(10.rr),
            ),
            child: Row(
              children: [
                Text(country.symbol,
                    style: TextStyle(color: _textSecondary, fontSize: 18.rf, fontWeight: FontWeight.w300)),
                SizedBox(width: 8.rw),
                Expanded(
                  child: TextField(
                    controller: wageCtrl,
                    style: TextStyle(color: _textPrimary, fontSize: 20.rf, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: country.minWage > 0
                          ? '最低 ${country.minWage.toStringAsFixed(2)}'
                          : '输入时薪',
                      hintStyle: TextStyle(color: _textMuted, fontSize: 16.rf, fontWeight: FontWeight.w400),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                ),
                Text(country.currency,
                    style: TextStyle(color: _textMuted, fontSize: 12.rf)),
              ],
            ),
          ),
          if (country.minWage > 0) ...[
            SizedBox(height: 5.rh),
            Text('当地最低时薪参考：${country.symbol}${country.minWage.toStringAsFixed(2)}/h',
                style: TextStyle(color: _textMuted, fontSize: 11.rf)),
          ],
          SizedBox(height: 20.rh),

          // 每周工时滑块
          Row(
            children: [
              Text('每周工时', style: TextStyle(color: _textMuted, fontSize: 12.rf, fontWeight: FontWeight.w500)),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: REdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: overLimit ? _red.withValues(alpha: 0.1) : _green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.rr),
                ),
                child: Text(
                  '${hours.toStringAsFixed(0)}h / 周',
                  style: TextStyle(
                    color: overLimit ? _red : _green,
                    fontSize: 14.rf,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.rh),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: overLimit ? _red : _accent,
              inactiveTrackColor: (overLimit ? _red : _accent).withValues(alpha: 0.15),
              thumbColor: overLimit ? _red : _accent,
              overlayColor: (overLimit ? _red : _accent).withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: hours,
              min: 1,
              max: 60,
              divisions: 59,
              onChanged: onHoursChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1h', style: TextStyle(color: _textMuted, fontSize: 10.rf)),
              if (overLimit)
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 12.ri, color: _red),
                    SizedBox(width: 4.rw),
                    Text(
                      '超出签证工时限制',
                      style: TextStyle(color: _red, fontSize: 11.rf, fontWeight: FontWeight.w500),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 12.ri, color: _green),
                    SizedBox(width: 4.rw),
                    Text('符合签证规定', style: TextStyle(color: _green, fontSize: 11.rf)),
                  ],
                ),
              Text('60h', style: TextStyle(color: _textMuted, fontSize: 10.rf)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── ResultCard ───────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final _Country country;
  final _CalcResult result;
  final double hours;
  final String Function(double) fmtShort;
  final String Function(double) fmt;

  const _ResultCard({
    required this.country,
    required this.result,
    required this.hours,
    required this.fmtShort,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A40), Color(0xFF5969FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.rr),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: REdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('预计收入',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12.rf,
                )),
            SizedBox(height: 4.rh),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(country.symbol,
                    style: TextStyle(color: Colors.white, fontSize: 20.rf, fontWeight: FontWeight.w300)),
                SizedBox(width: 4.rw),
                Text(
                  fmtShort(result.netMonthly),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 44.rf,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    letterSpacing: -1,
                  ),
                ),
                SizedBox(width: 8.rw),
                Padding(
                  padding: EdgeInsets.only(bottom: 4.rh),
                  child: Text('/ 月（税后）',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7), fontSize: 13.rf)),
                ),
              ],
            ),
            SizedBox(height: 20.rh),
            // 三个指标
            Row(
              children: [
                _MetricChip(
                  label: '周薪',
                  value: '${country.symbol}${fmtShort(result.grossWeekly)}',
                  sub: '税前 · ${hours.toStringAsFixed(0)}h',
                ),
                SizedBox(width: 10.rw),
                _MetricChip(
                  label: '月薪',
                  value: '${country.symbol}${fmtShort(result.grossMonthly)}',
                  sub: '税前',
                ),
                SizedBox(width: 10.rw),
                _MetricChip(
                  label: '年薪',
                  value: '${country.symbol}${fmtShort(result.netAnnual)}',
                  sub: '税后',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  const _MetricChip({required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: REdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12.rr),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65), fontSize: 10.rf)),
            SizedBox(height: 3.rh),
            Text(value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.rf,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis),
            SizedBox(height: 1.rh),
            Text(sub,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 9.rf)),
          ],
        ),
      ),
    );
  }
}

// ─── TaxBreakdown ─────────────────────────────────────────────────────────────

class _TaxBreakdown extends StatelessWidget {
  final _Country country;
  final _Region? region;
  final _CalcResult result;
  final String Function(double) fmt;

  const _TaxBreakdown({
    required this.country,
    required this.region,
    required this.result,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, Color)>[];

    rows.add(('税前月薪', '${country.symbol}${fmt(result.grossMonthly)}', _textPrimary));
    rows.add(('预估税费（${(result.effectiveTaxRate * 100).toStringAsFixed(1)}%）',
        '−${country.symbol}${fmt(result.taxMonthly)}', _red));
    if (country.ficaExempt > 0) {
      rows.add(('F1 免缴 FICA（已节省 7.65%）', '+已豁免', _green));
    }
    rows.add(('税后月薪', '${country.symbol}${fmt(result.netMonthly)}', _accent));

    return Container(
      padding: REdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16.rr),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, size: 16.ri, color: _textSecondary),
              SizedBox(width: 8.rw),
              Text('税费明细',
                  style: TextStyle(
                      color: _textPrimary, fontSize: 14.rf, fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 12.rh),
          ...rows.asMap().entries.map((e) {
            final r = e.value;
            final isLast = e.key == rows.length - 1;
            return Column(
              children: [
                if (isLast) ...[
                  Divider(height: 16, thickness: 1, color: const Color(0xFFF0F0F8)),
                ],
                Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 10.rh),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(r.$1,
                            style: TextStyle(
                              color: isLast ? _textPrimary : _textSecondary,
                              fontSize: isLast ? 14.rf : 13.rf,
                              fontWeight: isLast ? FontWeight.w700 : FontWeight.w400,
                            )),
                      ),
                      Text(r.$2,
                          style: TextStyle(
                            color: r.$3,
                            fontSize: isLast ? 16.rf : 13.rf,
                            fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                          )),
                    ],
                  ),
                ),
              ],
            );
          }),
          SizedBox(height: 12.rh),
          Container(
            padding: REdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8FC),
              borderRadius: BorderRadius.circular(8.rr),
            ),
            child: Text(country.taxNote,
                style: TextStyle(color: _textSecondary, fontSize: 11.rf, height: 1.6)),
          ),
        ],
      ),
    );
  }
}

// ─── Placeholder ──────────────────────────────────────────────────────────────

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120.rh,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16.rr),
        border: Border.all(color: _accent.withValues(alpha: 0.15)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calculate_rounded, size: 32.ri, color: _accent.withValues(alpha: 0.4)),
            SizedBox(height: 8.rh),
            Text('输入时薪查看预计收入',
                style: TextStyle(color: _textMuted, fontSize: 13.rf)),
          ],
        ),
      ),
    );
  }
}

// ─── NotesCard ────────────────────────────────────────────────────────────────

class _NotesCard extends StatelessWidget {
  final _Country country;
  const _NotesCard({required this.country});

  static const _globalNotes = [
    (Icons.schedule_rounded, '工时记录', '建议保留每次打工的排班记录，以备签证检查或税务申报使用'),
    (Icons.attach_money_rounded, '工资单保留', '每月工资单（Pay Stub）保存至少 3 年，报税和续签时需要提供'),
    (Icons.account_balance_rounded, '雇主合规', '务必通过合法雇主打工，现金交易无法积累税务记录，影响后续申请'),
  ];

  static const _usNotes = [
    (Icons.description_rounded, 'W-4 / W-2 表格', '入职填写 W-4 确定税额预扣；年底收到 W-2 用于报税'),
    (Icons.calendar_month_rounded, '年度报税截止', '每年 4 月 15 日前提交上一年度税表（F1 使用 1040NR）'),
  ];

  @override
  Widget build(BuildContext context) {
    final notes = [
      ..._globalNotes,
      if (country.currency == 'USD') ..._usNotes,
    ];

    return Container(
      padding: REdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16.rr),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates_rounded, size: 16.ri, color: _orange),
              SizedBox(width: 8.rw),
              Text('打工注意事项',
                  style: TextStyle(
                      color: _textPrimary, fontSize: 14.rf, fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 12.rh),
          ...notes.asMap().entries.map((e) {
            final n = e.value;
            final isLast = e.key == notes.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12.rh),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28.ri,
                    height: 28.ri,
                    decoration: BoxDecoration(
                      color: _orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(7.rr),
                    ),
                    child: Icon(n.$1, size: 14.ri, color: _orange),
                  ),
                  SizedBox(width: 10.rw),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.$2,
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 13.rf,
                              fontWeight: FontWeight.w600,
                            )),
                        SizedBox(height: 2.rh),
                        Text(n.$3,
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 12.rf,
                              height: 1.5,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
