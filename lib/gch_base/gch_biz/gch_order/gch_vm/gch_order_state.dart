/// 同步状态枚举
enum SyncStatus {
  idle, // 空闲
  syncing, // 同步中
  success, // 同步成功
  failed, // 同步失败
}

/// 订单管理状态 - 仅跟踪同步与加载元信息
class OrderManagerState {
  /// 同步状态
  final SyncStatus syncStatus;

  /// 最后同步时间
  final DateTime? lastSyncTime;

  /// 错误信息
  final String? errorMessage;

  /// 是否正在加载
  final bool isLoading;

  const OrderManagerState({
    this.syncStatus = SyncStatus.idle,
    this.lastSyncTime,
    this.errorMessage,
    this.isLoading = false,
  });

  /// 创建副本并更新部分字段
  OrderManagerState copyWith({
    SyncStatus? syncStatus,
    DateTime? lastSyncTime,
    String? errorMessage,
    bool? isLoading,
  }) {
    return OrderManagerState(
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
