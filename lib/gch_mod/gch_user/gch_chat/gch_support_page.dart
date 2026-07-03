import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guichao/gch_aux/gch_nav_ext.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:url_launcher/url_launcher.dart';

class _C {
  static final email = 'support@example.com';
  static final wechat = 'YOUR_WECHAT_ID';
}

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 20.ri,
          ),
          onPressed: () => context.safePop(),
        ),
        title: Text(
          '技术支持',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.rf,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/gch_pics/gch_e532f7.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: REdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              children: [
                const _LogoSection(),
                SizedBox(height: 28.rh),
                _SupportCard(email: _C.email, wechat: _C.wechat),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88.ri,
          height: 88.ri,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF8B9CFF).withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/gch_pics/gch_brand/gch_logo_bird.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: 12.rh),
        Text(
          'GUICHAO',
          style: TextStyle(
            color: const Color(0xFF5969FF),
            fontSize: 22.rf,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }
}

class _SupportCard extends StatelessWidget {
  final String email;
  final String wechat;

  const _SupportCard({required this.email, required this.wechat});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.rr),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: REdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '技术支持',
                style: TextStyle(
                  color: const Color(0xFF1A1A1A),
                  fontSize: 18.rf,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16.rh),
            Text(
              '尊敬的用户：',
              style: TextStyle(
                color: const Color(0xFF333333),
                fontSize: 14.rf,
              ),
            ),
            SizedBox(height: 8.rh),
            Text(
              '    感谢您使用本应用，若您在使用期间遇到任何技术故障、功能使用问题、账号相关疑问，或希望提出产品优化建议，欢迎通过以下官方渠道联系技术支持团队，我们很乐意为您服务。\n(服务时段每天9:00—18:00)',
              style: TextStyle(
                color: const Color(0xFF444444),
                fontSize: 13.rf,
                height: 1.6,
              ),
            ),
            SizedBox(height: 16.rh),
            _ContactRow(
              icon: Icons.email_outlined,
              label: '邮箱',
              value: email,
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            _ContactRow(
              icon: Icons.chat_bubble_outline,
              label: '微信',
              value: wechat,
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const _LinksRow(),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: REdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36.ri,
            height: 36.ri,
            decoration: const BoxDecoration(
              color: Color(0xFF34C759),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18.ri),
          ),
          SizedBox(width: 12.rw),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF333333),
              fontSize: 15.rf,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF333333),
                fontSize: 13.rf,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _copy(context),
            child: Text(
              '复制',
              style: TextStyle(
                color: const Color(0xFF5969FF),
                fontSize: 14.rf,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinksRow extends StatelessWidget {
  const _LinksRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: REdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () => launchUrl(
              Uri.parse('https://example.com/iOSTerms.html'),
              mode: LaunchMode.inAppBrowserView,
            ),
            child: Text(
              '《用户协议》',
              style: TextStyle(
                color: const Color(0xFF5969FF),
                fontSize: 14.rf,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => launchUrl(
              Uri.parse('https://example.com/privacyA.html'),
              mode: LaunchMode.inAppBrowserView,
            ),
            child: Text(
              '《隐私政策》',
              style: TextStyle(
                color: const Color(0xFF5969FF),
                fontSize: 14.rf,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
