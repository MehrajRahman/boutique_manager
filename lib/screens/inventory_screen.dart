import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:boutique_manager/providers/product_provider.dart';
import 'package:boutique_manager/models/product.dart';
import 'package:boutique_manager/screens/add_product_screen.dart';
import 'package:boutique_manager/screens/product_detail_screen.dart';
import 'package:boutique_manager/screens/low_stock_screen.dart';
import 'package:boutique_manager/screens/pdf_catalog_screen.dart';
import 'dart:io';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<ProductProvider>();
      if (provider.hasMore && !provider.isLoading) {
        provider.loadProducts();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search products...',
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (q) => provider.search(q),
              )
            : const Text('Inventory'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  provider.search('');
                }
              });
            },
          ),
          if (provider.lowStockProducts.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text('${provider.lowStockProducts.length}'),
                child: const Icon(Icons.warning_amber_rounded),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LowStockScreen()),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'catalog') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PdfCatalogScreen()),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'catalog',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf),
                  title: Text('Generate Catalog'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadProducts(refresh: true),
        child: provider.products.isEmpty && !provider.isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 64, color: theme.colorScheme.outline),
                    const SizedBox(height: 16),
                    Text(
                      'No products yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add your first product',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: provider.products.length + (provider.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == provider.products.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  return _ProductCard(product: provider.products[index]);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddProductScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: product.imagePath != null &&
                          File(product.imagePath!).existsSync()
                      ? Image.file(
                          File(product.imagePath!),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.image_outlined,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Stock badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: product.isLowStock
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${product.quantity}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: product.isLowStock
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.onPrimaryContainer,
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
