import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<User?> signInAsAdmin({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;
    if (user == null) return null;
    await _ensureAdminAccess(user);
    return user;
  }

  // NEW: Google sign-in for web using popup
  Future<User?> signInWithGoogleAsAdmin() async {
    final googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');

    final cred = await _auth.signInWithPopup(googleProvider);
    final user = cred.user;
    if (user == null) return null;

    await _ensureAdminAccess(user);
    return user;
  }

  Future<void> _ensureAdminAccess(User user) async {
    final doc = await _db.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};
    final role = data['role'] as String? ?? 'user';
    final isBlocked = data['isBlocked'] as bool? ?? false;

    if (role != 'admin' || isBlocked) {
      await _auth.signOut();
      throw Exception('No admin access');
    }
  }

  Future<void> signOut() => _auth.signOut();
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
