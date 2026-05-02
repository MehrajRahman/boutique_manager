import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:boutique_manager/models/product.dart';
import 'package:boutique_manager/providers/product_provider.dart';
import 'package:boutique_manager/providers/ledger_provider.dart';
import 'package:intl/intl.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product _product;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  void _refreshProduct() {
    final provider = context.read<ProductProvider>();
    final found = provider.products.where((p) => p.id == _product.id);
    if (found.isNotEmpty) {
      setState(() => _product = found.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _refreshProduct();

    return Scaffold(
      appBar: AppBar(
        title: Text(_product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Product image
          if (_product.imagePath != null &&
              File(_product.imagePath!).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(_product.imagePath!),
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(Icons.image_outlined,
                    size: 64, color: theme.colorScheme.outline),
              ),
            ),
          const SizedBox(height: 24),

          // Price & Stock row
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  label: 'Price',
                  value: '\$${_product.price.toStringAsFixed(2)}',
                  icon: Icons.attach_money,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  label: 'In Stock',
                  value: '${_product.quantity}',
                  icon: Icons.inventory,
                  color: _product.isLowStock
                      ? theme.colorScheme.error
                      : theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_product.isLowStock)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber,
                      color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Text(
                    'Low stock! Threshold: ${_product.lowStockThreshold}',
                    style: TextStyle(
                        color: theme.colorScheme.onErrorContainer),
                  ),
                ],
              ),
            ),

          if (_product.barcode != null) ...[
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Barcode'),
              subtitle: Text(_product.barcode!),
              tileColor: theme.colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ],

          if (_product.customFields.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Details', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...(_product.customFields.entries.map((e) => ListTile(
                  title: Text(e.key),
                  trailing: Text(e.value,
                      style: theme.textTheme.bodyLarge),
                  dense: true,
                ))),
          ],

          const SizedBox(height: 24),

          // Stock adjustment
          Text('Adjust Stock', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _showStockAdjust(context, isAdd: false),
                  icon: const Icon(Icons.remove),
                  label: const Text('Remove'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showStockAdjust(context, isAdd: true),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent ledger entries for this product
          Text('Stock History', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _ProductLedger(productId: _product.id),
        ],
      ),
    );
  }

  void _showStockAdjust(BuildContext context, {required bool isAdd}) {
    final qtyController = TextEditingController();
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          16, 24, 16, MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isAdd ? 'Add Stock' : 'Remove Stock',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: qtyController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final n = int.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Enter a positive number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  final qty = int.parse(qtyController.text.trim());
                  final change = isAdd ? qty : -qty;
                  context.read<ProductProvider>().adjustStock(
                        _product,
                        change,
                        reason: reasonController.text.trim(),
                      );
                  context.read<LedgerProvider>().loadEntries(refresh: true);
                  Navigator.pop(ctx);
                },
                child: Text(isAdd ? 'Add Stock' : 'Remove Stock'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: _product.name);
    final priceCtrl =
        TextEditingController(text: _product.price.toStringAsFixed(2));
    final threshCtrl =
        TextEditingController(text: '${_product.lowStockThreshold}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: threshCtrl,
              decoration:
                  const InputDecoration(labelText: 'Low Stock Threshold'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final updated = _product.copyWith(
                name: nameCtrl.text.trim(),
                price: double.tryParse(priceCtrl.text.trim()) ?? _product.price,
                lowStockThreshold:
                    int.tryParse(threshCtrl.text.trim()) ?? _product.lowStockThreshold,
              );
              await context.read<ProductProvider>().updateProduct(updated);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${_product.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              context.read<ProductProvider>().deleteProduct(_product.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}

class _ProductLedger extends StatelessWidget {
  final String productId;
  const _ProductLedger({required this.productId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledger = context.watch<LedgerProvider>();
    final entries =
        ledger.entries.where((e) => e.productId == productId).toList();

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text('No history yet',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline)),
      );
    }

    final dateFormat = DateFormat('MMM dd, HH:mm');

    return Column(
      children: entries.take(10).map((entry) {
        final isAdd = entry.quantityChange > 0;
        return ListTile(
          dense: true,
          leading: Icon(
            isAdd ? Icons.add_circle : Icons.remove_circle,
            color: isAdd ? Colors.green : Colors.red,
            size: 20,
          ),
          title: Text(
            '${isAdd ? '+' : ''}${entry.quantityChange} → ${entry.quantityAfter} in stock',
            style: theme.textTheme.bodyMedium,
          ),
          subtitle: entry.reason.isNotEmpty ? Text(entry.reason) : null,
          trailing: Text(
            dateFormat.format(entry.createdAt),
            style: theme.textTheme.bodySmall,
          ),
        );
      }).toList(),
    );
  }
}
