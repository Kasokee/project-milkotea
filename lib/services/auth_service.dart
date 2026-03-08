import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Local user state
  String? _userId;
  String? _userName;
  String? _userEmail;
  bool _isAuthenticated = false;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Register new user
  Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      // Create user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update displayName in Firebase
      await credential.user?.updateDisplayName(name);
      await credential.user?.reload(); // Refresh user data

      // Update singleton state
      _userId = credential.user?.uid;
      _userName = name;
      _userEmail = email;
      _isAuthenticated = true;

      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'Email is already registered';
      } else if (e.code == 'weak-password') {
        return 'Password is too weak';
      } else {
        return e.message;
      }
    } catch (e) {
      return 'An error occurred. Please try again.';
    }
  }

  /// Login user
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Refresh user
      await credential.user?.reload();
      final currentUser = _auth.currentUser;

      // Update singleton state
      _userId = currentUser?.uid;
      _userName = currentUser?.displayName ?? email.split('@')[0];
      _userEmail = currentUser?.email;
      _isAuthenticated = true;

      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'User not found';
      } else if (e.code == 'wrong-password') {
        return 'Incorrect password';
      } else {
        return e.message;
      }
    } catch (e) {
      return 'An error occurred. Please try again.';
    }
  }

  /// Logout
  Future<void> logout() async {
    await _auth.signOut();
    _userId = null;
    _userName = null;
    _userEmail = null;
    _isAuthenticated = false;
  }

  /// Check auth status
  Future<bool> checkAuthStatus() async {
    final user = _auth.currentUser;
    if (user != null) {
      _userId = user.uid;
      _userName = user.displayName ?? user.email?.split('@')[0];
      _userEmail = user.email;
      _isAuthenticated = true;
      return true;
    }
    return false;
  }

  /// Send password reset email
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Failed to reset password';
    }
  }
}
