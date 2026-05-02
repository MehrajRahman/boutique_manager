import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:boutique_manager/models/product.dart';
import 'package:boutique_manager/providers/order_provider.dart';

class ClientProductDetailScreen extends StatelessWidget {
  final Product product;
  const ClientProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              background: product.imagePath != null &&
                      File(product.imagePath!).existsSync()
                  ? Image.file(File(product.imagePath!), fit: BoxFit.cover)
                  : Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.image_outlined,
                          size: 80, color: theme.colorScheme.outline),
                    ),
            ),
            title: Text(product.name),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stock status
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: product.quantity > 5
                          ? Colors.green.withValues(alpha: 0.1)
                          : product.quantity > 0
                              ? Colors.orange.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          product.quantity > 5
                              ? Icons.check_circle
                              : product.quantity > 0
                                  ? Icons.warning_amber_rounded
                                  : Icons.cancel,
                          color: product.quantity > 5
                              ? Colors.green
                              : product.quantity > 0
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.quantity > 5
                                    ? 'In Stock'
                                    : product.quantity > 0
                                        ? 'Low Stock - Hurry!'
                                        : 'Out of Stock',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${product.quantity} available',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Custom fields
                  if (product.customFields.isNotEmpty) ...[
                    Text('Details',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...product.customFields.entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Text('${entry.key}: ',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600)),
                              Text(entry.value),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // Barcode
                  if (product.barcode != null && product.barcode!.isNotEmpty)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.qr_code),
                        title: const Text('Barcode'),
                        subtitle: Text(product.barcode!),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: product.quantity > 0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () {
                    context.read<OrderProvider>().addToCart(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} added to cart'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Add to Cart'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
