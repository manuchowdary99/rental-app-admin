import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'users_detail_screen.dart';

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usersRef = FirebaseFirestore.instance.collection('users');

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.snapshots(),
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
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Blocked')),
                DataColumn(label: Text('Trusted')),
              ],
              rows: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final role = data['role'] as String? ?? 'user';
                final isBlocked = data['isBlocked'] as bool? ?? false;
                final isTrusted = data['isTrusted'] as bool? ?? false;

                return DataRow(
                  cells: [
                    // Clickable name → opens UserDetailScreen
                    DataCell(
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  UserDetailScreen(userId: doc.id),
                            ),
                          );
                        },
                        child: Text(data['displayName'] ?? ''),
                      ),
                    ),
                    DataCell(Text(data['email'] ?? '')),
                    DataCell(Text(role)),
                    DataCell(
                      Switch(
                        value: isBlocked,
                        onChanged: (val) {
                          usersRef.doc(doc.id).update({'isBlocked': val});
                        },
                      ),
                    ),
                    DataCell(
                      Switch(
                        value: isTrusted,
                        onChanged: (val) {
                          usersRef.doc(doc.id).update({'isTrusted': val});
                        },
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
