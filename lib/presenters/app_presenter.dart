import 'dart:math';
import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import '../services/mock_data_service.dart';

class AppPresenter extends ChangeNotifier {
  AppPresenter({FirestoreService? firestoreService, MockDataService? mockData})
      : _firestoreService = firestoreService ?? FirestoreService(),
        _mockDataService = mockData ?? const MockDataService() {
    loadProducts();
  }

  final FirestoreService _firestoreService;
  final MockDataService _mockDataService;

  late List<Product> _products = [];
  ProductCategory? _selectedCategory;
  final List<CartItem> _cart = [];
  Order? _activeOrder;
  User? _user;
  PaymentMethod _paymentMethod = PaymentMethod.cod;
  bool isBusy = false;

  // -----------------------
  // Getters
  // -----------------------
  List<Product> get products => _selectedCategory == null
      ? _products
      : _products.where((p) => p.category == _selectedCategory).toList();
  ProductCategory? get selectedCategory => _selectedCategory;
  List<CartItem> get cartItems => List.unmodifiable(_cart);
  User? get user => _user;
  Order? get activeOrder => _activeOrder;
  PaymentMethod get paymentMethod => _paymentMethod;
  int get cartCount => _cart.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _cart.fold(
        0,
        (sum, item) => sum + _computeItemPrice(item) * item.quantity,
      );

  double get deliveryFee => _cart.isEmpty ? 0 : 35;

  double get total => subtotal + deliveryFee;

  // -----------------------
  // Load products from Firestore with fallback
  // -----------------------
  Future<void> loadProducts() async {
    try {
      final firestoreProducts = await _firestoreService.getProducts();
      if (firestoreProducts.isNotEmpty) {
        _products = firestoreProducts;
      } else {
        _products = _mockDataService.products();
      }
    } catch (_) {
      _products = _mockDataService.products();
    }
    notifyListeners();
  }

  void selectCategory(ProductCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setPaymentMethod(PaymentMethod method) {
    _paymentMethod = method;
    notifyListeners();
  }

  // -----------------------
  // Pricing helpers
  // -----------------------
  double _sizePrice(DrinkSize size) => switch (size) {
        DrinkSize.small => 0,
        DrinkSize.medium => 15,
        DrinkSize.large => 30,
      };

  double _addOnPrice(AddOn addOn) => 20;

  double _computeItemPrice(CartItem item) {
    final addOnTotal = item.addOns.fold<double>(
      0,
      (sum, addOn) => sum + _addOnPrice(addOn),
    );
    return item.product.price + _sizePrice(item.size) + addOnTotal;
  }

  String itemLabel(CartItem item) =>
      '${item.product.name} • ${item.size.name} • ${_sugarDisplay(item.sugarLevel)}';

  String _sugarDisplay(SugarLevel level) => switch (level) {
        SugarLevel.zero => '0%',
        SugarLevel.twentyFive => '25%',
        SugarLevel.fifty => '50%',
        SugarLevel.seventyFive => '75%',
        SugarLevel.full => '100%',
      };

  // -----------------------
  // Cart operations
  // -----------------------
  void addToCart({
    required Product product,
    required DrinkSize size,
    required SugarLevel sugarLevel,
    required List<AddOn> addOns,
    String? note,
  }) {
    final index = _cart.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.size == size &&
          item.sugarLevel == sugarLevel &&
          _sameAddOns(item.addOns, addOns) &&
          item.note == note,
    );

    if (index >= 0) {
      _cart[index] =
          _cart[index].copyWith(quantity: _cart[index].quantity + 1);
    } else {
      _cart.add(CartItem(
        product: product,
        size: size,
        sugarLevel: sugarLevel,
        addOns: List.from(addOns),
        note: note,
        quantity: 1,
      ));
    }
    notifyListeners();
    _saveCartToFirestore();
  }

  void updateQuantity(CartItem item, int delta) {
    final index = _cart.indexOf(item);
    if (index == -1) return;

    final qty = _cart[index].quantity + delta;
    if (qty <= 0) {
      _cart.removeAt(index);
    } else {
      _cart[index] = _cart[index].copyWith(quantity: qty);
    }
    notifyListeners();
    _saveCartToFirestore();
  }

  bool _sameAddOns(List<AddOn> a, List<AddOn> b) {
    if (a.length != b.length) return false;
    final aSorted = List<AddOn>.from(a)..sort((x, y) => x.name.compareTo(y.name));
    final bSorted = List<AddOn>.from(b)..sort((x, y) => x.name.compareTo(y.name));
    for (var i = 0; i < aSorted.length; i++) {
      if (aSorted[i] != bSorted[i]) return false;
    }
    return true;
  }

  // -----------------------
  // Firestore cart save/load
  // -----------------------
  Future<void> _saveCartToFirestore() async {
    if (_user != null) {
      await _firestoreService.addToCart(
        _user!.id,
        _cart.map((e) => e.toMap()).toList(),
      );
    }
  }

  Future<void> loadCart() async {
    if (_user == null) return;
    try {
      final cartData = await _firestoreService.getCart(_user!.id);
      _cart.clear();
      _cart.addAll(cartData.map((e) => CartItemFirestore.fromMap(e)));
      notifyListeners();
    } catch (_) {
      print('Failed to load cart');
    }
  }

  // -----------------------
  // Checkout & Orders
  // -----------------------
  bool isViracAddress(String address) =>
      address.toLowerCase().contains('virac') && address.trim().isNotEmpty;

  String? validateCheckout({
    required String name,
    required String phone,
    required String address,
  }) {
    if (_cart.isEmpty) return 'Your cart is empty.';
    if (name.trim().isEmpty || phone.trim().isEmpty || address.trim().isEmpty) {
      return 'Please complete all customer details.';
    }
    if (!isViracAddress(address)) {
      return 'Delivery is currently available within Virac, Catanduanes only.';
    }
    return null;
  }

  Future<String?> placeOrder({
    required String name,
    required String phone,
    required String address,
  }) async {
    final validation = validateCheckout(
      name: name,
      phone: phone,
      address: address,
    );
    if (validation != null) return validation;

    isBusy = true;
    notifyListeners();

    _user ??= User(id: 'guest', name: name, phone: phone, address: address);
    final order = Order(
      orderId: 'MK${Random().nextInt(90000) + 10000}',
      items: List<CartItem>.from(_cart),
      totalPrice: total,
      paymentMethod: _paymentMethod,
      status: OrderStatus.preparing,
      deliveryAddress: address,
    );

    await _firestoreService.addOrder(
      order.orderId,
      _user!.id,
      _user!.name,
      _user!.phone,
      order.deliveryAddress,
      order.items.map((e) => e.toMap()).toList(),
      subtotal,
      deliveryFee,
      total,
      _paymentMethod.name,
      order.status.name,
    );

    _activeOrder = order;
    _cart.clear();
    isBusy = false;
    notifyListeners();
    return null;
  }

  Future<void> progressOrder() async {
    if (_activeOrder == null || _activeOrder!.status == OrderStatus.delivered) return;
    isBusy = true;
    notifyListeners();
    _activeOrder = _activeOrder!.copyWith(
      status: OrderStatus.values[_activeOrder!.status.index + 1],
    );
    isBusy = false;
    notifyListeners();
  }

  void reorderLastOrder() {
    if (_activeOrder == null) return;
    for (final item in _activeOrder!.items) {
      _cart.add(item);
    }
    _activeOrder = null;
    notifyListeners();
    _saveCartToFirestore();
  }
}
