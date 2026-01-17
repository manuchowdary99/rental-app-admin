import 'package:cloud_firestore/cloud_firestore.dart';

class KYC {
  final String userId;
  final String fullName;
  final String idType;
  final String idNumber;
  final String idImageUrl;
  final String selfieUrl;
  final String status;
  final Timestamp submittedAt;

  KYC({
    required this.userId,
    required this.fullName,
    required this.idType,
    required this.idNumber,
    required this.idImageUrl,
    required this.selfieUrl,
    required this.status,
    required this.submittedAt,
  });

  factory KYC.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return KYC(
      userId: data['userId'],
      fullName: data['fullName'],
      idType: data['idType'],
      idNumber: data['idNumber'],
      idImageUrl: data['idImageUrl'],
      selfieUrl: data['selfieUrl'],
      status: data['status'],
      submittedAt: data['submittedAt'],
    );
  }
}
