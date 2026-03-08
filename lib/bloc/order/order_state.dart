import 'package:equatable/equatable.dart';
import '../../models/order.dart';

abstract class OrderState extends Equatable {
  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderPlacing extends OrderState {}

class OrderPlaced extends OrderState {
  final Order order;
  OrderPlaced(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderProgressing extends OrderState {}

class OrderStatusUpdated extends OrderState {
  final Order order;
  OrderStatusUpdated(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderError extends OrderState {
  final String message;
  OrderError(this.message);

  @override
  List<Object?> get props => [message];
}