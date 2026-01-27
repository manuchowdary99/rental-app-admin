import 'package:cloud_firestore/cloud_firestore.dart';

class UserSubscription {
  const UserSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.planName,
    required this.billingCycle,
    required this.status,
    required this.price,
    required this.currency,
    required this.autoRenew,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.startedAt,
    this.renewsAt,
    this.canceledAt,
    this.cancelReason,
  });

  final String id;
  final String userId;
  final String planId;
  final String planName;
  final String billingCycle; // monthly or yearly
  final String status; // active, canceled, expired
  final int price;
  final String currency;
  final bool autoRenew;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final Timestamp? startedAt;
  final Timestamp? renewsAt;
  final Timestamp? canceledAt;
  final String? cancelReason;

  bool get isActive => status == 'active';
  bool get isCanceled => status == 'canceled';
  bool get isExpired => status == 'expired';

  factory UserSubscription.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserSubscription(
      id: doc.id,
      userId: (data['userId'] ?? doc.id).toString(),
      planId: (data['planId'] ?? data['subscriptionTier'] ?? '').toString(),
      planName: (data['planName'] ??
              data['subscriptionTier'] ??
              data['planId'] ??
              'Unknown Plan')
          .toString(),
      billingCycle: (data['billingCycle'] ??
              data['subscriptionCycle'] ??
              data['subscriptionDuration'] ??
              'monthly')
          .toString(),
      status:
          (data['status'] ?? data['subscriptionStatus'] ?? 'active').toString(),
      price: _readPrice(
        data['price'] ?? data['amount'] ?? data['subscriptionAmount'],
      ),
      currency: (data['currency'] ?? data['subscriptionCurrency'] ?? 'INR')
          .toString(),
      autoRenew: data['autoRenew'] != false,
      userName: data['userName']?.toString() ?? data['user_name']?.toString(),
      userEmail: data['userEmail']?.toString() ?? data['email']?.toString(),
      userPhone: data['userPhone']?.toString() ?? data['phone']?.toString(),
      startedAt: data['startedAt'] is Timestamp
          ? data['startedAt'] as Timestamp
          : data['startDate'] is Timestamp
              ? data['startDate'] as Timestamp
              : data['subscriptionStart'] is Timestamp
                  ? data['subscriptionStart'] as Timestamp
                  : null,
      renewsAt: data['subscriptionExpiry'] is Timestamp
          ? data['subscriptionExpiry'] as Timestamp
          : data['expiryDate'] is Timestamp
              ? data['expiryDate'] as Timestamp
              : data['renewsAt'] is Timestamp
                  ? data['renewsAt'] as Timestamp
                  : null,
      canceledAt: data['canceledAt'] is Timestamp
          ? data['canceledAt'] as Timestamp
          : null,
      cancelReason: data['cancelReason']?.toString(),
    );
  }

  UserSubscription copyWith({
    String? id,
    String? userId,
    String? planId,
    String? planName,
    String? billingCycle,
    String? status,
    int? price,
    String? currency,
    bool? autoRenew,
    String? userName,
    String? userEmail,
    String? userPhone,
    Timestamp? startedAt,
    Timestamp? renewsAt,
    Timestamp? canceledAt,
    String? cancelReason,
  }) {
    return UserSubscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      billingCycle: billingCycle ?? this.billingCycle,
      status: status ?? this.status,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      autoRenew: autoRenew ?? this.autoRenew,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      startedAt: startedAt ?? this.startedAt,
      renewsAt: renewsAt ?? this.renewsAt,
      canceledAt: canceledAt ?? this.canceledAt,
      cancelReason: cancelReason ?? this.cancelReason,
    );
  }

  static int _readPrice(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString()) ?? 0;
  }
}
