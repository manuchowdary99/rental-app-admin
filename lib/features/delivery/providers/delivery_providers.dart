import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/delivery_models.dart';
import '../../../core/services/delivery_repository.dart';

final deliveriesForReviewProvider = StreamProvider<List<DeliveryRecord>>((ref) {
  final repo = ref.watch(deliveryRepositoryProvider);
  return repo.watchDeliveriesForReview();
});

final deliveryDetailProvider = StreamProvider.family<DeliveryRecord?, String>(
  (ref, deliveryId) {
    final repo = ref.watch(deliveryRepositoryProvider);
    return repo.watchDeliveryById(deliveryId);
  },
);
