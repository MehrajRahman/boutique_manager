class Order {
  final String id;
  final String buyerName;
  final String? buyerPhone;
  final String? buyerNote;
  final double totalAmount;
  final OrderStatus status;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  Order({
    required this.id,
    required this.buyerName,
    this.buyerPhone,
    this.buyerNote,
    required this.totalAmount,
    this.status = OrderStatus.pending,
    this.items = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Order copyWith({
    String? id,
    String? buyerName,
    String? buyerPhone,
    String? buyerNote,
    double? totalAmount,
    OrderStatus? status,
    List<OrderItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Order(
      id: id ?? this.id,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      buyerNote: buyerNote ?? this.buyerNote,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'buyer_name': buyerName,
      'buyer_phone': buyerPhone,
      'buyer_note': buyerNote,
      'total_amount': totalAmount,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map, {List<OrderItem>? items}) {
    return Order(
      id: map['id'] as String,
      buyerName: map['buyer_name'] as String,
      buyerPhone: map['buyer_phone'] as String?,
      buyerNote: map['buyer_note'] as String?,
      totalAmount: (map['total_amount'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'pending'),
        orElse: () => OrderStatus.pending,
      ),
      items: items ?? [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}

class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final double price;
  final int quantity;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
    );
  }
}

enum OrderStatus { pending, confirmed, fulfilled, cancelled }
