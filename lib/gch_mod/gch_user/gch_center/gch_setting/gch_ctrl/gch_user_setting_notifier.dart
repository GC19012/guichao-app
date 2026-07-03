import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authuser_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_providers/gch_auth_providers.dart';
import 'package:guichao/gch_aux/gch_log_mix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:guichao/gch_base/gch_biz/gch_common/gch_enums.dart';
import 'package:guichao/gch_base/gch_umeng/gch_umeng_svc.dart';

part 'gch_user_setting_notifier.g.dart';

/// 用户设置通知器 - 简单封装配置选项访问和认证管理
@Riverpod(keepAlive: true)
class UserSettingNotifier extends _$UserSettingNotifier with GchAppLogger {
  @override
  bool build() {
    // 监听认证状态变化
    ref.listen(authStateChangesProvider, (previous, next) {
      next.whenData((authState) {
        // 当认证状态变化时，更新我们的状态来触发UI重建
        state = authState.isAuthenticated;
      });
    });

    return false;
  }

  /// 用户登出
  Future<bool> signOut() async {
    try {
      final authManager = await ref.read(authManagerProvider.future);
      final result = await authManager.signOut();

      if (result) {
        GchUmengSvc.onLogoutTap();
        state = true; // 标记操作完成
        loggy.info("用户成功登出");
      }

      return result;
    } catch (e, st) {
      loggy.warning("用户登出失败", e, st);
      return false;
    }
  }

  /// 删除账号
  Future<bool> deleteAccount() async {
    try {
      final authManager = await ref.read(authManagerProvider.future);
      final result = await authManager.deleteAccount();

      if (result) {
        state = true; // 标记操作完成
        loggy.info("账号注销成功");
      }

      return result;
    } catch (e, st) {
      loggy.warning("账号注销失败", e, st);
      return false;
    }
  }

  /// 检查用户登录状态
  Future<bool> isUserAuthenticated() async {
    try {
      final authManager = await ref.read(authManagerProvider.future);
      final currentUser = await authManager.getCurrentUser();
      return currentUser != null;
    } catch (e, st) {
      loggy.warning("检查用户认证状态失败", e, st);
      return false;
    }
  }

  /// 获取当前用户邮箱
  Future<String?> getCurrentUserEmail() async {
    try {
      final authManager = await ref.read(authManagerProvider.future);
      final currentUser = await authManager.getCurrentUser();
      return currentUser?.email;
    } catch (e, st) {
      loggy.warning("获取当前用户邮箱失败", e, st);
      return null;
    }
  }

  /// 获取用户完整信息 - 优化版本，一次调用获取所有信息
  Future<({
    bool isAuthenticated,
    String? email,
    String? phone,
    String gcSeq,
    VipType vipType,
    DateTime? expiredAt,
    String? authType,
    AuthUser? user
  })> getUserInfo() async {
    try {
      // 获取认证管理器和当前用户（只调用一次）
      final authManager = await ref.read(authManagerProvider.future);
      final currentUser = await authManager.getCurrentUser();

      final isAuthenticated = currentUser != null;
      final email = currentUser?.email;
      final phone = currentUser?.phone;
      final vipType = currentUser?.currentVip ?? VipType.free;
      final expiredAt = currentUser?.expiredAt;
      final authType = currentUser?.authType;

      // 获取GUICHAO
      String gcSeq = GchNucleus.gcSerial ?? await GchNucleus.buildGcSeq();
      GchNucleus.gcSerial ??= gcSeq;

      return (
        isAuthenticated: isAuthenticated,
        email: email,
        phone: phone,
        gcSeq: gcSeq,
        vipType: vipType,
        expiredAt: expiredAt,
        authType: authType,
        user: currentUser,
      );
    } catch (e, st) {
      loggy.warning("获取用户信息失败", e, st);
      return (
        isAuthenticated: false,
        email: null,
        phone: null,
        gcSeq: 'GC00000000',
        vipType: VipType.free,
        expiredAt: null,
        authType: null,
        user: null,
      );
    }
  }

  /// 获取GUICHAO（GcSeq）
  Future<String> getGcSeq() async {
    try {
      // 如果GchNucleus中已经有GcSeq，直接返回
      if (GchNucleus.gcSerial != null) {
        return GchNucleus.gcSerial!;
      }

      // 如果没有，生成一个新的
      final gcSeq = await GchNucleus.buildGcSeq();
      GchNucleus.gcSerial = gcSeq;
      return gcSeq;
    } catch (e, st) {
      loggy.warning("获取GUICHAO失败", e, st);
      // 返回一个默认值或者基于时间戳的临时ID
      return 'GC00000000';
    }
  }
}
