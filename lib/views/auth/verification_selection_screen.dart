import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import 'otp_screen.dart';

class VerificationSelectionScreen extends StatefulWidget {
  final String userEmail;
  final String userPhone;

  const VerificationSelectionScreen({
    super.key,
    required this.userEmail,
    required this.userPhone,
  });

  @override
  State<VerificationSelectionScreen> createState() =>
      _VerificationSelectionScreenState();
}

class _VerificationSelectionScreenState
    extends State<VerificationSelectionScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _loadingType; // tracks which button is loading

  Future<void> _sendOtp(String type) async {
    setState(() => _loadingType = type);

    final String userId =
        type == 'email' ? widget.userEmail : widget.userPhone;

    try {
      // 🔥 Correct: let FirestoreService generate & send OTP
      await _firestoreService.createOtp(
        userId,
        method: type,
        contact: userId,
      );

      if (!mounted) return;
      setState(() => _loadingType = null);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(userId: userId), // method: type
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingType = null);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send OTP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary.withOpacity(0.1), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_user_outlined,
                      size: 72,
                      color: primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  'Verify Your Account',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Choose how you\'d like to receive\nyour one-time verification code',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 15,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                _VerificationOptionCard(
                  icon: Icons.email_outlined,
                  title: 'Email Address',
                  subtitle: _maskEmail(widget.userEmail),
                  isLoading: _loadingType == 'email',
                  isDisabled: _loadingType != null && _loadingType != 'email',
                  onTap: () => _sendOtp('email'),
                ),
                const SizedBox(height: 16),

                _VerificationOptionCard(
                  icon: Icons.sms_outlined,
                  title: 'Phone Number',
                  subtitle: _maskPhone(widget.userPhone),
                  isLoading: _loadingType == 'sms',
                  isDisabled: _loadingType != null && _loadingType != 'sms',
                  onTap: () => _sendOtp('sms'),
                ),

                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'A 6-digit OTP code will be sent to your chosen contact. '
                          'The code expires in 5 minutes.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.5,
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
      ),
    );
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return '---';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    final visible = name.length > 1 ? name[0] : name;
    return '$visible${'*' * (name.length - 1)}@$domain';
  }

  String _maskPhone(String phone) {
    if (phone.length < 4) return '---';
    final last4 = phone.substring(phone.length - 4);
    final masked = '*' * (phone.length - 4);
    return '$masked$last4';
  }
}

class _VerificationOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onTap;

  const _VerificationOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Opacity(
      opacity: isDisabled ? 0.6 : 1,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primary.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[500]),
            ],
          ),
        ),
      ),
    );
  }
}
