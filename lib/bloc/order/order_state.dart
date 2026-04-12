import '../../models/order.dart';

abstract class OrderState {}

class OrderInitial extends OrderState {
  final PaymentMethod paymentMethod;
  OrderInitial({this.paymentMethod = PaymentMethod.cod});
}

class OrderPlacing extends OrderState {}

class OrderPlaced extends OrderState {
  final Order order;
  OrderPlaced(this.order);
}

class OrderProgressing extends OrderState {}

class OrderStatusUpdated extends OrderState {
  final Order order;
  OrderStatusUpdated(this.order);
}

class OrderError extends OrderState {
  final String message;
  OrderError(this.message);
}

class PaymentMethodUpdated extends OrderState {
  final PaymentMethod paymentMethod;
  PaymentMethodUpdated(this.paymentMethod);
}