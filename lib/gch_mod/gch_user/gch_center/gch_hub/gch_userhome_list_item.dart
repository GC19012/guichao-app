import 'package:flutter/material.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';

class UserHomeListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showDivider;
  final Color? backgroundColor;
  final Color? dividerColor;
  final Color? iconColor;
  final Color? titleColor;

  const UserHomeListItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.showDivider = true,
    this.backgroundColor,
    this.dividerColor,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = backgroundColor ?? Colors.white.withOpacity(0.05);
    final Color divColor = dividerColor ?? Colors.white.withOpacity(0.18);
    final Color icColor = iconColor ?? Colors.white;
    final Color tColor = titleColor ?? Colors.white;
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12.rr),
          ),
          child: ListTile(
            leading: Icon(icon, color: icColor, size: 28.ri),
            title: Text(title, style: TextStyle(color: tColor, fontSize: 15.rf)),
            subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(color: const Color(0xFFB0B8C1), fontSize: 13.rf)) : null,
            trailing: const Icon(Icons.chevron_right, color: Color(0xFFB0B8C1)),
            onTap: onTap,
            tileColor: Colors.transparent,
            contentPadding: REdgeInsets.symmetric(horizontal: 12),
          ),
        ),
        if (showDivider)
          Container(
            margin: REdgeInsets.only(left: 56, right: 12),
            height: 1,
            color: divColor, // 高对比度分隔线
          ),
      ],
    );
  }
}
