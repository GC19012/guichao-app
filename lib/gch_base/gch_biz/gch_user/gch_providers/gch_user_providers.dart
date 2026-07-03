import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:guichao/gch_base/gch_store/gch_db_provider.dart';
import 'package:guichao/gch_base/gch_biz/gch_api/gch_providers/gch_api_client_providers.dart';
import 'package:guichao/gch_base/gch_biz/gch_user/gch_api/gch_user_api.dart';
import 'package:guichao/gch_base/gch_biz/gch_user/gch_dao/gch_user_dao_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_user/gch_dao/gch_sqlite_user_dao_adapter.dart';
import 'package:guichao/gch_base/gch_biz/gch_user/gch_repo/gch_user_repository.dart';

part 'gch_user_providers.g.dart';

/// User DAO Provider - SQLite 实现
@Riverpod(keepAlive: true)
UserDaoInterface userDao(UserDaoRef ref) {
  final db = ref.watch(gchDatabaseProvider);
  return SQLiteUserDaoAdapter(db.userDao);
}

@Riverpod(keepAlive: true)
UserApi userApi(UserApiRef ref) {
  // 使用 DataApiClient
  final apiClient = ref.watch(apiClientProvider);
  return UserApi(apiClient: apiClient);
}

@Riverpod(keepAlive: true)
UserRepositoryInterface userRepository(UserRepositoryRef ref) {
  final api = ref.watch(userApiProvider);
  final dao = ref.watch(userDaoProvider);
  return UserRepository(api, dao);
}
