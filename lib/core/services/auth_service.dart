import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // ==========================
  // ADMIN EMAIL LOGIN
  // ==========================
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

  // ==========================
  // GOOGLE REDIRECT HANDLER
  // ==========================
  /// Call once on app start to finish a pending Google redirect sign‑in.
  Future<User?> handleGoogleRedirectIfNeeded() async {
    final result = await _auth.getRedirectResult();
    final user = result.user;
    if (user == null) return null;

    await _ensureAdminAccess(user);
    return user;
  }

  // ==========================
  // GOOGLE ADMIN LOGIN
  // ==========================
  /// Google sign‑in using redirect (avoids popup handler bug on some projects).
  Future<void> signInWithGoogleAsAdmin() async {
    final googleProvider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile');

    await _auth.signInWithRedirect(googleProvider);
  }

  // ==========================
  // ADMIN ACCESS CHECK
  // ==========================
  Future<void> _ensureAdminAccess(User user) async {
    final docRef = _db.collection('users').doc(user.uid);
    final doc = await docRef.get();

    // If admin user doc does not exist, deny access
    if (!doc.exists) {
      await _auth.signOut();
      throw Exception('Admin profile not found');
    }

    final data = doc.data() ?? {};

    final role = data['role'] as String? ?? 'normal';
    final status = data['status'] as String? ?? 'active';

    // Blocked users can't log in
    if (status == 'blocked') {
      await _auth.signOut();
      throw Exception('Your account has been blocked by admin');
    }

    // Only admins can enter admin panel
    if (role != 'admin') {
      await _auth.signOut();
      throw Exception('No admin access');
    }

    // Update last login time
    await docRef.update({
      'lastLoginAt': Timestamp.now(),
    });
  }

  // ==========================
  // NORMAL USER LOGIN
  // ==========================
  Future<User?> signInUser({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user == null) return null;

    await _createUserIfNotExists(user);
    await _checkUserBlocked(user);

    return user;
  }

  // ==========================
  // USER BLOCK CHECK
  // ==========================
  Future<void> _checkUserBlocked(User user) async {
    final docRef = _db.collection("users").doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) return;

    final data = doc.data()!;
    if (data["status"] == "blocked") {
      await _auth.signOut();
      throw Exception("Your account has been blocked by admin");
    }

    // Update last login
    await docRef.update({
      "lastLoginAt": Timestamp.now(),
    });
  }

  // ==========================
  // CREATE USER DOC
  // ==========================
  Future<void> _createUserIfNotExists(User user) async {
    final docRef = _db.collection("users").doc(user.uid);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set({
        "uid": user.uid,
        "email": user.email,
        "displayName": user.displayName ?? "User",

        "role": "normal",
        "status": "active",
        "kycStatus": "not_submitted",

        "createdAt": Timestamp.now(),
        "lastLoginAt": Timestamp.now(),

        "itemsListed": 0,
        "rentalsCount": 0,
        "rating": 0,
        "photoURL": null,
      });
    }
  }

  // ==========================
  // SIGN OUT
  // ==========================
  Future<void> signOut() => _auth.signOut();

  // ==========================
  // CREATE TEST ADMIN
  // ==========================
  Future<void> createTestAdmin() async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: 'admin@test.com',
        password: 'admin123',
      );

      if (cred.user != null) {
        await _db.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'email': 'admin@test.com',
          'displayName': 'Test Admin',

          'role': 'admin',
          'status': 'active',
          'kycStatus': 'approved',

          'createdAt': Timestamp.now(),
          'lastLoginAt': Timestamp.now(),
        });

        print('Test admin user created successfully!');
      }
    } catch (e) {
      print('Admin user might already exist or error: $e');
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
