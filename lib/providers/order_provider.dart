import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:boutique_manager/models/order.dart';
import 'package:boutique_manager/models/product.dart';
import 'package:boutique_manager/services/database_service.dart';

class OrderProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;
  final _uuid = const Uuid();

  List<Order> _orders = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _pendingCount = 0;
  double _totalRevenue = 0;

  // Cart state for client
  final Map<String, CartItem> _cart = {};

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  int get pendingCount => _pendingCount;
  double get totalRevenue => _totalRevenue;
  Map<String, CartItem> get cart => Map.unmodifiable(_cart);
  int get cartItemCount => _cart.values.fold(0, (sum, item) => sum + item.quantity);
  double get cartTotal =>
      _cart.values.fold(0.0, (sum, item) => sum + item.product.price * item.quantity);

  void addToCart(Product product) {
    if (_cart.containsKey(product.id)) {
      final existing = _cart[product.id]!;
      if (existing.quantity < product.quantity) {
        _cart[product.id] = CartItem(
          product: product,
          quantity: existing.quantity + 1,
        );
      }
    } else {
      _cart[product.id] = CartItem(product: product, quantity: 1);
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cart.remove(productId);
    notifyListeners();
  }

  void updateCartQuantity(String productId, int quantity) {
    if (!_cart.containsKey(productId)) return;
    if (quantity <= 0) {
      _cart.remove(productId);
    } else {
      final item = _cart[productId]!;
      _cart[productId] = CartItem(
        product: item.product,
        quantity: quantity.clamp(1, item.product.quantity),
      );
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  Future<Order> placeOrder({
    required String buyerName,
    String? buyerPhone,
    String? buyerNote,
  }) async {
    final orderId = _uuid.v4();
    final items = _cart.values.map((cartItem) {
      return OrderItem(
        id: _uuid.v4(),
        orderId: orderId,
        productId: cartItem.product.id,
        productName: cartItem.product.name,
        price: cartItem.product.price,
        quantity: cartItem.quantity,
      );
    }).toList();

    final total = items.fold(0.0, (sum, item) => sum + item.subtotal);

    final order = Order(
      id: orderId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      buyerNote: buyerNote,
      totalAmount: total,
      items: items,
    );

    await _db.insertOrder(
      order.toMap(),
      items.map((i) => i.toMap()).toList(),
    );

    _orders.insert(0, order);
    _pendingCount++;
    _cart.clear();
    notifyListeners();
    return order;
  }

  Future<void> loadOrders({bool refresh = false, String? status}) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    if (refresh) {
      _orders = [];
      _hasMore = true;
    }

    final maps = await _db.getOrders(
      status: status,
      limit: 20,
      offset: _orders.length,
    );

    for (final map in maps) {
      final items = await _db.getOrderItems(map['id'] as String);
      _orders.add(Order.fromMap(map,
          items: items.map((i) => OrderItem.fromMap(i)).toList()));
    }

    _hasMore = maps.length == 20;
    _isLoading = false;
    notifyListeners();

    await refreshStats();
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    await _db.updateOrderStatus(orderId, status.name);
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      _orders[idx] = _orders[idx].copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
    }
    await refreshStats();
    notifyListeners();
  }

  Future<void> refreshStats() async {
    final stats = await _db.getOrderStats();
    _pendingCount = stats['pending_count'] as int;
    _totalRevenue = stats['total_revenue'] as double;
  }
}

class CartItem {
  final Product product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});
}
