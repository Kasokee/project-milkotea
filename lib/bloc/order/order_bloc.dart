import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/order.dart';
import '../../services/firestore_service.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final FirestoreService _firestoreService;
  Order? _activeOrder;
  PaymentMethod _paymentMethod = PaymentMethod.cod;

  OrderBloc({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService(),
        super(OrderInitial()) {
    on<PlaceOrder>(_onPlaceOrder);
    on<ProgressOrderStatus>(_onProgressOrderStatus);
    on<SetPaymentMethod>(_onSetPaymentMethod);
  }

  Order? get activeOrder => _activeOrder;
  PaymentMethod get paymentMethod => _paymentMethod;

  Future<void> _onPlaceOrder(
    PlaceOrder event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderPlacing());

    try {
      final order = Order(
        orderId: 'MK${Random().nextInt(90000) + 10000}',
        items: event.items,
        totalPrice: event.totalPrice,
        paymentMethod: event.paymentMethod,
        status: OrderStatus.preparing,
        deliveryAddress: event.deliveryAddress,
      );

      await _firestoreService.addOrder(
        order.orderId,
        event.userId,
        event.customerName,
        event.customerPhone,
        event.deliveryAddress,
        order.items.map((e) => e.toMap()).toList(),
        event.subtotal,
        event.deliveryFee,
        event.totalPrice,
        event.paymentMethod.name,
        order.status.name,
      );

      _activeOrder = order;
      emit(OrderPlaced(order));
    } catch (e) {
      emit(OrderError('Failed to place order: ${e.toString()}'));
    }
  }

  void _onProgressOrderStatus(
    ProgressOrderStatus event,
    Emitter<OrderState> emit,
  ) {
    if (_activeOrder == null ||
        _activeOrder!.status == OrderStatus.delivered) return;

    emit(OrderProgressing());

    _activeOrder = _activeOrder!.copyWith(
      status: OrderStatus.values[_activeOrder!.status.index + 1],
    );

    emit(OrderStatusUpdated(_activeOrder!));
  }

  void _onSetPaymentMethod(
    SetPaymentMethod event,
    Emitter<OrderState> emit,
  ) {
    _paymentMethod = event.method;
    emit(PaymentMethodUpdated(event.method));
  }
}