class Category {
  final String id;
  final String name;
  final String? description;
  final String? iconName;
  final String? coverImagePath;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
    this.coverImagePath,
    this.sortOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    String? coverImagePath,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_name': iconName,
      'cover_image_path': coverImagePath,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      iconName: map['icon_name'] as String?,
      coverImagePath: map['cover_image_path'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}
