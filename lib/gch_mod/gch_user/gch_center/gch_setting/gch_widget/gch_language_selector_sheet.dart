import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 语言选择底部弹出框（仅支持简体中文）
class LanguageSelectorSheet extends ConsumerWidget {
  const LanguageSelectorSheet({super.key});

  static Future<void> show(BuildContext context) async {
    // 仅支持简体中文，无需显示选择器
  }

  static String getLanguageName(dynamic locale) {
    return '简体中文';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox.shrink();
  }
}
