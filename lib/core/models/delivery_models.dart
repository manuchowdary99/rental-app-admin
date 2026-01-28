import 'package:cloud_firestore/cloud_firestore.dart';

enum DeliveryLegType {
  pickupFromOwner('PICKUP_FROM_OWNER'),
  returnToOwner('RETURN_TO_OWNER');

  final String value;
  const DeliveryLegType(this.value);

  static DeliveryLegType? from(String? raw) {
    if (raw == null) return null;
    return values.firstWhere(
      (type) => type.value == raw,
      orElse: () => DeliveryLegType.pickupFromOwner,
    );
  }
}

class DeliveryPhotoSet {
  final Map<String, String> urls;

  const DeliveryPhotoSet({this.urls = const {}});

  factory DeliveryPhotoSet.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const DeliveryPhotoSet();
    }

    return DeliveryPhotoSet(
      urls: data.map((key, value) => MapEntry(key, value as String)),
    );
  }
}

class DamageLogEntry {
  final String severity;
  final String location;
  final String description;
  final List<String> photos;

  const DamageLogEntry({
    required this.severity,
    required this.location,
    required this.description,
    this.photos = const [],
  });

  factory DamageLogEntry.fromMap(Map<String, dynamic> data) {
    return DamageLogEntry(
      severity: (data['severity'] as String? ?? 'unknown').trim(),
      location: (data['location'] as String? ?? 'unspecified').trim(),
      description: (data['description'] as String? ?? '').trim(),
      photos: List<String>.from(data['photos'] ?? const []),
    );
  }
}

class DeliveryLeg {
  final DeliveryLegType type;
  final String partnerId;
  final Timestamp? timestamp;
  final double? latitude;
  final double? longitude;
  final DeliveryPhotoSet photos;
  final String damageDescription;

  const DeliveryLeg({
    required this.type,
    required this.partnerId,
    this.timestamp,
    this.latitude,
    this.longitude,
    this.photos = const DeliveryPhotoSet(),
    this.damageDescription = '',
  });

  factory DeliveryLeg.fromMap(
      DeliveryLegType legType, Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};

    return DeliveryLeg(
      type: legType,
      partnerId: map['partnerId'] as String? ?? '',
      timestamp: map['timestamp'] as Timestamp?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      photos: DeliveryPhotoSet.fromMap(map['photos'] as Map<String, dynamic>?),
      damageDescription: map['damageDescription'] as String? ?? '',
    );
  }
}

class PenaltyInfo {
  final double amount;
  final String reason;
  final String? status; // pending, approved, rejected
  final String? decidedBy;
  final Timestamp? decidedAt;

  const PenaltyInfo({
    required this.amount,
    required this.reason,
    this.status,
    this.decidedBy,
    this.decidedAt,
  });

  bool get hasAmount => amount > 0;

  factory PenaltyInfo.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const PenaltyInfo(amount: 0, reason: '');
    }

    return PenaltyInfo(
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      reason: data['reason'] as String? ?? '',
      status: data['status'] as String?,
      decidedBy: data['decidedBy'] as String?,
      decidedAt: data['decidedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'reason': reason,
      if (status != null) 'status': status,
      if (decidedBy != null) 'decidedBy': decidedBy,
      if (decidedAt != null) 'decidedAt': decidedAt,
    };
  }
}

class DeliveryRecord {
  final String id;
  final String orderId;
  final String itemName;
  final bool readyForAdminReview;
  final DeliveryLeg? pickupLeg;
  final DeliveryLeg? returnLeg;
  final List<DamageLogEntry> damageLogs;
  final PenaltyInfo penalty;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const DeliveryRecord({
    required this.id,
    required this.orderId,
    required this.itemName,
    required this.readyForAdminReview,
    this.pickupLeg,
    this.returnLeg,
    this.damageLogs = const [],
    this.penalty = const PenaltyInfo(amount: 0, reason: ''),
    this.createdAt,
    this.updatedAt,
  });

  bool get hasBothLegs => pickupLeg != null && returnLeg != null;

  factory DeliveryRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return DeliveryRecord(
      id: doc.id,
      orderId: data['orderId'] as String? ?? '',
      itemName: data['itemName'] as String? ?? 'Unknown item',
      readyForAdminReview: data['readyForAdminReview'] as bool? ?? false,
      pickupLeg: data.containsKey('delivery1')
          ? DeliveryLeg.fromMap(
              DeliveryLegType.pickupFromOwner,
              data['delivery1'] as Map<String, dynamic>?,
            )
          : null,
      returnLeg: data.containsKey('delivery2')
          ? DeliveryLeg.fromMap(
              DeliveryLegType.returnToOwner,
              data['delivery2'] as Map<String, dynamic>?,
            )
          : null,
      damageLogs: List<Map<String, dynamic>>.from(
        data['damageLogs'] ?? const [],
      ).map(DamageLogEntry.fromMap).toList(),
      penalty: PenaltyInfo.fromMap(data['penalty'] as Map<String, dynamic>?),
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }
}
