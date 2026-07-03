import 'package:fpdart/fpdart.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_user/gch_api/gch_user_api.dart';
import 'package:guichao/gch_base/gch_biz/gch_user/gch_dao/gch_user_dao_interface.dart';

abstract class UserRepositoryInterface {
  TaskEither<String, UserEntry?> getUser();
  TaskEither<String, UserEntry?> getUserById(String id);
  TaskEither<String, bool> updateUser(UserEntriesCompanion user);
  TaskEither<String, int> deleteUser(String id);
  TaskEither<String, Stream<List<UserEntry>>> watchUser();
  TaskEither<String, Stream<UserEntry?>> watchUserById(String id);
  TaskEither<String, List<UserEntry>> getUsers({
    int? limit,
    int? offset,
  });
  TaskEither<String, UserEntry> createUser(UserEntriesCompanion user);
}

class UserRepository implements UserRepositoryInterface {
  final UserApi _api;
  final UserDaoInterface _userDao; // ✅ 类型安全：支持任何实现 UserDaoInterface 的 DAO

  UserRepository(this._api, this._userDao);

  @override
  TaskEither<String, UserEntry?> getUser() {
    return TaskEither(() async {
      try {
        final user = await _userDao.getUser();
        if (user != null) return right(user);
      } catch (_) {}
      // 本地无数据或异常，尝试 API
      try {
        final apiUser = await _api.getUser();
        return right(apiUser);
      } catch (e) {
        return left(e.toString());
      }
    });
  }

  @override
  TaskEither<String, UserEntry?> getUserById(String id) {
    return TaskEither(() async {
      try {
        final user = await _userDao.getUserById(id);
        if (user != null) return right(user);

        // 如果本地没有，尝试从API获取
        final apiUser = await _api.getUserById(id);
        return right(apiUser);
      } catch (e) {
        return left(e.toString());
      }
    });
  }

  @override
  TaskEither<String, bool> updateUser(UserEntriesCompanion user) {
    return TaskEither(() async {
      try {
        // 先更新本地数据
        final result = await _userDao.updateUser(user);
        // 然后同步到API（新的API接口返回bool）
        final apiResult = await _api.updateUser(user);
        return right(result && apiResult);
      } catch (e) {
        return left(e.toString());
      }
    });
  }

  @override
  TaskEither<String, int> deleteUser(String id) {
    return TaskEither(() async {
      try {
        // 先删除本地数据
        final result = await _userDao.deleteUser(id);
        // 然后同步到API
        await _api.deleteUser(id);
        return right(result);
      } catch (e) {
        return left(e.toString());
      }
    });
  }

  @override
  TaskEither<String, Stream<List<UserEntry>>> watchUser() {
    return TaskEither(() async {
      try {
        final stream = _userDao.watchUser().map((user) => user == null ? <UserEntry>[] : [user]);
        return right(stream);
      } catch (e) {
        return left(e.toString());
      }
    });
  }

  @override
  TaskEither<String, Stream<UserEntry?>> watchUserById(String id) {
    return TaskEither(() async {
      try {
        final stream = _userDao.watchUserById(id);
        return right(stream);
      } catch (e) {
        return left(e.toString());
      }
    });
  }

  @override
  TaskEither<String, List<UserEntry>> getUsers({
    int? limit,
    int? offset,
  }) {
    return TaskEither(() async {
      try {
        // 优先从本地获取
        final localUsers = await _userDao.getUsers(limit: limit, offset: offset);
        if (localUsers.isNotEmpty) {
          return right(localUsers);
        }

        // 本地无数据时从API获取
        final apiUsers = await _api.getUsers(limit: limit, offset: offset);
        return right(apiUsers);
      } catch (e) {
        return left(e.toString());
      }
    });
  }

  @override
  TaskEither<String, UserEntry> createUser(UserEntriesCompanion user) {
    return TaskEither(() async {
      try {
        // 先通过API创建
        final apiUser = await _api.createUser(user);
        // 然后保存到本地
        await _userDao.createUser(apiUser);
        return right(apiUser);
      } catch (e) {
        return left(e.toString());
      }
    });
  }
}
