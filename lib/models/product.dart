import 'dart:convert';

class Product {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final int lowStockThreshold;
  final String? imagePath;
  final String? imageUrl; // Supabase remote URL
  final List<double>? visualFingerprint; // ML feature vector
  final Map<String, String> customFields;
  final String? barcode;
  final String? categoryId;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 0,
    this.lowStockThreshold = 5,
    this.imagePath,
    this.imageUrl,
    this.visualFingerprint,
    this.customFields = const {},
    this.barcode,
    this.categoryId,
    this.isPublic = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isLowStock => quantity <= lowStockThreshold;

  Product copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    int? lowStockThreshold,
    String? imagePath,
    String? imageUrl,
    List<double>? visualFingerprint,
    Map<String, String>? customFields,
    String? barcode,
    String? categoryId,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      visualFingerprint: visualFingerprint ?? this.visualFingerprint,
      customFields: customFields ?? this.customFields,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'low_stock_threshold': lowStockThreshold,
      'image_path': imagePath,
      'image_url': imageUrl,
      'visual_fingerprint': visualFingerprint != null
          ? jsonEncode(visualFingerprint)
          : null,
      'custom_fields': jsonEncode(customFields),
      'barcode': barcode,
      'category_id': categoryId,
      'is_public': isPublic ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int? ?? 0,
      lowStockThreshold: map['low_stock_threshold'] as int? ?? 5,
      imagePath: map['image_path'] as String?,
      imageUrl: map['image_url'] as String?,
      visualFingerprint: map['visual_fingerprint'] != null
          ? (jsonDecode(map['visual_fingerprint'] as String) as List)
              .map((e) => (e as num).toDouble())
              .toList()
          : null,
      customFields: map['custom_fields'] != null
          ? Map<String, String>.from(
              jsonDecode(map['custom_fields'] as String) as Map)
          : {},
      barcode: map['barcode'] as String?,
      categoryId: map['category_id'] as String?,
      isPublic: (map['is_public'] as int?) != 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}
