import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/kyc_request.dart';

enum KycStatusFilter { all, pending, approved, rejected }

class KycService {
  KycService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _kycCollection =>
      _firestore.collection('kyc');
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  Stream<List<KycRequest>> watchAllRequests() {
    return _kycCollection
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final enriched = await Future.wait(
        snapshot.docs.map((doc) async {
          final request = KycRequest.fromDoc(doc);
          return _attachUserProfile(request);
        }),
      );
      return enriched;
    });
  }

  Stream<int> pendingCountStream() {
    return _kycCollection
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Future<void> approve(KycRequest request) async {
    final adminId = _auth.currentUser?.uid;
    final now = Timestamp.now();
    final batch = _firestore.batch();

    final kycDoc = _kycCollection.doc(request.id);
    final approvalData = {
      'status': 'approved',
      'verifiedAt': now,
      'verifiedBy': adminId,
      'rejectionReason': null,
      'lastRejectedAt': null,
      'updatedAt': now,
      'estimatedApprovalTime': null,
    };

    batch.update(kycDoc, approvalData);

    final userDoc = _usersCollection.doc(request.userId);
    batch.update(userDoc, {
      'kycStatus': 'approved',
      'kycVerifiedAt': now,
    });

    await batch.commit();
  }

  Future<void> reject(KycRequest request, String reason) async {
    final now = Timestamp.now();
    final batch = _firestore.batch();

    final kycDoc = _kycCollection.doc(request.id);
    batch.update(kycDoc, {
      'status': 'rejected',
      'rejectionReason': reason,
      'lastRejectedAt': now,
      'verifiedAt': null,
      'verifiedBy': null,
      'updatedAt': now,
    });

    final userDoc = _usersCollection.doc(request.userId);
    batch.update(userDoc, {
      'kycStatus': 'rejected',
    });

    await batch.commit();
  }

  Future<KycRequest> _attachUserProfile(KycRequest request) async {
    final needsName = request.fullName?.trim().isEmpty ?? true;
    final needsEmail = request.email?.trim().isEmpty ?? true;
    final needsPhone = request.phone?.trim().isEmpty ?? true;
    final needsAddress = request.address?.trim().isEmpty ?? true;

    if (!(needsName || needsEmail || needsPhone || needsAddress)) {
      return request;
    }

    try {
      final userSnap = await _usersCollection.doc(request.userId).get();
      final data = userSnap.data();
      if (data == null) return request;

      String? pick(List<String> keys) {
        for (final key in keys) {
          final value = data[key];
          if (value == null) continue;
          final text = value.toString().trim();
          if (text.isNotEmpty) return text;
        }
        return null;
      }

      return request.copyWith(
        fullName: needsName
            ? pick(['displayName', 'fullName', 'name']) ?? request.fullName
            : request.fullName,
        email: needsEmail
            ? pick(['email', 'userEmail']) ?? request.email
            : request.email,
        phone: needsPhone
            ? pick(['phone', 'phoneNumber', 'mobile']) ?? request.phone
            : request.phone,
        address: needsAddress
            ? pick(['address', 'addressLine', 'address_line']) ??
                request.address
            : request.address,
      );
    } catch (_) {
      return request;
    }
  }
}
