import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';

const _bg = Color(0xFFF1EFF9);
const _accent = Color(0xFF2ECC9A);
const _card = Colors.white;
const _textPrimary = Color(0xFF1A1A2E);
const _textSecondary = Color(0xFF666680);
const _textMuted = Color(0xFF9999B3);
const _bestColor = Color(0xFF2ECC9A);
const _warnColor = Color(0xFFFF7043);

// ─── 数据模型 ──────────────────────────────────────────────────────────────────

class _Platform {
  final String name;
  final String emoji;
  final Color color;
  final double feeRate;       // 手续费率，如 0.0041 = 0.41%
  final double fixedFeeCny;   // 固定手续费（人民币）
  final double spreadRate;    // 汇率差价率，如 0.005 = 0.5% 贵于中间价
  final String speed;
  final String note;

  const _Platform({
    required this.name,
    required this.emoji,
    required this.color,
    required this.feeRate,
    required this.fixedFeeCny,
    required this.spreadRate,
    required this.speed,
    required this.note,
  });

  /// 预计收到金额（目标货币）
  double received(double amountCny, double midRate) {
    if (amountCny <= fixedFeeCny) return 0;
    final afterFixed = amountCny - fixedFeeCny;
    final afterFee = afterFixed * (1 - feeRate);
    final effectiveRate = midRate * (1 - spreadRate);
    return afterFee * effectiveRate;
  }

  /// 综合成本（CNY等值损失）
  double costCny(double amountCny, double midRate) {
    final r = received(amountCny, midRate);
    if (r <= 0) return amountCny;
    return amountCny - r / midRate;
  }

  /// 综合费率（用于展示，无输入金额时）
  String get totalCostLabel {
    final parts = <String>[];
    if (fixedFeeCny > 0) parts.add('固定 ¥${fixedFeeCny.toStringAsFixed(0)}');
    if (feeRate > 0) parts.add('${(feeRate * 100).toStringAsFixed(2)}% 手续费');
    if (spreadRate > 0) parts.add('${(spreadRate * 100).toStringAsFixed(1)}% 汇率差');
    return parts.isEmpty ? '免费' : parts.join(' + ');
  }
}

// ─── 参考汇率（CNY → X，仅供估算参考）───────────────────────────────────────────

const _currencies = ['USD', 'GBP', 'AUD', 'CAD', 'JPY', 'SGD', 'KRW'];
const _midRates = {
  'USD': 0.1378,
  'GBP': 0.1088,
  'AUD': 0.2118,
  'CAD': 0.1904,
  'JPY': 21.05,
  'SGD': 0.1845,
  'KRW': 189.5,
};
const _currencySymbols = {
  'USD': '\$',
  'GBP': '£',
  'AUD': 'A\$',
  'CAD': 'C\$',
  'JPY': '¥',
  'SGD': 'S\$',
  'KRW': '₩',
};

// ─── 平台数据 ──────────────────────────────────────────────────────────────────

const _platforms = [
  _Platform(
    name: 'Wise',
    emoji: '💳',
    color: Color(0xFF9FE870),
    feeRate: 0.0041,
    fixedFeeCny: 0,
    spreadRate: 0.0,
    speed: '1–2 工作日',
    note: '使用真实中间市场汇率，费率透明，无隐藏费用。大额或中额首选，综合成本最低',
  ),
  _Platform(
    name: '支付宝国际汇款',
    emoji: '🔵',
    color: Color(0xFF1677FF),
    feeRate: 0.005,
    fixedFeeCny: 0,
    spreadRate: 0.004,
    speed: '实时到账',
    note: '到账极快，适合小额急用资金。汇率含小幅差价，金额越大差距越明显',
  ),
  _Platform(
    name: '微信跨境汇款',
    emoji: '💚',
    color: Color(0xFF07C160),
    feeRate: 0.005,
    fixedFeeCny: 0,
    spreadRate: 0.008,
    speed: '实时',
    note: '微信生态内操作便捷，仅限国内有微信银行卡绑定的用户',
  ),
  _Platform(
    name: 'Remitly',
    emoji: '🟢',
    color: Color(0xFF00A664),
    feeRate: 0.0,
    fixedFeeCny: 0,
    spreadRate: 0.016,
    speed: '数分钟–4小时',
    note: '首次转账免手续费，汇率含差价。后续转账汇率差价约 1.5–2%',
  ),
  _Platform(
    name: 'Western Union',
    emoji: '🟡',
    color: Color(0xFFFFCC00),
    feeRate: 0.0,
    fixedFeeCny: 36,
    spreadRate: 0.025,
    speed: '实时–1 天',
    note: '收款方无银行账户可现金提取（全球 50 万+ 网点），但汇率差价偏高',
  ),
  _Platform(
    name: '银行电汇',
    emoji: '🏦',
    color: Color(0xFF5969FF),
    feeRate: 0.0,
    fixedFeeCny: 150,
    spreadRate: 0.015,
    speed: '3–5 工作日',
    note: '大额汇款首选（>5 万元），固定手续费 ¥100–200，汇率使用银行牌价（偏低）',
  ),
  _Platform(
    name: 'PayPal',
    emoji: '🅿️',
    color: Color(0xFF003087),
    feeRate: 0.0349,
    fixedFeeCny: 0,
    spreadRate: 0.025,
    speed: '1–3 天',
    note: '综合费率最高（手续费 3.49% + 汇率差价 2.5%），仅在对方只接受 PayPal 时使用',
  ),
];

// ─── 场景推荐 ──────────────────────────────────────────────────────────────────

const _scenarios = [
  (icon: Icons.bolt_rounded, color: Color(0xFFFF7043), title: '急用小额（< 3000元）', text: '支付宝国际 / 微信跨境实时到账，牺牲少量汇率差换取速度'),
  (icon: Icons.balance_rounded, color: Color(0xFF5969FF), title: '常规金额（3000–50000元）', text: 'Wise 综合成本最低，到账 1–2 天，日常生活费汇款首选'),
  (icon: Icons.account_balance_rounded, color: Color(0xFF2ECC9A), title: '大额汇款（> 50000元）', text: '银行电汇固定手续费更划算；或 Wise 限额内+银行补充'),
  (icon: Icons.person_off_rounded, color: Color(0xFFFFB300), title: '对方无银行账户', text: 'Western Union 现金领取网点遍布全球，紧急情况备用'),
];

// ─── Page ─────────────────────────────────────────────────────────────────────

class GchRemitPage extends StatefulWidget {
  const GchRemitPage({super.key});

  @override
  State<GchRemitPage> createState() => _PageState();
}

class _PageState extends State<GchRemitPage> {
  final _ctrl = TextEditingController();
  String _currency = 'USD';
  double _amount = 0;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final v = double.tryParse(_ctrl.text.replaceAll(',', '')) ?? 0;
      if (v != _amount) setState(() => _amount = v);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _midRate => _midRates[_currency] ?? 1.0;
  String get _symbol => _currencySymbols[_currency] ?? '';

  List<_Platform> get _sorted {
    if (_amount <= 0) return _platforms;
    final list = List<_Platform>.from(_platforms);
    list.sort((a, b) => b.received(_amount, _midRate).compareTo(a.received(_amount, _midRate)));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: Text(
          '转账比价',
          style: TextStyle(color: _textPrimary, fontSize: 17.rf, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: _textPrimary),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.rw, vertical: 12.rh),
          children: [
            // 计算器卡片
            _CalculatorCard(
              ctrl: _ctrl,
              selectedCurrency: _currency,
              onCurrencyChanged: (c) => setState(() => _currency = c),
            ),
            SizedBox(height: 16.rh),

            // 对比列表
            _SectionLabel('各平台对比', _amount > 0 ? '已按到账金额排序' : '输入金额可预估到账'),
            SizedBox(height: 8.rh),
            _ComparisonCard(
              platforms: _sorted,
              amount: _amount,
              midRate: _midRate,
              symbol: _symbol,
            ),
            SizedBox(height: 16.rh),

            // 场景推荐
            _SectionLabel('场景推荐', null),
            SizedBox(height: 8.rh),
            _ScenarioCard(),
            SizedBox(height: 16.rh),

            // 注意事项
            _SectionLabel('转账注意事项', null),
            SizedBox(height: 8.rh),
            _TipsCard(),
            SizedBox(height: 16.rh),

            // 免责
            Padding(
              padding: REdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '⚠️ 以上汇率和费率均为参考数据，实际费率以各平台当时显示为准。汇率随市场实时波动，大额转账前建议在平台内实际比较。',
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

// ─── CalculatorCard ───────────────────────────────────────────────────────────

class _CalculatorCard extends StatelessWidget {
  final TextEditingController ctrl;
  final String selectedCurrency;
  final ValueChanged<String> onCurrencyChanged;

  const _CalculatorCard({
    required this.ctrl,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: REdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A2A), Color(0xFF2ECC9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.rr),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2ECC9A).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('汇款计算器',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12.rf,
                fontWeight: FontWeight.w500,
              )),
          SizedBox(height: 10.rh),
          // 输入框
          Container(
            padding: REdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.rr),
            ),
            child: Row(
              children: [
                Text('¥',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.rf,
                      fontWeight: FontWeight.w300,
                    )),
                SizedBox(width: 6.rw),
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.rf,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 24.rf,
                        fontWeight: FontWeight.w300,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                Text('CNY',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14.rf,
                    )),
              ],
            ),
          ),
          SizedBox(height: 12.rh),
          // 货币选择
          Text('目标货币',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11.rf,
              )),
          SizedBox(height: 8.rh),
          SizedBox(
            height: 32.rh,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _currencies.length,
              separatorBuilder: (_, __) => SizedBox(width: 6.rw),
              itemBuilder: (_, i) {
                final c = _currencies[i];
                final active = c == selectedCurrency;
                return GestureDetector(
                  onTap: () => onCurrencyChanged(c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: REdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16.rr),
                    ),
                    child: Text(
                      c,
                      style: TextStyle(
                        color: active ? _accent : Colors.white,
                        fontSize: 13.rf,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ComparisonCard ───────────────────────────────────────────────────────────

class _ComparisonCard extends StatelessWidget {
  final List<_Platform> platforms;
  final double amount;
  final double midRate;
  final String symbol;
  const _ComparisonCard({
    required this.platforms,
    required this.amount,
    required this.midRate,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16.rr),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: platforms.asMap().entries.map((e) {
          final p = e.value;
          final isBest = amount > 0 && e.key == 0;
          final isLast = e.key == platforms.length - 1;
          final recv = amount > 0 ? p.received(amount, midRate) : null;
          final cost = amount > 0 ? p.costCny(amount, midRate) : null;

          return Column(
            children: [
              _PlatformRow(
                platform: p,
                isBest: isBest,
                received: recv,
                costCny: cost,
                symbol: symbol,
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16.rw,
                  endIndent: 16.rw,
                  color: const Color(0xFFF0F0F8),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _PlatformRow extends StatefulWidget {
  final _Platform platform;
  final bool isBest;
  final double? received;
  final double? costCny;
  final String symbol;
  const _PlatformRow({
    required this.platform,
    required this.isBest,
    this.received,
    this.costCny,
    required this.symbol,
  });

  @override
  State<_PlatformRow> createState() => _PlatformRowState();
}

class _PlatformRowState extends State<_PlatformRow> {
  bool _expanded = false;

  String _formatReceived(double v) {
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(2)}万';
    if (v >= 1000) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.platform;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: REdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 平台 emoji
                Container(
                  width: 40.ri,
                  height: 40.ri,
                  decoration: BoxDecoration(
                    color: p.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10.rr),
                  ),
                  child: Center(child: Text(p.emoji, style: TextStyle(fontSize: 20.rf))),
                ),
                SizedBox(width: 12.rw),
                // 名称 + 费率说明
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(p.name,
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 14.rf,
                                fontWeight: FontWeight.w600,
                              )),
                          if (widget.isBest) ...[
                            SizedBox(width: 6.rw),
                            Container(
                              padding: REdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: _bestColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4.rr),
                              ),
                              child: Text('最优',
                                  style: TextStyle(
                                    color: _bestColor,
                                    fontSize: 10.rf,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 2.rh),
                      Text(p.speed,
                          style: TextStyle(color: _textMuted, fontSize: 11.rf)),
                    ],
                  ),
                ),
                // 到账金额 或 费率
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.received != null && widget.received! > 0) ...[
                      Text(
                        '${widget.symbol}${_formatReceived(widget.received!)}',
                        style: TextStyle(
                          color: widget.isBest ? _bestColor : _textPrimary,
                          fontSize: 16.rf,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2.rh),
                      Text(
                        '损耗 ¥${widget.costCny!.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: widget.isBest ? _bestColor.withValues(alpha: 0.7) : _textMuted,
                          fontSize: 10.rf,
                        ),
                      ),
                    ] else ...[
                      Text(
                        p.feeRate > 0
                            ? '${(p.feeRate * 100).toStringAsFixed(2)}%'
                            : p.fixedFeeCny > 0
                                ? '¥${p.fixedFeeCny.toStringAsFixed(0)}'
                                : '免手续费',
                        style: TextStyle(
                          color: p.spreadRate < 0.01 ? _bestColor : _textSecondary,
                          fontSize: 15.rf,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.rh),
                      Text(
                        '+ ${(p.spreadRate * 100).toStringAsFixed(1)}% 汇率差',
                        style: TextStyle(color: _textMuted, fontSize: 10.rf),
                      ),
                    ],
                  ],
                ),
                SizedBox(width: 4.rw),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 16.ri,
                  color: _textMuted,
                ),
              ],
            ),
            if (_expanded) ...[
              SizedBox(height: 10.rh),
              Container(
                padding: REdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8FC),
                  borderRadius: BorderRadius.circular(10.rr),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.note,
                        style: TextStyle(color: _textSecondary, fontSize: 12.rf, height: 1.6)),
                    SizedBox(height: 8.rh),
                    Text('综合费用构成：${p.totalCostLabel}',
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 11.rf,
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── ScenarioCard ─────────────────────────────────────────────────────────────

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16.rr),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: _scenarios.asMap().entries.map((e) {
          final s = e.value;
          final isLast = e.key == _scenarios.length - 1;
          return Column(
            children: [
              Padding(
                padding: REdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32.ri,
                      height: 32.ri,
                      decoration: BoxDecoration(
                        color: s.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8.rr),
                      ),
                      child: Icon(s.icon, size: 16.ri, color: s.color),
                    ),
                    SizedBox(width: 12.rw),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title,
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 13.rf,
                                fontWeight: FontWeight.w600,
                              )),
                          SizedBox(height: 3.rh),
                          Text(s.text,
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
              ),
              if (!isLast)
                Divider(height: 1, thickness: 1, indent: 16.rw, endIndent: 16.rw, color: const Color(0xFFF0F0F8)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── TipsCard ─────────────────────────────────────────────────────────────────

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  static const _tips = [
    (icon: Icons.swap_horiz_rounded, text: '汇率高时换汇（CNY走强），汇率低时少换——可在"货币换算"页面查看当前汇率趋势'),
    (icon: Icons.schedule_rounded, text: '避开节假日前后转账，外汇市场流动性低，汇率差价通常扩大 0.5–1%'),
    (icon: Icons.account_balance_rounded, text: '银行牌价通常比中间汇率低 1–2%，同等金额下使用 Wise 或 Remitly 可多收数十到数百元'),
    (icon: Icons.verified_rounded, text: '首次使用新平台前完成 KYC 身份验证，避免汇款时才发现被拦截导致资金延误'),
    (icon: Icons.warning_amber_rounded, text: '大额汇款（>5万元）需符合国内年度换汇额度限制（\$50,000/人/年），超出需额外申报'),
  ];

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
        children: _tips.asMap().entries.map((e) {
          final t = e.value;
          final isLast = e.key == _tips.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12.rh),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(t.icon, size: 16.ri, color: _accent),
                SizedBox(width: 10.rw),
                Expanded(
                  child: Text(t.text,
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 12.rf,
                        height: 1.55,
                      )),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── SectionLabel ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  final String? sub;
  const _SectionLabel(this.title, this.sub);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 14.rf,
              fontWeight: FontWeight.w700,
            )),
        if (sub != null) ...[
          SizedBox(width: 8.rw),
          Text(sub!,
              style: TextStyle(color: _textMuted, fontSize: 11.rf)),
        ],
      ],
    );
  }
}
