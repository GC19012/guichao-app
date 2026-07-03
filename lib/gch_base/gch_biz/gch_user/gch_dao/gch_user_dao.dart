import 'package:drift/drift.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_user/gch_dao/gch_user_dao_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_user/gch_model/gch_user_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_common/gch_enums.dart';
part 'gch_user_dao.g.dart';

@DriftAccessor(tables: [UserEntries])
class UserDao extends DatabaseAccessor<GchDatabase> with _$UserDaoMixin implements UserDaoInterface {
  UserDao(super.db);

  // 简化的基础方法 - 参照 mvvc 模式
  Future<UserEntry?> getUser() => select(userEntries).getSingleOrNull();
  Future<UserEntry?> getUserById(String id) => (select(userEntries)..where((tbl) => tbl.userId.equals(id))).getSingleOrNull();
  Future<bool> updateUser(UserEntriesCompanion user) => update(userEntries).replace(user);
  Future<int> deleteUser(String id) => (delete(userEntries)..where((tbl) => tbl.userId.equals(id))).go();

  // 扩展方法以支持原有功能
  Future<List<UserEntry>> getUsers({
    int? limit,
    int? offset,
    UserStatus? status,
    VipType? vipType,
  }) async {
    final query = select(userEntries);

    if (status != null) {
      query.where((tbl) => tbl.status.equals(status.index));
    }

    if (vipType != null) {
      query.where((tbl) => tbl.vipType.equals(vipType.index));
    }

    if (limit != null) {
      query.limit(limit, offset: offset);
    }

    return query.get();
  }

  Future<UserEntry> createUser(UserEntry userEntry) async {
    return into(userEntries).insertReturning(userEntry.toCompanion(true));
  }

  // 流式数据方法 - 添加 watch 功能
  Stream<UserEntry?> watchUser() => select(userEntries).watchSingleOrNull();
  Stream<UserEntry?> watchUserById(String id) => (select(userEntries)..where((tbl) => tbl.userId.equals(id))).watchSingleOrNull();

  // 验证方法
  Future<bool> emailExists(String email) async {
    final query = select(userEntries)..where((tbl) => tbl.email.equals(email));
    final user = await query.getSingleOrNull();
    return user != null;
  }

  Future<bool> phoneExists(String phone) async {
    final query = select(userEntries)..where((tbl) => tbl.phone.equals(phone));
    final user = await query.getSingleOrNull();
    return user != null;
  }

  Future<bool> inviteCodeExists(String inviteCode) async {
    final query = select(userEntries)..where((tbl) => tbl.inviteCode.equals(inviteCode));
    final user = await query.getSingleOrNull();
    return user != null;
  }
}
