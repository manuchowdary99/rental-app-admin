import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminAuthStatus {
  unauthenticated,
  checking,
  authenticated,
  unauthorized,
  error,
}

class AdminAuthState {
  final AdminAuthStatus status;
  final User? user;
  final String? message;

  const AdminAuthState._(this.status, {this.user, this.message});

  const AdminAuthState.unauthenticated()
      : this._(AdminAuthStatus.unauthenticated);

  const AdminAuthState.checking(User user)
      : this._(AdminAuthStatus.checking, user: user);

  const AdminAuthState.authenticated(User user)
      : this._(AdminAuthStatus.authenticated, user: user);

  const AdminAuthState.unauthorized(String message)
      : this._(AdminAuthStatus.unauthorized, message: message);

  const AdminAuthState.error(String message)
      : this._(AdminAuthStatus.error, message: message);
}

class AdminAccessException implements Exception {
  final String message;

  AdminAccessException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Stream<AdminAuthState> adminAuthStateChanges() async* {
    await for (final user in _auth.authStateChanges()) {
      if (user == null) {
        yield const AdminAuthState.unauthenticated();
        continue;
      }

      yield AdminAuthState.checking(user);

      try {
        await _ensureAdminAccess(user);
        yield AdminAuthState.authenticated(user);
      } on AdminAccessException catch (e) {
        yield AdminAuthState.unauthorized(e.message);
        await _auth.signOut();
      } catch (_) {
        yield const AdminAuthState.error(
          'Unable to verify admin access. Please try again.',
        );
        await _auth.signOut();
      }
    }
  }

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

    try {
      await _ensureAdminAccess(user);
      return user;
    } on AdminAccessException {
      await _auth.signOut();
      rethrow;
    }
  }

  Future<void> sendAdminPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ==========================
  // GOOGLE REDIRECT HANDLER
  // ==========================
  /// Call once on app start to finish a pending Google redirect sign‑in.
  Future<User?> handleGoogleRedirectIfNeeded() async {
    final result = await _auth.getRedirectResult();
    final user = result.user;
    if (user == null) return null;

    try {
      await _ensureAdminAccess(user);
      return user;
    } on AdminAccessException {
      await _auth.signOut();
      rethrow;
    }
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
      throw AdminAccessException('Admin profile not found');
    }

    final data = doc.data() ?? {};

    final role = (data['role'] as String? ?? 'normal').toLowerCase().trim();
    final status = (data['status'] as String? ?? 'active').toLowerCase().trim();
    final isAdminFlag = data['isAdmin'] == true;

    // Blocked users can't log in
    if (status == 'blocked') {
      throw AdminAccessException('Your account has been blocked by admin');
    }

    // Only admins can enter admin panel
    final hasAdminRole = role == 'admin' || role == 'super_admin';
    if (!isAdminFlag && !hasAdminRole) {
      throw AdminAccessException('No admin access');
    }

    // Update last login time
    try {
      await docRef.set(
        {
          'lastLoginAt': Timestamp.now(),
        },
        SetOptions(merge: true),
      );
    } catch (e, stack) {
      debugPrint('Failed to update lastLoginAt for admin: $e');
      debugPrint(stack.toString());
    }
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
  // CHANGE PASSWORD
  // ==========================
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No authenticated admin user found.',
      );
    }

    final email = user.email;
    if (email == null) {
      throw FirebaseAuthException(
        code: 'no-email',
        message: 'Admin account does not have an email address.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);

    try {
      await _db.collection('users').doc(user.uid).set(
        {
          'passwordLastChangedAt': Timestamp.now(),
        },
        SetOptions(merge: true),
      );
    } catch (e, stack) {
      debugPrint('Failed to update password metadata: $e');
      debugPrint(stack.toString());
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

        debugPrint('Test admin user created successfully!');
      }
    } catch (e) {
      debugPrint('Admin user might already exist or error: $e');
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
