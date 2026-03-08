import 'cart_item.dart';

enum PaymentMethod { cod, gcash }
enum OrderStatus { preparing, outForDelivery, delivered }

class Order {
  Order({
    required this.orderId,
    required this.items,
    required this.totalPrice,
    required this.paymentMethod,
    required this.status,
    required this.deliveryAddress,
    DateTime? createdAt, // NEW
  }) : createdAt = createdAt ?? DateTime.now();

  final String orderId;
  final List<CartItem> items;
  final double totalPrice;
  final PaymentMethod paymentMethod;
  final OrderStatus status;
  final String deliveryAddress;
  final DateTime createdAt; // NEW

  Order copyWith({
    String? orderId,
    List<CartItem>? items,
    double? totalPrice,
    PaymentMethod? paymentMethod,
    OrderStatus? status,
    String? deliveryAddress,
    DateTime? createdAt, // NEW
  }) {
    return Order(
      orderId: orderId ?? this.orderId,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      createdAt: createdAt ?? this.createdAt, // NEW
    );
  }
}
