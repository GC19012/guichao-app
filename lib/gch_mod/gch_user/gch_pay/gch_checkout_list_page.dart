import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_ctrl/gch_checkout_notifier_v2.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_widget/gch_checkout_page_components.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_widget/gch_purchase_style_widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 结账页面 - 参照 member_page 参考设计的 UI 布局
///
/// 该页面负责展示 VIP 会员购买界面，包含以下区域：
/// - 顶部背景图（Stack 底层）
/// - 顶部导航栏 [CheckoutPageHeader]
/// - 用户信息卡片 [PurchaseStyleUserCard]
/// - 白色圆角卡片可滚动内容区域 [CheckoutScrollableContent]
///   - VIP 特权标题 + 图标行
///   - 套餐卡片 Grid 布局
///   - 支付方式
///   - 促销横幅
/// - 底部支付栏（黑色胶囊 + 协议）[PurchaseStyleBottomPayBar] - 固定浮动在底部
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _configureSystemUI();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 预缓存背景图，避免首帧出现黑色闪烁
    precacheImage(const AssetImage('assets/gch_pics/gch_e532f7.webp'), context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 配置系统 UI 样式（状态栏）
  void _configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('CheckoutPage lifecycle: $state');
    if (state == AppLifecycleState.resumed) {
      debugPrint('CheckoutPage resumed, calling onAppResumed');
      ref.read(checkoutNotifierV2Provider.notifier).onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutNotifierV2Provider);
    final scaleFactors = CheckoutScaleFactors.fromScreen();

    // 参照 member_page 的 Stack 布局：
    // 底层 = 背景图
    // 上层 = SafeArea > Column > [AppBar, UserInfo, Expanded(ScrollContent)]
    // 手动读取顶部安全区域高度，避免嵌套 SafeArea 导致双重 padding
    final topPadding = MediaQuery.of(context).padding.top;

    // 底部 tab 栏浮动胶囊视觉高度：64(内部 SizedBox) + 12(外层 padding)
    // + 设备底部 home indicator 安全区
    final tabBarVisualHeight =
         12.0.rh + MediaQuery.of(context).padding.bottom;

    return CheckoutPageBackground(
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            SizedBox(height: topPadding),
            // 顶部导航栏
            CheckoutPageHeader.fromContext(
              context: context,
              title: GchText.userPayTitle,
              scaleFactors: scaleFactors,
            ),
            // 用户信息卡片
            const PurchaseStyleUserCard(),
            // 中间可滚动区域（包含白色卡片，不含底部支付栏）
            Expanded(
              child: CheckoutScrollableContent(
                isLoadingProducts: checkoutState.isLoadingProducts,
                isLoadingPayProviders: checkoutState.isLoadingPayProviders,
                scaleFactors: scaleFactors,
              ),
            ),
            // 底部支付栏 - 上推一个 tab 栏的高度，使其坐落在 tab 栏之上
            Padding(
              padding: EdgeInsets.only(bottom: tabBarVisualHeight),
              child: const PurchaseStyleBottomPayBar(),
            ),
          ],
        ),
      ),
    );
  }
}
