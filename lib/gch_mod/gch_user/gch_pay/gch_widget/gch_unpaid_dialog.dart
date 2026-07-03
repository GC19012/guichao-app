import 'dart:async';

import 'package:flutter/material.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_providers/gch_product_providers.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 未支付订单弹窗 - 浅色主题（与新版 checkout_list_page 保持一致）
class UnpaidDialog extends ConsumerStatefulWidget {
  final OrderEntry order;
  final VoidCallback onPay;
  final VoidCallback onCancel;

  const UnpaidDialog({
    super.key,
    required this.order,
    required this.onPay,
    required this.onCancel,
  });

  @override
  ConsumerState<UnpaidDialog> createState() => _UnpaidDialogState();
}

class _UnpaidDialogState extends ConsumerState<UnpaidDialog> {
  late Timer _timer;
  late int _seconds;

  @override
  void initState() {
    super.initState();

    // 计算剩余时间
    final now = DateTime.now();
    final elapsed = now.difference(widget.order.createAt);
    final remaining = const Duration(minutes: 10) - elapsed;
    _seconds = remaining.inSeconds.clamp(0, 600);

    // 启动倒计时
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds--;
        });
        if (_seconds <= 0) {
          _timer.cancel();
          widget.onCancel();
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _timeText {
    final minutes = _seconds ~/ 60;
    final seconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final description = _resolveProductDescription();
    final currency = widget.order.currency.trim();
    final amountText = currency.isNotEmpty
        ? '$currency ${widget.order.total}'
        : widget.order.total.toString();

    // 浅色主题配色
    const dialogBg = Color(0xFFF7F6FF);
    const borderColor = Color(0xFFE4E6F5);
    const cardBg = Colors.white;
    const textDark = Color(0xFF2F2F3A);
    const textMuted = Color(0xFF8C8FAE);
    const accentPurple = Color(0xFF5969FF);

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.rr),
        side: const BorderSide(color: borderColor, width: 1),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 380.rw),
        child: Padding(
          padding: REdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题图标 - 浅紫玻璃质感
                Container(
                  width: 54.rw,
                  height: 54.rh,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFF2F4FF),
                        Color(0xFFDCE3FF),
                        Color(0xFFC6D0FF),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentPurple.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.payment,
                    color: accentPurple,
                    size: 26.ri,
                  ),
                ),

                SizedBox(height: 14.rh),

                // 标题
                Text(
                  '你有一笔订单未支付',
                  style: TextStyle(
                    fontSize: 18.rf,
                    fontWeight: FontWeight.w500,
                    color: textDark,
                  ),
                ),

                SizedBox(height: 18.rh),

                // 倒计时
                Container(
                  padding: REdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2FF),
                    borderRadius: BorderRadius.circular(8.rr),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer,
                        color: textMuted,
                        size: 18.ri,
                      ),
                      SizedBox(width: 6.rw),
                      Text(
                        '剩余时间: $_timeText',
                        style: TextStyle(
                          fontSize: 14.rf,
                          color: textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 18.rh),

                // 订单信息
                Container(
                  width: double.infinity,
                  padding: REdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12.rr),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            color: textMuted,
                            size: 18.ri,
                          ),
                          SizedBox(width: 8.rw),
                          Text(
                            '产品名称',
                            style: TextStyle(
                              fontSize: 14.rf,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.rh),
                      Text(
                        widget.order.productName ?? widget.order.productId.toString(),
                        style: TextStyle(
                          fontSize: 16.rf,
                          color: textDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      if (description != null && description.isNotEmpty) ...[
                        SizedBox(height: 12.rh),
                          Row(
                            children: [
                              Icon(
                                Icons.notes,
                                color: textMuted,
                                size: 18.ri,
                              ),
                              SizedBox(width: 8.rw),
                              Text(
                                '产品描述',
                                style: TextStyle(
                                  fontSize: 14.rf,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.rh),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 14.rf,
                              color: const Color(0xFF6B7280),
                              height: 1.3,
                            ),
                          ),
                      ],

                      SizedBox(height: 14.rh),

                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            color: textMuted,
                            size: 18.ri,
                          ),
                          SizedBox(width: 8.rw),
                          Text(
                            '金额',
                            style: TextStyle(
                              fontSize: 14.rf,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.rh),
                      Text(
                        amountText,
                        style: TextStyle(
                          fontSize: 18.rf,
                          color: accentPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 18.rh),

                // 按钮组
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onCancel();
                        },
                        style: TextButton.styleFrom(
                          padding: REdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.rr),
                            side: const BorderSide(color: borderColor),
                          ),
                        ),
                        child: Text(
                          '取消',
                          style: TextStyle(
                            fontSize: 15.rf,
                            color: textMuted,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 12.rw),

                    Expanded(
                      flex: 2,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onPay();
                        },
                        style: TextButton.styleFrom(
                          padding: REdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.rr),
                            side: const BorderSide(color: borderColor),
                          ),
                        ),
                        child: Text(
                          '立即支付',
                          style: TextStyle(
                            fontSize: 15.rf,
                            color: textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _resolveProductDescription() {
    final products = ref.watch(productsProvider).valueOrNull;
    if (products == null || products.isEmpty) return null;

    final order = widget.order;
    ProductEntry? match;
    for (final product in products) {
      if (product.id == order.productId ||
          (order.storeProductId != null && product.productId == order.storeProductId)) {
        match = product;
        break;
      }
    }

    final desc = match?.description?.trim();
    return (desc == null || desc.isEmpty) ? null : desc;
  }
}
