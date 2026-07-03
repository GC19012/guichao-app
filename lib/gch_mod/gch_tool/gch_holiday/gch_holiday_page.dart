import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guichao/gch_aux/gch_nav_ext.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:guichao/gch_mod/gch_tool/gch_holiday/gch_holiday_data.dart';
import 'package:guichao/gch_base/gch_signal/gch_signal_hub.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class _C {
  static const Color bg = Color(0xFFF1EFF9);
  static const Color card = Colors.white;
  static const Color accent = Color(0xFF5969FF);
  static const Color primary = Color(0xFF333333);
  static const Color secondary = Color(0xFF666666);
  static const Color tertiary = Color(0xFF999999);
  static const Color passed = Color(0xFFBBBBBB);
  static const Color soon = Color(0xFFFF8C00);
}

class HolidayPage extends StatefulWidget {
  const HolidayPage({super.key});

  @override
  State<HolidayPage> createState() => _HolidayPageState();
}

class _HolidayPageState extends State<HolidayPage> {
  int _year = DateTime.now().year;
  bool _passedExpanded = false;

  @override
  Widget build(BuildContext context) {
    final all = GchHolidayData.allHolidays()
        .where((h) => h.date.year == _year)
        .toList();

    final passed = all.where((h) => GchHolidayData.daysUntil(h) < 0).toList();
    final upcoming = all.where((h) => GchHolidayData.daysUntil(h) >= 0).toList();

    // 构建列表 items：折叠头 + (展开时的已过列表) + 即将节日
    final items = <Widget>[
      if (passed.isNotEmpty)
        _PassedHeader(
          count: passed.length,
          expanded: _passedExpanded,
          onTap: () => setState(() => _passedExpanded = !_passedExpanded),
        ),
      if (_passedExpanded)
        ...passed.map((h) => _HolidayRow(holiday: h)),
      if (_passedExpanded && upcoming.isNotEmpty)
        SizedBox(height: 6.rh),
      ...upcoming.map((h) => _HolidayRow(holiday: h)),
    ];

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: _C.primary, size: 20.ri),
          onPressed: () => context.safePop(),
        ),
        title: Text(
          '节假日',
          style: TextStyle(
            color: _C.primary,
            fontSize: 18.rf,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          _YearSwitcher(
            year: _year,
            onChanged: (y) => setState(() {
              _year = y;
              _passedExpanded = false;
            }),
          ),
          SizedBox(width: 8.rw),
        ],
      ),
      body: ListView(
        padding: REdgeInsets.fromLTRB(16, 8, 16, 32),
        children: items,
      ),
    );
  }
}

// ── 已过节日折叠头 ───────────────────────────────────────────────────────────

class _PassedHeader extends StatelessWidget {
  final int count;
  final bool expanded;
  final VoidCallback onTap;

  const _PassedHeader({
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: REdgeInsets.only(bottom: 10),
        padding: REdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _C.card.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14.rr),
          border: Border.all(
            color: const Color(0xFFE0DFF0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.history,
              color: _C.tertiary,
              size: 18.ri,
            ),
            SizedBox(width: 8.rw),
            Text(
              '已过节日',
              style: TextStyle(
                color: _C.tertiary,
                fontSize: 14.rf,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 6.rw),
            Container(
              padding: REdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E7F5),
                borderRadius: BorderRadius.circular(10.rr),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: _C.tertiary,
                  fontSize: 11.rf,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: _C.tertiary,
                size: 20.ri,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearSwitcher extends StatelessWidget {
  final int year;
  final ValueChanged<int> onChanged;

  const _YearSwitcher({required this.year, required this.onChanged});

  void _openPicker(BuildContext context) {
    final minYear = DateTime.now().year;
    final maxYear = minYear + 4;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _GchYearPickerSheet(
        selected: year,
        minYear: minYear,
        maxYear: maxYear,
        onConfirm: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final minYear = DateTime.now().year;
    final maxYear = minYear + 4;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left,
              color: year > minYear ? _C.accent : _C.tertiary, size: 22.ri),
          onPressed: year > minYear ? () => onChanged(year - 1) : null,
        ),
        GestureDetector(
          onTap: () => _openPicker(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$year',
                style: TextStyle(
                  color: _C.accent,
                  fontSize: 15.rf,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.rh),
              Container(
                width: 20.rw,
                height: 2.rh,
                decoration: BoxDecoration(
                  color: _C.accent.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right,
              color: year < maxYear ? _C.accent : _C.tertiary, size: 22.ri),
          onPressed: year < maxYear ? () => onChanged(year + 1) : null,
        ),
      ],
    );
  }
}

// ── 年份滚轮底部弹窗 ─────────────────────────────────────────────────────────

class _GchYearPickerSheet extends StatefulWidget {
  final int selected;
  final int minYear;
  final int maxYear;
  final ValueChanged<int> onConfirm;

  const _GchYearPickerSheet({
    required this.selected,
    required this.minYear,
    required this.maxYear,
    required this.onConfirm,
  });

  @override
  State<_GchYearPickerSheet> createState() => _GchYearPickerSheetState();
}

class _GchYearPickerSheetState extends State<_GchYearPickerSheet> {
  late int _current;
  late FixedExtentScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    _current = widget.selected;
    _ctrl = FixedExtentScrollController(
        initialItem: widget.selected - widget.minYear);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(
        widget.maxYear - widget.minYear + 1, (i) => widget.minYear + i);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.rr)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12.rh),
          Container(
            width: 36.rw,
            height: 4.rh,
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 18.rh),
          Text(
            '选择年份',
            style: TextStyle(
              color: _C.primary,
              fontSize: 17.rf,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.rh),
          SizedBox(
            height: 220.rh,
            child: Stack(
              children: [
                // 滚轮
                ListWheelScrollView.useDelegate(
                  controller: _ctrl,
                  itemExtent: 54.rh,
                  perspective: 0.004,
                  diameterRatio: 2.8,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (i) =>
                      setState(() => _current = years[i]),
                  childDelegate: ListWheelChildListDelegate(
                    children: years.map((y) {
                      final sel = y == _current;
                      return Center(
                        child: Text(
                          '$y 年',
                          style: TextStyle(
                            color: sel ? _C.accent : _C.secondary,
                            fontSize: sel ? 22.rf : 17.rf,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // 选中行分隔线
                IgnorePointer(
                  child: Center(
                    child: Container(
                      height: 54.rh,
                      margin: REdgeInsets.symmetric(horizontal: 48),
                      decoration: BoxDecoration(
                        border: Border.symmetric(
                          horizontal: BorderSide(
                            color: _C.accent.withValues(alpha: 0.18),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 顶部渐隐
                Positioned(
                  top: 0, left: 0, right: 0,
                  height: 70.rh,
                  child: IgnorePointer(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, Color(0x00FFFFFF)],
                        ),
                      ),
                    ),
                  ),
                ),
                // 底部渐隐
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  height: 70.rh,
                  child: IgnorePointer(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.white, Color(0x00FFFFFF)],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.rh),
          Padding(
            padding: REdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 50.rh,
              child: ElevatedButton(
                onPressed: () {
                  widget.onConfirm(_current);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.rr),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '确认',
                  style:
                      TextStyle(fontSize: 16.rf, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          SizedBox(height: 32.rh),
        ],
      ),
    );
  }
}

class _HolidayRow extends StatelessWidget {
  final GchHoliday holiday;

  const _HolidayRow({required this.holiday});

  @override
  Widget build(BuildContext context) {
    final days = GchHolidayData.daysUntil(holiday);
    final isPassed = days < 0;
    final isToday = days == 0;
    final isSoon = days > 0 && days <= 7;

    return GestureDetector(
      onTap: isPassed ? null : () => _showGreetings(context),
      child: Container(
        margin: REdgeInsets.only(bottom: 10),
        padding: REdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isPassed ? _C.card.withValues(alpha: 0.6) : _C.card,
          borderRadius: BorderRadius.circular(14.rr),
          boxShadow: isPassed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Text(
              holiday.emoji,
              style: TextStyle(fontSize: 24.rf),
            ),
            SizedBox(width: 12.rw),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    holiday.name,
                    style: TextStyle(
                      color: isPassed ? _C.passed : _C.primary,
                      fontSize: 15.rf,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 3.rh),
                  Text(
                    _dateLabel(holiday.date, holiday.lunarDesc),
                    style: TextStyle(
                      color: isPassed ? _C.passed : _C.secondary,
                      fontSize: 12.rf,
                    ),
                  ),
                ],
              ),
            ),
            _DaysBadge(days: days, isPassed: isPassed, isToday: isToday, isSoon: isSoon),
            if (!isPassed) ...[
              SizedBox(width: 6.rw),
              Icon(Icons.chevron_right, color: _C.tertiary, size: 18.ri),
            ],
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime date, String lunar) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final base = '${date.year}年$m月$d日';
    return lunar.isEmpty ? base : '$base · $lunar';
  }

  void _showGreetings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _GreetingSheet(holiday: holiday),
    );
  }
}

class _DaysBadge extends StatelessWidget {
  final int days;
  final bool isPassed;
  final bool isToday;
  final bool isSoon;

  const _DaysBadge({
    required this.days,
    required this.isPassed,
    required this.isToday,
    required this.isSoon,
  });

  @override
  Widget build(BuildContext context) {
    if (isPassed) {
      return Text(
        '已过',
        style: TextStyle(color: _C.passed, fontSize: 12.rf),
      );
    }
    if (isToday) {
      return Container(
        padding: REdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _C.accent,
          borderRadius: BorderRadius.circular(20.rr),
        ),
        child: Text(
          '今天',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11.rf,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Text(
      '$days天后',
      style: TextStyle(
        color: isSoon ? _C.soon : _C.accent,
        fontSize: 13.rf,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ── 祝福语弹窗 ──────────────────────────────────────────────────────────────

class _GreetingSheet extends ConsumerStatefulWidget {
  final GchHoliday holiday;

  const _GreetingSheet({required this.holiday});

  @override
  ConsumerState<_GreetingSheet> createState() => _GreetingSheetState();
}

class _GreetingSheetState extends ConsumerState<_GreetingSheet> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final h = widget.holiday;
    return Container(
      margin: REdgeInsets.fromLTRB(12, 0, 12, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.rr),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8.rh),
          Container(
            width: 36.rw,
            height: 4.rh,
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2.rr),
            ),
          ),
          SizedBox(height: 20.rh),
          Text(
            '${h.emoji} ${h.name}',
            style: TextStyle(
              color: _C.primary,
              fontSize: 20.rf,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.rh),
          Text(
            _dateStr(h.date, h.lunarDesc),
            style: TextStyle(color: _C.secondary, fontSize: 13.rf),
          ),
          Divider(
            height: 28.rh,
            indent: 20.rw,
            endIndent: 20.rw,
            color: const Color(0xFFF0F0F0),
          ),
          Padding(
            padding: REdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                for (int i = 0; i < h.greetings.length; i++)
                  _GreetingCard(
                    text: h.greetings[i],
                    selected: _selected == i,
                    onTap: () => setState(() => _selected = i),
                  ),
              ],
            ),
          ),
          SizedBox(height: 16.rh),
          Padding(
            padding: REdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 48.rh,
              child: ElevatedButton(
                onPressed: () => _copy(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.rr),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '复制祝福语',
                  style: TextStyle(
                    fontSize: 15.rf,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20.rh),
        ],
      ),
    );
  }

  String _dateStr(DateTime date, String lunar) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final base = '${date.year}年$m月$d日';
    return lunar.isEmpty ? base : '$base · $lunar';
  }

  void _copy(BuildContext context) {
    final text = widget.holiday.greetings[_selected];
    Clipboard.setData(ClipboardData(text: text));
    Navigator.of(context).pop();
    ref.read(gchSignalHubProvider).flashSuccess('祝福语已复制');
  }
}

class _GreetingCard extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _GreetingCard({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: REdgeInsets.only(bottom: 10),
        padding: REdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? _C.accent.withValues(alpha: 0.08)
              : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12.rr),
          border: Border.all(
            color: selected ? _C.accent.withValues(alpha: 0.4) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? _C.accent : _C.tertiary,
              size: 18.ri,
            ),
            SizedBox(width: 10.rw),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: _C.primary,
                  fontSize: 14.rf,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
