import '../models/order.dart';

class OrderService {
  const OrderService();

  Future<Order> placeOrder(Order order) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return order;
  }

  Future<Order> advanceStatus(Order order) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final next = switch (order.status) {
      OrderStatus.preparing => OrderStatus.outForDelivery,
      OrderStatus.outForDelivery => OrderStatus.delivered,
      OrderStatus.delivered => OrderStatus.delivered,
    };
    return order.copyWith(status: next);
  }
}