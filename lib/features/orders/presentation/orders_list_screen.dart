import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'order_detail_screen.dart';

class OrdersListScreen extends StatelessWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ordersRef = FirebaseFirestore.instance.collection('orders');

    return Scaffold(
      appBar: AppBar(title: const Text('Orders / Rentals')),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Order ID')),
                DataColumn(label: Text('Item ID')),
                DataColumn(label: Text('Lender ID')),
                DataColumn(label: Text('Borrower ID')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Expected Time')),
                DataColumn(label: Text('Tracking')),
                DataColumn(label: Text('Damage')),
                DataColumn(label: Text('Actions')),
              ],
              rows: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] as String? ?? 'placed';
                final expectedTs = data['expectedDeliveryTime'] as Timestamp?;
                final expectedStr =
                    expectedTs != null ? expectedTs.toDate().toString() : '-';
                final tracking = data['trackingInfo'] as String? ?? '';

                final damageScore = (data['damageScore'] as num?)?.toDouble();
                final damageLabel = data['damageLabel'] as String?;

                return DataRow(
                  cells: [
                    // Clickable order ID → detail page
                    DataCell(
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  OrderDetailScreen(orderId: doc.id),
                            ),
                          );
                        },
                        child: Text(doc.id),
                      ),
                    ),
                    DataCell(Text(data['itemId']?.toString() ?? '')),
                    DataCell(Text(data['lenderId']?.toString() ?? '')),
                    DataCell(Text(data['borrowerId']?.toString() ?? '')),
                    DataCell(Text(status)),
                    DataCell(Text(expectedStr)),
                    DataCell(Text(tracking.isEmpty ? '-' : tracking)),
                    DataCell(
                      Text(
                        damageScore != null
                            ? '${damageLabel ?? 'scored'} '
                              '(${damageScore.toStringAsFixed(2)})'
                            : 'No score',
                      ),
                    ),
                    DataCell(
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'set_time') {
                            final newTime = await _pickDateTime(context);
                            if (newTime != null) {
                              await ordersRef.doc(doc.id).update({
                                'expectedDeliveryTime':
                                    Timestamp.fromDate(newTime),
                              });
                            }
                          } else if (value.startsWith('status:')) {
                            final newStatus = value.split(':')[1];

                            // 1) update order status
                            await ordersRef.doc(doc.id).update({
                              'status': newStatus,
                            });

                            // 2) update linked item availability
                            final itemId = data['itemId'] as String?;
                            if (itemId != null && itemId.isNotEmpty) {
                              final itemsRef = FirebaseFirestore.instance
                                  .collection('items');

                              // active statuses -> rented, finished -> available
                              final itemStatus =
                                  (newStatus == 'completed' ||
                                          newStatus == 'cancelled')
                                      ? 'available'
                                      : 'rented';

                              await itemsRef
                                  .doc(itemId)
                                  .update({'status': itemStatus});
                            }
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'set_time',
                            child: Text('Set / Change Expected Time'),
                          ),
                          PopupMenuItem(
                            value: 'status:placed',
                            child: Text('Status: placed'),
                          ),
                          PopupMenuItem(
                            value: 'status:on_the_way',
                            child: Text('Status: on_the_way'),
                          ),
                          PopupMenuItem(
                            value: 'status:delivered',
                            child: Text('Status: delivered'),
                          ),
                          PopupMenuItem(
                            value: 'status:returned',
                            child: Text('Status: returned'),
                          ),
                          PopupMenuItem(
                            value: 'status:completed',
                            child: Text('Status: completed'),
                          ),
                          PopupMenuItem(
                            value: 'status:cancelled',
                            child: Text('Status: cancelled'),
                          ),
                        ],
                        child: const Icon(Icons.more_vert),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Future<DateTime?> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return null;

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
}
