import '../../models/cart_item.dart';

abstract class CartState {}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<CartItem> items;

  CartLoaded({required this.items});

  int get cartCount => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal {
    return items.fold(0.0, (sum, item) {
      double itemPrice = item.product.price;
      
      // Add size price
      switch (item.size) {
        case DrinkSize.small:
          itemPrice += 0;
          break;
        case DrinkSize.medium:
          itemPrice += 15;
          break;
        case DrinkSize.large:
          itemPrice += 30;
          break;
      }
      
      // Add add-ons price
      itemPrice += item.addOns.length * 20;
      
      return sum + (itemPrice * item.quantity);
    });
  }

  double get deliveryFee => items.isEmpty ? 0 : 35;
  double get total => subtotal + deliveryFee;

  String itemLabel(CartItem item) {
    final sugarDisplay = switch (item.sugarLevel) {
      SugarLevel.zero => '0%',
      SugarLevel.twentyFive => '25%',
      SugarLevel.fifty => '50%',
      SugarLevel.seventyFive => '75%',
      SugarLevel.full => '100%',
    };
    return '${item.product.name} • ${item.size.name} • $sugarDisplay';
  }
}

class CartError extends CartState {
  final String message;
  CartError(this.message);
}