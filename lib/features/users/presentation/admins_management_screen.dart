import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminsManagementScreen extends StatelessWidget {
  const AdminsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usersRef = FirebaseFirestore.instance.collection('users');

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Admins')),
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

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final email = data['email']?.toString() ?? '';
              final name = data['displayName']?.toString() ?? '';
              final role = data['role'] as String? ?? 'user';
              final isAdmin = role == 'admin';

              return ListTile(
                title: Text(name.isEmpty ? email : name),
                subtitle: Text(email),
                trailing: Switch(
                  value: isAdmin,
                  onChanged: (value) async {
                    await usersRef.doc(doc.id).update({
                      'role': value ? 'admin' : 'user',
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
