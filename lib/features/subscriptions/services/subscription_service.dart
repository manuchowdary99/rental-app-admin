import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/subscription_plan.dart';
import '../models/user_subscription.dart';

class SubscriptionService {
  SubscriptionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _plansCollection =>
      _firestore.collection('plans');
  CollectionReference<Map<String, dynamic>> get _subscriptionsCollection =>
      _firestore.collection('subscriptions');
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection('notifications');

  static const List<Map<String, dynamic>> _defaultPlans = [
    {
      'id': 'basic',
      'name': 'Basic',
      'code': 'basic',
      'audience': 'all',
      'description': 'Free starter tier for browsing listings.',
      'currency': 'INR',
      'monthlyPrice': 0,
      'yearlyPrice': 0,
      'sortIndex': 0,
    },
    {
      'id': 'lender_pro',
      'name': 'Lender Pro',
      'code': 'lender_pro',
      'audience': 'lender',
      'description': 'Advanced listing tools for lenders.',
      'currency': 'INR',
      'monthlyPrice': 499,
      'yearlyPrice': 4999,
      'sortIndex': 1,
    },
    {
      'id': 'renter_plus',
      'name': 'Renter Plus',
      'code': 'renter_plus',
      'audience': 'renter',
      'description': 'Priority support and damage protection.',
      'currency': 'INR',
      'monthlyPrice': 299,
      'yearlyPrice': 2999,
      'sortIndex': 2,
    },
    {
      'id': 'pro_max',
      'name': 'Pro Max',
      'code': 'pro_max',
      'audience': 'renter',
      'description': 'All-inclusive coverage for power renters.',
      'currency': 'INR',
      'monthlyPrice': 699,
      'yearlyPrice': 6999,
      'sortIndex': 3,
    },
  ];

  Future<void> ensureDefaultPlans() async {
    final snapshot = await _plansCollection.get();
    final existingIds = snapshot.docs.map((doc) => doc.id).toSet();
    for (final plan in _defaultPlans) {
      if (existingIds.contains(plan['id'])) continue;
      final docRef = _plansCollection.doc(plan['id'] as String);
      await docRef.set({
        ...plan,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<List<SubscriptionPlan>> watchPlans() {
    return _plansCollection
        .orderBy('sortIndex', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SubscriptionPlan.fromDoc(doc)).toList());
  }

  Stream<List<UserSubscription>> watchSubscriptions() {
    return _subscriptionsCollection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final subscriptions =
          snapshot.docs.map((doc) => UserSubscription.fromDoc(doc)).toList();
      if (subscriptions.isEmpty) return [];
      final cache = <String, Map<String, dynamic>?>{};
      final enriched = await Future.wait(
        subscriptions.map(
          (subscription) => _attachUserProfile(subscription, cache),
        ),
      );
      return enriched;
    });
  }

  Future<void> upsertPlan(SubscriptionPlan plan) async {
    final docRef = plan.id.isNotEmpty
        ? _plansCollection.doc(plan.id)
        : plan.code.isNotEmpty
            ? _plansCollection.doc(plan.code)
            : _plansCollection.doc();

    final docSnapshot = await docRef.get();
    final data = {
      'name': plan.name,
      'code': plan.code.isNotEmpty ? plan.code : docRef.id,
      'audience': plan.audience,
      'currency': plan.currency,
      'monthlyPrice': plan.monthlyPrice,
      'yearlyPrice': plan.yearlyPrice,
      'active': plan.active,
      'description': plan.description,
      'sortIndex': plan.sortIndex ?? 0,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!docSnapshot.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await docRef.set(
      data,
      SetOptions(merge: true),
    );
  }

  Future<void> setPlanActive(String planId, bool isActive) {
    return _plansCollection.doc(planId).update({
      'active': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelSubscription(
    UserSubscription subscription, {
    String? reason,
  }) {
    return _subscriptionsCollection.doc(subscription.id).update({
      'status': 'canceled',
      'subscriptionStatus': 'canceled',
      'cancelReason': reason,
      'canceledAt': FieldValue.serverTimestamp(),
      'autoRenew': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'expiryDate': FieldValue.serverTimestamp(),
      'subscriptionExpiry': FieldValue.serverTimestamp(),
    });
  }

  Timestamp _computeExpiryDate(String billingCycle) {
    final now = DateTime.now();
    final duration = billingCycle == 'yearly'
        ? const Duration(days: 365)
        : const Duration(days: 30);
    return Timestamp.fromDate(now.add(duration));
  }

  Future<void> switchSubscriptionPlan({
    required UserSubscription subscription,
    required SubscriptionPlan newPlan,
    required String billingCycle,
  }) {
    final normalizedCycle = billingCycle == 'yearly' ? 'yearly' : 'monthly';
    final expiryDate = _computeExpiryDate(normalizedCycle);

    return _subscriptionsCollection.doc(subscription.id).update({
      'planId': newPlan.id,
      'planName': newPlan.name,
      'subscriptionTier': newPlan.id,
      'billingCycle': normalizedCycle,
      'status': 'active',
      'subscriptionStatus': 'active',
      'autoRenew': true,
      'currency': newPlan.currency,
      'updatedAt': FieldValue.serverTimestamp(),
      'expiryDate': expiryDate,
      'subscriptionExpiry': expiryDate,
    });
  }

  Future<int> expireOverdueSubscriptions() async {
    final now = Timestamp.fromDate(DateTime.now());
    final snapshots = await Future.wait([
      _subscriptionsCollection
          .where('subscriptionExpiry', isLessThan: now)
          .get(),
      _subscriptionsCollection.where('expiryDate', isLessThan: now).get(),
    ]);

    var updated = 0;
    final processedIds = <String>{};
    for (final snapshot in snapshots) {
      for (final doc in snapshot.docs) {
        if (!processedIds.add(doc.id)) continue;
        final data = doc.data();
        final status =
            (data['status'] ?? data['subscriptionStatus'] ?? 'active')
                .toString();
        if (status != 'active') continue;
        await doc.reference.update({
          'status': 'expired',
          'subscriptionStatus': 'expired',
          'autoRenew': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        updated++;
      }
    }
    return updated;
  }

  Future<void> expireSubscription(UserSubscription subscription) {
    return _subscriptionsCollection.doc(subscription.id).update({
      'status': 'expired',
      'subscriptionStatus': 'expired',
      'autoRenew': false,
      'expiryDate': FieldValue.serverTimestamp(),
      'subscriptionExpiry': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> enqueueExpiringNotification(
    UserSubscription subscription, {
    int? daysLeft,
  }) {
    final docId = 'subscription_${subscription.id}';
    final message = daysLeft != null && daysLeft >= 0
        ? 'Your ${subscription.planName} plan will expire in $daysLeft days.'
        : 'Your ${subscription.planName} plan is about to expire.';

    return _notificationsCollection.doc(docId).set(
      {
        'userId': subscription.userId,
        'subscriptionId': subscription.id,
        'planId': subscription.planId,
        'planName': subscription.planName,
        'status': subscription.status,
        'type': 'subscription_expiring',
        'message': message,
        'daysLeft': daysLeft,
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      },
      SetOptions(merge: true),
    );
  }

  Future<UserSubscription> _attachUserProfile(
    UserSubscription subscription,
    Map<String, Map<String, dynamic>?> cache,
  ) async {
    final hasName = subscription.userName?.trim().isNotEmpty == true;
    final hasEmail = subscription.userEmail?.trim().isNotEmpty == true;
    final hasPhone = subscription.userPhone?.trim().isNotEmpty == true;

    if (hasName && hasEmail && hasPhone) return subscription;

    Map<String, dynamic>? data;
    if (cache.containsKey(subscription.userId)) {
      data = cache[subscription.userId];
    } else {
      try {
        final doc = await _usersCollection.doc(subscription.userId).get();
        data = doc.data();
        cache[subscription.userId] = data;
      } catch (_) {
        cache[subscription.userId] = null;
        return subscription;
      }
    }

    if (data == null) return subscription;

    return subscription.copyWith(
      userName: hasName ? subscription.userName : _readUserName(data),
      userEmail: hasEmail ? subscription.userEmail : _readUserEmail(data),
      userPhone: hasPhone ? subscription.userPhone : _readUserPhone(data),
    );
  }

  String? _readUserName(Map<String, dynamic> data) {
    final profile = data['profile'];
    final profileName = profile is Map<String, dynamic>
        ? _stringValue(profile['fullName']) ??
            _stringValue(profile['displayName']) ??
            _stringValue(profile['name'])
        : null;

    final first = _stringValue(data['firstName']);
    final last = _stringValue(data['lastName']);
    final combined = [
      if (first != null) first,
      if (last != null) last,
    ];

    return _stringValue(data['displayName']) ??
        _stringValue(data['fullName']) ??
        _stringValue(data['name']) ??
        _stringValue(data['legalName']) ??
        profileName ??
        (combined.isNotEmpty ? combined.join(' ') : null);
  }

  String? _readUserEmail(Map<String, dynamic> data) {
    final profile = data['profile'];
    return _stringValue(data['email']) ??
        _stringValue(data['contactEmail']) ??
        (profile is Map<String, dynamic>
            ? _stringValue(profile['email'])
            : null);
  }

  String? _readUserPhone(Map<String, dynamic> data) {
    final profile = data['profile'];
    return _stringValue(data['phone']) ??
        _stringValue(data['phoneNumber']) ??
        _stringValue(data['contactNumber']) ??
        (profile is Map<String, dynamic>
            ? _stringValue(profile['phone'] ?? profile['phoneNumber'])
            : null);
  }

  String? _stringValue(dynamic value) {
    if (value == null) return null;
    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }
}
