import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/order/order_bloc.dart';
import '../bloc/order/order_state.dart';
import '../bloc/cart/cart_bloc.dart';
import '../bloc/cart/cart_event.dart';
import '../models/order.dart';
import '../widgets/price_text.dart';
import 'order_tracking_screen.dart';
import 'checkout_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  static const route = '/orders';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders'), centerTitle: true, elevation: 0),
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          final order = context.read<OrderBloc>().activeOrder;

          if (order == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No orders yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Your order history will appear here', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500])),
                ],
              ),
            );
          }

          return ListView(padding: const EdgeInsets.all(16), children: [_buildOrderCard(context, order)]);
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, OrderTrackingScreen.route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order #${order.orderId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: _getStatusColor(order.status).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(_getStatusText(order.status),
                        style: TextStyle(color: _getStatusColor(order.status), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(_formatDate(order.createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(order.deliveryAddress, style: TextStyle(color: Colors.grey[600], fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(_getPaymentText(order.paymentMethod), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  PriceText(order.totalPrice,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor)),
                ],
              ),
              const SizedBox(height: 12),
              if (order.status != OrderStatus.delivered)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, OrderTrackingScreen.route),
                    icon: const Icon(Icons.delivery_dining),
                    label: const Text('Track Order'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: () {
                            for (final item in order.items) {
                              context.read<CartBloc>().add(
                                    AddToCart(
                                      product: item.product,
                                      size: item.size,
                                      sugarLevel: item.sugarLevel,
                                      addOns: item.addOns,
                                      note: item.note,
                                    ),
                                  );
                            }
                            Navigator.pushNamed(context, CheckoutScreen.route);
                          },
                          style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          child: const Text('Reorder', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          child: const Text('Rate', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) => switch (status) {
        OrderStatus.preparing => Colors.orange,
        OrderStatus.outForDelivery => Colors.blue,
        OrderStatus.delivered => Colors.green,
      };

  String _getStatusText(OrderStatus status) => switch (status) {
        OrderStatus.preparing => 'Preparing',
        OrderStatus.outForDelivery => 'Out for Delivery',
        OrderStatus.delivered => 'Delivered',
      };

  String _getPaymentText(PaymentMethod method) => method == PaymentMethod.cod ? 'Cash on Delivery' : 'GCash';

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}