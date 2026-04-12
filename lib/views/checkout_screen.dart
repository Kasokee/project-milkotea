import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../bloc/order/order_bloc.dart';
import '../bloc/order/order_state.dart';
import '../bloc/order/order_event.dart';

import '../bloc/cart/cart_bloc.dart';
import '../bloc/cart/cart_state.dart';
import '../bloc/cart/cart_event.dart';

import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';

import '../models/order.dart';
import '../widgets/price_text.dart';
import 'order_confirmation_screen.dart';
import 'add_edit_address_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  static const route = '/checkout';

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Map<String, dynamic>? _selectedAddress;
  List<Map<String, dynamic>> _savedAddresses = [];
  bool _isLoadingAddresses = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        setState(() => _isLoadingAddresses = false);
        return;
      }

      final data = doc.data();
      final addresses = data?['addresses'] as List<dynamic>? ?? [];

      setState(() {
        _savedAddresses =
            addresses.map((addr) => Map<String, dynamic>.from(addr)).toList();
        _isLoadingAddresses = false;

        // Auto-select default address
        if (_savedAddresses.isNotEmpty) {
          final defaultAddr = _savedAddresses.firstWhere(
            (addr) => addr['isDefault'] == true,
            orElse: () => _savedAddresses.first,
          );
          _selectedAddress = defaultAddr;
        }
      });
    } catch (e) {
      setState(() => _isLoadingAddresses = false);
    }
  }

  void _selectAddress(Map<String, dynamic> address) {
    setState(() => _selectedAddress = address);
    Navigator.pop(context);
  }

  void _showAddressSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    children: [
                      const Text('Select Delivery Address',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddEditAddressScreen()),
                          ).then((_) => _loadAddresses());
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add New'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _savedAddresses.length,
                    itemBuilder: (context, index) {
                      final address = _savedAddresses[index];
                      final isSelected = _selectedAddress == address;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: isSelected ? 4 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _selectAddress(address),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Radio<Map<String, dynamic>>(
                                  value: address,
                                  groupValue: _selectedAddress,
                                  onChanged: (value) => _selectAddress(address),
                                  activeColor: Theme.of(context).primaryColor,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(address['label'] ?? 'Address',
                                              style: const TextStyle(fontWeight: FontWeight.bold)),
                                          if (address['isDefault'] == true) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text('Default',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Theme.of(context).primaryColor)),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(address['fullAddress'] ?? '',
                                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      if (address['phone'] != null && address['phone'].isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(address['phone'],
                                                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return MultiBlocListener(
      listeners: [
        BlocListener<OrderBloc, OrderState>(
          listener: (context, state) {
            if (state is OrderPlaced) {
              context.read<CartBloc>().add(ClearCart());
              Navigator.pushNamedAndRemoveUntil(
                context,
                OrderConfirmationScreen.route,
                (route) => route.settings.name == '/menu',
              );
            } else if (state is OrderError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('Checkout'), centerTitle: true, elevation: 0),
        body: _isLoadingAddresses
            ? const Center(child: CircularProgressIndicator())
            : _savedAddresses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No saved addresses',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Text('Add a delivery address to continue', style: TextStyle(color: Colors.grey[500])),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddEditAddressScreen()),
                            ).then((_) => _loadAddresses());
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Address'),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  )
                : BlocBuilder<CartBloc, CartState>(
                    builder: (context, cartState) {
                      if (cartState is! CartLoaded) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return BlocBuilder<OrderBloc, OrderState>(
                        builder: (context, orderState) {
                          final paymentMethod = context.read<OrderBloc>().paymentMethod;
                          final isPlacingOrder = orderState is OrderPlacing;

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Delivery Address
                                Row(
                                  children: [
                                    Icon(Icons.location_on, color: primary),
                                    const SizedBox(width: 8),
                                    const Text('Delivery Address',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_selectedAddress != null)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey[200]!),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(_selectedAddress!['label'] ?? 'Address',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                  if (_selectedAddress!['isDefault'] == true) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: primary.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text('Default',
                                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primary)),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(_selectedAddress!['fullAddress'] ?? '',
                                                  style: TextStyle(color: Colors.grey[700], height: 1.4)),
                                              const SizedBox(height: 4),
                                              if (_selectedAddress!['phone'] != null &&
                                                  _selectedAddress!['phone'].isNotEmpty)
                                                Row(
                                                  children: [
                                                    Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                                                    const SizedBox(width: 4),
                                                    Text(_selectedAddress!['phone'],
                                                        style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                        TextButton(onPressed: _showAddressSelector, child: const Text('Change')),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 32),

                                // Payment Method
                                Row(
                                  children: [
                                    Icon(Icons.payment, color: primary),
                                    const SizedBox(width: 8),
                                    const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildPaymentOption(context, paymentMethod, PaymentMethod.cod, 'Cash on Delivery (COD)',
                                    'Pay when your order arrives', Icons.money),
                                const SizedBox(height: 12),
                                _buildPaymentOption(context, paymentMethod, PaymentMethod.gcash, 'GCash Online Payment',
                                    'Mock flow ready for payment gateway integration', Icons.account_balance_wallet),
                                const SizedBox(height: 32),

                                // Order Summary
                                Row(
                                  children: [
                                    Icon(Icons.receipt_long, color: primary),
                                    const SizedBox(width: 8),
                                    const Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildSummaryRow('Subtotal', cartState.subtotal),
                                      const SizedBox(height: 12),
                                      _buildSummaryRow('Delivery Fee', cartState.deliveryFee),
                                      const Divider(height: 24),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                          PriceText(cartState.total,
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primary)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Place Order Button
                                BlocBuilder<AuthBloc, AuthState>(
                                  builder: (context, authState) {
                                    return SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: FilledButton(
                                        onPressed: isPlacingOrder
                                            ? null
                                            : () async {
                                                if (authState is! Authenticated) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Please login first')),
                                                  );
                                                  return;
                                                }

                                                final user = FirebaseAuth.instance.currentUser;
                                                final userName = user?.displayName ?? authState.userName;

                                                context.read<OrderBloc>().add(
                                                      PlaceOrder(
                                                        userId: authState.userId,
                                                        customerName: userName,
                                                        customerPhone: _selectedAddress!['phone'] ?? '',
                                                        deliveryAddress: _selectedAddress!['fullAddress'] ?? '',
                                                        items: cartState.items,
                                                        subtotal: cartState.subtotal,
                                                        deliveryFee: cartState.deliveryFee,
                                                        totalPrice: cartState.total,
                                                        paymentMethod: paymentMethod,
                                                      ),
                                                    );
                                              },
                                        style: FilledButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: isPlacingOrder
                                            ? const SizedBox(
                                                height: 24,
                                                width: 24,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                              )
                                            : const Text('Place Order',
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context,
    PaymentMethod currentMethod,
    PaymentMethod method,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = currentMethod == method;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!, width: isSelected ? 2 : 1),
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.05) : Colors.white,
      ),
      child: RadioListTile<PaymentMethod>(
        value: method,
        groupValue: currentMethod,
        onChanged: (value) => context.read<OrderBloc>().add(SetPaymentMethod(value!)),
        title: Row(
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ),
        activeColor: Theme.of(context).primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        PriceText(amount),
      ],
    );
  }
}