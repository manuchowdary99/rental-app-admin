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

  /// Call once on app start to finish a pending Google redirect sign‑in.
  Future<User?> handleGoogleRedirectIfNeeded() async {
    final result = await _auth.getRedirectResult();
    final user = result.user;
    if (user == null) return null;
    await _ensureAdminAccess(user);
    return user;
  }

  /// Google sign‑in using redirect (avoids popup handler bug on some projects).
  Future<void> signInWithGoogleAsAdmin() async {
    final googleProvider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile');

    await _auth.signInWithRedirect(googleProvider);
    // After redirect back to your app, handleGoogleRedirectIfNeeded()
    // will be called from your root widget to complete sign‑in.
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

  Future<void> createTestAdmin() async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: 'admin@test.com',
        password: 'admin123',
      );

      if (cred.user != null) {
        await _db.collection('users').doc(cred.user!.uid).set({
          'email': 'admin@test.com',
          'displayName': 'Test Admin',
          'role': 'admin',
          'isBlocked': false,
          'isTrusted': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('Test admin user created successfully!');
      }
    } catch (e) {
      print('Admin user might already exist or error: $e');
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
