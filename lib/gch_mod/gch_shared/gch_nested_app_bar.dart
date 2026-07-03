import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guichao/gch_base/gch_nav/gch_nav.dart';
import 'package:guichao/gch_mod/gch_shared/gch_adaptive_root_scaffold.dart';

bool showDrawerButton(BuildContext context) {
  // always mobile router
  final String location = GoRouterState.of(context).uri.path;
  if (location == const HomeRoute().location) return true;
  if (location.startsWith(const ProxiesRoute().location)) return true;
  return false;
}

class NestedAppBar extends StatelessWidget {
  const NestedAppBar({
    super.key,
    this.title,
    this.actions,
    this.pinned = true,
    this.forceElevated = false,
    this.bottom,
    this.backgroundColor,
    this.foregroundColor,
  });

  final Widget? title;
  final List<Widget>? actions;
  final bool pinned;
  final bool forceElevated;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    RootScaffold.canShowDrawer(context);

    return SliverAppBar(
      backgroundColor: backgroundColor ?? Colors.transparent,
      foregroundColor: foregroundColor,
      leading: (RootScaffold.stateKey.currentState?.hasDrawer ?? false) && showDrawerButton(context)
          ? DrawerButton(
              onPressed: () {
                RootScaffold.stateKey.currentState?.openDrawer();
              },
            )
          : (context.canPop()
              ? IconButton(
                  icon: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.arrow_forward : Icons.arrow_back),
                  padding: EdgeInsets.only(right: Directionality.of(context) == TextDirection.rtl ? 50 : 0),
                  onPressed: () {
                    context.pop(); // 使用 GoRouter 的 pop 方法
                  },
                )
              : null),
      title: title,
      actions: actions,
      pinned: pinned,
      forceElevated: forceElevated,
      bottom: bottom,
    );
  }
}
