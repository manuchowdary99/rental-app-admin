import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/kyc.dart';

class KycService {
  final _firestore = FirebaseFirestore.instance.collection('kyc');

  // User submits KYC
  Future<void> submitKyc(KYC kyc) async {
    await _firestore.doc(kyc.userId).set({
      'userId': kyc.userId,
      'fullName': kyc.fullName,
      'idType': kyc.idType,
      'idNumber': kyc.idNumber,
      'idImageUrl': kyc.idImageUrl,
      'selfieUrl': kyc.selfieUrl,
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  // Admin views all KYC
  Stream<List<KYC>> get kycStream {
    return _firestore.snapshots().map(
      (snapshot) => snapshot.docs.map(KYC.fromFirestore).toList(),
    );
  }

  // Admin approves/rejects
  Future<void> updateStatus(String userId, String status) async {
    await _firestore.doc(userId).update({
      'status': status,
    });
  }
}
