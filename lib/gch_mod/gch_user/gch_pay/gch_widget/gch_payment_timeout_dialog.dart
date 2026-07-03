import 'package:flutter/material.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';

/// 支付超时弹窗
class PaymentTimeoutDialog extends StatelessWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onCheckOrder;

  const PaymentTimeoutDialog({
    super.key,
    this.onRetry,
    this.onCheckOrder,
  });

  /// 显示支付超时弹窗
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onRetry,
    VoidCallback? onCheckOrder,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentTimeoutDialog(
        onRetry: onRetry,
        onCheckOrder: onCheckOrder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Dialog(
      backgroundColor: const Color(0xFFF7F6FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.rr),
        side: const BorderSide(color: Color(0xFFE4E6F5), width: 1),
      ),
      child: Container(
        padding: REdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.rr),
          color: const Color(0xFFF7F6FF),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 超时图标 - 深蓝色渐变
            Container(
              width: 60.rw,
              height: 60.rh,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE5E9FF),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5969FF).withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.schedule,
                color: const Color(0xFF5969FF),
                size: 28.ri,
              ),
            ),

            SizedBox(height: 16.rh),

            // 标题
            Text(
              '支付处理中...',
              style: TextStyle(
                fontSize: 20.rf,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2F2F3A),
              ),
            ),

            SizedBox(height: 16.rh),

            // 说明文本 - 低色调深蓝
            Container(
              width: double.infinity,
              padding: REdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.rr),
                border: Border.all(color: const Color(0xFFE4E6F5), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: const Color(0xFF5969FF),
                        size: 18.ri,
                      ),
                      SizedBox(width: 8.rw),
                      Text(
                        '请稍等片刻',
                        style: TextStyle(
                          fontSize: 14.rf,
                          color: const Color(0xFF5969FF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.rh),
                  Text(
                    '支付处理时间较长，这可能是因为：',
                    style: TextStyle(
                      fontSize: 15.rf,
                      color: const Color(0xFF2F2F3A),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 8.rh),
                  Text(
                    '• 网络连接响应较慢\n• 支付平台正在处理\n• 订单验证需要时间',
                    style: TextStyle(
                      fontSize: 14.rf,
                      color: const Color(0xFF8C8FAE),
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 12.rh),
                  Container(
                    padding: REdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF2FF),
                      borderRadius: BorderRadius.circular(8.rr),
                      border: Border.all(color: const Color(0xFFD6DBFF), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: const Color(0xFF5969FF),
                          size: 16.ri,
                        ),
                        SizedBox(width: 8.rw),
                        Expanded(
                          child: Text(
                            '支付可能已成功，可稍后查看订单状态',
                            style: TextStyle(
                              fontSize: 13.rf,
                              color: const Color(0xFF5969FF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.rh),

            // 按钮组 - 深蓝色调
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: REdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.rr),
                        side: const BorderSide(color: Color(0xFFE4E6F5)),
                      ),
                    ),
                    child: Text(
                      '我知道了',
                      style: TextStyle(
                        fontSize: 16.rf,
                        color: const Color(0xFF8C8FAE),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12.rw),

                if (onCheckOrder != null) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onCheckOrder?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5969FF),
                        foregroundColor: Colors.white,
                        padding: REdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.rr),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: Text(
                        '查看订单',
                        style: TextStyle(
                          fontSize: 16.rf,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.rw),
                ],

                if (onRetry != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onRetry?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6F7BFF),
                        foregroundColor: Colors.white,
                        padding: REdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.rr),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.rr),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6F7BFF).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '重试支付',
                          style: TextStyle(
                            fontSize: 16.rf,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
