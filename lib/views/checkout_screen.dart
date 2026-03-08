import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order.dart';
import '../presenters/app_presenter.dart';
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
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Select Delivery Address',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddEditAddressScreen(),
                            ),
                          ).then((_) => _loadAddresses());
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add New'),
                      ),
                    ],
                  ),
                ),

                // Address list
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
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            address['label'] ?? 'Address',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (address['isDefault'] == true) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .primaryColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Default',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        address['fullAddress'] ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (address['phone'] != null &&
                                          address['phone'].isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.phone,
                                                size: 12,
                                                color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Text(
                                              address['phone'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                            ),
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

  void _navigateToAddAddress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddEditAddressScreen(),
      ),
    ).then((_) => _loadAddresses());
  }

  @override
  Widget build(BuildContext context) {
    final presenter = context.watch<AppPresenter>();
    final primary = Theme.of(context).primaryColor;

    if (_isLoadingAddresses) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show "Add Address Required" screen if no addresses
    if (_savedAddresses.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off,
                  size: 100,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 24),
                Text(
                  'No Delivery Address',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please add a delivery address\nto continue with your order',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _navigateToAddAddress,
                    icon: const Icon(Icons.add_location_alt),
                    label: const Text(
                      'Add Delivery Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Main checkout screen with selected address
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Delivery Address Section
          Row(
            children: [
              Icon(Icons.location_on, color: primary),
              const SizedBox(width: 8),
              const Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Selected Address Card
          InkWell(
            onTap: _showAddressSelector,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _selectedAddress!['label'] ?? 'Selected Address',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primary,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: primary),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    _selectedAddress!['fullAddress'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        _selectedAddress!['phone'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Payment Method Section
          Row(
            children: [
              Icon(Icons.payment, color: primary),
              const SizedBox(width: 8),
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPaymentOption(
            context,
            presenter,
            PaymentMethod.cod,
            'Cash on Delivery (COD)',
            'Pay when your order arrives',
            Icons.money,
          ),
          const SizedBox(height: 12),
          _buildPaymentOption(
            context,
            presenter,
            PaymentMethod.gcash,
            'GCash Online Payment',
            'Mock flow ready for payment gateway integration',
            Icons.account_balance_wallet,
          ),

          const SizedBox(height: 32),

          // Order Summary Section
          Row(
            children: [
              Icon(Icons.receipt_long, color: primary),
              const SizedBox(width: 8),
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                _buildSummaryRow('Subtotal', presenter.subtotal),
                const SizedBox(height: 12),
                _buildSummaryRow('Delivery Fee', presenter.deliveryFee),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    PriceText(
                      presenter.total,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Place Order Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: presenter.isBusy
                  ? null
                  : () async {
                      // Get user name from Firebase
                      final user = FirebaseAuth.instance.currentUser;
                      final userName = user?.displayName ?? 'Customer';

                      final error = await presenter.placeOrder(
                        name: userName,
                        phone: _selectedAddress!['phone'] ?? '',
                        address: _selectedAddress!['fullAddress'] ?? '',
                      );

                      if (!context.mounted) return;

                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      } else {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          OrderConfirmationScreen.route,
                          (route) => route.settings.name == '/menu',
                        );
                      }
                    },
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
                      'Place Order',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context,
    AppPresenter presenter,
    PaymentMethod method,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = presenter.paymentMethod == method;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.05)
            : Colors.white,
      ),
      child: RadioListTile<PaymentMethod>(
        value: method,
        groupValue: presenter.paymentMethod,
        onChanged: (value) => presenter.setPaymentMethod(value!),
        title: Row(
          children: [
            Icon(icon,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
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