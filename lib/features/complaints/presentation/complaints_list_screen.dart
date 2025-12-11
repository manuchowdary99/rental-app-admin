import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ComplaintsListScreen extends StatelessWidget {
  const ComplaintsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final complaintsRef = FirebaseFirestore.instance.collection('complaints');

    return Scaffold(
      appBar: AppBar(title: const Text('Complaints / Reports')),
      body: StreamBuilder<QuerySnapshot>(
        stream: complaintsRef.orderBy('createdAt', descending: true).snapshots(),
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
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Reported By')),
                DataColumn(label: Text('Item ID')),
                DataColumn(label: Text('User ID')),
                DataColumn(label: Text('Order ID')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Description')),
                DataColumn(label: Text('Actions')),
              ],
              rows: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] as String? ?? 'open';

                return DataRow(
                  cells: [
                    DataCell(Text(doc.id)),
                    DataCell(Text(data['reportedBy']?.toString() ?? '')),
                    DataCell(Text(data['targetItemId']?.toString() ?? '-')),
                    DataCell(Text(data['targetUserId']?.toString() ?? '-')),
                    DataCell(Text(data['orderId']?.toString() ?? '-')),
                    DataCell(Text(status)),
                    DataCell(
                      SizedBox(
                        width: 250,
                        child: Text(
                          data['description']?.toString() ?? '',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          await complaintsRef.doc(doc.id).update({
                            'status': value,
                          });
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'open',
                            child: Text('Mark as Open'),
                          ),
                          PopupMenuItem(
                            value: 'in_review',
                            child: Text('Mark as In Review'),
                          ),
                          PopupMenuItem(
                            value: 'resolved',
                            child: Text('Mark as Resolved'),
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
}
