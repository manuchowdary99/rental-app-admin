import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/delivery_models.dart';

class DeliveryRepository {
  DeliveryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('deliveries');

  Stream<List<DeliveryRecord>> watchDeliveriesForReview(
      {bool onlyReady = true}) {
    Query<Map<String, dynamic>> query = _collection.orderBy(
      'updatedAt',
      descending: true,
    );

    if (onlyReady) {
      query = query.where('readyForAdminReview', isEqualTo: true);
    }

    return query.limit(100).snapshots().map(
          (snapshot) =>
              snapshot.docs.map(DeliveryRecord.fromDoc).toList(growable: false),
        );
  }

  Stream<DeliveryRecord?> watchDeliveryById(String deliveryId) {
    return _collection.doc(deliveryId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return DeliveryRecord.fromDoc(doc);
    });
  }

  Future<void> updatePenalty({
    required String deliveryId,
    required PenaltyInfo penalty,
  }) async {
    final penaltyMap = penalty.toMap()
      ..['updatedAt'] = FieldValue.serverTimestamp();

    await _collection.doc(deliveryId).update({
      'penalty': penaltyMap,
    });
  }

  Future<void> markReviewCompleted({
    required String deliveryId,
    required bool reviewComplete,
  }) async {
    await _collection.doc(deliveryId).update({
      'readyForAdminReview': !reviewComplete,
      'reviewCompletedAt': FieldValue.serverTimestamp(),
    });
  }
}

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return DeliveryRepository(FirebaseFirestore.instance);
});
