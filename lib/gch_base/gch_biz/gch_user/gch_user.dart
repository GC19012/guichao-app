/// 用户管理模块统一导出文件 (MVVC架构)
///
/// 这个模块提供了基于MVVC架构的用户信息管理功能，包括：
/// - Model: 用户数据模型和实体定义
/// - View: 用户界面组件
/// - ViewModel: 业务逻辑和状态管理
/// - Controller: 数据访问层（DAO、Repository、API）

// Model Layer
export 'gch_model/gch_user_model.dart';

// View Layer
export 'gch_view/gch_user_view.dart';

// ViewModel Layer
export 'gch_vm/gch_user_viewmodel.dart';

// Controller Layer
export 'gch_api/gch_user_api.dart';
export 'gch_dao/gch_user_dao.dart';
export 'gch_repo/gch_user_repository.dart';

// Providers
export 'gch_providers/gch_user_providers.dart';
