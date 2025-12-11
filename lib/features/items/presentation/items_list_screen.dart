import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ItemsListScreen extends StatelessWidget {
  const ItemsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final itemsRef = FirebaseFirestore.instance.collection('items');

    return Scaffold(
      appBar: AppBar(title: const Text('Items / Listings')),
      body: StreamBuilder<QuerySnapshot>(
        stream: itemsRef.snapshots(),
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
                DataColumn(label: Text('Title')),
                DataColumn(label: Text('Owner ID')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Price/Day')),
                DataColumn(label: Text('Actions')),
              ],
              rows: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] as String? ?? 'available';

                return DataRow(
                  cells: [
                    DataCell(Text(data['title']?.toString() ?? '')),
                    DataCell(Text(data['ownerId']?.toString() ?? '')),
                    DataCell(Text(status)),
                    DataCell(
                      Text(
                        (data['rentalPricePerDay'] ?? 0).toString(),
                      ),
                    ),
                    DataCell(
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          itemsRef.doc(doc.id).update({'status': value});
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'pending',
                            child: Text('Set as Pending'),
                          ),
                          PopupMenuItem(
                            value: 'approved',
                            child: Text('Set as Approved'),
                          ),
                          PopupMenuItem(
                            value: 'available',
                            child: Text('Set as Available'),
                          ),
                          PopupMenuItem(
                            value: 'rented',
                            child: Text('Set as Rented'),
                          ),
                          PopupMenuItem(
                            value: 'returned',
                            child: Text('Set as Returned'),
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
