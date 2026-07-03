import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_ctrl/gch_checkout_notifier_v2.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_widget/gch_purchase_style_widgets.dart';
import 'package:guichao/gch_aux/gch_nav_ext.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:guichao/gch_base/gch_umeng/gch_umeng_svc.dart';

/// 结账页面缩放因子计算
/// 提供统一的响应式缩放计算逻辑
class CheckoutScaleFactors {
  final double scaleW;
  final double scaleH;

  const CheckoutScaleFactors({
    required this.scaleW,
    required this.scaleH,
  });

  /// 从当前屏幕尺寸计算缩放因子
  factory CheckoutScaleFactors.fromScreen() {
    return CheckoutScaleFactors(
      scaleW: ResponsiveScale.width(max: 1.25),
      scaleH: ResponsiveScale.height(),
    );
  }
}

/// 结账页面顶部导航栏 - 参照设计稿 vip_purchase.webp
/// 左侧返回箭头 + 居中标题 + 右侧"恢复购买"按钮
/// 业务逻辑不变：返回导航逻辑 (canPop, safePop, NavMainHomeRoute)
/// 恢复购买逻辑不变：restorePurchases(context) 从 PurchaseUserCardContent 移入
class CheckoutPageHeader extends ConsumerWidget {
  final String title;
  final VoidCallback? onBackTap;
  final bool showBackButton;
  final CheckoutScaleFactors scaleFactors;

  const CheckoutPageHeader({
    super.key,
    required this.title,
    this.onBackTap,
    required this.showBackButton,
    required this.scaleFactors,
  });

  /// 从 BuildContext 构建，自动检测是否可以返回
  ///
  /// - 通过底部 tab 进入（branch 根路由）：不可 pop，不显示返回按钮
  /// - 通过其它页面 push 进入：可 pop，显示返回按钮
  factory CheckoutPageHeader.fromContext({
    Key? key,
    required BuildContext context,
    required String title,
    required CheckoutScaleFactors scaleFactors,
  }) {
    final canGoBack = context.canPop();
    return CheckoutPageHeader(
      key: key,
      title: title,
      showBackButton: canGoBack,
      onBackTap: canGoBack ? () => context.safePop() : null,
      scaleFactors: scaleFactors,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutState = ref.watch(checkoutNotifierV2Provider);
    final isRestoring = checkoutState.isRestoring;

    // 用 Stack 布局：标题整行居中，左右按钮绝对定位，
    // 保证无论左右元素宽度是否对称，标题都精确居中。
    return Padding(
      padding: REdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SizedBox(
        height: 44.rh,
        child: Stack(
          children: [
            // 标题 - 全宽居中
            Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18.rf,
                  fontWeight: FontWeight.w500,
                  color: PurchaseColors.textDark,
                ),
              ),
            ),
            // 左侧：返回按钮或空占位
            Align(
              alignment: Alignment.centerLeft,
              child: showBackButton
                  ? IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: PurchaseColors.textDark,
                      ),
                      onPressed: onBackTap,
                    )
                  : const SizedBox.shrink(),
            ),
            // 右侧"恢复购买"按钮 - 参考客服按钮：Align 不产生紧高度约束
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: isRestoring
                    ? null
                    : () {
                        GchUmengSvc.onRestorePurchaseTap();
                        ref
                            .read(checkoutNotifierV2Provider.notifier)
                            .restorePurchases(context);
                      },
                child: isRestoring
                    ? SizedBox(
                        width: 80.rw,
                        height: 32.rh,
                        child: Center(
                          child: SizedBox(
                            width: 18.rw,
                            height: 18.rw,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: PurchaseColors.primaryPurple,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        padding: REdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EAFF),
                          borderRadius: BorderRadius.circular(16.rr),
                          border: Border.all(
                            color: const Color(0xFF4F4893).withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          GchText.userPayRestorePurchase,
                          style: TextStyle(
                            fontSize: 11.rf,
                            color: PurchaseColors.primaryPurple,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// VIP 特权标题区域 - 已由 PurchaseStylePrivilegeTitle 替代
/// 保留类以确保向后兼容，内部委托给新组件
class CheckoutVipTitleSection extends StatelessWidget {
  final String vipTitle;
  final CheckoutScaleFactors scaleFactors;

  const CheckoutVipTitleSection({
    super.key,
    required this.vipTitle,
    required this.scaleFactors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * scaleFactors.scaleW),
      child: Text(
        vipTitle,
        style: TextStyle(
          fontSize: 15.rf,
          color: PurchaseColors.textGray,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

/// VIP 会员计划标题行
class CheckoutPlanTitleRow extends StatelessWidget {
  final String planTitle;
  final String platformSupport;
  final CheckoutScaleFactors scaleFactors;

  const CheckoutPlanTitleRow({
    super.key,
    required this.planTitle,
    required this.platformSupport,
    required this.scaleFactors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * scaleFactors.scaleW),
      child: Row(
        children: [
          Expanded(
            child: Text(
              planTitle,
              style: TextStyle(
                fontSize: 14.rf,
                color: PurchaseColors.textGray,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8 * scaleFactors.scaleW),
          Flexible(
            child: Text(
              platformSupport,
              style: TextStyle(
                fontSize: 9.rf,
                color: PurchaseColors.textGray,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// 支付方式标题
class CheckoutPaymentMethodTitle extends StatelessWidget {
  final String title;
  final CheckoutScaleFactors scaleFactors;

  const CheckoutPaymentMethodTitle({
    super.key,
    required this.title,
    required this.scaleFactors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * scaleFactors.scaleW),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15.rf,
          color: PurchaseColors.textDark,
        ),
      ),
    );
  }
}

/// 商品加载中占位组件
class CheckoutProductsLoading extends ConsumerWidget {
  const CheckoutProductsLoading({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 165.rh,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: PurchaseColors.primaryPurple),
            SizedBox(height: 5.rh),
            Text(
              GchText.userPayLoadingProducts,
              style: TextStyle(color: PurchaseColors.textGray, fontSize: 14.rf),
            ),
          ],
        ),
      ),
    );
  }
}

/// 支付方式加载中占位组件
class CheckoutPaymentMethodsLoading extends ConsumerWidget {
  const CheckoutPaymentMethodsLoading({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 60.rh,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: PurchaseColors.primaryPurple),
            SizedBox(height: 8.rh),
            Text(
              GchText.userPayLoadingPayments,
              style: TextStyle(color: PurchaseColors.textGray, fontSize: 14.rf),
            ),
          ],
        ),
      ),
    );
  }
}

/// 结账页面可滚动内容区域
/// 参照 member_page _buildWhiteCardSection - 白色圆角卡片包裹内容
class CheckoutScrollableContent extends ConsumerWidget {
  final bool isLoadingProducts;
  final bool isLoadingPayProviders;
  final CheckoutScaleFactors scaleFactors;

  const CheckoutScrollableContent({
    super.key,
    required this.isLoadingProducts,
    required this.isLoadingPayProviders,
    required this.scaleFactors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // iOS 平台始终隐藏支付方式选择（只有 Apple Pay，自动选中）
    final shouldHidePayMethods = Platform.isIOS;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.rh),
          // VIP 特权区域 - 独立半透白卡，与下方套餐形成清晰层级
          Padding(
            padding: REdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: REdgeInsets.symmetric(horizontal: 4, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(16.rr),
              ),
              child: Column(
                children: [
                  const PurchaseStylePrivilegeTitle(),
                  SizedBox(height: 4.rh),
                  const PurchaseStylePrivilegeRow(),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.rh),
          // 套餐选择 - 独立区域（上下间距对称 16rh）
          if (isLoadingProducts)
            const CheckoutProductsLoading()
          else
            const PurchaseStylePlanList(),
          // 支付方式 - iOS 隐藏
          if (!shouldHidePayMethods) ...[
            SizedBox(height: 10.rh),
            CheckoutPaymentMethodTitle(
              title: GchText.userPayPaymentMethod,
              scaleFactors: scaleFactors,
            ),
            SizedBox(height: 6.rh),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 20 * scaleFactors.scaleW),
              child: isLoadingPayProviders
                  ? const CheckoutPaymentMethodsLoading()
                  : const PurchaseStylePaymentMethods(),
            ),
          ],
          SizedBox(height: 8.rh), // 套餐 ↔ 底部支付栏合计 8 + 8 = 16rh
        ],
      ),
    );
  }
}

/// 结账页面背景容器 - 参照设计稿 vip_purchase.webp
/// 纯浅色背景（无顶部背景图），用户信息区域在纯色上
class CheckoutPageBackground extends StatelessWidget {
  final Widget child;

  const CheckoutPageBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        // 兜底颜色：与背景图顶部主色一致，避免首帧图片未加载时出现黑色闪烁
        color: Color(0xFFE8EEFF),
        image: DecorationImage(
          image: AssetImage('assets/gch_pics/gch_e532f7.webp'),
          fit: BoxFit.cover,
        ),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          decoration: TextDecoration.none,
          color: PurchaseColors.textDark,
          fontFamily: null,
        ),
        child: child,
      ),
    );
  }
}

/// 超时提示横幅组件
/// 当支付处理时间过长时显示
class CheckoutTimeoutBanner extends StatelessWidget {
  final String title;
  final String message;
  final String processingHint;
  final VoidCallback onClose;
  final CheckoutScaleFactors scaleFactors;

  const CheckoutTimeoutBanner({
    super.key,
    required this.title,
    required this.message,
    required this.processingHint,
    required this.onClose,
    required this.scaleFactors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 20 * scaleFactors.scaleW,
        vertical: 10 * scaleFactors.scaleH,
      ),
      padding: EdgeInsets.all(16 * scaleFactors.scaleW),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4A6CF7).withValues(alpha: 0.15),
            const Color(0xFF6366F1).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12.rr),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          SizedBox(height: 8 * scaleFactors.scaleH),
          _buildMessage(context),
          SizedBox(height: 12 * scaleFactors.scaleH),
          _buildProcessingHint(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28 * scaleFactors.scaleW,
          height: 28 * scaleFactors.scaleW,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.info_outline,
            color: const Color(0xFF6366F1),
            size: 16.ri,
          ),
        ),
        SizedBox(width: 12 * scaleFactors.scaleW),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: const Color(0xFF6366F1),
              fontSize: 16 * scaleFactors.scaleW,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: onClose,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: 8 * scaleFactors.scaleW,
              vertical: 4 * scaleFactors.scaleH,
            ),
            minimumSize: Size.zero,
          ),
          child: Icon(
            Icons.close,
            color: const Color(0xFF94A3B8),
            size: 16.ri,
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(BuildContext context) {
    return Text(
      message,
      style: TextStyle(
        color: PurchaseColors.textDark,
        fontSize: 14 * scaleFactors.scaleW,
        height: 1.4,
      ),
    );
  }

  Widget _buildProcessingHint(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.schedule,
          color: const Color(0xFF6366F1),
          size: 16.ri,
        ),
        SizedBox(width: 6 * scaleFactors.scaleW),
        Expanded(
          child: Text(
            processingHint,
            style: TextStyle(
              color: const Color(0xFF94A3B8),
              fontSize: 12 * scaleFactors.scaleW,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
