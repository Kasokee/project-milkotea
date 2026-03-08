import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../presenters/app_presenter.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  static const route = '/tracking';

  @override
  Widget build(BuildContext context) {
    final presenter = context.watch<AppPresenter>();
    final order = presenter.activeOrder;

    if (order == null) {
      return const Scaffold(
        body: Center(
          child: Text('No active order found.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderId}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getEstimatedTime(order.status),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Order Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              ...OrderStatus.values.map((status) {
                final index = OrderStatus.values.indexOf(status);
                final currentIndex = OrderStatus.values.indexOf(order.status);
                final isDone = currentIndex >= index;
                final isCurrent = currentIndex == index;

                return _buildStatusItem(
                  context,
                  status,
                  isDone,
                  isCurrent,
                  index < OrderStatus.values.length - 1,
                );
              }),
              const SizedBox(height: 32),

              /// ====== UPDATED SECTION ONLY ======
              if (order.status != OrderStatus.delivered)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed:
                        presenter.isBusy ? null : presenter.progressOrder,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: presenter.isBusy
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Advance Status (Demo)',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                )
              else
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.celebration, color: Colors.green[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Order delivered! Enjoy your milk tea!',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: FilledButton(
                              onPressed: presenter.isBusy
                                  ? null
                                  : presenter.reorderLastOrder,
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Reorder',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: OutlinedButton(
                              onPressed: () {
                                // TODO: Implement rating dialog/screen
                              },
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Rate',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              /// ====== END UPDATE ======
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(
    BuildContext context,
    OrderStatus status,
    bool isDone,
    bool isCurrent,
    bool showLine,
  ) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDone
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: isDone ? Colors.white : Colors.grey[600],
                    size: 24,
                  ),
                ),
                if (showLine)
                  Container(
                    width: 2,
                    height: 40,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: isDone
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusLabel(status),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color:
                            isDone ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusDescription(status),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getStatusIcon(OrderStatus status) => switch (status) {
        OrderStatus.preparing => Icons.restaurant,
        OrderStatus.outForDelivery => Icons.delivery_dining,
        OrderStatus.delivered => Icons.check_circle,
      };

  String _getStatusLabel(OrderStatus status) => switch (status) {
        OrderStatus.preparing => 'Preparing Your Order',
        OrderStatus.outForDelivery => 'Out for Delivery',
        OrderStatus.delivered => 'Delivered',
      };

  String _getStatusDescription(OrderStatus status) => switch (status) {
        OrderStatus.preparing =>
          'Our team is carefully preparing your milk tea',
        OrderStatus.outForDelivery =>
          'Your order is on its way to you',
        OrderStatus.delivered =>
          'Order has been delivered successfully',
      };

  String _getEstimatedTime(OrderStatus status) => switch (status) {
        OrderStatus.preparing =>
          'Estimated time: 15-20 minutes',
        OrderStatus.outForDelivery =>
          'Estimated time: 10-15 minutes',
        OrderStatus.delivered => 'Delivered',
      };
}
