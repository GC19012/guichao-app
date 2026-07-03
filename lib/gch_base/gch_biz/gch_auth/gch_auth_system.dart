// auth_system.dart - 新认证系统的统一入口

export 'package:guichao/gch_base/gch_biz/gch_auth/gch_config/gch_auth_config.dart';
export 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authtype_model.dart';
export 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authuser_model.dart';

// 核心服务和接口
export 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_manager.dart';
export 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_provider_interface.dart';
export 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_service.dart';

// 认证提供者实现
export 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_providers/gch_local_session_provider.dart';
export 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_providers/gch_local_user_profile_provider.dart';
export 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_providers/gch_supabase_auth_provider.dart';
// 状态管理和视图模型
export 'package:guichao/gch_base/gch_biz/gch_auth/gch_providers/gch_auth_providers.dart';
export 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_resilient_auth_wrapper.dart';
export 'package:guichao/gch_base/gch_biz/gch_auth/gch_vm/gch_auth_view_model.dart';

/// 新认证系统的快速使用指南
/// 
/// 1. 在main.dart中添加ProviderScope:
/// ```dart
/// void main() {
///   runApp(
///     ProviderScope(
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
/// 
/// 2. 在应用中使用认证功能:
/// ```dart
/// class LoginPage extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final authActions = ref.watch(authActionsProvider);
///     final authState = ref.watch(authStateChangesProvider);
///     
///     return authState.when(
///       data: (authProviderState) {
///         if (authProviderState.isAuthenticated && authProviderState.user != null) {
///           return HomePage(); // 已登录
///         } else {
///           return LoginForm(); // 未登录
///         }
///       },
///       loading: () => CircularProgressIndicator(),
///       error: (error, stack) => Text('Error: $error'),
///     );
///   }
/// }
/// ```
/// 
/// 3. 执行认证操作:
/// ```dart
/// // 邮箱登录
/// final result = await authActions.signInWithEmail('user@example.com', 'password');
///
/// // 安全存储登录（替代生物识别）
/// final result = await authActions.signInWithStoredCredentials();
/// ```
/// 
/// 4. 监听认证状态:
/// ```dart
/// ref.listen<AsyncValue<AuthProviderState>>(authStateChangesProvider, (previous, next) {
///   next.when(
///     data: (authProviderState) {
///       if (authProviderState.isAuthenticated && authProviderState.user != null) {
///         // 用户已登录
///         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
///       } else {
///         // 用户已登出
///         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage()));
///       }
///     },
///     loading: () {},
///     error: (error, stack) {
///       // 处理认证错误
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text('认证错误: $error')),
///       );
///     },
///   );
/// });
/// ```
/// 
/// 5. 获取当前用户信息:
/// ```dart
/// final currentUser = ref.watch(currentUserProvider);
/// currentUser.when(
///   data: (user) => user != null ? Text('欢迎 ${user.name}') : Text('未登录'),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('错误: $error'),
/// );
/// ```
