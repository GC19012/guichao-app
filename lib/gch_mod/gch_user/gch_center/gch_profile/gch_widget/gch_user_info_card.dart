import 'package:flutter/material.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';

/// 用户信息卡片组件
/// 
/// 显示用户的基本信息、会员状态和流量使用情况
class UserInfoCard extends StatelessWidget {
  const UserInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: REdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: REdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B8DEF), Color(0xFF907AFE)],
        ),
        borderRadius: BorderRadius.circular(16.rr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像和用户信息
          Row(
            children: [
              Container(
                width: 48.rw,
                height: 48.rh,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12.rw),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '游客',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.rf,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '888888888888',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14.rf,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.rh),
          // 会员信息
          Text(
            '娱乐版会员',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.rf,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.rh),
          Row(
            children: [
              Flexible(
                child: Text(
                  '2025-04-08 08:08:08',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14.rf,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.rw),
              Container(
                padding: REdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5B4),
                  borderRadius: BorderRadius.circular(16.rr),
                ),
                child: Text(
                  '解锁特权',
                  style: TextStyle(
                    color: Color(0xFF8B4513),
                    fontSize: 12.rf,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.rh),
          Text(
            '本月已用流量：0G    速率：正常',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14.rf,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
