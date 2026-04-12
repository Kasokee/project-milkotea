import '../../models/cart_item.dart';
import '../../models/order.dart';

abstract class OrderEvent {}

class PlaceOrder extends OrderEvent {
  final String userId;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double totalPrice;
  final PaymentMethod paymentMethod;

  PlaceOrder({
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalPrice,
    required this.paymentMethod,
  });
}

class ProgressOrderStatus extends OrderEvent {}

class LoadActiveOrder extends OrderEvent {}

class SetPaymentMethod extends OrderEvent {
  final PaymentMethod method;
  SetPaymentMethod(this.method);
}

