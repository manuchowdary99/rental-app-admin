import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserDetailScreen extends StatelessWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final usersRef = FirebaseFirestore.instance.collection('users');
    final itemsRef = FirebaseFirestore.instance.collection('items');
    final ordersRef = FirebaseFirestore.instance.collection('orders');

    final gradientBackground = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.surface,
            scheme.surfaceContainerHighest,
          ],
        ),
      ),
      child: SingleChildScrollView(
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
            Text(
              'Listings by this user',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                    return Text(
                      'No listings',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    );
                  }
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            data['title']?.toString() ?? '',
                            style: theme.textTheme.titleSmall,
                          ),
                          subtitle: Text(
                            'Status: ${data['status'] ?? 'unknown'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Orders as Lender',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    ordersRef.where('lenderId', isEqualTo: userId).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return Text(
                      'No orders as lender',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    );
                  }
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            'Order: ${doc.id}',
                            style: theme.textTheme.titleSmall,
                          ),
                          subtitle: Text(
                            'Status: ${data['status'] ?? 'unknown'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Orders as Borrower',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                    return Text(
                      'No orders as borrower',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    );
                  }
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            'Order: ${doc.id}',
                            style: theme.textTheme.titleSmall,
                          ),
                          subtitle: Text(
                            'Status: ${data['status'] ?? 'unknown'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
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

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(title: const Text('User Details')),
      body: gradientBackground,
    );
  }
}
