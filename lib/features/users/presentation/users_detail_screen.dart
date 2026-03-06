import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserDetailScreen extends StatelessWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  String _orderStatusLabel(Map<String, dynamic> data) {
    final status = data['orderStatus'] ??
        data['paymentStatus'] ??
        data['status'] ??
        'unknown';
    return status.toString();
  }

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
            /// 🔹 BASIC INFO
            StreamBuilder<DocumentSnapshot>(
              stream: usersRef.doc(userId).snapshots(),
              builder: (context, snapshot) {
                // ✅ Error handling added
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading user data"));
                }

                // ✅ Proper loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // ✅ Handle missing document
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("User not found"));
                }

                final data =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};

                return Card(
                  child: ListTile(
                    title: Text(data['displayName'] ?? 'No name'),
                    subtitle: Text(data['email'] ?? 'No email'),
                    trailing: Text(data['address'] ?? ''),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            /// 🔹 LISTINGS
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
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading listings"));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

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

            /// 🔹 ORDERS AS LENDER
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
                    ordersRef.where('ownerId', isEqualTo: userId).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading orders"));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

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
                      final orderLabel =
                          data['orderNumber']?.toString() ?? doc.id;
                      final statusLabel = _orderStatusLabel(data);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            'Order: $orderLabel',
                            style: theme.textTheme.titleSmall,
                          ),
                          subtitle: Text(
                            'Status: $statusLabel',
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

            /// 🔹 ORDERS AS BORROWER
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
                    .where(Filter.or(
                      Filter('userId', isEqualTo: userId),
                      Filter('buyerId', isEqualTo: userId),
                    ))
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading orders"));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

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
                      final orderLabel =
                          data['orderNumber']?.toString() ?? doc.id;
                      final statusLabel = _orderStatusLabel(data);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            'Order: $orderLabel',
                            style: theme.textTheme.titleSmall,
                          ),
                          subtitle: Text(
                            'Status: $statusLabel',
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
