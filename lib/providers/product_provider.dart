import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:boutique_manager/models/product.dart';
import 'package:boutique_manager/models/ledger_entry.dart';
import 'package:boutique_manager/services/database_service.dart';
import 'package:boutique_manager/services/notification_service.dart';
import 'package:boutique_manager/services/visual_search_service.dart';

class ProductProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;
  final _uuid = const Uuid();

  List<Product> _products = [];
  List<Product> _lowStockProducts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String _searchQuery = '';
  int _totalCount = 0;

  List<Product> get products => _products;
  List<Product> get lowStockProducts => _lowStockProducts;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;
  int get totalCount => _totalCount;

  Future<void> loadProducts({bool refresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    if (refresh) {
      _products = [];
      _hasMore = true;
    }

    final maps = await _db.getProducts(
      limit: 20,
      offset: _products.length,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
    );

    final newProducts = maps.map((m) => Product.fromMap(m)).toList();
    _products.addAll(newProducts);
    _hasMore = newProducts.length == 20;
    _totalCount = await _db.getProductCount();

    _isLoading = false;
    notifyListeners();

    await _refreshLowStock();
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    _products = [];
    _hasMore = true;
    await loadProducts();
  }

  Future<void> _refreshLowStock() async {
    final maps = await _db.getLowStockProducts();
    _lowStockProducts = maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<Product> addProduct({
    required String name,
    required double price,
    int quantity = 0,
    int lowStockThreshold = 5,
    String? imagePath,
    Map<String, String> customFields = const {},
    String? barcode,
    String? categoryId,
  }) async {
    final id = _uuid.v4();

    // Generate visual fingerprint if image provided
    List<double>? fingerprint;
    if (imagePath != null && File(imagePath).existsSync()) {
      fingerprint =
          await VisualSearchService.instance.generateFingerprint(imagePath);
    }

    final product = Product(
      id: id,
      name: name,
      price: price,
      quantity: quantity,
      lowStockThreshold: lowStockThreshold,
      imagePath: imagePath,
      visualFingerprint: fingerprint,
      customFields: customFields,
      barcode: barcode,
      categoryId: categoryId,
    );

    await _db.insertProduct(product.toMap());
    _products.insert(0, product);
    _totalCount++;
    notifyListeners();

    if (product.isLowStock) {
      await NotificationService.instance.showLowStockAlert(
        productName: product.name,
        quantity: product.quantity,
      );
      await _refreshLowStock();
    }

    return product;
  }

  Future<void> updateProduct(Product product) async {
    final updated = product.copyWith(
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    await _db.updateProduct(updated.toMap());

    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx >= 0) {
      _products[idx] = updated;
    }
    notifyListeners();

    if (updated.isLowStock) {
      await NotificationService.instance.showLowStockAlert(
        productName: updated.name,
        quantity: updated.quantity,
      );
    }
    await _refreshLowStock();
  }

  Future<void> adjustStock(
    Product product,
    int change, {
    String reason = '',
  }) async {
    final newQty = (product.quantity + change).clamp(0, 999999);
    final updated = product.copyWith(
      quantity: newQty,
      updatedAt: DateTime.now(),
      isSynced: false,
    );

    await _db.updateProduct(updated.toMap());

    // Create ledger entry
    final entry = LedgerEntry(
      id: _uuid.v4(),
      productId: product.id,
      productName: product.name,
      quantityChange: change,
      quantityAfter: newQty,
      reason: reason,
    );
    await _db.insertLedgerEntry(entry.toMap());

    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx >= 0) {
      _products[idx] = updated;
    }
    notifyListeners();

    if (updated.isLowStock) {
      await NotificationService.instance.showLowStockAlert(
        productName: updated.name,
        quantity: updated.quantity,
      );
    }
    await _refreshLowStock();
  }

  Future<void> deleteProduct(String id) async {
    await _db.deleteProduct(id);
    _products.removeWhere((p) => p.id == id);
    _totalCount--;
    notifyListeners();
    await _refreshLowStock();
  }

  /// Visual search: find products similar to the given image.
  Future<List<Product>> visualSearch(String imagePath) async {
    final queryFp =
        await VisualSearchService.instance.generateFingerprint(imagePath);
    if (queryFp.isEmpty) return [];

    // Build fingerprint map from all products
    final allMaps = await _db.getProducts(limit: 10000, offset: 0);
    final allProducts = allMaps.map((m) => Product.fromMap(m)).toList();

    final fpMap = <String, List<double>>{};
    for (final p in allProducts) {
      if (p.visualFingerprint != null && p.visualFingerprint!.isNotEmpty) {
        fpMap[p.id] = p.visualFingerprint!;
      }
    }

    final results = VisualSearchService.instance.findSimilar(queryFp, fpMap);
    final productMap = {for (final p in allProducts) p.id: p};

    return results
        .where((r) => productMap.containsKey(r.key))
        .map((r) => productMap[r.key]!)
        .toList();
  }
}
