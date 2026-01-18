import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProductModerationScreen extends StatelessWidget {
  const AdminProductModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Moderation'),
        backgroundColor: const Color(0xFF781C2E),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No pending products',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return _ProductCard(
                productId: doc.id,
                data: data,
              );
            },
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> data;

  const _ProductCard({
    required this.productId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Unnamed';
    final price = data['price'] ?? 0;
    final category = data['categoryName'] ?? 'Unknown';
    final isFlagged = data['isFlagged'] ?? false;
    final riskScore = data['riskScore'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isFlagged)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'FLAGGED ($riskScore)',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Category: $category'),
            Text('Price: ₹$price'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () => _approveProduct(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => _showRejectDialog(context, productId),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveProduct(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .update({
      'status': 'approved',
      'isActive': true,
      'approvedAt': Timestamp.now(),
      'rejectionReason': null,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product approved')),
    );
  }

  void _showRejectDialog(BuildContext context, String productId) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Product'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter rejection reason',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('products')
                  .doc(productId)
                  .update({
                'status': 'rejected',
                'isActive': false,
                'rejectionReason': controller.text,
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product rejected')),
              );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
