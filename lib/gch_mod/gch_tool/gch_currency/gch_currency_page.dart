import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';

// ─── 色彩 ──────────────────────────────────────────────
const _bg = Color(0xFFF1EFF9);
const _card = Colors.white;
const _accent = Color(0xFF5969FF);
const _textPrimary = Color(0xFF1A1A2E);
const _textSecondary = Color(0xFF666680);
const _textMuted = Color(0xFF9999B3);
const _green = Color(0xFF2ECC71);

// ─── 汇率接口（按可用性排序）────────────────────────────
// jsDelivr / Fastly 在中国均有 CDN 节点，fawazahmed0 数据每日更新
const _apiUrls = [
  'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/cny.json',
  'https://fastly.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/cny.json',
  'https://cdn.statically.io/npm/@fawazahmed0/currency-api@latest/v1/currencies/cny.json',
  'https://open.er-api.com/v6/latest/CNY',
];

const _targetCodes = ['USD', 'HKD', 'EUR', 'GBP', 'AUD', 'CAD', 'JPY', 'KRW', 'SGD', 'NZD'];

// 离线兜底汇率（2025-06-21 参考值）
const _fallbackRates = {
  'USD': 0.1379,
  'HKD': 1.0741,
  'EUR': 0.1261,
  'GBP': 0.1089,
  'AUD': 0.2151,
  'CAD': 0.1908,
  'JPY': 20.74,
  'KRW': 193.5,
  'SGD': 0.1866,
  'NZD': 0.2326,
};

// ─── 货币列表 ──────────────────────────────────────────
const _currencies = [
  ('USD', '美元', '🇺🇸'),
  ('HKD', '港元', '🇭🇰'),
  ('EUR', '欧元', '🇪🇺'),
  ('GBP', '英镑', '🇬🇧'),
  ('AUD', '澳元', '🇦🇺'),
  ('CAD', '加元', '🇨🇦'),
  ('JPY', '日元', '🇯🇵'),
  ('KRW', '韩元', '🇰🇷'),
  ('SGD', '新元', '🇸🇬'),
  ('NZD', '纽元', '🇳🇿'),
];

const _integerCurrencies = {'JPY', 'KRW'};

// ─── 快捷金额 ──────────────────────────────────────────
const _quickAmounts = [100, 500, 1000, 5000, 10000];

class GchCurrencyPage extends StatefulWidget {
  const GchCurrencyPage({super.key});

  @override
  State<GchCurrencyPage> createState() => _GchCurrencyPageState();
}

class _GchCurrencyPageState extends State<GchCurrencyPage> {
  final TextEditingController _cnyController =
      TextEditingController(text: '100');
  final FocusNode _focusNode = FocusNode();

  Map<String, double> _rates = {};
  bool _loading = false;
  bool _hasError = false;
  String _updatedAt = '';

  @override
  void initState() {
    super.initState();
    _fetchRates();
  }

  @override
  void dispose() {
    _cnyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<Map<String, double>?> _tryFetch(String urlStr) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);
      final request = await client.getUrl(Uri.parse(urlStr));
      final response =
          await request.close().timeout(const Duration(seconds: 3));
      if (response.statusCode != 200) { client.close(); return null; }
      final body = await response.transform(utf8.decoder).join();
      client.close();
      final json = jsonDecode(body) as Map<String, dynamic>;

      // jsDelivr/@fawazahmed0 格式：{"cny": {"usd": 0.138, ...}}（小写）
      if (json.containsKey('cny')) {
        final raw = json['cny'] as Map<String, dynamic>;
        final result = <String, double>{};
        for (final code in _targetCodes) {
          final v = raw[code.toLowerCase()];
          if (v != null) result[code] = (v as num).toDouble();
        }
        return result.isNotEmpty ? result : null;
      }

      // 标准格式：{"rates": {"USD": 0.138, ...}}
      if (json.containsKey('rates')) {
        return (json['rates'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble()));
      }
    } catch (_) {}
    return null;
  }

  Future<void> _fetchRates() async {
    setState(() { _loading = true; _hasError = false; });

    // 三个 API 并发抢跑，3s 内取最快成功的结果
    Map<String, double>? result;
    try {
      final completer = Completer<Map<String, double>?>();
      var remaining = _apiUrls.length;

      for (final url in _apiUrls) {
        _tryFetch(url).then((rates) {
          if (rates != null && !completer.isCompleted) {
            completer.complete(rates);
          } else {
            remaining--;
            if (remaining == 0 && !completer.isCompleted) {
              completer.complete(null);
            }
          }
        }).catchError((_) {
          remaining--;
          if (remaining == 0 && !completer.isCompleted) {
            completer.complete(null);
          }
        });
      }

      result = await completer.future.timeout(const Duration(seconds: 3));
    } catch (_) {
      result = null;
    }

    if (!mounted) return;

    if (result != null) {
      final now = DateTime.now();
      setState(() {
        _rates = result!;
        _updatedAt =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        _loading = false;
      });
    } else {
      setState(() {
        _rates = Map.from(_fallbackRates);
        _updatedAt = '6月参考';
        _loading = false;
      });
    }
  }

  String _formatAmount(String code, double amount) {
    if (_integerCurrencies.contains(code)) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }

  String _formatRate(String code, double rate) {
    if (_integerCurrencies.contains(code)) {
      return rate.toStringAsFixed(1);
    }
    return rate.toStringAsFixed(4);
  }

  double get _cnyAmount => double.tryParse(_cnyController.text) ?? 0.0;

  void _setAmount(int amount) {
    _focusNode.unfocus();
    setState(() => _cnyController.text = amount.toString());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focusNode.unfocus(),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          title: Text(
            '汇率换算',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 17.rf,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: _accent),
              onPressed: _loading ? null : _fetchRates,
            ),
          ],
        ),
        body: Column(
          children: [
            if (_loading)
              const LinearProgressIndicator(
                color: _accent,
                backgroundColor: Colors.transparent,
                minHeight: 2,
              )
            else
              const SizedBox(height: 2),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                    horizontal: 16.rw, vertical: 8.rh),
                children: [
                  // ── CNY 输入卡片 ─────────────────────────────────────
                  _InputCard(
                    controller: _cnyController,
                    focusNode: _focusNode,
                    updatedAt: _updatedAt,
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 10.rh),

                  // ── 快捷金额 ─────────────────────────────────────────
                  SizedBox(
                    height: 34.rh,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: _quickAmounts.length,
                      separatorBuilder: (_, __) => SizedBox(width: 8.rw),
                      itemBuilder: (_, i) {
                        final amt = _quickAmounts[i];
                        final sel = _cnyController.text == amt.toString();
                        return GestureDetector(
                          onTap: () => _setAmount(amt),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: REdgeInsets.symmetric(
                                horizontal: 16, vertical: 0),
                            decoration: BoxDecoration(
                              color: sel ? _accent : _card,
                              borderRadius: BorderRadius.circular(20.rr),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              amt >= 10000
                                  ? '¥${amt ~/ 10000}万'
                                  : '¥$amt',
                              style: TextStyle(
                                color: sel ? Colors.white : _textSecondary,
                                fontSize: 13.rf,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 14.rh),

                  // ── 汇率结果 ─────────────────────────────────────────
                  if (_hasError)
                    _ErrorCard(onRetry: _fetchRates)
                  else
                    _ResultCard(
                      currencies: _currencies,
                      rates: _rates,
                      cnyAmount: _cnyAmount,
                      formatAmount: _formatAmount,
                      formatRate: _formatRate,
                      loading: _loading,
                    ),
                  SizedBox(height: 8.rh),

                  // ── 说明 ─────────────────────────────────────────────
                  Padding(
                    padding: REdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '汇率数据来自 fawazahmed0/exchange-api（每日更新）· 仅供参考，实际汇率以银行/兑换商为准',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 11.rf,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 32.rh),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 输入卡片 ──────────────────────────────────────────
class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.controller,
    required this.focusNode,
    required this.updatedAt,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String updatedAt;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5969FF), Color(0xFF9B6FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.rr),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5969FF).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: REdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🇨🇳', style: TextStyle(fontSize: 22.rf)),
              SizedBox(width: 8.rw),
              Text(
                'CNY  人民币',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14.rf,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (updatedAt.isNotEmpty)
                Text(
                  '更新于 $updatedAt',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11.rf,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.rh),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '¥',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 32.rf,
                  fontWeight: FontWeight.w300,
                ),
              ),
              SizedBox(width: 4.rw),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onChanged,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38.rf,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 38.rf,
                      fontWeight: FontWeight.w700,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── 汇率结果卡片 ──────────────────────────────────────
class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.currencies,
    required this.rates,
    required this.cnyAmount,
    required this.formatAmount,
    required this.formatRate,
    required this.loading,
  });

  final List<(String, String, String)> currencies;
  final Map<String, double> rates;
  final double cnyAmount;
  final String Function(String code, double amount) formatAmount;
  final String Function(String code, double rate) formatRate;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18.rr),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: currencies.asMap().entries.map((entry) {
          final i = entry.key;
          final (code, name, flag) = entry.value;
          final isLast = i == currencies.length - 1;
          final rate = rates[code];
          final converted = rate != null ? rate * cnyAmount : null;

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 18.rw, vertical: 14.rh),
                child: Row(
                  children: [
                    Text(flag, style: TextStyle(fontSize: 24.rf)),
                    SizedBox(width: 12.rw),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            code,
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 15.rf,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 1.rh),
                          Text(
                            name,
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 12.rf,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (loading || converted == null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 72.rw,
                            height: 18.rh,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEEEF5),
                              borderRadius: BorderRadius.circular(4.rr),
                            ),
                          ),
                          SizedBox(height: 4.rh),
                          Container(
                            width: 50.rw,
                            height: 12.rh,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEEEF5),
                              borderRadius: BorderRadius.circular(4.rr),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatAmount(code, converted),
                            style: TextStyle(
                              color: _accent,
                              fontSize: 20.rf,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 2.rh),
                          Text(
                            '1¥ = ${formatRate(code, rate!)}',
                            style: TextStyle(
                              color: _textMuted,
                              fontSize: 11.rf,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 18.rw,
                  endIndent: 18.rw,
                  color: const Color(0xFFF0F0F8),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── 错误卡片 ──────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRetry,
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16.rr),
        ),
        padding: EdgeInsets.symmetric(vertical: 40.rh),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, color: _textMuted, size: 36.ri),
              SizedBox(height: 12.rh),
              Text(
                '加载失败，点击重试',
                style: TextStyle(color: _textSecondary, fontSize: 14.rf),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
