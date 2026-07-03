import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_common/gch_enums.dart';
import 'package:guichao/gch_base/gch_biz/gch_user/gch_dao/gch_user_dao.dart';
import 'package:guichao/gch_base/gch_biz/gch_user/gch_dao/gch_user_dao_interface.dart';

/// SQLite UserDao 适配器
///
/// 将 Drift 自动生成的 UserDao 适配为 UserDaoInterface
///
/// 【设计理由】
/// - Drift 的 UserDao 是自动生成的，无法直接修改让其实现接口
/// - 使用适配器模式包装，提供统一的接口实现
/// - 所有方法直接转发到底层的 UserDao
///
/// 【性能】
/// - 零开销：方法调用直接转发，无额外逻辑
/// - 编译器可内联优化
final class SQLiteUserDaoAdapter implements UserDaoInterface {
  SQLiteUserDaoAdapter(this._dao);

  final UserDao _dao;

  // ==================== 直接转发所有方法 ====================

  @override
  Future<UserEntry?> getUser() => _dao.getUser();

  @override
  Future<UserEntry?> getUserById(String id) => _dao.getUserById(id);

  @override
  Future<bool> updateUser(UserEntriesCompanion user) => _dao.updateUser(user);

  @override
  Future<int> deleteUser(String id) => _dao.deleteUser(id);

  @override
  Future<List<UserEntry>> getUsers({
    int? limit,
    int? offset,
    UserStatus? status,
    VipType? vipType,
  }) =>
      _dao.getUsers(
        limit: limit,
        offset: offset,
        status: status,
        vipType: vipType,
      );

  @override
  Future<UserEntry> createUser(UserEntry userEntry) => _dao.createUser(userEntry);

  @override
  Stream<UserEntry?> watchUser() => _dao.watchUser();

  @override
  Stream<UserEntry?> watchUserById(String id) => _dao.watchUserById(id);

  @override
  Future<bool> emailExists(String email) => _dao.emailExists(email);

  @override
  Future<bool> phoneExists(String phone) => _dao.phoneExists(phone);

  @override
  Future<bool> inviteCodeExists(String inviteCode) => _dao.inviteCodeExists(inviteCode);
}
