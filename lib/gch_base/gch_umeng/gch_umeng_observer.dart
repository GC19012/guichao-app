import 'package:flutter/widgets.dart';
import 'package:guichao/gch_base/gch_umeng/gch_umeng_svc.dart';

/// 友盟页面统计路由观察者
///
/// 自动追踪所有 GoRouter 页面的进入和离开，
/// 无需在每个页面手动添加埋点代码。
///
/// 使用方式：在 GoRouter 的 observers 中添加 [GchUmengObserver()]
class GchUmengObserver extends NavigatorObserver {
  String? _currentPage;

  /// 从 Route 中提取页面名称
  String _extractPageName(Route<dynamic>? route) {
    // 优先使用 route settings 中的 name
    final name = route?.settings.name;
    if (name != null && name.isNotEmpty && name != '/') {
      return name;
    }

    // 回退到路径
    final args = route?.settings.arguments;
    if (args is Map && args.containsKey('path')) {
      return args['path'] as String;
    }

    return route?.settings.toString() ?? 'unknown';
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _onPageChanged(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _onPageChanged(newRoute, oldRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // Pop 时，回到上一个页面
    if (previousRoute != null) {
      _onPageChanged(previousRoute, route);
    }
  }

  void _onPageChanged(Route<dynamic> newRoute, Route<dynamic>? oldRoute) {
    // 结束上一个页面
    if (_currentPage != null) {
      GchUmengSvc.onPageEnd(_currentPage!);
    }

    // 开始新页面
    final pageName = _extractPageName(newRoute);
    _currentPage = pageName;
    GchUmengSvc.onPageStart(pageName);
    GchUmengSvc.onPageView(pageName);
  }
}
