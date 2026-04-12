import '../../models/cart_item.dart';
import '../../models/product.dart';

abstract class CartEvent {}

class AddToCart extends CartEvent {
  final Product product;
  final DrinkSize size;
  final SugarLevel sugarLevel;
  final List<AddOn> addOns;
  final String? note;

  AddToCart({
    required this.product,
    required this.size,
    required this.sugarLevel,
    required this.addOns,
    this.note,
  });
}

class UpdateCartItemQuantity extends CartEvent {
  final CartItem item;
  final int delta;

  UpdateCartItemQuantity({required this.item, required this.delta});
}

class RemoveFromCart extends CartEvent {
  final CartItem item;
  RemoveFromCart(this.item);
}

class ClearCart extends CartEvent {}

class LoadCart extends CartEvent {
  final String userId;
  LoadCart(this.userId);
}