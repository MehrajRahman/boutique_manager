import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:boutique_manager/models/product.dart';
import 'package:boutique_manager/providers/order_provider.dart';
import 'package:boutique_manager/services/database_service.dart';
import 'package:boutique_manager/screens/client_product_detail_screen.dart';
import 'package:boutique_manager/screens/cart_screen.dart';

class ClientBrowseScreen extends StatefulWidget {
  const ClientBrowseScreen({super.key});

  @override
  State<ClientBrowseScreen> createState() => _ClientBrowseScreenState();
}

class _ClientBrowseScreenState extends State<ClientBrowseScreen> {
  final _db = DatabaseService.instance;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  List<Product> _products = [];
  bool _isLoading = true;
  bool _hasMore = true;
  String _searchQuery = '';

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

    final maps = await _db.getPublicProducts(
      limit: 20,
      offset: _products.length,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Products'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: orderProvider.cartItemCount > 0,
              label: Text('${orderProvider.cartItemCount}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _loadProducts(refresh: true);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
              ),
              onSubmitted: (q) {
                setState(() => _searchQuery = q);
                _loadProducts(refresh: true);
              },
            ),
          ),

          // Product grid
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadProducts(refresh: true),
              child: _products.isEmpty && !_isLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.storefront,
                              size: 64, color: theme.colorScheme.outline),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No products found'
                                : 'No products available',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.7,
                      ),
                      itemCount:
                          _products.length + (_hasMore && _isLoading ? 2 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _products.length) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return _ProductGridCard(
                          product: _products[index],
                          onAddToCart: () {
                            orderProvider.addToCart(_products[index]);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${_products[index].name} added to cart'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;

  const _ProductGridCard({
    required this.product,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClientProductDetailScreen(product: product),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  width: double.infinity,
                  child: product.imagePath != null &&
                          File(product.imagePath!).existsSync()
                      ? Image.file(File(product.imagePath!),
                          fit: BoxFit.cover)
                      : Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.image_outlined,
                              size: 40, color: theme.colorScheme.outline),
                        ),
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: product.quantity > 5
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.quantity > 5
                                ? 'In Stock'
                                : product.quantity > 0
                                    ? 'Low Stock'
                                    : 'Out',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: product.quantity > 5
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (product.quantity > 0)
                          InkWell(
                            onTap: onAddToCart,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.add_shopping_cart,
                                  size: 18,
                                  color:
                                      theme.colorScheme.onPrimaryContainer),
                            ),
                          ),
                      ],
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
}
