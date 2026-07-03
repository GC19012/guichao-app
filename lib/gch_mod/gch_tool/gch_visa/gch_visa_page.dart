import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:guichao/gch_base/gch_signal/gch_signal_svc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// ─── 色彩 ──────────────────────────────────────────────────────────────────────
const _bg = Color(0xFFF1EFF9);
const _card = Colors.white;
const _accent = Color(0xFF5969FF);
const _textPrimary = Color(0xFF1A1A2E);
const _textSecondary = Color(0xFF666680);
const _textMuted = Color(0xFF9999B3);

// ─── 证件类型 ──────────────────────────────────────────────────────────────────
enum VisaDocType {
  visa('签证', Icons.article_rounded, Color(0xFF5969FF)),
  student('学生证', Icons.school_rounded, Color(0xFF2ECC9A)),
  residence('居留许可', Icons.home_rounded, Color(0xFF9B6FFF)),
  passport('护照', Icons.book_rounded, Color(0xFFFF7043)),
  other('其他证件', Icons.badge_rounded, Color(0xFF78909C));

  const VisaDocType(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

// ─── 数据模型 ──────────────────────────────────────────────────────────────────
class VisaDoc {
  final String id;
  final VisaDocType type;
  final String label;
  final String country;
  final DateTime expiryDate;
  final int? totalEntries;
  final int usedEntries;
  final String notes;

  const VisaDoc({
    required this.id,
    required this.type,
    required this.label,
    required this.country,
    required this.expiryDate,
    this.totalEntries,
    this.usedEntries = 0,
    this.notes = '',
  });

  int get daysLeft {
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final exp =
        DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return exp.difference(today).inDays;
  }

  bool get isExpired => daysLeft < 0;
  bool get isUrgent => daysLeft >= 0 && daysLeft <= 7;
  bool get isWarning => daysLeft > 7 && daysLeft <= 30;

  Color get urgencyColor {
    if (isExpired) return const Color(0xFF9E9E9E);
    if (isUrgent) return const Color(0xFFE53935);
    if (isWarning) return const Color(0xFFFF9800);
    return const Color(0xFF2ECC9A);
  }

  int? get remainingEntries =>
      totalEntries != null ? totalEntries! - usedEntries : null;

  VisaDoc copyWith({
    VisaDocType? type,
    String? label,
    String? country,
    DateTime? expiryDate,
    Object? totalEntries = _sentinel,
    int? usedEntries,
    String? notes,
  }) {
    return VisaDoc(
      id: id,
      type: type ?? this.type,
      label: label ?? this.label,
      country: country ?? this.country,
      expiryDate: expiryDate ?? this.expiryDate,
      totalEntries: totalEntries == _sentinel
          ? this.totalEntries
          : totalEntries as int?,
      usedEntries: usedEntries ?? this.usedEntries,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'label': label,
        'country': country,
        'expiryDate': expiryDate.toIso8601String(),
        'totalEntries': totalEntries,
        'usedEntries': usedEntries,
        'notes': notes,
      };

  factory VisaDoc.fromJson(Map<String, dynamic> j) => VisaDoc(
        id: j['id'] as String,
        type: VisaDocType.values.firstWhere(
            (t) => t.name == j['type'],
            orElse: () => VisaDocType.visa),
        label: j['label'] as String,
        country: j['country'] as String,
        expiryDate: DateTime.parse(j['expiryDate'] as String),
        totalEntries: j['totalEntries'] as int?,
        usedEntries: (j['usedEntries'] as int?) ?? 0,
        notes: (j['notes'] as String?) ?? '',
      );
}

const _sentinel = Object();

// ─── 本地存储 ──────────────────────────────────────────────────────────────────
class _VisaRepo {
  static const _key = 'gch_visa_docs_v1';

  static Future<List<VisaDoc>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list
        .map((s) =>
            VisaDoc.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveAll(List<VisaDoc> docs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _key, docs.map((d) => jsonEncode(d.toJson())).toList());
  }
}

List<VisaDoc> _sortDocs(List<VisaDoc> docs) {
  final list = List<VisaDoc>.from(docs);
  list.sort((a, b) {
    if (a.isExpired && !b.isExpired) return 1;
    if (!a.isExpired && b.isExpired) return -1;
    return a.daysLeft.compareTo(b.daysLeft);
  });
  return list;
}

// ─── 主页面 ───────────────────────────────────────────────────────────────────
class GchVisaPage extends StatefulWidget {
  const GchVisaPage({super.key});

  @override
  State<GchVisaPage> createState() => _GchVisaPageState();
}

class _GchVisaPageState extends State<GchVisaPage> {
  List<VisaDoc> _docs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final docs = await _VisaRepo.loadAll();
    if (!mounted) return;
    setState(() {
      _docs = _sortDocs(docs);
      _loading = false;
    });
    _checkDueNotifications(_docs);
  }

  void _checkDueNotifications(List<VisaDoc> docs) {
    for (final doc in docs) {
      final d = doc.daysLeft;
      if (d == 30 || d == 7 || d == 1) {
        GchSignalSvc.instance.systemNotification.warning(
          '「${doc.label}」还有 $d 天到期，请及时处理！',
          title: '证件到期提醒',
        );
      } else if (d == 0) {
        GchSignalSvc.instance.systemNotification.error(
          '「${doc.label}」今天到期！',
          title: '证件到期警告',
        );
      }
    }
  }

  Future<void> _openForm({VisaDoc? editing}) async {
    final result = await Navigator.of(context, rootNavigator: true).push<VisaDoc>(
      MaterialPageRoute(
        builder: (_) => _VisaFormPage(editing: editing),
        fullscreenDialog: true,
      ),
    );
    if (result == null) return;
    final updated = List<VisaDoc>.from(_docs);
    final idx = updated.indexWhere((d) => d.id == result.id);
    if (idx >= 0) {
      updated[idx] = result;
    } else {
      updated.add(result);
    }
    final sorted = _sortDocs(updated);
    await _VisaRepo.saveAll(sorted);
    if (mounted) setState(() => _docs = sorted);
  }

  Future<void> _useEntry(VisaDoc doc) async {
    if (doc.remainingEntries != null && doc.remainingEntries! <= 0) return;
    final updated = doc.copyWith(usedEntries: doc.usedEntries + 1);
    final list = _docs.map((d) => d.id == doc.id ? updated : d).toList();
    final sorted = _sortDocs(list);
    await _VisaRepo.saveAll(sorted);
    if (mounted) setState(() => _docs = sorted);
  }

  Future<void> _delete(VisaDoc doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除证件'),
        content: Text('确定删除「${doc.label}」？此操作不可恢复。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除',
                  style: TextStyle(color: Color(0xFFE53935)))),
        ],
      ),
    );
    if (ok != true) return;
    final list = _docs.where((d) => d.id != doc.id).toList();
    await _VisaRepo.saveAll(list);
    if (mounted) setState(() => _docs = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: Text('签证提醒',
            style: TextStyle(
                color: _textPrimary,
                fontSize: 17.rf,
                fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: _accent, size: 26.ri),
            tooltip: '添加证件',
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _docs.isEmpty
              ? _EmptyState(onAdd: () => _openForm())
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(16.rw, 4.rh, 16.rw,
                      MediaQuery.of(context).padding.bottom + 16.rh),
                  itemCount: _docs.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) return _SummaryBar(docs: _docs);
                    final doc = _docs[i - 1];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.rh),
                      child: _DocCard(
                        doc: doc,
                        onTap: () => _openForm(editing: doc),
                        onDelete: () => _delete(doc),
                        onUseEntry:
                            doc.totalEntries != null ? () => _useEntry(doc) : null,
                      ),
                    );
                  },
                ),
    );
  }
}

// ─── 摘要条 ───────────────────────────────────────────────────────────────────
class _SummaryBar extends StatelessWidget {
  final List<VisaDoc> docs;
  const _SummaryBar({required this.docs});

  @override
  Widget build(BuildContext context) {
    final urgent = docs.where((d) => !d.isExpired && d.daysLeft <= 30).length;
    final expired = docs.where((d) => d.isExpired).length;
    return Padding(
      padding: EdgeInsets.only(top: 8.rh, bottom: 16.rh),
      child: Wrap(
        spacing: 8.rw,
        runSpacing: 6.rh,
        children: [
          _Chip('共 ${docs.length} 份证件', _accent),
          if (urgent > 0) _Chip('$urgent 份即将到期', const Color(0xFFFF9800)),
          if (expired > 0) _Chip('$expired 份已过期', const Color(0xFFE53935)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: REdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20.rr),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11.rf, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── 证件卡片 ─────────────────────────────────────────────────────────────────
class _DocCard extends StatelessWidget {
  final VisaDoc doc;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onUseEntry;

  const _DocCard({
    required this.doc,
    required this.onTap,
    required this.onDelete,
    this.onUseEntry,
  });

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final days = doc.daysLeft;
    final uc = doc.urgencyColor;

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.rw),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18.rr),
        ),
        child: Icon(Icons.delete_rounded,
            color: const Color(0xFFE53935), size: 22.ri),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(18.rr),
            border: Border(left: BorderSide(color: uc, width: 4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: REdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44.ri,
                    height: 44.ri,
                    decoration: BoxDecoration(
                      color: doc.type.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.rr),
                    ),
                    child: Icon(doc.type.icon,
                        size: 20.ri, color: doc.type.color),
                  ),
                  SizedBox(width: 12.rw),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.label,
                            style: TextStyle(
                                color: _textPrimary,
                                fontSize: 15.rf,
                                fontWeight: FontWeight.w700)),
                        SizedBox(height: 4.rh),
                        Row(
                          children: [
                            Container(
                              padding: REdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: doc.type.color
                                    .withValues(alpha: 0.10),
                                borderRadius:
                                    BorderRadius.circular(4.rr),
                              ),
                              child: Text(doc.type.label,
                                  style: TextStyle(
                                      color: doc.type.color,
                                      fontSize: 10.rf,
                                      fontWeight: FontWeight.w600)),
                            ),
                            SizedBox(width: 6.rw),
                            Text(doc.country,
                                style: TextStyle(
                                    color: _textSecondary,
                                    fontSize: 12.rf)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Countdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (doc.isExpired)
                        Text('已过期',
                            style: TextStyle(
                                color: const Color(0xFF9E9E9E),
                                fontSize: 15.rf,
                                fontWeight: FontWeight.w700))
                      else if (days == 0)
                        Text('今日到期',
                            style: TextStyle(
                                color: uc,
                                fontSize: 15.rf,
                                fontWeight: FontWeight.w700))
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('$days',
                                style: TextStyle(
                                    color: uc,
                                    fontSize: 30.rf,
                                    fontWeight: FontWeight.w800,
                                    height: 1.0,
                                    letterSpacing: -1)),
                            SizedBox(width: 2.rw),
                            Padding(
                              padding: EdgeInsets.only(bottom: 3.rh),
                              child: Text('天',
                                  style: TextStyle(
                                      color: uc,
                                      fontSize: 12.rf,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      SizedBox(height: 2.rh),
                      Text('${_fmtDate(doc.expiryDate)} 到期',
                          style: TextStyle(
                              color: _textMuted, fontSize: 10.rf)),
                    ],
                  ),
                ],
              ),

              // Entries row
              if (doc.totalEntries != null) ...[
                SizedBox(height: 12.rh),
                Divider(height: 1, color: const Color(0xFFF0F0F8)),
                SizedBox(height: 10.rh),
                Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded,
                        size: 14.ri, color: _textMuted),
                    SizedBox(width: 6.rw),
                    Text(
                      '已用 ${doc.usedEntries} / 共 ${doc.totalEntries} 次入境',
                      style: TextStyle(
                          color: _textSecondary, fontSize: 12.rf),
                    ),
                    const Spacer(),
                    if ((doc.remainingEntries ?? 1) > 0)
                      GestureDetector(
                        onTap: onUseEntry,
                        child: Container(
                          padding: REdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.rr),
                          ),
                          child: Text('记录入境',
                              style: TextStyle(
                                  color: _accent,
                                  fontSize: 11.rf,
                                  fontWeight: FontWeight.w600)),
                        ),
                      )
                    else
                      Text('次数已用完',
                          style: TextStyle(
                              color: const Color(0xFFE53935),
                              fontSize: 11.rf,
                              fontWeight: FontWeight.w600)),
                  ],
                ),
              ],

              if (doc.notes.isNotEmpty) ...[
                SizedBox(height: 8.rh),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(doc.notes,
                      style:
                          TextStyle(color: _textMuted, fontSize: 11.rf),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 空状态 ───────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80.ri,
            height: 80.ri,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.article_rounded, size: 36.ri, color: _accent),
          ),
          SizedBox(height: 20.rh),
          Text('还没有证件记录',
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 17.rf,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 8.rh),
          Text('添加签证、学生证、居留许可\n到期前 30 / 7 / 1 天打开 App 时自动提醒',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: _textMuted, fontSize: 13.rf, height: 1.6)),
          SizedBox(height: 28.rh),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  REdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.rr)),
            ),
            onPressed: onAdd,
            icon: Icon(Icons.add_rounded, size: 18.ri),
            label: Text('添加第一份证件',
                style: TextStyle(
                    fontSize: 15.rf, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── 添加 / 编辑表单 ───────────────────────────────────────────────────────────
class _VisaFormPage extends StatefulWidget {
  final VisaDoc? editing;
  const _VisaFormPage({this.editing});

  @override
  State<_VisaFormPage> createState() => _VisaFormPageState();
}

class _VisaFormPageState extends State<_VisaFormPage> {
  late VisaDocType _type;
  late TextEditingController _labelCtrl;
  late TextEditingController _countryCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _totalEntriesCtrl;
  DateTime? _expiryDate;
  bool _hasEntries = false;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _type = e?.type ?? VisaDocType.visa;
    _labelCtrl = TextEditingController(text: e?.label ?? '');
    _countryCtrl = TextEditingController(text: e?.country ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _expiryDate = e?.expiryDate;
    _hasEntries = e?.totalEntries != null;
    _totalEntriesCtrl =
        TextEditingController(text: e?.totalEntries?.toString() ?? '');
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _countryCtrl.dispose();
    _notesCtrl.dispose();
    _totalEntriesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ??
          DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      helpText: '选择证件到期日期',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _accent,
            onPrimary: Colors.white,
            surface: _card,
            onSurface: _textPrimary,
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: _card,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            headerBackgroundColor: _accent,
            headerForegroundColor: Colors.white,
            headerHeadlineStyle: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
            headerHelpStyle: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
            ),
            dayStyle: const TextStyle(fontSize: 15),
            weekdayStyle: TextStyle(
              color: _textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            todayBorder: const BorderSide(color: _accent, width: 1.5),
            todayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return _accent;
            }),
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              if (states.contains(WidgetState.disabled)) return _textMuted;
              return _textPrimary;
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return _accent;
              return Colors.transparent;
            }),
            dayOverlayColor: WidgetStateProperty.all(
              _accent.withOpacity(0.08),
            ),
            dividerColor: Colors.transparent,
            cancelButtonStyle: TextButton.styleFrom(
              foregroundColor: _textSecondary,
              textStyle: const TextStyle(fontSize: 15),
            ),
            confirmButtonStyle: TextButton.styleFrom(
              foregroundColor: _accent,
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  void _save() {
    final label = _labelCtrl.text.trim();
    final country = _countryCtrl.text.trim();
    if (label.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入证件名称')));
      return;
    }
    if (country.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入所在国家/地区')));
      return;
    }
    if (_expiryDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请选择到期日期')));
      return;
    }
    final doc = VisaDoc(
      id: widget.editing?.id ?? const Uuid().v4(),
      type: _type,
      label: label,
      country: country,
      expiryDate: _expiryDate!,
      totalEntries: _hasEntries
          ? int.tryParse(_totalEntriesCtrl.text.trim())
          : null,
      usedEntries: widget.editing?.usedEntries ?? 0,
      notes: _notesCtrl.text.trim(),
    );
    Navigator.of(context).pop(doc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leadingWidth: 64,
        leading: TextButton(
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消',
              style:
                  TextStyle(color: _textSecondary, fontSize: 15.rf)),
        ),
        title: Text(_isEditing ? '编辑证件' : '添加证件',
            style: TextStyle(
                color: _textPrimary,
                fontSize: 17.rf,
                fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('保存',
                style: TextStyle(
                    color: _accent,
                    fontSize: 15.rf,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.rw, 8.rh, 16.rw,
            MediaQuery.of(context).padding.bottom + 32.rh),
        children: [
          // Type picker
          _FormSection(
            title: '证件类型',
            child: Wrap(
              spacing: 8.rw,
              runSpacing: 8.rh,
              children: VisaDocType.values.map((t) {
                final sel = _type == t;
                return GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: REdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? t.color.withValues(alpha: 0.15)
                          : _card,
                      borderRadius: BorderRadius.circular(10.rr),
                      border: Border.all(
                        color: sel ? t.color : const Color(0xFFE0E0EE),
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t.icon,
                            size: 14.ri,
                            color: sel ? t.color : _textMuted),
                        SizedBox(width: 6.rw),
                        Text(t.label,
                            style: TextStyle(
                                color: sel ? t.color : _textSecondary,
                                fontSize: 13.rf,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.normal)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 14.rh),

          _FormSection(
            title: '证件名称',
            child: _FormField(
              controller: _labelCtrl,
              hint: '例：美国 F1 签证、英国 Tier 4 学生签',
            ),
          ),
          SizedBox(height: 14.rh),

          _FormSection(
            title: '所在国家 / 地区',
            child: _FormField(
              controller: _countryCtrl,
              hint: '例：美国、英国、澳大利亚',
            ),
          ),
          SizedBox(height: 14.rh),

          _FormSection(
            title: '到期日期',
            child: GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding:
                    REdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12.rr),
                  border:
                      Border.all(color: const Color(0xFFE0E0EE)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 16.ri, color: _accent),
                    SizedBox(width: 10.rw),
                    Text(
                      _expiryDate == null
                          ? '点击选择日期'
                          : '${_expiryDate!.year} 年 '
                              '${_expiryDate!.month.toString().padLeft(2, '0')} 月 '
                              '${_expiryDate!.day.toString().padLeft(2, '0')} 日',
                      style: TextStyle(
                        color: _expiryDate == null
                            ? _textMuted
                            : _textPrimary,
                        fontSize: 14.rf,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 14.rh),

          _FormSection(
            title: '入境次数限制（选填）',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text('此签证有入境次数限制',
                            style: TextStyle(
                                color: _textSecondary,
                                fontSize: 13.rf))),
                    Switch(
                      value: _hasEntries,
                      activeColor: _accent,
                      onChanged: (v) =>
                          setState(() => _hasEntries = v),
                    ),
                  ],
                ),
                if (_hasEntries) ...[
                  SizedBox(height: 8.rh),
                  _FormField(
                    controller: _totalEntriesCtrl,
                    hint: '总允许入境次数，例：2',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 14.rh),

          _FormSection(
            title: '备注（选填）',
            child: _FormField(
              controller: _notesCtrl,
              hint: '续签时间节点、大使馆地址、注意事项等',
              maxLines: 3,
            ),
          ),
          SizedBox(height: 28.rh),

          SizedBox(
            width: double.infinity,
            height: 52.rh,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.rr)),
              ),
              onPressed: _save,
              child: Text('保存证件',
                  style: TextStyle(
                      fontSize: 16.rf, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 表单辅助组件 ──────────────────────────────────────────────────────────────
class _FormSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _FormSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 2.rw, bottom: 8.rh),
          child: Text(title,
              style: TextStyle(
                  color: _textSecondary,
                  fontSize: 12.rf,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3)),
        ),
        child,
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  const _FormField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12.rr),
        border: Border.all(color: const Color(0xFFE0E0EE)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(color: _textPrimary, fontSize: 14.rf),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _textMuted, fontSize: 13.rf),
          contentPadding:
              REdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
