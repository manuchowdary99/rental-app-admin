import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RentalsManagementScreen extends StatefulWidget {
  const RentalsManagementScreen({super.key});

  @override
  State<RentalsManagementScreen> createState() =>
      _RentalsManagementScreenState();
}

class _RentalsManagementScreenState extends State<RentalsManagementScreen> {
  String selectedFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final rentalsRef = FirebaseFirestore.instance.collection('rentals');

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6EE),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _filters(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: rentalsRef
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Failed to load rentals'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allRentals = snapshot.data!.docs;

                  final filteredRentals = selectedFilter == 'ALL'
                      ? allRentals
                      : allRentals.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = (data['status'] ?? '')
                              .toString()
                              .toUpperCase();
                          return status == selectedFilter;
                        }).toList();

                  if (filteredRentals.isEmpty) {
                    return const Center(child: Text('No rentals found'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredRentals.length,
                    itemBuilder: (context, index) {
                      final doc = filteredRentals[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _rentalCard(context, doc.id, data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: const [
          Icon(Icons.assignment_rounded, color: Color(0xFF781C2E), size: 28),
          SizedBox(width: 12),
          Text(
            'Rentals Management',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ================= FILTER CHIPS =================

  Widget _filters() {
    final filters = ['ALL', 'REQUESTED', 'ACTIVE', 'COMPLETED', 'CANCELLED'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: filters.map((filter) {
            final isSelected = selectedFilter == filter;

            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    selectedFilter = filter;
                  });
                },
                selectedColor: const Color(0xFF781C2E),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF781C2E)
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ================= RENTAL CARD =================

  Widget _rentalCard(
    BuildContext context,
    String rentalId,
    Map<String, dynamic> rental,
  ) {
    final status = (rental['status'] ?? '').toString().toLowerCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _itemTitle(rental['itemId']),
            const SizedBox(height: 6),
            _renterName(rental['renterId']),
            const SizedBox(height: 12),
            _statusBadge(status),
            const SizedBox(height: 12),
            if (status == 'requested')
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      'Approve',
                      Colors.green,
                      () => _updateStatus(rentalId, rental['itemId'], 'active'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionButton(
                      'Reject',
                      Colors.red,
                      () => _updateStatus(
                        rentalId,
                        rental['itemId'],
                        'cancelled',
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ================= LOOKUPS =================

  Widget _itemTitle(String? itemId) {
    if (itemId == null) return const Text('Item: Unknown');

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('items').doc(itemId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text('Item: Loading...');
        }
        final item = snapshot.data!.data() as Map<String, dynamic>?;
        return Text(
          'Item: ${item?['title'] ?? 'Unknown Item'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        );
      },
    );
  }

  Widget _renterName(String? renterId) {
    if (renterId == null) return const Text('Renter: Unknown');

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(renterId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text('Renter: Loading...');
        }
        final user = snapshot.data!.data() as Map<String, dynamic>?;
        return Text('Renter: ${user?['displayName'] ?? 'Unknown User'}');
      },
    );
  }

  // ================= STATUS =================

  Widget _statusBadge(String status) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _statusColor(status),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // ================= ACTIONS =================

  Widget _actionButton(String text, Color color, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
      child: Text(text),
    );
  }

  Future<void> _updateStatus(
    String rentalId,
    String? itemId,
    String newStatus,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    batch.update(
      FirebaseFirestore.instance.collection('rentals').doc(rentalId),
      {'status': newStatus, 'updatedAt': FieldValue.serverTimestamp()},
    );

    if (itemId != null) {
      batch.update(FirebaseFirestore.instance.collection('items').doc(itemId), {
        'status': newStatus == 'active' ? 'rented' : 'available',
      });
    }

    await batch.commit();
  }
}
