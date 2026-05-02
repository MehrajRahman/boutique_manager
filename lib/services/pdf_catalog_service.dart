import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:boutique_manager/models/product.dart';
import 'package:intl/intl.dart';

class PdfCatalogService {
  static Future<File> generateCatalog(
    List<Product> products, {
    String shopName = 'Boutique Manager',
  }) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.simpleCurrency();
    final dateFormat = DateFormat('MMM dd, yyyy');

    // Split products into pages of 6
    final pages = <List<Product>>[];
    for (int i = 0; i < products.length; i += 6) {
      pages.add(products.sublist(
          i, i + 6 > products.length ? products.length : i + 6));
    }

    for (final page in pages) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      shopName,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Product Catalog — ${dateFormat.format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 12),
                // Product grid
                pw.Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: page.map((product) {
                    return pw.Container(
                      width: 240,
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (product.imagePath != null)
                            pw.Container(
                              height: 120,
                              width: double.infinity,
                              child: pw.Image(
                                pw.MemoryImage(
                                  File(product.imagePath!).readAsBytesSync(),
                                ),
                                fit: pw.BoxFit.cover,
                              ),
                            ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            product.name,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            currencyFormat.format(product.price),
                            style: const pw.TextStyle(
                              fontSize: 16,
                              color: PdfColors.teal,
                            ),
                          ),
                          if (product.quantity > 0)
                            pw.Text(
                              'In stock: ${product.quantity}',
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.grey600,
                              ),
                            ),
                          if (product.customFields.isNotEmpty)
                            ...product.customFields.entries.map((e) {
                              return pw.Text(
                                '${e.key}: ${e.value}',
                                style: const pw.TextStyle(fontSize: 9),
                              );
                            }),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      );
    }

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/catalog_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
