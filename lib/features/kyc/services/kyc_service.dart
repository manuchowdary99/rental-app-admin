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
        .map((snapshot) =>
            snapshot.docs.map((doc) => KycRequest.fromDoc(doc)).toList());
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
}
