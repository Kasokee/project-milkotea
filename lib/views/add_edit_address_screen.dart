import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEditAddressScreen extends StatefulWidget {
  final Map<String, dynamic>? existingAddress;
  final int? addressIndex;

  const AddEditAddressScreen({
    super.key,
    this.existingAddress,
    this.addressIndex,
  });

  static const route = '/add-edit-address';

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _fullAddressController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isDefault = false;
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (widget.existingAddress != null) {
      _labelController.text = widget.existingAddress!['label'] ?? '';
      _fullAddressController.text = widget.existingAddress!['fullAddress'] ?? '';
      _phoneController.text = widget.existingAddress!['phone'] ?? '';
      _isDefault = widget.existingAddress!['isDefault'] ?? false;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _fullAddressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate() || _user == null) return;

    setState(() => _isLoading = true);

    try {
      // Get current addresses
      final userDoc = await _firestore.collection('users').doc(_user.uid).get();
      List<dynamic> addresses = [];
      
      if (userDoc.exists) {
        final data = userDoc.data();
        addresses = List.from(data?['addresses'] ?? []);
      }

      // Create new address object
      final newAddress = {
        'label': _labelController.text.trim(),
        'fullAddress': _fullAddressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'isDefault': _isDefault,
      };

      // If setting as default, unset all others
      if (_isDefault) {
        for (var addr in addresses) {
          addr['isDefault'] = false;
        }
      }

      // Add or update address
      if (widget.addressIndex != null) {
        // Update existing
        addresses[widget.addressIndex!] = newAddress;
      } else {
        // Add new
        addresses.add(newAddress);
      }

      // Save to Firestore
      await _firestore.collection('users').doc(_user.uid).set({
        'addresses': addresses,
      }, SetOptions(merge: true));

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.addressIndex != null
                ? 'Address updated successfully'
                : 'Address added successfully',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save address'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isEditing = widget.existingAddress != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Address' : 'Add New Address'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on,
                    size: 48,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Label field
              Text(
                'Address Label',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _labelController,
                decoration: InputDecoration(
                  hintText: 'e.g., Home, Office, Mom\'s House',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an address label';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Full address field
              Text(
                'Full Address',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fullAddressController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Street, Barangay, City, Province\nMust include Virac, Catanduanes',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.home_outlined),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter full address';
                  }
                  if (!value.toLowerCase().contains('virac')) {
                    return 'Address must include Virac, Catanduanes';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Phone field
              Text(
                'Contact Number',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'e.g., 09123456789',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter contact number';
                  }
                  if (value.trim().length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Set as default checkbox
              Container(
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primary.withOpacity(0.2)),
                ),
                child: CheckboxListTile(
                  value: _isDefault,
                  onChanged: (value) => setState(() => _isDefault = value ?? false),
                  title: const Text(
                    'Set as default address',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'This address will be used by default in checkout',
                    style: TextStyle(fontSize: 12),
                  ),
                  activeColor: primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _saveAddress,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isLoading
                        ? 'Saving...'
                        : isEditing
                            ? 'Update Address'
                            : 'Save Address',
                    style: const TextStyle(
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
              const SizedBox(height: 16),

              // Info note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Make sure your address is complete and accurate for smooth delivery.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}