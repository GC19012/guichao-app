// auth_view_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authuser_model.dart';

part 'gch_auth_view_state.freezed.dart';
part 'gch_auth_view_state.g.dart';

/// 认证视图状态 - 使用 Freezed 自动生成不可变数据类
@freezed
abstract class AuthViewState with _$AuthViewState {
  const factory AuthViewState({
    /// 当前用户
    AuthUser? user,
    
    /// 认证令牌
    String? token,
    
    /// 是否正在加载
    @Default(false) bool isLoading,
    
    /// 错误信息
    String? error,
  }) = _AuthViewState;

  factory AuthViewState.fromJson(Map<String, dynamic> json) => _$AuthViewStateFromJson(json);
}

/// 扩展方法，为 AuthViewState 提供便捷的状态管理方法
extension AuthViewStateExtension on AuthViewState {
  /// 清除错误信息
  AuthViewState clearError() {
    return copyWith(error: null);
  }

  /// 清除用户信息
  AuthViewState clearUser() {
    return copyWith(
      user: null,
      token: null,
      error: null,
    );
  }
}
