import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/delivery_models.dart';
import '../../../core/widgets/admin_widgets.dart';
import '../providers/delivery_providers.dart';

class DeliveryManagementScreen extends ConsumerStatefulWidget {
  const DeliveryManagementScreen({super.key});

  @override
  ConsumerState<DeliveryManagementScreen> createState() =>
      _DeliveryManagementScreenState();
}

class _DeliveryManagementScreenState
    extends ConsumerState<DeliveryManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final deliveriesAsync = ref.watch(deliveriesForReviewProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6EE),
      body: SafeArea(
        child: deliveriesAsync.when(
          data: (deliveries) {
            if (deliveries.isEmpty) {
              return const Center(
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No deliveries pending review',
                  subtitle:
                      'Drivers will appear here once they mark jobs ready',
                ),
              );
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(deliveries)),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final record = deliveries[index];
                      return _DeliveryCard(record: record);
                    },
                    childCount: deliveries.length,
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: EmptyState(
              icon: Icons.error_outline,
              title: 'Unable to load deliveries',
              subtitle: error.toString(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(List<DeliveryRecord> deliveries) {
    final awaitingReturn =
        deliveries.where((d) => d.returnLeg?.timestamp == null).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF781C2E), Color(0xFF5A1521)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delivery_dining_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Delivery Reviews',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Compare pickup vs return proofs before payouts',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Ready for review',
                  value: deliveries.length.toString(),
                  icon: Icons.rule_folder_outlined,
                  color: const Color(0xFF781C2E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Awaiting return proofs',
                  value: awaitingReturn.toString(),
                  icon: Icons.pending_actions_outlined,
                  color: const Color(0xFF8B2635),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.record});

  final DeliveryRecord record;

  @override
  Widget build(BuildContext context) {
    final pickup = record.pickupLeg;
    final drop = record.returnLeg;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: AdminCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.itemName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Order • ${record.orderId}'),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    record.readyForAdminReview ? 'Pending' : 'In progress',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _LegSummary(title: 'Pickup from owner', leg: pickup),
            const Divider(height: 32),
            _LegSummary(title: 'Return to owner', leg: drop),
            const SizedBox(height: 16),
            if (record.damageLogs.isNotEmpty)
              _DamageList(entries: record.damageLogs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showDetails(context),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.95,
        child: _DeliveryDetailView(record: record),
      ),
    );
  }
}

class _LegSummary extends StatelessWidget {
  const _LegSummary({required this.title, required this.leg});

  final String title;
  final DeliveryLeg? leg;

  @override
  Widget build(BuildContext context) {
    if (leg == null) {
      return Text(
        '$title • Awaiting courier update',
        style: const TextStyle(color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _InfoChip(
              icon: Icons.person_pin_circle,
              text: leg!.partnerId.isEmpty ? 'Unassigned' : leg!.partnerId,
            ),
            if (leg!.timestamp != null)
              _InfoChip(
                icon: Icons.access_time,
                text: leg!.timestamp!.toDate().toLocal().toString(),
              ),
            if (leg!.latitude != null && leg!.longitude != null)
              _InfoChip(
                icon: Icons.location_on_outlined,
                text: '${leg!.latitude!.toStringAsFixed(4)}, '
                    '${leg!.longitude!.toStringAsFixed(4)}',
              ),
          ],
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _DamageList extends StatelessWidget {
  const _DamageList({required this.entries});

  final List<DamageLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Damage logs',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  entry.severity.toLowerCase() == 'critical'
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline,
                  color: entry.severity.toLowerCase() == 'critical'
                      ? Colors.red
                      : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.severity} • ${entry.location}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(entry.description),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DeliveryDetailView extends StatelessWidget {
  const _DeliveryDetailView({required this.record});

  final DeliveryRecord record;

  @override
  Widget build(BuildContext context) {
    final pickupPhotos = record.pickupLeg?.photos.urls ?? const {};
    final returnPhotos = record.returnLeg?.photos.urls ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery ${record.orderId}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _PhotoComparison(
              pickupPhotos: pickupPhotos, returnPhotos: returnPhotos),
          const SizedBox(height: 24),
          if (record.damageLogs.isNotEmpty)
            _DamageList(entries: record.damageLogs),
          const SizedBox(height: 24),
          if (record.penalty.hasAmount)
            _PenaltyBanner(penalty: record.penalty)
          else
            const Text('No penalty applied yet'),
        ],
      ),
    );
  }
}

class _PhotoComparison extends StatelessWidget {
  const _PhotoComparison({
    required this.pickupPhotos,
    required this.returnPhotos,
  });

  final Map<String, String> pickupPhotos;
  final Map<String, String> returnPhotos;

  @override
  Widget build(BuildContext context) {
    final keys = {
      ...pickupPhotos.keys,
      ...returnPhotos.keys,
    }.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photo evidence',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...keys.map(
          (key) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: _PhotoTile(
                    label: 'Pickup • $key',
                    url: pickupPhotos[key],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PhotoTile(
                    label: 'Return • $key',
                    url: returnPhotos[key],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.label, this.url});

  final String label;
  final String? url;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        AspectRatio(
          aspectRatio: 4 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: const Color(0xFFE2E8F0),
              child: url == null
                  ? const Center(child: Text('No photo'))
                  : Image.network(url!, fit: BoxFit.cover),
            ),
          ),
        ),
      ],
    );
  }
}

class _PenaltyBanner extends StatelessWidget {
  const _PenaltyBanner({required this.penalty});

  final PenaltyInfo penalty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Penalty',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text('Amount: ₹${penalty.amount.toStringAsFixed(2)}'),
          if (penalty.reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Reason: ${penalty.reason}'),
            ),
        ],
      ),
    );
  }
}
