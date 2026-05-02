import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:boutique_manager/models/order.dart';
import 'package:boutique_manager/providers/order_provider.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<OrderProvider>().loadOrders(refresh: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Confirmed'),
            Tab(text: 'Fulfilled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrderList(
            orders: orderProvider.orders,
            isOwner: true,
          ),
          _OrderList(
            orders: orderProvider.orders
                .where((o) => o.status == OrderStatus.pending)
                .toList(),
            isOwner: true,
          ),
          _OrderList(
            orders: orderProvider.orders
                .where((o) => o.status == OrderStatus.confirmed)
                .toList(),
            isOwner: true,
          ),
          _OrderList(
            orders: orderProvider.orders
                .where((o) => o.status == OrderStatus.fulfilled)
                .toList(),
            isOwner: true,
          ),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<Order> orders;
  final bool isOwner;

  const _OrderList({required this.orders, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('No orders',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) =>
          _OrderCard(order: orders[index], isOwner: isOwner),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final bool isOwner;

  const _OrderCard({required this.order, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.buyerName,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                _StatusChip(status: order.status),
              ],
            ),
            if (order.buyerPhone != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(order.buyerPhone!,
                    style: theme.textTheme.bodySmall),
              ),
            const Divider(height: 20),

            // Items
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity}× ${item.productName}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '\$${item.subtotal.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )),
            const Divider(height: 16),

            // Total & actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${order.totalAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      dateFormat.format(order.createdAt),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                if (isOwner) _buildOwnerActions(context),
              ],
            ),

            if (order.buyerNote != null && order.buyerNote!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note,
                          size: 16, color: theme.colorScheme.outline),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(order.buyerNote!,
                            style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerActions(BuildContext context) {
    final orderProvider = context.read<OrderProvider>();

    switch (order.status) {
      case OrderStatus.pending:
        return Row(
          children: [
            FilledButton.tonal(
              onPressed: () =>
                  orderProvider.updateStatus(order.id, OrderStatus.confirmed),
              child: const Text('Confirm'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () =>
                  orderProvider.updateStatus(order.id, OrderStatus.cancelled),
              child: const Text('Cancel'),
            ),
          ],
        );
      case OrderStatus.confirmed:
        return FilledButton(
          onPressed: () =>
              orderProvider.updateStatus(order.id, OrderStatus.fulfilled),
          child: const Text('Fulfill'),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      OrderStatus.pending => (Colors.orange, 'Pending'),
      OrderStatus.confirmed => (Colors.blue, 'Confirmed'),
      OrderStatus.fulfilled => (Colors.green, 'Fulfilled'),
      OrderStatus.cancelled => (Colors.red, 'Cancelled'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
