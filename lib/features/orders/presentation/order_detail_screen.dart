import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final ordersRef = FirebaseFirestore.instance.collection('orders');

    return Scaffold(
      appBar: AppBar(title: Text('Order Details: $orderId')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: ordersRef.doc(orderId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final status = data['status'] as String? ?? 'placed';
          final itemId = data['itemId']?.toString() ?? '';
          final lenderId = data['lenderId']?.toString() ?? '';
          final borrowerId = data['borrowerId']?.toString() ?? '';
          final tracking = data['trackingInfo']?.toString() ?? '';
          final expectedTs = data['expectedDeliveryTime'] as Timestamp?;
          final expectedStr = expectedTs != null
              ? expectedTs.toDate().toString()
              : '-';

          final beforeUrl = data['beforeImageUrl'] as String?;
          final afterUrl = data['afterImageUrl'] as String?;
          final damageScore = (data['damageScore'] as num?)?.toDouble();
          final damageLabel = data['damageLabel'] as String?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: ListTile(
                    title: Text('Status: $status'),
                    subtitle: Text('Expected time: $expectedStr'),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('IDs'),
                    subtitle: Text(
                      'Item: $itemId\n'
                      'Lender: $lenderId\n'
                      'Borrower: $borrowerId',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (tracking.isNotEmpty)
                  Card(
                    child: ListTile(
                      title: const Text('Tracking info'),
                      subtitle: Text(tracking),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Before & After Images',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Before'),
                          const SizedBox(height: 8),
                          if (beforeUrl != null && beforeUrl.isNotEmpty)
                            AspectRatio(
                              aspectRatio: 1,
                              child: Image.network(
                                beforeUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Center(child: Text('Image error')),
                              ),
                            )
                          else
                            const Text('No before image'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('After'),
                          const SizedBox(height: 8),
                          if (afterUrl != null && afterUrl.isNotEmpty)
                            AspectRatio(
                              aspectRatio: 1,
                              child: Image.network(
                                afterUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Center(child: Text('Image error')),
                              ),
                            )
                          else
                            const Text('No after image'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Damage Assessment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  damageScore != null
                      ? 'Damage: ${damageLabel ?? 'scored'} '
                            '(${damageScore.toStringAsFixed(2)})'
                      : 'No damage score yet',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
