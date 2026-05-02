import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:boutique_manager/models/category.dart' as model;
import 'package:boutique_manager/services/database_service.dart';

typedef ProductCategory = model.Category;

class CategoryProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;
  final _uuid = const Uuid();

  List<ProductCategory> _categories = [];
  final Map<String, int> _productCounts = {};
  int _uncategorizedCount = 0;
  bool _isLoading = false;

  List<ProductCategory> get categories => _categories;
  Map<String, int> get productCounts => _productCounts;
  int get uncategorizedCount => _uncategorizedCount;
  bool get isLoading => _isLoading;

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    final maps = await _db.getCategories();
    _categories = maps.map((m) => ProductCategory.fromMap(m)).toList();

    // Load product counts
    for (final cat in _categories) {
      _productCounts[cat.id] = await _db.getCategoryProductCount(cat.id);
    }
    _uncategorizedCount = await _db.getUncategorizedProductCount();

    _isLoading = false;
    notifyListeners();
  }

  Future<ProductCategory> addCategory({
    required String name,
    String? description,
    String? iconName,
    String? coverImagePath,
  }) async {
    final id = _uuid.v4();
    final category = ProductCategory(
      id: id,
      name: name,
      description: description,
      iconName: iconName,
      coverImagePath: coverImagePath,
      sortOrder: _categories.length,
    );

    await _db.insertCategory(category.toMap());
    _categories.add(category);
    _productCounts[id] = 0;
    notifyListeners();
    return category;
  }

  Future<void> updateCategory(ProductCategory category) async {
    final updated = category.copyWith(updatedAt: DateTime.now());
    await _db.updateCategory(updated.toMap());

    final idx = _categories.indexWhere((c) => c.id == category.id);
    if (idx >= 0) _categories[idx] = updated;
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    await _db.deleteCategory(id);
    _categories.removeWhere((c) => c.id == id);
    _productCounts.remove(id);
    _uncategorizedCount = await _db.getUncategorizedProductCount();
    notifyListeners();
  }

  Future<void> refreshCounts() async {
    for (final cat in _categories) {
      _productCounts[cat.id] = await _db.getCategoryProductCount(cat.id);
    }
    _uncategorizedCount = await _db.getUncategorizedProductCount();
    notifyListeners();
  }
}
