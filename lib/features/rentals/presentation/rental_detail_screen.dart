import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RentalDetailScreen extends StatelessWidget {
  final String rentalId;

  const RentalDetailScreen({super.key, required this.rentalId});

  @override
  Widget build(BuildContext context) {
    final rentalsRef = FirebaseFirestore.instance.collection('rentals');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rental Details'),
        backgroundColor: const Color(0xFF781C2E),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: rentalsRef.doc(rentalId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _error('Error loading rental');
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final status = data['rentalStatus'] ?? 'requested';
          final itemId = data['itemId'] ?? '-';
          final renterId = data['renterId'] ?? '-';
          final lenderId = data['lenderId'] ?? '-';

          final startTs = data['startDate'] as Timestamp?;
          final endTs = data['endDate'] as Timestamp?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section(title: 'Status', child: _chip(status)),
                const SizedBox(height: 16),

                _section(
                  title: 'IDs',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row('Rental ID', rentalId),
                      _row('Item ID', itemId),
                      _row('Renter ID', renterId),
                      _row('Lender ID', lenderId),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _section(
                  title: 'Rental Period',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row(
                        'Start Date',
                        startTs != null ? startTs.toDate().toString() : '-',
                      ),
                      _row(
                        'End Date',
                        endTs != null ? endTs.toDate().toString() : '-',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _infoBox(
                  'Note',
                  'Rental status updates are managed from the Rentals Management screen.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _section({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('$label: $value', style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _chip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }

  Widget _infoBox(String title, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _error(String message) {
    return Center(
      child: Text(message, style: const TextStyle(color: Colors.red)),
    );
  }
}
