import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:guichao/gch_base/gch_signal/gch_signal_hub.dart';
import 'package:guichao/gch_base/gch_bridge/gch_pprof.dart';
import 'package:guichao/gch_mod/gch_shared/gch_nested_app_bar.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Pprof 性能调试页面 - 最小化实现
class PprofDebugPage extends HookConsumerWidget {
  const PprofDebugPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pprofService = ref.watch(pprofServiceProvider);
    final serverStatus = ref.watch(pprofServerStatusProvider);
    final runtimeStats = ref.watch(pprofRuntimeStatsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const NestedAppBar(
            title: Text('Pprof 性能调试'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: REdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 服务器状态卡片
                  Card(
                    child: Padding(
                      padding: REdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'HTTP 服务器',
                                style: TextStyle(
                                  fontSize: 18.rf,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              serverStatus.when(
                                data: (isRunning) => Container(
                                  padding: REdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isRunning ? Colors.green : Colors.grey,
                                    borderRadius: BorderRadius.circular(12.rr),
                                  ),
                                  child: Text(
                                    isRunning ? '运行中' : '已停止',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.rf,
                                    ),
                                  ),
                                ),
                                loading: () => const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                error: (_, __) => const Icon(Icons.error, color: Colors.red),
                              ),
                            ],
                          ),
                          const Gap(12),
                          Text(
                            '端口: 6060\n使用 adb forward tcp:6060 tcp:6060',
                            style: TextStyle(fontSize: 12.rf, color: Colors.grey),
                          ),
                          const Gap(16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final success = await pprofService.startServer();
                                    if (context.mounted) {
                                      final notificationController = ref.read(gchSignalHubProvider);
                                      if (success) {
                                        notificationController.flashSuccess('服务器已启动');
                                      } else {
                                        notificationController.flashError('启动失败');
                                      }
                                      ref.invalidate(pprofServerStatusProvider);
                                    }
                                  },
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('启动'),
                                ),
                              ),
                              const Gap(8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final success = await pprofService.stopServer();
                                    if (context.mounted) {
                                      final notificationController = ref.read(gchSignalHubProvider);
                                      if (success) {
                                        notificationController.flashSuccess('服务器已停止');
                                      } else {
                                        notificationController.flashError('停止失败');
                                      }
                                      ref.invalidate(pprofServerStatusProvider);
                                    }
                                  },
                                  icon: const Icon(Icons.stop),
                                  label: const Text('停止'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Gap(16),

                  // 运行时统计
                  Card(
                    child: Padding(
                      padding: REdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '运行时统计',
                                style: TextStyle(
                                  fontSize: 18.rf,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: () {
                                  ref.invalidate(pprofRuntimeStatsProvider);
                                },
                              ),
                            ],
                          ),
                          const Gap(12),
                          runtimeStats.when(
                            data: (stats) {
                              if (stats == null) {
                                return const Text('无数据');
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildStatRow('Goroutines', '${stats.goroutines}'),
                                  _buildStatRow('内存分配', '${stats.allocMb.toStringAsFixed(2)} MB'),
                                  _buildStatRow('系统内存', '${stats.sysMb.toStringAsFixed(2)} MB'),
                                  _buildStatRow('GC 次数', '${stats.numGc}'),
                                  _buildStatRow('CPU 核数', '${stats.numCpu}'),
                                ],
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (err, _) => Text('错误: $err'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Gap(16),

                  // 采集 Profile
                  Card(
                    child: Padding(
                      padding: REdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '采集 Profile',
                            style: TextStyle(
                              fontSize: 18.rf,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Gap(16),
                          ListTile(
                            leading: const Icon(Icons.speed),
                            title: const Text('CPU Profile'),
                            subtitle: const Text('采集 30 秒 CPU 使用情况'),
                            onTap: () async {
                              final notificationController = ref.read(gchSignalHubProvider);
                              notificationController.flashInfo('正在采集 CPU Profile (30秒)...');
                              final path = await pprofService.collectCpuProfile();
                              if (context.mounted) {
                                if (path != null) {
                                  notificationController.flashSuccess('已保存: $path');
                                } else {
                                  notificationController.flashError('采集失败');
                                }
                              }
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.memory),
                            title: const Text('Heap Profile'),
                            subtitle: const Text('采集堆内存快照'),
                            onTap: () async {
                              final path = await pprofService.collectHeapProfile();
                              if (context.mounted) {
                                final notificationController = ref.read(gchSignalHubProvider);
                                if (path != null) {
                                  notificationController.flashSuccess('已保存: $path');
                                } else {
                                  notificationController.flashError('采集失败');
                                }
                              }
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.timeline),
                            title: const Text('Goroutine Profile'),
                            subtitle: const Text('采集 Goroutine 状态'),
                            onTap: () async {
                              final path = await pprofService.collectGoroutineProfile();
                              if (context.mounted) {
                                final notificationController = ref.read(gchSignalHubProvider);
                                if (path != null) {
                                  notificationController.flashSuccess('已保存: $path');
                                } else {
                                  notificationController.flashError('采集失败');
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Gap(16),

                  // 使用说明
                  Card(
                    child: Padding(
                      padding: REdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '使用说明',
                            style: TextStyle(
                              fontSize: 18.rf,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Gap(12),
                          Text(
                            '1. 启动 HTTP 服务器\n'
                            '2. 执行端口转发: adb forward tcp:6060 tcp:6060\n'
                            '3. 浏览器访问: http://localhost:6060/debug/pprof/\n'
                            '4. 或使用 go tool pprof 分析:\n'
                            '   go tool pprof -http=:8080 http://localhost:6060/debug/pprof/heap',
                            style: TextStyle(fontSize: 12.rf, height: 1.5),
                          ),
                          const Gap(12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                const ClipboardData(text: 'adb forward tcp:6060 tcp:6060'),
                              );
                              final notificationController = ref.read(gchSignalHubProvider);
                              notificationController.flashSuccess('已复制命令到剪贴板');
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('复制 ADB 命令'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Gap(16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: REdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
