import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:boutique_manager/providers/order_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderProvider = context.watch<OrderProvider>();
    final cart = orderProvider.cart;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () => orderProvider.clearCart(),
              child: const Text('Clear'),
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('Your cart is empty',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      )),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final entry = cart.entries.elementAt(index);
                      final item = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold)),
                                    Text(
                                      '\$${item.product.price.toStringAsFixed(2)} each',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              // Quantity controls
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () {
                                      if (item.quantity <= 1) {
                                        orderProvider
                                            .removeFromCart(entry.key);
                                      } else {
                                        orderProvider.updateCartQuantity(
                                            entry.key, item.quantity - 1);
                                      }
                                    },
                                    iconSize: 20,
                                  ),
                                  Text('${item.quantity}',
                                      style: theme.textTheme.titleSmall),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: item.quantity <
                                            item.product.quantity
                                        ? () {
                                            orderProvider.updateCartQuantity(
                                                entry.key,
                                                item.quantity + 1);
                                          }
                                        : null,
                                    iconSize: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Total & Checkout
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total (${orderProvider.cartItemCount} items)',
                                style: theme.textTheme.titleMedium),
                            Text(
                              '\$${orderProvider.cartTotal.toStringAsFixed(2)}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () =>
                              _showCheckoutDialog(context, orderProvider),
                          icon: const Icon(Icons.shopping_bag),
                          label: const Text('Place Order'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showCheckoutDialog(
      BuildContext context, OrderProvider orderProvider) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Place Order',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  await orderProvider.placeOrder(
                    buyerName: nameController.text.trim(),
                    buyerPhone: phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    buyerNote: noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx); // close sheet
                    Navigator.pop(context); // back from cart
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order placed successfully!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: Text(
                    'Confirm (\$${orderProvider.cartTotal.toStringAsFixed(2)})'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
