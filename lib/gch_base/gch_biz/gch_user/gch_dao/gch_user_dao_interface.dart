import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_common/gch_enums.dart';

/// User DAO 统一接口
///
/// 提供类型安全的数据访问抽象，支持多种存储后端实现：
/// - SQLite: 使用 Drift DAO
/// - Realm: 使用 Realm API
/// - 未来: Hive, ObjectBox, 等
///
/// 【设计原则】
/// 1. 接口定义所有必需的数据操作方法
/// 2. 保持方法签名与现有 UserDao 一致，确保向后兼容
/// 3. 返回类型统一使用 Drift 的 UserEntry，简化业务层适配
abstract interface class UserDaoInterface {
  // ==================== 基础 CRUD 方法 ====================

  /// 获取用户（通常是当前登录用户）
  Future<UserEntry?> getUser();

  /// 根据用户ID获取用户
  Future<UserEntry?> getUserById(String id);

  /// 更新用户信息
  Future<bool> updateUser(UserEntriesCompanion user);

  /// 删除用户
  Future<int> deleteUser(String id);

  // ==================== 查询方法 ====================

  /// 查询用户列表
  ///
  /// [limit] 返回记录数限制
  /// [offset] 跳过记录数（用于分页）
  /// [status] 按状态筛选
  /// [vipType] 按VIP类型筛选
  Future<List<UserEntry>> getUsers({
    int? limit,
    int? offset,
    UserStatus? status,
    VipType? vipType,
  });

  /// 创建新用户
  Future<UserEntry> createUser(UserEntry userEntry);

  // ==================== 响应式方法（Stream）====================

  /// 监听用户变化（当前用户）
  Stream<UserEntry?> watchUser();

  /// 监听特定用户变化
  Stream<UserEntry?> watchUserById(String id);

  // ==================== 验证方法 ====================

  /// 检查邮箱是否已存在
  Future<bool> emailExists(String email);

  /// 检查手机号是否已存在
  Future<bool> phoneExists(String phone);

  /// 检查邀请码是否已存在
  Future<bool> inviteCodeExists(String inviteCode);
}
