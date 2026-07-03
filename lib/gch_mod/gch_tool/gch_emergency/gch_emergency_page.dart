import 'package:flutter/material.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Colors ──────────────────────────────────────────────────────────────────
const _bg = Color(0xFFF1EFF9);
const _card = Colors.white;
const _accent = Color(0xFF5969FF);
const _red = Color(0xFFE53935);
const _textPrimary = Color(0xFF1A1A2E);
const _textSecondary = Color(0xFF666680);

// ─── Data Models ─────────────────────────────────────────────────────────────
class _Phone {
  final String label;
  final String number;
  final bool isEmergency;
  const _Phone(this.label, this.number, {this.isEmergency = false});
}

class _Country {
  final String name;
  final String flag;
  final List<_Phone> phones;
  const _Country(this.name, this.flag, this.phones);
}

// ─── Data ─────────────────────────────────────────────────────────────────────
const _data = [
  _Country('中国国内', '🇨🇳', [
    _Phone('急救', '120', isEmergency: true),
    _Phone('报警', '110', isEmergency: true),
    _Phone('火警', '119', isEmergency: true),
    _Phone('驻外领事保护热线', '+86-10-12308'),
    _Phone('中国银行挂失', '95566'),
    _Phone('招商银行挂失', '95555'),
  ]),
  _Country('美国', '🇺🇸', [
    _Phone('急救/警察/消防', '911', isEmergency: true),
    _Phone('中国驻美大使馆', '+1-202-495-2266'),
    _Phone('中国驻纽约总领馆', '+1-212-695-3125'),
    _Phone('中国驻洛杉矶总领馆', '+1-213-807-8088'),
    _Phone('留学生心理援助热线', '1-800-950-6264'),
  ]),
  _Country('英国', '🇬🇧', [
    _Phone('急救/警察/消防', '999', isEmergency: true),
    _Phone('非急救警察', '101'),
    _Phone('中国驻英大使馆', '+44-20-7299-4049'),
    _Phone('中国驻曼彻斯特总领馆', '+44-161-224-7478'),
    _Phone('NHS 医疗咨询', '111'),
  ]),
  _Country('澳大利亚', '🇦🇺', [
    _Phone('急救/警察/消防', '000', isEmergency: true),
    _Phone('非急救医疗', '1800-022-222'),
    _Phone('中国驻澳大使馆', '+61-2-6228-4218'),
    _Phone('中国驻悉尼总领馆', '+61-2-8595-8002'),
    _Phone('中国驻墨尔本总领馆', '+61-3-9822-0604'),
  ]),
  _Country('加拿大', '🇨🇦', [
    _Phone('急救/警察/消防', '911', isEmergency: true),
    _Phone('中国驻加拿大大使馆', '+1-613-789-3434'),
    _Phone('中国驻多伦多总领馆', '+1-416-964-7260'),
    _Phone('中国驻温哥华总领馆', '+1-604-734-0704'),
    _Phone('加拿大危机热线', '1-833-456-4566'),
  ]),
  _Country('新西兰', '🇳🇿', [
    _Phone('急救/警察/消防', '111', isEmergency: true),
    _Phone('中国驻新西兰大使馆', '+64-4-472-1382'),
    _Phone('中国驻奥克兰总领馆', '+64-9-525-1589'),
  ]),
  _Country('日本', '🇯🇵', [
    _Phone('急救/消防', '119', isEmergency: true),
    _Phone('报警', '110', isEmergency: true),
    _Phone('中国驻日本大使馆', '+81-3-3403-3380'),
    _Phone('中国驻大阪总领馆', '+81-6-6445-9481'),
    _Phone('Japan Visitor Hotline', '+81-50-3816-2787'),
  ]),
  _Country('韩国', '🇰🇷', [
    _Phone('急救', '119', isEmergency: true),
    _Phone('报警', '112', isEmergency: true),
    _Phone('中国驻韩国大使馆', '+82-2-738-1038'),
    _Phone('外国人综合咨询', '1345'),
  ]),
  _Country('新加坡', '🇸🇬', [
    _Phone('急救/消防', '995', isEmergency: true),
    _Phone('警察', '999', isEmergency: true),
    _Phone('中国驻新加坡大使馆', '+65-6418-0251'),
    _Phone('非急救救护', '1777'),
  ]),
  _Country('德国', '🇩🇪', [
    _Phone('急救', '112', isEmergency: true),
    _Phone('警察', '110', isEmergency: true),
    _Phone('中国驻德国大使馆', '+49-30-27588-0'),
    _Phone('中国驻法兰克福总领馆', '+49-69-599-1610'),
    _Phone('中国驻慕尼黑总领馆', '+49-89-5231-8680'),
    _Phone('心理危机热线（德文）', '0800-111-0111'),
  ]),
  _Country('法国', '🇫🇷', [
    _Phone('急救 SAMU', '15', isEmergency: true),
    _Phone('警察', '17', isEmergency: true),
    _Phone('消防', '18', isEmergency: true),
    _Phone('统一急救号', '112', isEmergency: true),
    _Phone('中国驻法国大使馆', '+33-1-4953-6900'),
    _Phone('中国驻里昂总领馆', '+33-4-7814-9800'),
    _Phone('心理危机热线（法文）', '3114'),
  ]),
];

// ─── Dial Helper ─────────────────────────────────────────────────────────────
Future<void> _call(BuildContext context, String number) async {
  final cleaned = number.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  final uri = Uri(scheme: 'tel', path: cleaned);
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请手动拨打: $number')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请手动拨打: $number')),
      );
    }
  }
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class GchEmergencyPage extends StatelessWidget {
  const GchEmergencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: Text(
          '留学急救电话',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18.rf,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: _textPrimary),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.rw, vertical: 8.rh),
        children: [
          const _Banner(),
          SizedBox(height: 12.rh),
          ..._data.map((c) => _CountryCard(country: c)),
          SizedBox(height: 24.rh),
        ],
      ),
    );
  }
}

// ─── Top Banner ──────────────────────────────────────────────────────────────
class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.rw, vertical: 10.rh),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.rf),
        border: Border.all(color: _red.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: _red, size: 16.rf),
          SizedBox(width: 8.rw),
          Expanded(
            child: Text(
              '遇到紧急情况请优先拨打当地紧急服务 · 点击号码可直接拨打',
              style: TextStyle(
                color: _red,
                fontSize: 12.rf,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Country Card ─────────────────────────────────────────────────────────────
class _CountryCard extends StatelessWidget {
  final _Country country;
  const _CountryCard({required this.country});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.rh),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14.rf),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(16.rw, 14.rh, 16.rw, 10.rh),
            child: Row(
              children: [
                Text(
                  country.flag,
                  style: TextStyle(fontSize: 22.rf),
                ),
                SizedBox(width: 8.rw),
                Text(
                  country.name,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 15.rf,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F5)),
          // Phone rows
          ...country.phones.asMap().entries.map((entry) {
            final i = entry.key;
            final phone = entry.value;
            final isLast = i == country.phones.length - 1;
            return Column(
              children: [
                _PhoneRow(phone: phone),
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16.rw,
                    endIndent: 16.rw,
                    color: const Color(0xFFF0F0F5),
                  ),
              ],
            );
          }),
          SizedBox(height: 4.rh),
        ],
      ),
    );
  }
}

// ─── Phone Row ────────────────────────────────────────────────────────────────
class _PhoneRow extends StatelessWidget {
  final _Phone phone;
  const _PhoneRow({required this.phone});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Red left bar for emergency
          if (phone.isEmergency)
            Container(
              width: 3.rw,
              margin: EdgeInsets.symmetric(vertical: 6.rh),
              decoration: BoxDecoration(
                color: _red,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(2.rf),
                  bottomRight: Radius.circular(2.rf),
                ),
              ),
            )
          else
            SizedBox(width: 3.rw),
          // Label + Number
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(13.rw, 12.rh, 8.rw, 12.rh),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    phone.label,
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 12.rf,
                    ),
                  ),
                  SizedBox(height: 2.rh),
                  Text(
                    phone.number,
                    style: TextStyle(
                      color: phone.isEmergency ? _red : _textPrimary,
                      fontSize: 15.rf,
                      fontWeight: phone.isEmergency
                          ? FontWeight.w700
                          : FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Call button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.rw, vertical: 6.rh),
            child: GestureDetector(
              onTap: () => _call(context, phone.number),
              child: Container(
                width: 36.rw,
                height: 36.rh,
                decoration: BoxDecoration(
                  color: phone.isEmergency
                      ? _red.withValues(alpha: 0.10)
                      : _accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18.rf),
                ),
                child: Icon(
                  Icons.phone_rounded,
                  color: phone.isEmergency ? _red : _accent,
                  size: 18.rf,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
