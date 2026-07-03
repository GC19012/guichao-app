import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:guichao/gch_aux/gch_nav_ext.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_mod/gch_user/gch_order/gch_ctrl/gch_order_list_notifier.dart';

/// “我的订单”页面，使用 OrderListNotifier 从服务端拉取订单数据并展示。
class OrderListPage extends ConsumerStatefulWidget {
  const OrderListPage({super.key});

  @override
  ConsumerState<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends ConsumerState<OrderListPage> {
  final _scrollController = ScrollController();
  late final OrderListActionHandler _actions;

  @override
  void initState() {
    super.initState();
    _actions = OrderListActionHandler(ref);
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      if (!mounted) return;
      _actions.load();
    });
  }

  void _onScroll() {
    _actions.handleScroll(_scrollController);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderListUiProvider);

    return Scaffold(
      backgroundColor: _Palette.background,
      body: SafeArea(
        child: Container(
          color: _Palette.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderBar(title: GchText.userOrderTitle),
              const SizedBox(height: 12),
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ErrorBanner(message: state.errorMessage!),
                ),
              Expanded(
                child: state.items.isEmpty && state.isLoading
                    ? _LoadingPlaceholder(message: GchText.userOrderLoadingMore)
                    : RefreshIndicator(
                        onRefresh: () => _actions.refresh(),
                        color: _Palette.linkColor,
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemBuilder: (context, index) {
                            if (index == state.items.length) {
                              return _ListFooter(
                                isLoading: state.isLoading && state.items.isNotEmpty,
                                hasMore: state.hasMore,
                              );
                            }
                            final entry = state.items[index];
                            return _OrderCard(data: entry);
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemCount: state.items.length + 1,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

// =============================  UI 常量  =============================
class _Palette {
  // 背景色
  static const Color background = Color(0xFFF4F6FB);
  static const Color card = Colors.white;

  // 文字颜色
  static const Color textPrimary = Color(0xFF1F2430);
  static const Color textSecondary = Color(0xFF8C94A5);
  static const Color textMuted = Color(0xFFA7AFBF);

  // 边框和分割线
  static const Color border = Color(0xFFE5EAF2);
  static const Color divider = Color(0xFFE8EDF5);

  // 链接和高亮色
  static const Color linkColor = Color(0xFF4F7DFF);

  // 渐变按钮颜色
  static const Color gradientStart = Color(0xFF7B60FF);
  static const Color gradientEnd = Color(0xFF5AA1FF);

  // 状态颜色
  static const Color statusDone = Color(0xFF4F7DFF);
  static const Color statusPending = Color(0xFFFFB224);
  static const Color statusCanceled = Color(0xFF9AA4B2);

  // 错误颜色
  static const Color error = Color(0xFFE5484D);

  // 卡片阴影
  static const Color cardShadow = Color(0x14000000);

  // 徽标背景
  static const Color badgeBackground = Color(0xFFF1F3F8);
  static const Color badgeBorder = Color(0xFFE3E8F0);
}

// =============================  Header  =============================
class _HeaderBar extends StatelessWidget {
  const _HeaderBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () {
                  // 直接使用 context.pop() 返回
                  if (context.canPop()) {
                    context.safePop();
                  } else {
                    // 如果不能pop，导航到设置页面
                    context.go('/user/setting');
                  }
                },
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: _Palette.textPrimary,
                ),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: _Palette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on OrderListItemStatus {
  Color get color {
    switch (this) {
      case OrderListItemStatus.completed:
        return _Palette.statusDone;
      case OrderListItemStatus.pending:
        return _Palette.statusPending;
      case OrderListItemStatus.canceled:
        return _Palette.statusCanceled;
    }
  }
}

// =============================  订单卡片  =============================
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.data});
  final OrderListItemUi data;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _Palette.card,
        border: Border.all(color: _Palette.border, width: 1),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: _Palette.cardShadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OrderHeader(
            orderNo: data.orderNo,
            status: data.status,
            statusLabel: data.statusLabel,
            label: GchText.userOrderOrderNumber,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ProductBadge(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        color: _Palette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.secondary,
                      style: const TextStyle(
                        color: _Palette.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _LabelValue(
                      label: GchText.userOrderOrderTime,
                      value: data.orderTime,
                      valueWeight: FontWeight.w400,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: _Palette.divider),
          const SizedBox(height: 10),
          _OrderFooter(
            payMethod: data.payMethod,
            payLabel: GchText.userOrderPaymentMethod,
            currency: data.currency,
            amount: data.amount,
          ),
        ],
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({
    required this.orderNo,
    required this.status,
    required this.statusLabel,
    required this.label,
  });
  final String orderNo;
  final OrderListItemStatus status;
  final String statusLabel;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label$orderNo',
            style: const TextStyle(
              color: _Palette.textMuted,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          statusLabel,
          style: TextStyle(
            color: status.color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ProductBadge extends StatelessWidget {
  const _ProductBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _Palette.badgeBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Palette.badgeBorder),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_Palette.gradientStart, _Palette.gradientEnd],
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.credit_card_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

class _Price extends StatelessWidget {
  const _Price({required this.currency, required this.amount});
  final String currency;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final symbol = _currencySymbol(currency);
    final spans = <InlineSpan>[];
    if (symbol.isNotEmpty) {
      spans.add(
        TextSpan(
          text: '$symbol ',
          style: const TextStyle(
            color: _Palette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    spans.add(
      TextSpan(
        text: amount.toStringAsFixed(2),
        style: const TextStyle(
          color: _Palette.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    spans.add(const TextSpan(text: ' '));
    spans.add(
      TextSpan(
        text: currency,
        style: const TextStyle(
          color: _Palette.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    return RichText(
      textAlign: TextAlign.right,
      text: TextSpan(
        children: spans,
      ),
    );
  }

  String _currencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'CNY':
      case 'RMB':
        return '¥';
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'JPY':
        return '¥';
      default:
        return '';
    }
  }
}

class _OrderFooter extends StatelessWidget {
  const _OrderFooter({
    required this.payMethod,
    required this.payLabel,
    required this.currency,
    required this.amount,
  });
  final String payMethod;
  final String payLabel;
  final String currency;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LabelValue(label: payLabel, value: payMethod),
        ),
        _Price(currency: currency, amount: amount),
      ],
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({
    required this.label,
    required this.value,
    this.valueWeight = FontWeight.w600,
  });
  final String label;
  final String value;
  final FontWeight valueWeight;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.left,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(color: _Palette.textSecondary, fontSize: 13),
          ),
          TextSpan(
            text: value,
            style: TextStyle(color: _Palette.textPrimary, fontSize: 12, fontWeight: valueWeight),
          ),
        ],
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(_Palette.linkColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: _Palette.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({
    required this.isLoading,
    required this.hasMore,
  });
  final bool isLoading;
  final bool hasMore;
  @override
  Widget build(BuildContext context) {
    final text = isLoading
        ? GchText.userOrderLoadingMore
        : (hasMore ? GchText.userOrderPullToLoadMore : GchText.userOrderNoMoreData);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: _Palette.textSecondary, fontSize: 12),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _Palette.error.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Palette.error.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: _Palette.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _Palette.textPrimary, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
