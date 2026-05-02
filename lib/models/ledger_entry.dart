class LedgerEntry {
  final String id;
  final String productId;
  final String productName;
  final int quantityChange; // positive = add, negative = subtract
  final int quantityAfter;
  final String reason;
  final DateTime createdAt;
  final bool isSynced;

  LedgerEntry({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantityChange,
    required this.quantityAfter,
    this.reason = '',
    DateTime? createdAt,
    this.isSynced = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'quantity_change': quantityChange,
      'quantity_after': quantityAfter,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory LedgerEntry.fromMap(Map<String, dynamic> map) {
    return LedgerEntry(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      quantityChange: map['quantity_change'] as int,
      quantityAfter: map['quantity_after'] as int,
      reason: map['reason'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}
