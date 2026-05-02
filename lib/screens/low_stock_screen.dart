import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:boutique_manager/providers/product_provider.dart';
import 'package:boutique_manager/screens/product_detail_screen.dart';

class LowStockScreen extends StatelessWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = context.watch<ProductProvider>().lowStockProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Alerts'),
      ),
      body: products.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.green.shade400),
                  const SizedBox(height: 16),
                  Text('All stocked up!',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('No items are running low',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.errorContainer,
                      child: Text(
                        '${product.quantity}',
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(product.name),
                    subtitle: Text(
                      'Threshold: ${product.lowStockThreshold} • Price: \$${product.price.toStringAsFixed(2)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailScreen(product: product),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
