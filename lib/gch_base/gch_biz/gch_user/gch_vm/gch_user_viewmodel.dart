import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:guichao/gch_base/gch_biz/gch_user/gch_providers/gch_user_providers.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';

part 'gch_user_viewmodel.g.dart';

class UserState {
  final UserEntry? user;
  final List<UserEntry>? users;
  final bool isLoading;
  final String? error;
  final bool isOnline;
  final DateTime? lastSyncTime;

  const UserState({
    this.user,
    this.users,
    this.isLoading = false,
    this.error,
    this.isOnline = false,
    this.lastSyncTime,
  });

  UserState copyWith({
    UserEntry? user,
    List<UserEntry>? users,
    bool? isLoading,
    String? error,
    bool? isOnline,
    DateTime? lastSyncTime,
  }) {
    return UserState(
      user: user ?? this.user,
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isOnline: isOnline ?? this.isOnline,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

@Riverpod(keepAlive: true)
class UserViewModel extends _$UserViewModel {
  @override
  Future<UserState> build() async {
    final result = await ref.read(userRepositoryProvider).getUser().run();
    return result.fold(
      (error) => UserState(error: error),
      (user) => UserState(user: user, isOnline: user != null, lastSyncTime: DateTime.now()),
    );
  }

  Future<void> refreshUser() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(userRepositoryProvider).getUser().run();
      return result.fold(
        (error) => UserState(error: error),
        (user) => UserState(user: user, isOnline: user != null, lastSyncTime: DateTime.now()),
      );
    });
  }

  Future<void> getUserById(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(userRepositoryProvider).getUserById(id).run();
      return result.fold(
        (error) => UserState(error: error),
        (user) => UserState(user: user, isOnline: user != null, lastSyncTime: DateTime.now()),
      );
    });
  }

  Future<void> getUsers({int? limit, int? offset}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(userRepositoryProvider).getUsers(limit: limit, offset: offset).run();
      return result.fold(
        (error) => UserState(error: error),
        (users) => UserState(users: users, isOnline: true, lastSyncTime: DateTime.now()),
      );
    });
  }

  Future<void> createUser(UserEntriesCompanion user) async {
    state = const AsyncValue.loading();
    final result = await ref.read(userRepositoryProvider).createUser(user).run();
    await result.fold(
      (error) async => state = AsyncValue.error(error, StackTrace.current),
      (createdUser) async {
        await refreshUser();
      },
    );
  }

  Future<void> updateUser(UserEntriesCompanion user) async {
    state = const AsyncValue.loading();
    final result = await ref.read(userRepositoryProvider).updateUser(user).run();
    await result.fold(
      (error) async => state = AsyncValue.error(error, StackTrace.current),
      (success) async {
        if (success) {
          await refreshUser();
        }
      },
    );
  }

  Future<void> deleteUser(String id) async {
    state = const AsyncValue.loading();
    final result = await ref.read(userRepositoryProvider).deleteUser(id).run();
    await result.fold(
      (error) async => state = AsyncValue.error(error, StackTrace.current),
      (_) async => state = const AsyncValue.data(UserState()),
    );
  }

  Stream<UserEntry?> watchUser() async* {
    final result = await ref.watch(userRepositoryProvider).watchUser().run();
    yield* result.fold(
      (error) => throw error,
      (stream) => stream.map((users) => users.firstOrNull),
    );
  }

  Stream<UserEntry?> watchUserById(String id) async* {
    final result = await ref.watch(userRepositoryProvider).watchUserById(id).run();
    yield* result.fold(
      (error) => throw error,
      (stream) => stream,
    );
  }

  // 业务逻辑方法 - 整合原有Service层功能
  Future<bool> validateEmail(String email) async {
    final dao = ref.read(userDaoProvider);
    return await dao.emailExists(email);
  }

  Future<bool> validatePhone(String phone) async {
    final dao = ref.read(userDaoProvider);
    return await dao.phoneExists(phone);
  }

  Future<bool> validateInviteCode(String inviteCode) async {
    final dao = ref.read(userDaoProvider);
    return await dao.inviteCodeExists(inviteCode);
  }
}
