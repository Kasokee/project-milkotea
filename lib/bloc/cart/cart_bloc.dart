import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/cart_item.dart';
import '../../services/firestore_service.dart';
import '../../services/local_db_service.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final FirestoreService _firestoreService;
  final LocalDbService _localDbService;
  String? _currentUserId;

  CartBloc({FirestoreService? firestoreService, LocalDbService? localDbService})
    : _firestoreService = firestoreService ?? FirestoreService(),
      _localDbService = localDbService ?? LocalDbService(),
      super(CartInitial()) {
    on<AddToCart>(_onAddToCart);
    on<UpdateCartItemQuantity>(_onUpdateQuantity);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<ClearCart>(_onClearCart);
    on<LoadCart>(_onLoadCart);
  }

  Future<void> _onAddToCart(AddToCart event, Emitter<CartState> emit) async {
    final items = state is CartLoaded
        ? List<CartItem>.from((state as CartLoaded).items)
        : <CartItem>[];

    final index = items.indexWhere(
      (item) =>
          item.product.id == event.product.id &&
          item.size == event.size &&
          item.sugarLevel == event.sugarLevel &&
          _sameAddOns(item.addOns, event.addOns) &&
          item.note == event.note,
    );

    if (index >= 0) {
      items[index] = items[index].copyWith(quantity: items[index].quantity + 1);
    } else {
      items.add(
        CartItem(
          product: event.product,
          size: event.size,
          sugarLevel: event.sugarLevel,
          addOns: event.addOns,
          note: event.note,
          quantity: 1,
        ),
      );
    }

    emit(CartLoaded(items: items));
    await _saveCart(items);
  }

  Future<void> _onUpdateQuantity(
    UpdateCartItemQuantity event,
    Emitter<CartState> emit,
  ) async {
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
        await _saveCart(items);
      }
    }
  }

  Future<void> _onRemoveFromCart(
    RemoveFromCart event,
    Emitter<CartState> emit,
  ) async {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      final items = List<CartItem>.from(currentState.items);
      items.remove(event.item);
      emit(CartLoaded(items: items));
      await _saveCart(items);
    }
  }

  Future<void> _onClearCart(ClearCart event, Emitter<CartState> emit) async {
    emit(CartLoaded(items: []));
    await _saveCart([]);
  }

  Future<void> _onLoadCart(LoadCart event, Emitter<CartState> emit) async {
    _currentUserId = event.userId;
    emit(CartLoading());

    List<CartItem> localItems = [];
    try {
      localItems = await _localDbService.loadCart(event.userId);
      emit(CartLoaded(items: localItems));
    } catch (_) {
      emit(CartLoaded(items: []));
    }

    try {
      final cartData = await _firestoreService.getCart(event.userId);
      final remoteItems = cartData
          .map((e) => CartItemFirestore.fromMap(e))
          .toList();
      final mergedItems = _mergeCartItems(remoteItems, localItems);
      await _localDbService.saveCart(event.userId, mergedItems);
      emit(CartLoaded(items: mergedItems));
      await _firestoreService.addToCart(
        event.userId,
        mergedItems.map((e) => e.toMap()).toList(),
      );
    } catch (_) {
      // Remote load failed or offline; keep the local cart state.
    }
  }

  Future<void> _saveCart(List<CartItem> items) async {
    if (_currentUserId == null) return;

    try {
      await _localDbService.saveCart(_currentUserId!, items);
    } catch (_) {
      // Local persistence failed; ignore so user can continue.
    }

    try {
      await _firestoreService.addToCart(
        _currentUserId!,
        items.map((e) => e.toMap()).toList(),
      );
    } catch (_) {
      // Firestore sync may fail if offline. The cart is still saved locally.
    }
  }

  List<CartItem> _mergeCartItems(List<CartItem> remote, List<CartItem> local) {
    final merged = <String, CartItem>{};

    for (final item in remote) {
      merged[_itemKey(item)] = item;
    }

    for (final item in local) {
      final key = _itemKey(item);
      if (merged.containsKey(key)) {
        merged[key] = merged[key]!.copyWith(
          quantity: merged[key]!.quantity + item.quantity,
        );
      } else {
        merged[key] = item;
      }
    }

    return merged.values.toList();
  }

  String _itemKey(CartItem item) {
    final addOns = List<AddOn>.from(item.addOns)
      ..sort((a, b) => a.name.compareTo(b.name));
    return '${item.product.id}|${item.size.name}|${item.sugarLevel.name}|${addOns.map((e) => e.name).join(',')}|${item.note ?? ''}';
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
