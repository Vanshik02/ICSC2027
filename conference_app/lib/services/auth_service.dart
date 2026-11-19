import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current logged-in user
  User? get currentUser => _auth.currentUser;

  // Listen to authentication changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register a new attendee
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Registration failed');
    }
  }

  // Login
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Login failed');
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
