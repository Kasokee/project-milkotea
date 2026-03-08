import 'product.dart';

enum DrinkSize { small, medium, large }

enum SugarLevel { zero, twentyFive, fifty, seventyFive, full }

enum AddOn { pearls, nata, pudding }

class CartItem {
  const CartItem({
    required this.product,
    required this.quantity,
    required this.size,
    required this.sugarLevel,
    required this.addOns,
    this.note, 
  });

  final Product product;
  final int quantity;
  final DrinkSize size;
  final SugarLevel sugarLevel;
  final List<AddOn> addOns;
  final String? note;
  
  CartItem copyWith({
    Product? product,
    int? quantity,
    DrinkSize? size,
    SugarLevel? sugarLevel,
    List<AddOn>? addOns,
    String? note,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      size: size ?? this.size,
      sugarLevel: sugarLevel ?? this.sugarLevel,
      addOns: addOns ?? this.addOns,
      note: note ?? this.note,
    );
  }
}
