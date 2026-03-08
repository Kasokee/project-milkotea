import 'package:equatable/equatable.dart';
import '../../models/cart_item.dart';

abstract class CartState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {} 

class CartError extends CartState {
  final String? message;
  CartError({this.message});
}

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
}