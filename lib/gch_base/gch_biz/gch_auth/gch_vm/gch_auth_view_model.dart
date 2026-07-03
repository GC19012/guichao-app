import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_auth_view_state.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authtype_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_service.dart';

// 认证状态管理器
class AuthNotifier extends StateNotifier<AuthViewState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthViewState()) {
    _initialize();
    _subscribeToAuthChanges();
  }

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _authService.getCurrentUser();
      final token = await _authService.getToken();
      state = state.copyWith(
        user: user,
        token: token,
        isLoading: false,
      );
    } catch (e) {
      _handleError(e);
    }
  }

  void _subscribeToAuthChanges() {
    _authService.onAuthStateChanged.listen(
      (user) => state = state.copyWith(user: user),
      onError: _handleError,
    );
  }

  void _handleError(dynamic error) {
    state = state.copyWith(
      error: error.toString(),
      isLoading: false,
    );
  }

  // 登录方法
  Future<AuthResponse> signIn({
    String? email,
    String? password,
    String? phone,
    String? code,
    Map<String, dynamic>? metadata,
  }) async {
    state = state.copyWith(isLoading: true).clearError();
    try {
      final request = AuthRequest(
        email: email,
        password: password,
        phone: phone,
        code: code,
        metadata: metadata,
      );

      final response = await _authService.signIn(request: request);
      if (response.isSuccess) {
        state = state.copyWith(
          user: response.user,
          token: response.token,
          isLoading: false,
        );
      } else {
        _handleError(response.errorMessage);
      }
      return response;
    } catch (e) {
      _handleError(e);
      return AuthResponse(errorMessage: e.toString());
    }
  }

  // 注册方法
  Future<AuthResponse> signUp({
    String? email,
    String? password,
    String? phone,
    String? code,
    String? name,
    String? nickname,
    String? country,
    Map<String, dynamic>? metadata,
  }) async {
    state = state.copyWith(isLoading: true).clearError();
    try {
      final request = AuthRequest.forSignUp(
        email: email,
        password: password,
        phone: phone,
        name: name,
        nickname: nickname,
        country: country,
        metadata: metadata,
      );

      final response = await _authService.signUp(request: request);
      if (response.isSuccess) {
        state = state.copyWith(
          user: response.user,
          token: response.token,
          isLoading: false,
        );
      } else {
        _handleError(response.errorMessage);
      }
      return response;
    } catch (e) {
      _handleError(e);
      return AuthResponse(errorMessage: e.toString());
    }
  }

  // 第三方登录

  Future<AuthResponse> signInWithOAuth2({
    required String provider,
    String? redirectUrl,
    String? authCode,
    String? idToken,
    Map<String, dynamic>? extraParams,
  }) async {
    state = state.copyWith(isLoading: true).clearError();
    try {
      final response = await _authService.signInWithOAuth2(
        provider: provider,
        redirectUrl: redirectUrl,
        authCode: authCode,
        idToken: idToken,
        extraParams: extraParams,
      );

      if (response.isSuccess) {
        state = state.copyWith(
          user: response.user,
          token: response.token,
          isLoading: false,
        );
      } else {
        _handleError(response.errorMessage);
      }
      return response;
    } catch (e) {
      _handleError(e);
      return AuthResponse(errorMessage: e.toString());
    }
  }

  // 登出方法
  Future<AuthResponse> signOut() async {
    state = state.copyWith(isLoading: true).clearError();
    try {
      final response = await _authService.signOut();
      state = state.clearUser();
      return response;
    } catch (e) {
      _handleError(e);
      return AuthResponse(errorMessage: e.toString());
    }
  }

  // 发送短信验证码
  Future<bool> sendSmsCode(String phone) async {
    state = state.copyWith(isLoading: true).clearError();
    try {
      final success = await _authService.sendSmsCode(phone: phone);
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  // 重置密码
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true).clearError();
    try {
      final success = await _authService.resetPassword(email: email);
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  // 确认重置密码
  Future<bool> confirmPasswordReset(String code, String newPassword) async {
    state = state.copyWith(isLoading: true).clearError();
    try {
      final success = await _authService.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  // 修改密码
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    state = state.copyWith(isLoading: true).clearError();
    try {
      final success = await _authService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  // 验证邮箱验证码
  Future<AuthResponse> verifyOtp({required String email, required String code}) async {
    state = state.copyWith(isLoading: true).clearError();
    try {
      final response = await _authService.verifyOtp(
        email: email,
        code: code,
      );
      if (response.isSuccess) {
        state = state.copyWith(
          user: response.user,
          token: response.token,
          isLoading: false,
        );
      } else {
        _handleError(response.errorMessage);
      }
      return response;
    } catch (e) {
      _handleError(e);
      return AuthResponse(errorMessage: e.toString());
    }
  }

  // 发送邮箱验证码
  Future<AuthResponse> signInWithOtp({required String email}) async {
    state = state.copyWith(isLoading: true).clearError();
    try {
      final response = await _authService.signInWithOtp(
        email: email,
      );
      if (response.isSuccess) {
        state = state.copyWith(
          user: response.user,
          token: response.token,
          isLoading: false,
        );
      } else {
        _handleError(response.errorMessage);
      }
      return response;
    } catch (e) {
      _handleError(e);
      return AuthResponse(errorMessage: e.toString());
    }
  }
}
// // 在widget中使用
// final authState = ref.watch(authStateProvider);
// final authNotifier = ref.read(authStateProvider.notifier);
//
// // 邮箱登录
// await authNotifier.signIn(
// email: 'user@example.com',
// password: 'password'
// );
//
// // 注册新用户
// await authNotifier.signUp(
// email: 'newuser@example.com',
// password: 'password',
// name: '张三',
// country: 'CN'
// );
//
// // 判断登录状态
// if (authState.user != null) {
// // 已登录
// }