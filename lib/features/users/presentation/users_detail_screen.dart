import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserDetailScreen extends StatelessWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final usersRef = FirebaseFirestore.instance.collection('users');
    final itemsRef = FirebaseFirestore.instance.collection('items');
    final ordersRef = FirebaseFirestore.instance.collection('orders');

    return Scaffold(
      appBar: AppBar(title: const Text('User Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic info
            StreamBuilder<DocumentSnapshot>(
              stream: usersRef.doc(userId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};
                return Card(
                  child: ListTile(
                    title: Text(data['displayName'] ?? ''),
                    subtitle: Text(data['email'] ?? ''),
                    trailing: Text(data['address'] ?? ''),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Listings by this user',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    itemsRef.where('ownerId', isEqualTo: userId).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Text('No listings');
                  }
                  return ListView(
                    children: docs.map((doc) {
                      final data =
                          doc.data() as Map<String, dynamic>? ?? {};
                      return ListTile(
                        title: Text(data['title']?.toString() ?? ''),
                        subtitle:
                            Text('Status: ${data['status'] ?? 'unknown'}'),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Orders as Lender',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: StreamBuilder<QuerySnapshot>(
                stream: ordersRef
                    .where('lenderId', isEqualTo: userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Text('No orders as lender');
                  }
                  return ListView(
                    children: docs.map((doc) {
                      final data =
                          doc.data() as Map<String, dynamic>? ?? {};
                      return ListTile(
                        title: Text('Order: ${doc.id}'),
                        subtitle:
                            Text('Status: ${data['status'] ?? 'unknown'}'),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Orders as Borrower',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: StreamBuilder<QuerySnapshot>(
                stream: ordersRef
                    .where('borrowerId', isEqualTo: userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Text('No orders as borrower');
                  }
                  return ListView(
                    children: docs.map((doc) {
                      final data =
                          doc.data() as Map<String, dynamic>? ?? {};
                      return ListTile(
                        title: Text('Order: ${doc.id}'),
                        subtitle:
                            Text('Status: ${data['status'] ?? 'unknown'}'),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
