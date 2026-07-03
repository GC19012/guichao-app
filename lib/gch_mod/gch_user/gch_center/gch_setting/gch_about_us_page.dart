import 'package:flutter/material.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:go_router/go_router.dart';
import 'package:guichao/gch_aux/gch_nav_ext.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:guichao/gch_base/gch_schema/gch_const.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// 页面主题颜色 - 与 setting_page 保持一致
class _PageColors {
  static const Color background = Color(0xFFF1EFF9);
  static const Color card = Colors.white;
  static const Color primaryText = Color(0xFF333333);
  static const Color secondaryText = Color(0xFF666666);
  static const Color tertiaryText = Color(0xFF999999);
  static const Color accent = Color(0xFF5969FF);
}

class _T {
  static const secProductTitle = '产品定位';
  static const secProductBody =
      'GUICHAO 是专为留学生设计的实用工具集，整合时差时钟、汇率换算、急救电话、节假日查询、签证提醒、转账比价、省钱手册等功能，帮助您在海外留学生活中游刃有余。';
  static const secToolTitle = '留学工具';
  static const secToolBody =
      '覆盖美国、英国、澳大利亚、加拿大、日本、韩国等 11 个主要留学目的地，提供实时时差、最新汇率、当地急救号码及节假日信息，支持离线查阅，随时随地使用。';
  static const secPrivacyTitle = '安全与隐私';
  static const secPrivacyBody =
      '本地优先存储，不收集或上传您的个人数据。汇率等功能调用公开 API，基础工具无需账号即可使用，完全尊重您的隐私权益。';
  static const secUpdateTitle = '持续更新';
  static const secUpdateBody =
      '团队定期更新汇率数据来源、急救电话、节假日及省钱攻略，根据用户反馈持续扩充国家覆盖范围与功能类型，让工具越用越好。';
  static const secSupportTitle = '支持与服务';
  static const secSupportBody =
      '7×24 小时在线客服，随时解答您的问题。持续迭代产品，让 GUICHAO 成为每位留学生出行必备的贴心助手。';
  static const supportLabel = '联系客服';
  static const brand = 'GUICHAO';
  static const copyright = '© Guichao. All rights reserved.';
}

class AboutUsPage extends ConsumerWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Scaffold(
      backgroundColor: _PageColors.background,
      appBar: AppBar(
        backgroundColor: _PageColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: _PageColors.primaryText,
            size: 20.ri,
          ),
          onPressed: () => context.safePop(),
        ),
        title: Text(
          GchText.userCenterAboutUs,
          style: TextStyle(
            color: _PageColors.primaryText,
            fontSize: 18.rf,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: REdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _BrandHeader(),
            SizedBox(height: 20.rh),
            _Section(title: _T.secProductTitle, body: _T.secProductBody),
            _Section(title: _T.secToolTitle, body: _T.secToolBody),
            _Section(title: _T.secPrivacyTitle, body: _T.secPrivacyBody),
            _Section(title: _T.secUpdateTitle, body: _T.secUpdateBody),
            _Section(title: _T.secSupportTitle, body: _T.secSupportBody),
            SizedBox(height: 4.rh),
            const _LegalLinks(),
            SizedBox(height: 16.rh),
            const _FooterCopyright(),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: REdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20.rr),
            child: Image.asset(
              'assets/gch_pics/gch_brand/gch_logo_bird.png',
              width: 72.ri,
              height: 72.ri,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 14.rh),
          Text(
            _T.brand,
            style: TextStyle(
              color: _PageColors.primaryText,
              fontSize: 22.rf,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: REdgeInsets.only(bottom: 12),
      padding: REdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _PageColors.card,
        borderRadius: BorderRadius.circular(14.rr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4.rw,
                height: 16.rh,
                decoration: BoxDecoration(
                  color: _PageColors.accent,
                  borderRadius: BorderRadius.circular(2.rr),
                ),
              ),
              SizedBox(width: 8.rw),
              Text(
                title,
                style: TextStyle(
                  color: _PageColors.primaryText,
                  fontSize: 15.rf,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.rh),
          Text(
            body,
            style: TextStyle(
              color: _PageColors.secondaryText,
              fontSize: 13.rf,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalLinks extends StatelessWidget {
  const _LegalLinks();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _PageColors.card,
        borderRadius: BorderRadius.circular(14.rr),
      ),
      child: Column(
        children: [
          _LegalRow(
            label: GchText.aboutPrivacyPolicy,
            onTap: () => launchUrl(
              Uri.parse(GchConst.privacyUrl),
              mode: LaunchMode.inAppBrowserView,
            ),
          ),
          Divider(height: 1, indent: 16.rw, endIndent: 16.rw, color: const Color(0xFFF0F0F0)),
          _LegalRow(
            label: _T.supportLabel,
            onTap: () => context.push('/nav/setting/support'),
          ),
        ],
      ),
    );
  }
}

class _LegalRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LegalRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14.rr),
      onTap: onTap,
      child: Padding(
        padding: REdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: _PageColors.primaryText,
                fontSize: 14.rf,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 14.ri, color: _PageColors.tertiaryText),
          ],
        ),
      ),
    );
  }
}

class _FooterCopyright extends StatelessWidget {
  const _FooterCopyright();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: REdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          _T.copyright,
          style: TextStyle(
            color: _PageColors.tertiaryText,
            fontSize: 11.rf,
          ),
        ),
      ),
    );
  }
}
