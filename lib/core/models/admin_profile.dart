import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProfile {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final String status;
  final String? phoneNumber;
  final String? photoUrl;
  final String? title;
  final String? bio;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const AdminProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.status,
    this.phoneNumber,
    this.photoUrl,
    this.title,
    this.bio,
    this.createdAt,
    this.lastLoginAt,
  });

  factory AdminProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return AdminProfile(
      uid: doc.id,
      email: (data['email'] as String?)?.trim() ?? 'unknown@admin.com',
      displayName: (data['displayName'] as String?)?.trim() ?? 'Admin',
      role: (data['role'] as String?)?.trim() ?? 'admin',
      status: (data['status'] as String?)?.trim() ?? 'active',
      phoneNumber: (data['phoneNumber'] as String?)?.trim(),
      photoUrl: (data['photoURL'] as String?)?.trim(),
      title: (data['title'] as String?)?.trim(),
      bio: (data['bio'] as String?)?.trim(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  AdminProfile copyWith({
    String? displayName,
    String? phoneNumber,
    String? title,
    String? bio,
    String? photoUrl,
  }) {
    return AdminProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role,
      status: status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      title: title ?? this.title,
      bio: bio ?? this.bio,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }

  Map<String, dynamic> toUpdatePayload() {
    return {
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'title': title,
      'bio': bio,
      'photoURL': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }..removeWhere((_, value) => value == null);
  }

  bool get isSuperAdmin => role.toLowerCase().contains('super');
  bool get isSuspended => status.toLowerCase() == 'blocked';
}
