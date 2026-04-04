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
        await _safeSignOut();
      } on FirebaseException catch (e) {
        yield AdminAuthState.error(
          e.message ?? 'Unable to verify admin access. Please try again.',
        );
      } catch (e) {
        yield AdminAuthState.error(
          e.toString().isNotEmpty
              ? e.toString()
              : 'Unable to verify admin access. Please try again.',
        );
      }
    }
  }

  // ================= ADMIN LOGIN =================

  Future<User?> signInAsAdmin({
    required String email,
    required String password,
  }) async {
    try {
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
        await _safeSignOut();
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      throw AdminAccessException(e.message ?? e.code);
    }
  }

  Future<void> sendAdminPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ================= GOOGLE =================

  Future<User?> handleGoogleRedirectIfNeeded() async {
    final result = await _auth.getRedirectResult();
    final user = result.user;
    if (user == null) return null;

    try {
      await _ensureAdminAccess(user);
      return user;
    } on AdminAccessException {
      await _safeSignOut();
      rethrow;
    }
  }

  Future<void> signInWithGoogleAsAdmin() async {
    final googleProvider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile');

    await _auth.signInWithRedirect(googleProvider);
  }

  // ================= ADMIN ACCESS =================

  Future<void> _ensureAdminAccess(User user) async {
    final docRef = _db.collection('users').doc(user.uid);
    final doc = await _getAdminProfileDoc(docRef);

    if (!doc.exists) {
      throw AdminAccessException('Admin profile not found');
    }

    final data = doc.data() ?? {};

    final role = (data['role'] ?? 'normal').toString().toLowerCase();
    final status = (data['status'] ?? 'active').toString().toLowerCase();
    final isAdminFlag = data['isAdmin'] == true;

    if (status == 'blocked') {
      throw AdminAccessException('Your account has been blocked');
    }

    final hasAdminRole = role == 'admin' || role == 'super_admin';
    final hasAdminEmail =
        (data['email']?.toString().trim().isNotEmpty == true) &&
            user.email != null &&
            data['email'].toString().toLowerCase() == user.email!.toLowerCase();

    if (!isAdminFlag && !hasAdminRole && !hasAdminEmail) {
      throw AdminAccessException('No admin access');
    }

    try {
      await docRef.set(
        {'lastLoginAt': Timestamp.now()},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getAdminProfileDoc(
    DocumentReference<Map<String, dynamic>> docRef,
  ) async {
    try {
      return await docRef.get(const GetOptions(source: Source.server));
    } on FirebaseException catch (firstError) {
      debugPrint('Admin profile server read failed: $firstError');

      // Fallback sequence for intermittent Firestore Web internal assertion.
      try {
        return await docRef.get();
      } on FirebaseException catch (secondError) {
        debugPrint('Admin profile default read failed: $secondError');
        try {
          return await docRef.get(const GetOptions(source: Source.cache));
        } on FirebaseException catch (thirdError) {
          debugPrint('Admin profile cache read failed: $thirdError');
          final msg = thirdError.message ??
              secondError.message ??
              firstError.message ??
              '';
          if (msg.toLowerCase().contains('internal assertion failed')) {
            throw AdminAccessException(
              'Firestore web cache error detected. Please hard refresh the browser (Ctrl+F5) and login again.',
            );
          }
          throw AdminAccessException(
            msg.isNotEmpty
                ? msg
                : 'Unable to read admin profile. Please try again.',
          );
        }
      }
    }
  }

  // ================= USER LOGIN =================

  Future<User?> signInUser({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);

    final user = cred.user;
    if (user == null) return null;

    await _createUserIfNotExists(user);
    await _checkUserBlocked(user);

    return user;
  }

  Future<void> _checkUserBlocked(User user) async {
    final doc = await _db.collection("users").doc(user.uid).get();
    if (!doc.exists) return;

    if (doc.data()?["status"] == "blocked") {
      await _safeSignOut();
      throw Exception("Account blocked");
    }

    await _db.collection("users").doc(user.uid).update({
      "lastLoginAt": Timestamp.now(),
    });
  }

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
      });
    }
  }

  // ================= CHANGE PASSWORD (FIX ERROR) =================

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user");

    final email = user.email;
    if (email == null) throw Exception("No email");

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);

    try {
      await _db.collection('users').doc(user.uid).set(
        {'passwordLastChangedAt': Timestamp.now()},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  // ================= SIGN OUT (FIX FREEZE) =================

  Future<void> signOut() async {
    await _safeSignOut();
  }

  Future<void> _safeSignOut() async {
    try {
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }
    } catch (e) {
      debugPrint("SignOut error: $e");
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
