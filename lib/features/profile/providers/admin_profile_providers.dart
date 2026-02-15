import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/admin_profile.dart';

final adminProfileServiceProvider = Provider<AdminProfileService>((ref) {
  return AdminProfileService(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

final adminProfileProvider = StreamProvider.autoDispose<AdminProfile>((ref) {
  final service = ref.watch(adminProfileServiceProvider);
  return service.watchProfile();
});

class AdminProfileService {
  AdminProfileService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<AdminProfile> watchProfile() {
    final uid = _requireUid();
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) => AdminProfile.fromDoc(snap));
  }

  Future<void> updateProfile(AdminProfileUpdateInput input) async {
    final uid = _requireUid();
    final payload = input.toMap()..['updatedAt'] = FieldValue.serverTimestamp();

    payload.removeWhere(
      (_, value) => value == null || (value is String && value.trim().isEmpty),
    );

    await _firestore.collection('users').doc(uid).set(
          payload,
          SetOptions(merge: true),
        );
  }

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('No authenticated admin user found.');
    }
    return uid;
  }
}

class AdminProfileUpdateInput {
  AdminProfileUpdateInput({
    required this.displayName,
    this.phoneNumber,
    this.title,
    this.bio,
    this.timezone,
  });

  final String displayName;
  final String? phoneNumber;
  final String? title;
  final String? bio;
  final String? timezone;

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'title': title,
      'bio': bio,
      'timezone': timezone,
    };
  }
}

class AdminProfileController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> save(AdminProfileUpdateInput input) async {
    final service = ref.read(adminProfileServiceProvider);
    try {
      state = const AsyncLoading();
      await service.updateProfile(input);
      state = const AsyncData(null);
    } catch (error, stack) {
      state = AsyncError(error, stack);
      rethrow;
    }
  }
}

final adminProfileControllerProvider =
    AutoDisposeAsyncNotifierProvider<AdminProfileController, void>(
  AdminProfileController.new,
);
