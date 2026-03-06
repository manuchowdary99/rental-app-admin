import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.code,
    required this.audience,
    required this.currency,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.active,
    this.description,
    this.sortIndex,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String code;
  final String audience; // lender, renter, all
  final String currency;
  final int monthlyPrice;
  final int yearlyPrice;
  final bool active;

  final String? description;
  final int? sortIndex;

  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  /// -------------------------
  /// PLAN HELPERS
  /// -------------------------

  bool get isFree => monthlyPrice == 0 && yearlyPrice == 0;

  bool get isPaid => !isFree;

  /// yearly savings compared to paying monthly
  int get yearlySavings {
    if (monthlyPrice == 0 || yearlyPrice == 0) return 0;
    return (monthlyPrice * 12) - yearlyPrice;
  }

  /// formatted display helpers
  String get monthlyLabel => "$currency $monthlyPrice / month";

  String get yearlyLabel => "$currency $yearlyPrice / year";

  /// -------------------------
  /// COPY WITH
  /// -------------------------

  SubscriptionPlan copyWith({
    String? id,
    String? name,
    String? code,
    String? audience,
    String? currency,
    int? monthlyPrice,
    int? yearlyPrice,
    bool? active,
    String? description,
    int? sortIndex,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      audience: audience ?? this.audience,
      currency: currency ?? this.currency,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      yearlyPrice: yearlyPrice ?? this.yearlyPrice,
      active: active ?? this.active,
      description: description ?? this.description,
      sortIndex: sortIndex ?? this.sortIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// -------------------------
  /// FIRESTORE → MODEL
  /// -------------------------

  factory SubscriptionPlan.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return SubscriptionPlan(
      id: doc.id,
      name: (data['name'] ?? 'Untitled Plan').toString(),
      code: (data['code'] ?? doc.id).toString(),
      audience: (data['audience'] ?? 'all').toString(),
      currency: (data['currency'] ?? 'INR').toString(),

      monthlyPrice:
          _readPrice(data['monthlyPrice'] ?? data['monthly_price']),

      yearlyPrice:
          _readPrice(data['yearlyPrice'] ?? data['yearly_price']),

      active: data['active'] != false,

      description: data['description']?.toString(),

      sortIndex: _readInt(data['sortIndex'] ?? data['sort_index']),

      createdAt:
          data['createdAt'] is Timestamp ? data['createdAt'] as Timestamp : null,

      updatedAt:
          data['updatedAt'] is Timestamp ? data['updatedAt'] as Timestamp : null,
    );
  }

  /// -------------------------
  /// MODEL → FIRESTORE
  /// -------------------------

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'audience': audience,
      'currency': currency,
      'monthlyPrice': monthlyPrice,
      'yearlyPrice': yearlyPrice,
      'active': active,
      'description': description,
      'sortIndex': sortIndex,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    }..removeWhere((key, value) => value == null);
  }

  /// -------------------------
  /// HELPERS
  /// -------------------------

  static int _readPrice(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is double) return value.round();

    return int.tryParse(value.toString()) ?? 0;
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    if (value is double) return value.round();

    return int.tryParse(value.toString());
  }
}

