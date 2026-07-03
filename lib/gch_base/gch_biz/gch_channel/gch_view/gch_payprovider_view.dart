import 'package:flutter/material.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_vm/gch_payprovider_viewmodel.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_model/gch_payprovider_model.dart';

/// 支付渠道管理页面
class PayProviderView extends ConsumerWidget {
  const PayProviderView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payProvidersAsync = ref.watch(payProviderViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('支付渠道管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(payProviderViewModelProvider.notifier).refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddPayProviderDialog(context, ref);
            },
          ),
        ],
      ),
      body: payProvidersAsync.when(
        data: (payProviders) => _buildPayProvidersList(context, ref, payProviders),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('加载失败: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(payProviderViewModelProvider.notifier).refresh();
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayProvidersList(BuildContext context, WidgetRef ref, List<PayProviderEntry> payProviders) {
    if (payProviders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无支付渠道', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('点击右上角 + 按钮添加支付渠道', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: payProviders.length,
      itemBuilder: (context, index) {
        final provider = payProviders[index];
        return _buildPayProviderCard(context, ref, provider);
      },
    );
  }

  Widget _buildPayProviderCard(BuildContext context, WidgetRef ref, PayProviderEntry provider) {
    final method = PayMethod.fromValue(provider.method);
    final payType = PayType.fromValue(provider.payType);
    final environment = Environment.fromValue(provider.environment);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: provider.status == 1 ? Colors.green : Colors.grey,
          child: Icon(
            _getPayMethodIcon(method),
            color: Colors.white,
          ),
        ),
        title: Text(provider.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('代码: ${provider.code}'),
            Text('方式: ${_getPayMethodText(method)}'),
            Text('类型: ${_getPayTypeText(payType)}'),
            Text('环境: ${_getEnvironmentText(environment)}'),
            if (provider.regions != null) Text('地区: ${provider.regions}'),
            if (provider.clientTypes != null) Text('客户端: ${provider.clientTypes}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditPayProviderDialog(context, ref, provider);
                break;
              case 'delete':
                _showDeletePayProviderDialog(context, ref, provider);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('编辑'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('删除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPayMethodIcon(PayMethod method) {
    switch (method) {
      case PayMethod.pc:
        return Icons.computer;
      case PayMethod.wap:
        return Icons.phone_android;
      case PayMethod.h5:
        return Icons.web;
      case PayMethod.appStore:
        return Icons.apple;
    }
  }

  String _getPayMethodText(PayMethod method) {
    switch (method) {
      case PayMethod.pc:
        return 'PC端';
      case PayMethod.wap:
        return 'WAP';
      case PayMethod.h5:
        return 'H5';
      case PayMethod.appStore:
        return 'App Store';
    }
  }

  String _getPayTypeText(PayType payType) {
    switch (payType) {
      case PayType.online:
        return '在线支付';
      case PayType.cardKey:
        return '卡密兑换';
      case PayType.inAppPurchase:
        return '应用内购买';
    }
  }

  String _getEnvironmentText(Environment environment) {
    switch (environment) {
      case Environment.production:
        return '生产环境';
      case Environment.sandbox:
        return '沙箱环境';
    }
  }

  void _showAddPayProviderDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const AddPayProviderDialog(),
    );
  }

  void _showEditPayProviderDialog(BuildContext context, WidgetRef ref, PayProviderEntry provider) {
    showDialog(
      context: context,
      builder: (context) => EditPayProviderDialog(provider: provider),
    );
  }

  void _showDeletePayProviderDialog(BuildContext context, WidgetRef ref, PayProviderEntry provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除支付渠道 "${provider.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(payProviderViewModelProvider.notifier).deletePayProvider(provider.id);
              Navigator.of(context).pop();
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// 添加支付渠道对话框
class AddPayProviderDialog extends ConsumerStatefulWidget {
  const AddPayProviderDialog({super.key});

  @override
  ConsumerState<AddPayProviderDialog> createState() => _AddPayProviderDialogState();
}

class _AddPayProviderDialogState extends ConsumerState<AddPayProviderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  PayMethod _selectedMethod = PayMethod.pc;
  PayType _selectedPayType = PayType.online;
  Environment _selectedEnvironment = Environment.production;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加支付渠道'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: '支付代码'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入支付代码';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '支付名称'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入支付名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PayMethod>(
                value: _selectedMethod,
                decoration: const InputDecoration(labelText: '支付方式'),
                items: PayMethod.values.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(_getPayMethodText(method)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMethod = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PayType>(
                value: _selectedPayType,
                decoration: const InputDecoration(labelText: '支付类型'),
                items: PayType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getPayTypeText(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPayType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Environment>(
                value: _selectedEnvironment,
                decoration: const InputDecoration(labelText: '环境'),
                items: Environment.values.map((env) {
                  return DropdownMenuItem(
                    value: env,
                    child: Text(_getEnvironmentText(env)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEnvironment = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              ref.read(payProviderViewModelProvider.notifier).createPayProvider(
                    code: _codeController.text,
                    name: _nameController.text,
                    method: _selectedMethod,
                    payType: _selectedPayType,
                    environment: _selectedEnvironment,
                  );
              Navigator.of(context).pop();
            }
          },
          child: const Text('添加'),
        ),
      ],
    );
  }

  String _getPayMethodText(PayMethod method) {
    switch (method) {
      case PayMethod.pc:
        return 'PC端';
      case PayMethod.wap:
        return 'WAP';
      case PayMethod.h5:
        return 'H5';
      case PayMethod.appStore:
        return 'App Store';
    }
  }

  String _getPayTypeText(PayType payType) {
    switch (payType) {
      case PayType.online:
        return '在线支付';
      case PayType.cardKey:
        return '卡密兑换';
      case PayType.inAppPurchase:
        return '应用内购买';
    }
  }

  String _getEnvironmentText(Environment environment) {
    switch (environment) {
      case Environment.production:
        return '生产环境';
      case Environment.sandbox:
        return '沙箱环境';
    }
  }
}

/// 编辑支付渠道对话框
class EditPayProviderDialog extends ConsumerStatefulWidget {
  final PayProviderEntry provider;

  const EditPayProviderDialog({super.key, required this.provider});

  @override
  ConsumerState<EditPayProviderDialog> createState() => _EditPayProviderDialogState();
}

class _EditPayProviderDialogState extends ConsumerState<EditPayProviderDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late PayMethod _selectedMethod;
  late PayType _selectedPayType;
  late Environment _selectedEnvironment;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.provider.code);
    _nameController = TextEditingController(text: widget.provider.name);
    _selectedMethod = PayMethod.fromValue(widget.provider.method);
    _selectedPayType = PayType.fromValue(widget.provider.payType);
    _selectedEnvironment = Environment.fromValue(widget.provider.environment);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑支付渠道'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: '支付代码'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入支付代码';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '支付名称'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入支付名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PayMethod>(
                value: _selectedMethod,
                decoration: const InputDecoration(labelText: '支付方式'),
                items: PayMethod.values.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(_getPayMethodText(method)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMethod = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PayType>(
                value: _selectedPayType,
                decoration: const InputDecoration(labelText: '支付类型'),
                items: PayType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getPayTypeText(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPayType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Environment>(
                value: _selectedEnvironment,
                decoration: const InputDecoration(labelText: '环境'),
                items: Environment.values.map((env) {
                  return DropdownMenuItem(
                    value: env,
                    child: Text(_getEnvironmentText(env)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEnvironment = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              ref.read(payProviderViewModelProvider.notifier).updatePayProvider(
                    id: widget.provider.id,
                    code: _codeController.text,
                    name: _nameController.text,
                    method: _selectedMethod,
                    payType: _selectedPayType,
                    environment: _selectedEnvironment,
                  );
              Navigator.of(context).pop();
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  String _getPayMethodText(PayMethod method) {
    switch (method) {
      case PayMethod.pc:
        return 'PC端';
      case PayMethod.wap:
        return 'WAP';
      case PayMethod.h5:
        return 'H5';
      case PayMethod.appStore:
        return 'App Store';
    }
  }

  String _getPayTypeText(PayType payType) {
    switch (payType) {
      case PayType.online:
        return '在线支付';
      case PayType.cardKey:
        return '卡密兑换';
      case PayType.inAppPurchase:
        return '应用内购买';
    }
  }

  String _getEnvironmentText(Environment environment) {
    switch (environment) {
      case Environment.production:
        return '生产环境';
      case Environment.sandbox:
        return '沙箱环境';
    }
  }
}
