import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension NavigationContextExtension on BuildContext {
  /// 检查是否可以安全返回
  ///
  /// 与 [safePop] 使用相同的逻辑，确保一致性。
  bool canSafelyPop() {
    final navigator = Navigator.maybeOf(this);
    if (navigator != null && navigator.canPop()) {
      return true;
    }

    final router = GoRouter.maybeOf(this);
    if (router != null && router.canPop()) {
      return true;
    }
    return false;
  }

  /// Safely pop the current route or overlay.
  /// Priority: closest [Navigator] (dialogs, bottom sheets), then GoRouter.
  bool safePop<T extends Object?>([T? result]) {
    final navigator = Navigator.maybeOf(this);
    if (navigator != null && navigator.canPop()) {
      navigator.pop<T>(result);
      return true;
    }

    final router = GoRouter.maybeOf(this);
    if (router != null && router.canPop()) {
      router.pop(result);
      return true;
    }
    return false;
  }
}
