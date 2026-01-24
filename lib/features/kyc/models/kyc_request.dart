import 'package:cloud_firestore/cloud_firestore.dart';

class KycRequest {
  KycRequest({
    required this.id,
    required this.userId,
    required this.status,
    this.fullName,
    this.email,
    this.phone,
    this.address,
    this.location,
    this.geoPoint,
    this.documentType,
    this.documentNumber,
    this.documentUrl,
    this.selfieUrl,
    this.completionStep,
    this.resubmissionCount,
    this.createdAt,
    this.submittedAt,
    this.updatedAt,
    this.verifiedAt,
    this.lastRejectedAt,
    this.rejectionReason,
  });

  final String id;
  final String userId;
  final String status;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? address;
  final Map<String, dynamic>? location;
  final GeoPoint? geoPoint;
  final String? documentType;
  final String? documentNumber;
  final String? documentUrl;
  final String? selfieUrl;
  final int? completionStep;
  final int? resubmissionCount;
  final Timestamp? createdAt;
  final Timestamp? submittedAt;
  final Timestamp? updatedAt;
  final Timestamp? verifiedAt;
  final Timestamp? lastRejectedAt;
  final String? rejectionReason;

  static const List<String> _fullNameFields = [
    'fullName',
    'full_name',
    'name',
    'displayName',
    'profile.fullName',
    'profile.name',
    'contact.name',
  ];

  static const List<String> _emailFields = [
    'email',
    'userEmail',
    'contact.email',
    'profile.email',
  ];

  static const List<String> _phoneFields = [
    'phone',
    'phoneNumber',
    'phone_number',
    'mobile',
    'mobileNumber',
    'contact.phone',
    'contact.mobile',
    'profile.phone',
  ];

  static const List<String> _addressFields = [
    'address',
    'addressLine',
    'address_line',
    'addressLine1',
    'address_line_1',
    'addressLine2',
    'address_line_2',
    'profile.address',
    'contact.address',
  ];

  factory KycRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final locationMap = _readLocationMap(data);

    return KycRequest(
      id: doc.id,
      userId: data['userId']?.toString() ?? doc.id,
      status: (data['status'] ?? 'pending').toString(),
      fullName: _readPreferredString(data, _fullNameFields) ??
          _combineNameParts(data),
      email: _readPreferredString(data, _emailFields),
      phone: _readPreferredString(data, _phoneFields),
      address: _readPreferredString(data, _addressFields) ??
          _composeAddressFromParts(data) ??
          _formatAddressFromLocation(locationMap),
      location: locationMap,
      geoPoint: _readGeoPoint(data),
      documentType: _readString(data, 'documentType'),
      documentNumber: _readString(data, 'documentNumber'),
      documentUrl: _readString(data, 'documentUrl'),
      selfieUrl: _readString(data, 'selfieUrl'),
      completionStep: _readInt(data, 'completionStep'),
      resubmissionCount: _readInt(data, 'resubmissionCount'),
      createdAt: _readTimestamp(data, 'createdAt'),
      submittedAt: _readTimestamp(data, 'submittedAt'),
      updatedAt: _readTimestamp(data, 'updatedAt'),
      verifiedAt: _readTimestamp(data, 'verifiedAt'),
      lastRejectedAt: _readTimestamp(data, 'lastRejectedAt'),
      rejectionReason: _readString(data, 'rejectionReason'),
    );
  }

  String get initials {
    final source = fullName?.trim().isNotEmpty == true
        ? fullName!
        : email?.trim().isNotEmpty == true
            ? email!
            : userId;
    final cleaned = source.trim();
    if (cleaned.isEmpty) return '?';
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
  }

  String get locationLabel {
    final trimmedAddress = address?.trim();
    if (trimmedAddress != null && trimmedAddress.isNotEmpty) {
      return trimmedAddress;
    }
    if (location?.isNotEmpty == true) {
      final city = location!['city'] ?? location!['district'];
      final state = location!['state'];
      final country = location!['country'];
      final formatted = [city, state, country]
          .where((value) => value != null && value.toString().trim().isNotEmpty)
          .map((value) => value.toString())
          .join(', ');
      if (formatted.isNotEmpty) return formatted;
    }
    if (geoPoint != null) {
      return 'Lat: ${geoPoint!.latitude.toStringAsFixed(4)}, '
          'Lng: ${geoPoint!.longitude.toStringAsFixed(4)}';
    }
    return 'Not provided';
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  KycRequest copyWith({
    String? id,
    String? userId,
    String? status,
    String? fullName,
    String? email,
    String? phone,
    String? address,
    Map<String, dynamic>? location,
    GeoPoint? geoPoint,
    String? documentType,
    String? documentNumber,
    String? documentUrl,
    String? selfieUrl,
    int? completionStep,
    int? resubmissionCount,
    Timestamp? createdAt,
    Timestamp? submittedAt,
    Timestamp? updatedAt,
    Timestamp? verifiedAt,
    Timestamp? lastRejectedAt,
    String? rejectionReason,
  }) {
    return KycRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      location: location ?? this.location,
      geoPoint: geoPoint ?? this.geoPoint,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      documentUrl: documentUrl ?? this.documentUrl,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      completionStep: completionStep ?? this.completionStep,
      resubmissionCount: resubmissionCount ?? this.resubmissionCount,
      createdAt: createdAt ?? this.createdAt,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      lastRejectedAt: lastRejectedAt ?? this.lastRejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  static String? _readString(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value?.toString();
  }

  static String? _readPreferredString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final raw = _readValueByPath(data, key);
      if (raw == null) continue;
      final value = raw.toString().trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  static dynamic _readValueByPath(Map<String, dynamic> data, String path) {
    if (!path.contains('.')) return data[path];
    final segments = path.split('.');
    dynamic current = data;
    for (final segment in segments) {
      if (current is Map<String, dynamic> && current.containsKey(segment)) {
        current = current[segment];
      } else if (current is Map && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return null;
      }
    }
    return current;
  }

  static String? _combineNameParts(Map<String, dynamic> data) {
    final first = _readPreferredString(
      data,
      ['firstName', 'first_name', 'givenName'],
    );
    final last = _readPreferredString(
      data,
      ['lastName', 'last_name', 'surname'],
    );
    final combined = [first, last]
        .where((part) => part != null && part!.trim().isNotEmpty)
        .map((part) => part!.trim())
        .join(' ');
    return combined.isNotEmpty ? combined : null;
  }

  static String? _composeAddressFromParts(Map<String, dynamic> data) {
    final segments = <String>[];

    void addSegment(List<String> keys) {
      final value = _readPreferredString(data, keys);
      if (value != null && value.trim().isNotEmpty) {
        segments.add(value.trim());
      }
    }

    addSegment(['addressLine1', 'address_line_1', 'street', 'street1']);
    addSegment(['addressLine2', 'address_line_2', 'street2']);
    addSegment(['landmark']);
    addSegment(['city', 'district', 'town']);
    addSegment(['state', 'province']);
    addSegment(['postalCode', 'zip', 'zipCode', 'pincode']);
    addSegment(['country']);

    if (segments.isEmpty) return null;
    return segments.join(', ');
  }

  static String? _formatAddressFromLocation(
    Map<String, dynamic>? location,
  ) {
    if (location == null || location.isEmpty) return null;
    final parts = [
      location['addressLine1'],
      location['addressLine2'],
      location['landmark'],
      location['city'] ?? location['district'],
      location['state'] ?? location['province'],
      location['postalCode'] ?? location['zip'] ?? location['pincode'],
      location['country'],
    ]
        .map((value) => value?.toString().trim())
        .where((value) => value != null && value!.isNotEmpty)
        .map((value) => value!)
        .toList();

    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  static int? _readInt(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static Timestamp? _readTimestamp(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is Timestamp) return value;
    return null;
  }

  static Map<String, dynamic>? _readLocationMap(Map<String, dynamic> data) {
    const locationKeys = [
      'userLocation',
      'location',
      'address',
      'addressDetails',
      'address_info',
    ];

    for (final key in locationKeys) {
      final raw = data[key];
      if (raw is GeoPoint) continue;
      if (raw is Map<String, dynamic>) {
        return Map<String, dynamic>.from(raw);
      }
      if (raw is Map) {
        return raw
            .map((entryKey, value) => MapEntry(entryKey.toString(), value));
      }
    }
    return null;
  }

  static GeoPoint? _readGeoPoint(Map<String, dynamic> data) {
    final potentialSources = [
      data['geoPoint'],
      data['geopoint'],
      data['coordinates'],
      data['userLocation'],
      data['location'],
    ];

    for (final source in potentialSources) {
      if (source is GeoPoint) return source;
      if (source is Map && source['geopoint'] is GeoPoint) {
        return source['geopoint'] as GeoPoint;
      }
      if (source is Map && source['geoPoint'] is GeoPoint) {
        return source['geoPoint'] as GeoPoint;
      }
    }
    return null;
  }
}
