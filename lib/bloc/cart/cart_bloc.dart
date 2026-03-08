import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/cart_item.dart';
import '../../services/firestore_service.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final FirestoreService _firestoreService;
  String? _currentUserId;

  CartBloc({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService(),
        super(CartInitial()) {
    on<AddToCart>(_onAddToCart);
    on<UpdateCartItemQuantity>(_onUpdateQuantity);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<ClearCart>(_onClearCart);
    on<LoadCart>(_onLoadCart);
  }

  Future<void> _onAddToCart(
    AddToCart event,
    Emitter<CartState> emit,
  ) async {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      final items = List<CartItem>.from(currentState.items);

      // Check if item already exists
      final index = items.indexWhere(
        (item) =>
            item.product.id == event.product.id &&
            item.size == event.size &&
            item.sugarLevel == event.sugarLevel &&
            _sameAddOns(item.addOns, event.addOns) &&
            item.note == event.note,
      );

      if (index >= 0) {
        items[index] = items[index].copyWith(
          quantity: items[index].quantity + 1,
        );
      } else {
        items.add(CartItem(
          product: event.product,
          size: event.size,
          sugarLevel: event.sugarLevel,
          addOns: event.addOns,
          note: event.note,
          quantity: 1,
        ));
      }

      emit(CartLoaded(items: items));
      _saveToFirestore(items);
    }
  }

  void _onUpdateQuantity(
    UpdateCartItemQuantity event,
    Emitter<CartState> emit,
  ) {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      final items = List<CartItem>.from(currentState.items);
      final index = items.indexOf(event.item);

      if (index != -1) {
        final newQuantity = items[index].quantity + event.delta;
        if (newQuantity <= 0) {
          items.removeAt(index);
        } else {
          items[index] = items[index].copyWith(quantity: newQuantity);
        }
        emit(CartLoaded(items: items));
        _saveToFirestore(items);
      }
    }
  }

  void _onRemoveFromCart(
    RemoveFromCart event,
    Emitter<CartState> emit,
  ) {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      final items = List<CartItem>.from(currentState.items);
      items.remove(event.item);
      emit(CartLoaded(items: items));
      _saveToFirestore(items);
    }
  }

  void _onClearCart(
    ClearCart event,
    Emitter<CartState> emit,
  ) {
    emit(CartLoaded(items: []));
    _saveToFirestore([]);
  }

  Future<void> _onLoadCart(
    LoadCart event,
    Emitter<CartState> emit,
  ) async {
    _currentUserId = event.userId;
    emit(CartLoading());
    try {
      final cartData = await _firestoreService.getCart(event.userId);
      final items = cartData.map((e) => CartItemFirestore.fromMap(e)).toList();
      emit(CartLoaded(items: items));
    } catch (e) {
      emit(CartError(message: 'Failed to load cart'));
      emit(CartLoaded(items: []));
    }
  }

  Future<void> _saveToFirestore(List<CartItem> items) async {
    if (_currentUserId != null) {
      await _firestoreService.addToCart(
        _currentUserId!,
        items.map((e) => e.toMap()).toList(),
      );
    }
  }

  bool _sameAddOns(List<AddOn> a, List<AddOn> b) {
    if (a.length != b.length) return false;
    final aSorted = List<AddOn>.from(a)
      ..sort((x, y) => x.name.compareTo(y.name));
    final bSorted = List<AddOn>.from(b)
      ..sort((x, y) => x.name.compareTo(y.name));
    for (var i = 0; i < aSorted.length; i++) {
      if (aSorted[i] != bSorted[i]) return false;
    }
    return true;
  }
}