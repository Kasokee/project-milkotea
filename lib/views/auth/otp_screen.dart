import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/firestore_service.dart';
import '../product_menu_screen.dart';
import 'dart:async';

class OtpScreen extends StatefulWidget {
  final String userId;

  const OtpScreen({super.key, required this.userId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _resendSeconds = 60;
  Timer? _timer;

  final FirestoreService _firestoreService = FirestoreService();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── Timer ──────────────────────────────────────────────────────────────────

  void _startResendTimer() {
    _resendSeconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          t.cancel();
        }
      });
    });
  }

  // ── OTP helpers ────────────────────────────────────────────────────────────

  String get _otpValue => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});

    // Auto-submit when all 6 digits are filled
    if (_otpValue.length == 6) {
      _focusNodes[index].unfocus();
      _verifyOtp();
    }
  }

  void _onKeyDown(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      setState(() {});
    }
  }

  void _tryPaste(String pasted) {
    final digits = pasted.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 6) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = digits[i];
      }
      _focusNodes[5].unfocus();
      setState(() {});
      _verifyOtp();
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _verifyOtp() async {
    final otp = _otpValue;
    if (otp.length < 6) {
      _showSnackBar('Please enter all 6 digits', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final bool valid =
        await _firestoreService.verifyOtp(widget.userId, otp);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (valid) {
      _showSnackBar('Verification successful!', isError: false);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ProductMenuScreen()),
        (route) => false,
      );
    } else {
      _showSnackBar('Invalid or expired OTP. Please try again.', isError: true);
      for (final c in _controllers) c.clear();
      setState(() {});
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0 || _isResending) return;
    setState(() => _isResending = true);

    // TODO: hook into your FirestoreService resend logic
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isResending = false);
    _startResendTimer();
    _showSnackBar('A new OTP has been sent.', isError: false);
  }

  void _showSnackBar(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final allFilled = _otpValue.length == 6;

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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Back button ──────────────────────────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Icon ─────────────────────────────────────────────────
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_read_outlined,
                      size: 72,
                      color: primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Heading ───────────────────────────────────────────────
                Text(
                  'Enter OTP Code',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'We sent a 6-digit verification code\nto your contact. Enter it below.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 15,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // ── 6 digit boxes ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) => _buildDigitBox(i, primary)),
                ),
                const SizedBox(height: 12),

                Center(
                  child: Text(
                    'Paste a copied code and it fills automatically',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ),
                const SizedBox(height: 36),

                // ── Verify button ─────────────────────────────────────────
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: (_isLoading || !allFilled) ? null : _verifyOtp,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Verify OTP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Resend row ────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code?  ",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    if (_resendSeconds > 0)
                      Text(
                        'Resend in ${_resendSeconds}s',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      )
                    else if (_isResending)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primary,
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _resendOtp,
                        child: Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                            decorationColor: primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 36),

                // ── Info note ─────────────────────────────────────────────
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
                          'The OTP code expires in 5 minutes. '
                          "If you didn't receive a code, check your spam "
                          'folder or tap Resend OTP.',
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
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Single digit box ───────────────────────────────────────────────────────

  Widget _buildDigitBox(int index, Color primary) {
    final isFilled = _controllers[index].text.isNotEmpty;

    return SizedBox(
      width: 46,
      height: 58,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) => _onKeyDown(index, event),
        child: TextFormField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primary,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor:
                isFilled ? primary.withOpacity(0.08) : Colors.grey[50],
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isFilled ? primary.withOpacity(0.6) : Colors.grey[300]!,
                width: isFilled ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primary, width: 2),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (val) {
            // Handle paste: if 6 chars land in one box at once
            if (val.length > 1) {
              _controllers[index].text = val[0];
              _tryPaste(val);
              return;
            }
            _onDigitChanged(index, val);
          },
        ),
      ),
    );
  }
}