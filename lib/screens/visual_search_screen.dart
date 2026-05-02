import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:boutique_manager/providers/product_provider.dart';
import 'package:boutique_manager/models/product.dart';
import 'package:boutique_manager/screens/product_detail_screen.dart';

class VisualSearchScreen extends StatefulWidget {
  const VisualSearchScreen({super.key});

  @override
  State<VisualSearchScreen> createState() => _VisualSearchScreenState();
}

class _VisualSearchScreenState extends State<VisualSearchScreen> {
  File? _queryImage;
  List<Product>? _results;
  bool _isSearching = false;

  Future<void> _pickAndSearch(ImageSource source) async {
    final provider = context.read<ProductProvider>();
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() {
      _queryImage = File(picked.path);
      _isSearching = true;
      _results = null;
    });

    final results =
        await provider.visualSearch(picked.path);

    if (!mounted) return;

    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visual Search'),
      ),
      body: Column(
        children: [
          // Search area
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () => _showSourcePicker(),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  image: _queryImage != null
                      ? DecorationImage(
                          image: FileImage(_queryImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _queryImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_search,
                              size: 56, color: theme.colorScheme.outline),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to search by image',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'On-device AI • Zero cost per search',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
          ),

          if (_isSearching)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_results != null && _results!.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off,
                        size: 48, color: theme.colorScheme.outline),
                    const SizedBox(height: 12),
                    Text('No matching products found',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: theme.colorScheme.outline)),
                  ],
                ),
              ),
            )
          else if (_results != null)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _results!.length,
                itemBuilder: (context, index) {
                  final product = _results![index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: product.imagePath != null &&
                                  File(product.imagePath!).existsSync()
                              ? Image.file(File(product.imagePath!),
                                  fit: BoxFit.cover)
                              : Container(
                                  color: theme
                                      .colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.image_outlined),
                                ),
                        ),
                      ),
                      title: Text(product.name),
                      subtitle: Text(
                          '\$${product.price.toStringAsFixed(2)} • ${product.quantity} in stock'),
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
            )
          else
            const Spacer(),
        ],
      ),
      floatingActionButton: _queryImage != null
          ? FloatingActionButton(
              onPressed: _showSourcePicker,
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              subtitle: const Text('Compare live camera image'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSearch(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Search using existing photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSearch(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
