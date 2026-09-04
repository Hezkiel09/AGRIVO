import 'package:flutter/foundation.dart';

class CartItem {
  final dynamic id;
  final String name;
  final String priceStr;
  final int price;
  final String unit;
  final String grade;
  final String? imagePath;
  final String sellerName;
  final String? salesMode;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.priceStr,
    required this.price,
    this.unit = 'kg',
    this.grade = 'Grade A',
    this.imagePath,
    this.sellerName = 'Petani Agrivo',
    this.salesMode = 'market',
    this.quantity = 1,
  });

  int get itemTotal => price * quantity;
}

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItemCount {
    int total = 0;
    for (var item in _items) {
      total += item.quantity;
    }
    return total;
  }

  int get totalPrice {
    int total = 0;
    for (var item in _items) {
      total += item.itemTotal;
    }
    return total;
  }

  static int parsePrice(dynamic priceVal) {
    if (priceVal == null) return 0;
    if (priceVal is int) return priceVal;
    if (priceVal is double) return priceVal.toInt();
    String str = priceVal.toString();
    String digits = str.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  void addToCart(Map<String, dynamic> product, {int quantity = 1}) {
    dynamic id = product['id'] ?? product['name'];
    int existingIndex = _items.indexWhere((item) => item.id.toString() == id.toString());

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      String rawPrice = product['price']?.toString() ?? '0';
      int parsed = parsePrice(rawPrice);

      _items.add(CartItem(
        id: id,
        name: product['name'] ?? 'Hasil Panen',
        priceStr: rawPrice,
        price: parsed,
        unit: product['unit'] ?? 'kg',
        grade: product['grade'] ?? 'Grade A',
        imagePath: product['image_path'],
        sellerName: product['seller_name'] ?? product['farm_name'] ?? 'Petani Agrivo',
        salesMode: product['sales_mode'] ?? 'market',
        quantity: quantity,
      ));
    }
    notifyListeners();
  }

  void updateQuantity(dynamic id, int newQuantity) {
    int index = _items.indexWhere((item) => item.id.toString() == id.toString());
    if (index >= 0) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = newQuantity;
      }
      notifyListeners();
    }
  }

  void removeFromCart(dynamic id) {
    _items.removeWhere((item) => item.id.toString() == id.toString());
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
