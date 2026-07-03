import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_providers/gch_auth_providers.dart';
import 'package:guichao/gch_base/gch_signal/gch_signal_hub.dart';
import 'package:guichao/gch_base/gch_umeng/gch_umeng_svc.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_ctrl/gch_checkout_notifier_v2.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_utils/gch_product_utils.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_utils/gch_user_utils.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_utils/gch_payment_utils.dart';
import 'package:guichao/gch_base/gch_biz/gch_common/gch_enums.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:guichao/gch_aux/gch_text_styles.dart';

// ========== 颜色常量 (参照 member_page 参考设计 - 浅色主题) ==========
class PurchaseColors {
  /// 深色文字 - 标题等
  static const Color textDark = Color(0xFF333333);

  /// 灰色文字 - 副标题、说明
  static const Color textGray = Color(0xFF9A98AA);

  /// 浅灰文字 - 兼容旧接口
  static const Color textLightGray = Color(0xFFB7B7B7);

  /// 白色卡片背景
  static const Color cardWhiteBg = Colors.white;

  /// 分割线颜色
  static const Color borderGray = Color(0xFFEEEEEE);

  /// 金色文字（保留，用于恢复购买按钮）
  static const Color goldText = Color(0xFF5B3503);

  /// 蓝色选中（支付方式）
  static const Color blueSelected = Color(0xFF4A9EFF);

  /// 主色调紫色（参考设计）
  static const Color primaryPurple = Color(0xFF4F4893);

  /// 套餐卡选中主标题/价格色
  static const Color selectedOrange = Color(0xFFFF5A1F);

  /// 未选中套餐卡片的浅紫高亮文字
  static const Color lightPurple = Color(0xFF7C75C4);

  /// 选中红色（参考设计）
  static const Color selectedRed = Color(0xFFFF3300);

  /// 选中套餐卡片的浅金边框色
  static const Color lightSelectedBorder = Color(0xFFC9A15C);

  /// 套餐卡辅助灰字
  static const Color cardMutedText = Color(0xFFB8B1A6);

  /// 热门标签渐变起点
  static const Color promoBadgeStart = Color(0xFFFF6E78);

  /// 热门标签渐变终点
  static const Color promoBadgeEnd = Color(0xFFFFA85C);

  /// 标签蓝色渐变起点
  static const Color promoBlueStart = Color(0xFF5A73FF);

  /// 标签蓝色渐变终点
  static const Color promoBlueEnd = Color(0xFF7F59F5);

  /// 标签绿色渐变起点
  static const Color promoGreenStart = Color(0xFF19B77A);

  /// 标签绿色渐变终点
  static const Color promoGreenEnd = Color(0xFF4CCB9D);

  /// 标签金色渐变起点
  static const Color promoGoldStart = Color(0xFFE7B54A);

  /// 标签金色渐变终点
  static const Color promoGoldEnd = Color(0xFFF3CB76);

  /// 高亮蓝紫色（到期日、协议链接）
  static const Color accentBlue = Color(0xFF5969FF);

  /// 协议链接色
  static const Color linkPurple = Color(0xFF6366F1);

  /// 底部按钮文字
  static const Color bottomButtonText = Color(0xFF2C2382);

  /// 旧接口兼容 - cardBg
  static const Color cardBg = Color(0xff1E1E1E);

  /// 旧接口兼容 - purpleBg
  static const Color purpleBg = Color(0xFF4C507D);
}

// ========== 用户信息卡片 ==========
/// 用户卡片容器 - 恢复购买按钮已移至 CheckoutPageHeader
/// checkoutNotifierV2Provider watch 已移除（不再需要 isRestoring）
class PurchaseStyleUserCard extends StatelessWidget {
  const PurchaseStyleUserCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const PurchaseUserCardContent();
  }
}

/// 用户卡片内容 - 参照设计稿 vip_purchase.webp 视觉风格
/// 数据源统一使用 userInfoProvider，避免多 Provider 缓存不一致
/// 恢复购买按钮已移至 CheckoutPageHeader
class PurchaseUserCardContent extends ConsumerWidget {
  const PurchaseUserCardContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfoAsync = ref.watch(userInfoProvider);

    return Padding(
      padding: REdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: userInfoAsync.when(
        loading: () => _buildCardContent(gcSeq: 'GC00000000',
          email: null,
          phone: null,
          vipType: VipType.free,
          expiredAt: null,
          isAuthenticated: false,
        ),
        error: (_, __) => _buildCardContent(gcSeq: 'GC00000000',
          email: null,
          phone: null,
          vipType: VipType.free,
          expiredAt: null,
          isAuthenticated: false,
        ),
        data: (userInfo) => _buildCardContent(gcSeq: userInfo.gcSeq,
          email: userInfo.email,
          phone: userInfo.phone,
          vipType: userInfo.vipType,
          expiredAt: userInfo.expiredAt,
          isAuthenticated: userInfo.isAuthenticated,
          authType: userInfo.authType,
          name: userInfo.name,
          nickname: userInfo.nickname,
        ),
      ),
    );
  }

  /// 卡片内容构建 - 所有业务逻辑（判断、格式化）保持不变
  /// UI 样式改为参考设计的浅色主题
  Widget _buildCardContent({required String gcSeq,
    required String? email,
    required String? phone,
    required VipType vipType,
    required DateTime? expiredAt,
    required bool isAuthenticated,
    String? authType,
    String? name,
    String? nickname,
  }) {
    // 格式化到期时间 - 业务逻辑不变
    final expiredText = (vipType != VipType.free && expiredAt != null)
        ? UserUtils.formatExpiredTime(expiredAt)
        : '';
    final vipTypeText = UserUtils.getVipTypeDisplayText(vipType);

    // 构建联系方式显示列表 - 业务逻辑不变
    final contactInfoWidgets = <Widget>[];
    if (isAuthenticated) {
      if (email != null && email.isNotEmpty) {
        contactInfoWidgets.add(
          Text(
            '${GchText.userCenterEmailLabel}$email',
            style: TextStyle(
              fontSize: 12.rf,
              color: PurchaseColors.textGray,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }
      // 显示手机号（如果不为空）
      if (phone != null && phone.isNotEmpty) {
        contactInfoWidgets.add(
          Text(
            '${GchText.userCenterPhoneLabel}$phone',
            style: TextStyle(
              fontSize: 12.rf,
              color: PurchaseColors.textGray,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }
      // 如果都为空，显示未设置
      if (contactInfoWidgets.isEmpty) {
        contactInfoWidgets.add(
          Text(
            GchText.userCenterNotSet,
            style: TextStyle(
              fontSize: 12.rf,
              color: PurchaseColors.textGray,
            ),
          ),
        );
      }
    } else {
      // 未登录显示游客模式
      contactInfoWidgets.add(
        Text(
          GchText.userCenterGuestMode,
          style: TextStyle(
            fontSize: 12.rf,
            color: PurchaseColors.textGray,
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            // 用户头像 - Stack 叠加 VIP 徽章（参照设计稿 vip_purchase.webp）
            SizedBox(
              width: 64.ri,
              height: 64.ri,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/gch_pics/gch_pay/gch_eecc2c.webp',
                      width: 60.ri,
                      height: 60.ri,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // VIP 徽章 - 左下角叠加，仅 VIP 用户显示
                  if (vipType != VipType.free)
                    Positioned(
                      left: -4.rw,
                      bottom: -2.rh,
                      child: Image.asset(
                        'assets/gch_pics/gch_pay/gch_01149d.webp',
                        width: 48.rw,
                        height: 20.rh,
                        fit: BoxFit.contain,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 12.rw),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 用户名（不再带内联 VIP 标签，VIP 由头像徽章表达）
                  Text(
                    '${GchText.userCenterHomeNumberLabel}$gcSeq',
                    style: TextStyle(
                      fontSize: 16.rf,
                      fontWeight: FontWeight.w500,
                      color: PurchaseColors.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // 联系方式
                  ...contactInfoWidgets,
                  SizedBox(height: 4.rh),
                  // 会员到期信息（恢复购买按钮已移至 Header）
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 12.rf, color: PurchaseColors.textDark),
                      children: [
                        TextSpan(text: vipTypeText),
                        if (expiredText.isNotEmpty) ...[
                          TextSpan(
                            text: expiredText,
                            style: const TextStyle(color: PurchaseColors.accentBlue),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 用户卡片骨架加载
class PurchaseUserCardSkeleton extends StatelessWidget {
  const PurchaseUserCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100.rh,
      margin: REdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12.rr),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: PurchaseColors.primaryPurple),
      ),
    );
  }
}

/// 用户卡片错误显示
class PurchaseUserCardError extends ConsumerWidget {
  final String error;
  const PurchaseUserCardError({super.key, required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: REdgeInsets.all(16),
      margin: REdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.rr),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade300),
          SizedBox(width: 12.rw),
          Expanded(
            child: Text(
              GchText.userPayLoadUserFailed,
              style: TextStyle(color: Colors.red.shade300),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ========== VIP特权区域 (参照 member_page _buildVipPrivileges) ==========

/// VIP 特权标题行 - 钻石图标 + 文字（参照设计稿 vip_purchase.webp）
class PurchaseStylePrivilegeTitle extends ConsumerWidget {
  const PurchaseStylePrivilegeTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: REdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Icon(
            Icons.diamond_outlined,
            size: 20.ri,
            color: PurchaseColors.primaryPurple,
          ),
          SizedBox(width: 8.rw),
          Expanded(
            child: Text(
              GchText.userPayVipTitle,
              style: TextStyle(
                fontSize: 16.rf,
                fontWeight: FontWeight.w500,
                color: PurchaseColors.textDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// VIP 特权图标行 - 留学生工具 app 专属权益
class PurchaseStylePrivilegeRow extends ConsumerWidget {
  const PurchaseStylePrivilegeRow({super.key});

  static const _items = [
    (Icons.apps_rounded,                   Color(0xFF5969FF), '工具全开', '留学工具全套'),
    (Icons.history_rounded,                Color(0xFF9B6FFF), '无限记录', '测速·诊断不限'),
    (Icons.notifications_active_rounded,   Color(0xFFFF7043), '实时提醒', '签证·汇率推送'),
    (Icons.support_agent_rounded,          Color(0xFF2ECC9A), '专属客服', '优先响应服务'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: REdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _items.map((item) {
          final (icon, color, title, subtitle) = item;
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 50.rw,
                  height: 50.rw,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14.rr),
                  ),
                  child: Icon(icon, size: 24.ri, color: color),
                ),
                SizedBox(height: 8.rh),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.rf,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 把货币代码映射为常用符号，其他币种原样返回
String _currencySymbol(String code) {
  switch (code.toUpperCase()) {
    case 'CNY':
    case 'RMB':
    case '¥':
      return '¥';
    case 'USD':
      return '\$';
    default:
      return code;
  }
}

// ========== 套餐卡片列表 (参照 member_page - 两行三列 Grid 布局) ==========
/// 排序逻辑：仅当 title2 均有值时按 title2 排序，否则回退 productId / price
/// 选择逻辑不变：ref.read(checkoutNotifierV2Provider.notifier).selectProduct(product)
class PurchaseStylePlanList extends ConsumerWidget {
  const PurchaseStylePlanList({super.key});

  int _compareProducts(ProductEntry a, ProductEntry b) {
    final left = a.title2?.trim() ?? '';
    final right = b.title2?.trim() ?? '';

    if (left.isNotEmpty && right.isNotEmpty) {
      final leftNumber = num.tryParse(left);
      final rightNumber = num.tryParse(right);

      if (leftNumber != null && rightNumber != null) {
        final result = leftNumber.compareTo(rightNumber);
        if (result != 0) return result;
      } else {
        final result = left.compareTo(right);
        if (result != 0) return result;
      }
    }

    final productIdResult = a.productId.compareTo(b.productId);
    if (productIdResult != 0) return productIdResult;

    return a.price.compareTo(b.price);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutState = ref.watch(checkoutNotifierV2Provider);
    // title2 仅用于排序不参与展示；缺失时回退 productId / price
    final products = [...checkoutState.products]
      ..sort(_compareProducts);
    final selectedProduct = checkoutState.selectedProduct;

    // 加载失败或数据为空时显示错误提示和重试按钮
    if (products.isEmpty) {
      return SizedBox(
        height: 165.rh,
        child: Center(
          child: Text(
            GchText.userPayLoadingProducts,
            style: const TextStyle(color: PurchaseColors.textGray),
          ),
        ),
      );
    }

    // 横屏每行最多6个，竖屏每行最多3个
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final columnCount = isLandscape ? 6 : 3;
    final List<List<int>> rows = [];
    for (int i = 0; i < products.length; i += columnCount) {
      final end = (i + columnCount > products.length) ? products.length : i + columnCount;
      rows.add(List.generate(end - i, (j) => i + j));
    }

    return Padding(
      padding: REdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: REdgeInsets.all(0),
        child: Column(
          children: rows.asMap().entries.map((rowEntry) {
            final rowIndices = rowEntry.value;
            final isLastRow = rowEntry.key == rows.length - 1;
            final List<Widget> rowChildren = [];
            for (int k = 0; k < rowIndices.length; k++) {
              final index = rowIndices[k];
              final product = products[index];
              final isSelected = selectedProduct?.id == product.id;
              final isHot = index == 0;

              if (k > 0) {
                rowChildren.add(SizedBox(width: 10.rw));
              }
              rowChildren.add(
                Expanded(
                  child: PurchaseStylePlanCard(
                    product: product,
                    isSelected: isSelected,
                    isHot: isHot,
                    onTap: () {
                      ref.read(checkoutNotifierV2Provider.notifier).selectProduct(product);
                    },
                  ),
                ),
              );
            }
            final emptySlots = columnCount - rowIndices.length;
            for (int s = 0; s < emptySlots; s++) {
              rowChildren.add(SizedBox(width: 3.rw));
              rowChildren.add(const Expanded(child: SizedBox()));
            }
            return Padding(
              padding: EdgeInsets.only(bottom: isLastRow ? 0 : 3.rh),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: rowChildren,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// 单个套餐卡片 - 参照设计稿 vip_purchase.webp
class PurchaseStylePlanCard extends ConsumerWidget {
  final ProductEntry product;
  final bool isSelected;
  final bool isHot;
  final VoidCallback onTap;

  const PurchaseStylePlanCard({
    super.key,
    required this.product,
    required this.isSelected,
    required this.isHot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badge = ProductUtils.getTagByDuration(product.duration);
    final tagIsHot = badge == ProductBadgeType.hot;
    final tagLabel = ProductUtils.getTagLabel(badge);
    final promoLabel = (product.promoinfo1?.trim().isNotEmpty ?? false)
        ? product.promoinfo1!.trim()
        : ((tagIsHot || isHot) ? tagLabel : null);
    final originalPriceText = product.description2?.trim();
    final promoInfoText = product.promoinfo2?.trim();
    final benefitText = product.description3?.trim();

    const accent = Color(0xFF5969FF);
    final titleColor =
        isSelected ? accent : const Color(0xFF333333);
    final priceColor =
        isSelected ? accent : const Color(0xFF333333);
    final subPriceColor =
        isSelected ? accent : PurchaseColors.textGray;
    final strikeColor = PurchaseColors.textGray;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          // 默认与选中均使用白底，只通过 border 区分选中态
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.rr),
          border: Border.all(
            color: isSelected ? accent : Colors.transparent,
            width: 0.8,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 26.rh),
            Text(
              product.title,
              style: TextStyle(
                fontSize: 14.rf,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 16.rh),
            // 大字价格
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                alignment: Alignment.center,
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _currencySymbol(product.currency),
                      style: TextStyle(
                        fontSize: 12.rf,
                        color: priceColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                    ),
                    SizedBox(width: 2.rw),
                    Text(
                      product.price.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 20.rf,
                        fontWeight: FontWeight.w800,
                        color: priceColor,
                        height: 1,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
            // 副价格（有时服务端返回）
            if (promoInfoText != null && promoInfoText.isNotEmpty) ...[
              SizedBox(height: 8.rh),
              Padding(
                padding: REdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  promoInfoText,
                  style: TextStyle(
                    fontSize: 11.rf,
                    color: subPriceColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            // 划线原价（有时服务端返回）
            if (originalPriceText != null && originalPriceText.isNotEmpty) ...[
              SizedBox(height: 4.rh),
              Padding(
                padding: REdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  originalPriceText,
                  style: TextStyle(
                    fontSize: 11.rf,
                    color: strikeColor,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: strikeColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            SizedBox(height: 16.rh),
            // 底部优惠 Banner —— 有文字时才显示渐变色块
            Builder(builder: (context) {
              final label = benefitText?.isNotEmpty == true
                  ? benefitText!
                  : (promoLabel?.isNotEmpty == true ? promoLabel! : null);
              if (label == null && !isSelected) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding: REdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFFE8EDFF), Color(0xFFDEDCFF)],
                        )
                      : null,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(13.rr),
                  ),
                ),
                alignment: Alignment.center,
                child: label != null
                    ? Text(
                        label,
                        style: TextStyle(
                          fontSize: 10.rf,
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      )
                    : const SizedBox.shrink(),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ========== 支付方式列表 ==========
/// 选择逻辑不变：ref.read(checkoutNotifierV2Provider.notifier).selectPayProvider(provider)
class PurchaseStylePaymentMethods extends ConsumerWidget {
  const PurchaseStylePaymentMethods({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutState = ref.watch(checkoutNotifierV2Provider);
    final availableProviders = checkoutState.availablePayProviders;

    // 注意：加载状态已由父组件 CheckoutScrollableContent 处理，
    // 此组件仅在加载完成后渲染，此处只需处理空数据情况
    if (availableProviders.isEmpty) {
      return Center(
        child: Text(GchText.userPayNoPaymentMethods, style: const TextStyle(color: PurchaseColors.textGray)),
      );
    }

    return Column(
      children: availableProviders.map((provider) {
        final isSelected = checkoutState.selectedPayProvider?.id == provider.id;
        return PurchaseStylePaymentMethodItem(
          provider: provider,
          isSelected: isSelected,
          onTap: () {
            ref.read(checkoutNotifierV2Provider.notifier).selectPayProvider(provider);
          },
        );
      }).toList(),
    );
  }
}

/// 单个支付方式项 - 调整为浅色主题
class PurchaseStylePaymentMethodItem extends StatelessWidget {
  final PayProviderEntry provider;
  final bool isSelected;
  final VoidCallback onTap;

  const PurchaseStylePaymentMethodItem({
    super.key,
    required this.provider,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: REdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          border: Border(
            top: BorderSide(color: PurchaseColors.borderGray, width: 0.5),
            bottom: BorderSide(color: PurchaseColors.borderGray, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            _getPaymentIcon(provider),
            SizedBox(width: 12.rw),
            Expanded(
              child: Text(
                PaymentUtils.getPaymentDisplayName(provider),
                style: TextStyle(
                  fontSize: 15.rf,
                  color: PurchaseColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8.rw),
            Container(
              width: 11.rw,
              height: 11.rw,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? PurchaseColors.blueSelected : Colors.transparent,
                border: isSelected
                    ? null
                    : Border.all(color: PurchaseColors.textGray, width: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getPaymentIcon(PayProviderEntry provider) {
    // 根据provider.code返回对应的图标 - 业务逻辑不变
    // 统一使用PaymentUtils的图标
    return PaymentUtils.getPaymentIcon(provider);
  }
}

// ========== 促销横幅 ==========

// ========== 底部支付栏 (参照 member_page _buildBottomSection - 黑色胶囊) ==========
/// 支付逻辑不变：ref.read(checkoutNotifierV2Provider.notifier).handlePaymentTap(context)
/// 协议链接不变：launchUrl 目标 URL 不变
class PurchaseStyleBottomPayBar extends HookConsumerWidget {
  const PurchaseStyleBottomPayBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutState = ref.watch(checkoutNotifierV2Provider);
    final isLoggedIn = ref.watch(currentUserProvider).valueOrNull != null;
    final selectedProduct = checkoutState.selectedProduct;
    final rawPrice = selectedProduct?.price ?? 0.0;
    final price = rawPrice.toStringAsFixed(2);
    final currency = _currencySymbol(selectedProduct?.currency ?? '\$');
    // 用户是否已阅读并同意会员服务协议 + 自动续费协议；默认未勾选
    final isAgreed = useState(false);

    // 参照设计稿：淡紫胶囊外壳 + 左侧实付价格（深色）+ 右侧紫色渐变按钮
    return Padding(
      padding: REdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Container(
            height: 50.rh,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(27.rr),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFE8EDFF), Color(0xFFDEDCFF)],
              ),
            ),
            child: Row(
              children: [
                // 左侧：实付金额
                Expanded(
                  child: Padding(
                    padding: REdgeInsets.only(left: 20, right: 8),
                    child: Row(
                      children: [
                        // "实付" 固定标签，不参与弹性分配，绝不截断
                        Text(
                          '${GchText.userPayActualPay} ',
                          style: AppTextStyles.footnote.copyWith(
                            color: const Color(0xFF333333),
                          ),
                        ),
                        // 货币代码（小）+ 金额（大），FittedBox 防截断
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  currency,
                                  style: TextStyle(
                                    fontSize: 12.rf,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                                SizedBox(width: 2.rw),
                                Text(
                                  price,
                                  style: AppTextStyles.title2.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 右侧：立即开通 - 紫色渐变胶囊
                GestureDetector(
                  onTap: () async {
                    GchUmengSvc.onIapTap();
                    if (isLoggedIn && !isAgreed.value) {
                      ref
                          .read(gchSignalHubProvider)
                          .flashInfo(GchText.userPayPleaseAgreeAgreement);
                      return;
                    }
                    await ref
                        .read(checkoutNotifierV2Provider.notifier)
                        .handlePaymentTap(context);
                  },
                  child: Container(
                    height: 50.rh,
                    constraints: BoxConstraints(minWidth: 140.rw),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF8A9CFF), Color(0xFF5969FF)],
                      ),
                      borderRadius: BorderRadius.circular(27.rr),
                    ),
                    alignment: Alignment.center,
                    padding: REdgeInsets.symmetric(horizontal: 28),
                    child: checkoutState.isProcessing
                        ? SizedBox(
                            width: 22.rw,
                            height: 22.rw,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              isLoggedIn
                                  ? GchText.userPayConfirmPay
                                  : GchText.userPayGoToLogin,
                              style: AppTextStyles.subheadline.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.rh),
          // 协议勾选 - 用 RichText.WidgetSpan 把复选框嵌进文本，整体 textAlign.center
          // 保证"我已阅读并同意..."在水平方向居中对齐
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(fontSize: 12.rf, color: Colors.grey),
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: GestureDetector(
                    onTap: () => isAgreed.value = !isAgreed.value,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: REdgeInsets.only(right: 6),
                      child: Icon(
                        isAgreed.value
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 18.rw,
                        color: isAgreed.value
                            ? PurchaseColors.promoBadgeStart
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
                TextSpan(text: GchText.userPayAgreementPrefix),
                TextSpan(
                  text: GchText.userPayMemberAgreement,
                  style: const TextStyle(color: PurchaseColors.linkPurple),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => launchUrl(Uri.parse('https://example.com/iOSTerms.html'), mode: LaunchMode.inAppBrowserView),
                ),
                TextSpan(text: GchText.userPayAgreementAnd),
                TextSpan(
                  text: GchText.userPayAutoRenewalAgreement,
                  style: const TextStyle(color: PurchaseColors.linkPurple),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => launchUrl(Uri.parse('https://example.com/privacyA.html'), mode: LaunchMode.inAppBrowserView),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.rh),
          Center(
            child: Text(
              GchText.userPayAutoRenewalNotice,
              style: TextStyle(fontSize: 11.rf, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}


