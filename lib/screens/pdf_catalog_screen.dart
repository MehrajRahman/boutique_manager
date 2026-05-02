import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:boutique_manager/providers/product_provider.dart';
import 'package:boutique_manager/providers/settings_provider.dart';
import 'package:boutique_manager/services/pdf_catalog_service.dart';

class PdfCatalogScreen extends StatefulWidget {
  const PdfCatalogScreen({super.key});

  @override
  State<PdfCatalogScreen> createState() => _PdfCatalogScreenState();
}

class _PdfCatalogScreenState extends State<PdfCatalogScreen> {
  bool _isGenerating = false;

  Future<void> _generate() async {
    setState(() => _isGenerating = true);

    final products = context.read<ProductProvider>().products;
    final shopName = context.read<SettingsProvider>().shopName;

    final file = await PdfCatalogService.generateCatalog(
      products,
      shopName: shopName,
    );

    setState(() => _isGenerating = false);

    if (!mounted) return;

    // Share via system sheet (WhatsApp, iMessage, email, etc.)
    await Share.shareXFiles(
      [XFile(file.path)],
      text: '$shopName Product Catalog',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productCount = context.watch<ProductProvider>().products.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Catalog'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf,
                size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text('Generate Product Catalog',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Creates a professional PDF with $productCount products.\nReady to share via WhatsApp, iMessage, or email.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    _isGenerating || productCount == 0 ? null : _generate,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share),
                label: Text(_isGenerating
                    ? 'Generating...'
                    : 'Generate & Share'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (productCount == 0) ...[
              const SizedBox(height: 12),
              Text(
                'Add some products first!',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
