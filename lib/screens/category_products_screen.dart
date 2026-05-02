import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:boutique_manager/models/product.dart';
import 'package:boutique_manager/providers/category_provider.dart';
import 'package:boutique_manager/services/database_service.dart';
import 'package:boutique_manager/screens/product_detail_screen.dart';
import 'package:boutique_manager/screens/add_product_screen.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String? categoryId;
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final _db = DatabaseService.instance;
  final _scrollController = ScrollController();
  List<Product> _products = [];
  bool _isLoading = true;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoading) {
        _loadProducts();
      }
    }
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    if (_isLoading && !refresh && _products.isNotEmpty) return;
    setState(() => _isLoading = true);

    if (refresh) {
      _products = [];
      _hasMore = true;
    }

    final maps = await _db.getProductsByCategory(
      categoryId: widget.categoryId,
      limit: 20,
      offset: _products.length,
    );

    final newProducts = maps.map((m) => Product.fromMap(m)).toList();
    setState(() {
      _products.addAll(newProducts);
      _hasMore = newProducts.length == 20;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          Text('${_products.length} items',
              style: theme.textTheme.bodySmall),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final catProvider = context.read<CategoryProvider>();
          await _loadProducts(refresh: true);
          catProvider.refreshCounts();
        },
        child: _products.isEmpty && !_isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_open,
                        size: 64, color: theme.colorScheme.outline),
                    const SizedBox(height: 16),
                    Text('No products in this folder',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        )),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddProductScreen()),
                      ),
                      child: const Text('Add Product'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _products.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _products.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final product = _products[index];
                  return _CategoryProductCard(product: product);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddProductScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CategoryProductCard extends StatelessWidget {
  final Product product;
  const _CategoryProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 50,
            height: 50,
            child: product.imagePath != null &&
                    File(product.imagePath!).existsSync()
                ? Image.file(File(product.imagePath!), fit: BoxFit.cover)
                : Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.image_outlined,
                        color: theme.colorScheme.outline),
                  ),
          ),
        ),
        title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: product.isLowStock
                ? theme.colorScheme.errorContainer
                : theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${product.quantity}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: product.isLowStock
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        ),
      ),
    );
  }
}
