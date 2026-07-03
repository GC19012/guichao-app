import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_providers/gch_auth_providers.dart';

part 'gch_password_change_notifier.freezed.dart';

@freezed
abstract class PasswordChangeState with _$PasswordChangeState {
  const factory PasswordChangeState({
    @Default(false) bool isLoading,
    @Default(false) bool isNewPasswordVisible,
    @Default(false) bool isConfirmPasswordVisible,
    String? errorMessage,
    String? successMessage,
  }) = _PasswordChangeState;
}

final passwordChangeNotifierProvider =
    StateNotifierProvider.autoDispose<PasswordChangeNotifier, PasswordChangeState>((ref) {
  return PasswordChangeNotifier(ref);
});

class PasswordChangeNotifier extends StateNotifier<PasswordChangeState> {
  final Ref _ref;

  PasswordChangeNotifier(this._ref) : super(const PasswordChangeState());

  void toggleNewPasswordVisibility() {
    state = state.copyWith(isNewPasswordVisible: !state.isNewPasswordVisible);
  }

  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(isConfirmPasswordVisible: !state.isConfirmPasswordVisible);
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  Future<bool> changePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    clearMessages();

    if (newPassword.isEmpty) {
      state = state.copyWith(errorMessage: '请输入新密码');
      return false;
    }

    if (newPassword.length < 6) {
      state = state.copyWith(errorMessage: '新密码长度不能少于6位');
      return false;
    }

    if (newPassword != confirmPassword) {
      state = state.copyWith(errorMessage: '两次输入的密码不一致');
      return false;
    }

    state = state.copyWith(isLoading: true);

    try {
      final authManager = await _ref.read(authManagerProvider.future);
      final success = await authManager.updateUserPassword(newPassword);

      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: '密码修改成功！',
          errorMessage: null,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: '密码修改失败',
          successMessage: null,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '密码修改失败：${e.toString()}',
        successMessage: null,
      );
      return false;
    }
  }
}