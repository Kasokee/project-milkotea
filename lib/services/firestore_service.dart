import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../models/cart_item.dart';
import '../models/product.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -----------------------
  // Users
  // -----------------------
  Future<void> addUser(
    String userId,
    String name,
    String email,
    String phone,
    String password,
  ) async {
    String hashedPassword = sha256.convert(utf8.encode(password)).toString();

    await _db.collection('users').doc(userId).set({
      'name': name,
      'email': email,
      'phone': phone,
      'password': hashedPassword,
      'createdAt': FieldValue.serverTimestamp(),
      'addresses': [],
    });
  }

  // -----------------------
  // OTP Methods
  // -----------------------
  Future<void> createOtp(
    String userId, {
    required String method,
    required String contact,
  }) async {
    String otp = (Random().nextInt(900000) + 100000).toString();

    // 🔒 Hash OTP before storing
    final hashedOtp = sha256.convert(utf8.encode(otp)).toString();

    await _db.collection('otps').doc(userId).set({
      'otp': hashedOtp,
      'method': method,
      'contact': contact,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (method == 'email') {
      await _sendOtpEmail(contact, otp);
    } else {
      print('Send OTP $otp to phone $contact');
    }
  }

  Future<bool> verifyOtp(String userId, String enteredOtp) async {
    final docRef = _db.collection('otps').doc(userId);
    final doc = await docRef.get();
    if (!doc.exists) return false;

    final data = doc.data()!;
    final storedOtp = data['otp'] ?? '';
    final createdAt = data['createdAt'] as Timestamp?;

    if (createdAt == null) return false;

    final now = Timestamp.now();
    final diff = now.seconds - createdAt.seconds;

    // Expire after 5 minutes (300 seconds)
    if (diff > 300) {
      await docRef.delete();
      return false;
    }

    final hashedEntered = sha256.convert(utf8.encode(enteredOtp)).toString();
    final isValid = hashedEntered == storedOtp;

    if (isValid) {
      await docRef.delete(); // prevent OTP reuse
    }

    return isValid;
  }

  // Check if a user exists by email
    Future<bool> userExists(String email) async {
      final snapshot = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      return snapshot.docs.isNotEmpty;
    }

  Future<void> _sendOtpEmail(String email, String otp) async {
    const apiKey =
        'API_KEY';
    const senderEmail = 'frijholytz08@gmail.com';
    const senderName = 'MilkoTea Virac';

    final url = Uri.parse('https://api.brevo.com/v3/smtp/email');

    final headers = {
      'accept': 'application/json',
      'content-type': 'application/json',
      'api-key': apiKey,
    };


    // Enhanced HTML email template matching app design
    final htmlContent =
        '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MilkoTea OTP Verification</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: linear-gradient(135deg, #f5f5f5 0%, #ffffff 100%);
            padding: 20px;
        }
        .email-container {
            max-width: 600px;
            margin: 0 auto;
            background: white;
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
        }
        .header {
            background: linear-gradient(135deg, #6B4423 0%, #8B5A3C 100%);
            padding: 40px 30px;
            text-align: center;
        }
        .logo-circle {
            width: 80px;
            height: 80px;
            background: rgba(255, 255, 255, 0.2);
            border-radius: 50%;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 20px;
        }
        .logo-text {
            font-size: 36px;
            color: white;
        }
        .brand-name {
            font-size: 32px;
            font-weight: bold;
            color: white;
            margin: 0;
            letter-spacing: 1px;
        }
        .tagline {
            color: rgba(255, 255, 255, 0.9);
            font-size: 14px;
            margin-top: 8px;
        }
        .content {
            padding: 40px 30px;
        }
        .greeting {
            font-size: 24px;
            font-weight: bold;
            color: #333;
            margin-bottom: 16px;
        }
        .message {
            font-size: 16px;
            color: #666;
            line-height: 1.6;
            margin-bottom: 32px;
        }
        .otp-container {
            background: linear-gradient(135deg, #FFF3E0 0%, #FFE0B2 100%);
            border: 2px solid #6B4423;
            border-radius: 12px;
            padding: 32px;
            text-align: center;
            margin: 32px 0;
        }
        .otp-label {
            font-size: 14px;
            color: #6B4423;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 12px;
        }
        .otp-code {
            font-size: 48px;
            font-weight: bold;
            color: #6B4423;
            letter-spacing: 8px;
            font-family: 'Courier New', monospace;
            margin: 16px 0;
        }
        .otp-timer {
            font-size: 13px;
            color: #8B5A3C;
            margin-top: 12px;
        }
        .timer-icon {
            display: inline-block;
            margin-right: 4px;
        }
        .info-box {
            background: #F5F5F5;
            border-left: 4px solid #6B4423;
            padding: 16px 20px;
            border-radius: 8px;
            margin: 24px 0;
        }
        .info-box p {
            font-size: 14px;
            color: #666;
            line-height: 1.6;
            margin: 0;
        }
        .info-icon {
            color: #6B4423;
            margin-right: 8px;
        }
        .security-note {
            background: #FFF9C4;
            border-left: 4px solid #F9A825;
            padding: 16px 20px;
            border-radius: 8px;
            margin: 24px 0;
        }
        .security-note p {
            font-size: 13px;
            color: #666;
            line-height: 1.5;
            margin: 0;
        }
        .warning-icon {
            color: #F9A825;
            margin-right: 8px;
        }
        .footer {
            background: #F5F5F5;
            padding: 30px;
            text-align: center;
            border-top: 1px solid #E0E0E0;
        }
        .footer-text {
            font-size: 14px;
            color: #999;
            margin: 8px 0;
        }
        .social-links {
            margin: 20px 0;
        }
        .social-link {
            display: inline-block;
            width: 36px;
            height: 36px;
            background: #6B4423;
            border-radius: 50%;
            margin: 0 6px;
            text-align: center;
            line-height: 36px;
        }
        .divider {
            height: 1px;
            background: #E0E0E0;
            margin: 24px 0;
        }
        @media only screen and (max-width: 600px) {
            .email-container {
                border-radius: 0;
            }
            .content {
                padding: 30px 20px;
            }
            .otp-code {
                font-size: 36px;
                letter-spacing: 4px;
            }
            .greeting {
                font-size: 20px;
            }
        }
    </style>
</head>
<body>
    <div class="email-container">
        <!-- Header -->
        <div class="header">
            <div class="logo-circle">
                <span class="logo-text">☕</span>
            </div>
            <h1 class="brand-name">MilkoTea</h1>
            <p class="tagline">Virac, Catanduanes</p>
        </div>

        <!-- Content -->
        <div class="content">
            <h2 class="greeting">Verify Your Account</h2>
            <p class="message">
                Hello! We received a request to verify your MilkoTea account. 
                Use the code below to complete your verification.
            </p>

            <!-- OTP Box -->
            <div class="otp-container">
                <div class="otp-label">Your Verification Code</div>
                <div class="otp-code">$otp</div>
                <div class="otp-timer">
                    <span class="timer-icon">⏱</span>
                    This code expires in 5 minutes
                </div>
            </div>

            <!-- Info Box -->
            <div class="info-box">
                <p>
                    <strong style="color: #6B4423;">
                        <span class="info-icon">ℹ️</span> How to use this code:
                    </strong><br>
                    Enter this 6-digit code in the MilkoTea app to verify your account 
                    and start ordering your favorite milk tea drinks.
                </p>
            </div>

            <div class="divider"></div>

            <!-- Security Note -->
            <div class="security-note">
                <p>
                    <strong style="color: #F9A825;">
                        <span class="warning-icon">⚠️</span> Security Notice:
                    </strong><br>
                    If you didn't request this code, please ignore this email. 
                    Never share this code with anyone. MilkoTea staff will never ask 
                    for your verification code.
                </p>
            </div>

            <p class="message" style="margin-top: 32px; font-size: 14px;">
                Need help? Contact us at 
                <a href="mailto:support@milkotea.com" style="color: #6B4423; text-decoration: none;">
                    <strong>support@milkotea.com</strong>
                </a>
            </p>
        </div>

        <!-- Footer -->
        <div class="footer">
            <p class="footer-text">
                <strong style="color: #6B4423;">MilkoTea Virac</strong><br>
                Delivering happiness, one sip at a time
            </p>
            
            <div class="social-links">
                <!-- Facebook -->
                <a href="https://facebook.com/yourpage" class="social-link">
                    <img src="https://cdn-icons-png.flaticon.com/512/733/733547.png"
                         width="18" height="18"
                         style="margin-top:9px; border:0;" alt="Facebook">
                </a>

                <!-- Instagram -->
                <a href="https://instagram.com/yourpage" class="social-link">
                    <img src="https://cdn-icons-png.flaticon.com/512/2111/2111463.png"
                         width="18" height="18"
                         style="margin-top:9px; border:0;" alt="Instagram">
                </a>
            </div>

            <p class="footer-text" style="font-size: 12px;">
                © 2026 MilkoTea. All rights reserved.<br>
                Virac, Catanduanes, Philippines
            </p>
            
            <p class="footer-text" style="font-size: 11px; margin-top: 16px;">
                This is an automated message, please do not reply to this email.
            </p>
        </div>
    </div>
</body>
</html>
''';

    final body = jsonEncode({
      "sender": {"name": senderName, "email": senderEmail},
      "to": [
        {"email": email},
      ],
      "subject": "🔐 Your MilkoTea Verification Code - $otp",
      "htmlContent": htmlContent,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      print('OTP sent to $email');
    } else {
      print('Failed to send OTP: ${response.body}');
      throw Exception('Failed to send OTP');
    }
  }

  // -----------------------
  // Products
  // -----------------------
  Future<void> addProduct(
    String productId,
    String name,
    String description,
    double price,
    String category,
    String imageUrl,
    bool available,
  ) async {
    await _db.collection('products').doc(productId).set({
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image': imageUrl,
      'available': available,
    });
  }

  /// **New Method:** Fetch all products from Firestore
  Future<List<Product>> getProducts() async {
    try {
      final snapshot = await _db.collection('products').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final category = ProductCategory.values.firstWhere(
          (c) => c.name.toLowerCase() == (data['category'] ?? '').toLowerCase(),
          orElse: () => ProductCategory.classic,
        );
        return Product(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
          category: category,
          image: data['image'] ?? '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // -----------------------
  // Orders
  // -----------------------
  Future<void> addOrder(
    String orderId,
    String userId,
    String customerName,
    String customerPhone,
    String deliveryAddress,
    List<Map<String, dynamic>> items,
    double subtotal,
    double deliveryFee,
    double totalPrice,
    String paymentMethod,
    String status,
  ) async {
    await _db.collection('orders').doc(orderId).set({
      'userId': userId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'items': items,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'totalPrice': totalPrice,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // -----------------------
  // Cart
  // -----------------------
  Future<void> addToCart(
    String userId,
    List<Map<String, dynamic>> cartItems,
  ) async {
    final cartRef = _db.collection('cart').doc(userId);
    await cartRef.set({'items': cartItems});
  }

  Future<List<Map<String, dynamic>>> getCart(String userId) async {
    final doc = await _db.collection('cart').doc(userId).get();
    if (!doc.exists || doc['items'] == null) return [];
    return List<Map<String, dynamic>>.from(doc['items']);
  }
}

// -----------------------
// CART ITEM HELPER METHODS
// -----------------------
extension CartItemFirestore on CartItem {
  Map<String, dynamic> toMap() => {
    'productId': product.id,
    'productName': product.name,
    'price': product.price,
    'size': size.name,
    'sugarLevel': sugarLevel.name,
    'addOns': addOns.map((e) => e.name).toList(),
    'note': note,
    'quantity': quantity,
  };

  static CartItem fromMap(Map<String, dynamic> map) {
    final defaultCategory = ProductCategory.classic;

    final product = Product(
      id: map['productId'],
      name: map['productName'],
      description: '',
      price: (map['price'] as num).toDouble(),
      category: defaultCategory,
      image: '',
    );

    final size = DrinkSize.values.firstWhere(
      (e) => e.name == map['size'],
      orElse: () => DrinkSize.small,
    );
    final sugar = SugarLevel.values.firstWhere(
      (e) => e.name == map['sugarLevel'],
      orElse: () => SugarLevel.fifty,
    );

    final addOns = (map['addOns'] as List<dynamic>)
        .map((e) => AddOn.values.firstWhere((a) => a.name == e))
        .toList();

    return CartItem(
      product: product,
      size: size,
      sugarLevel: sugar,
      addOns: addOns,
      note: map['note'],
      quantity: map['quantity'],
    );
  }
}
