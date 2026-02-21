import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../navigation/widgets/admin_app_drawer.dart';

class AdminSupportTicketsScreen extends StatelessWidget {
  const AdminSupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Support Tickets'),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      drawer: const AdminAppDrawer(),
      body: DecoratedBox(
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('support_tickets')
              .snapshots(), // ✅ removed orderBy
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            if (!snapshot.hasData) return const SizedBox();

            final tickets = snapshot.data!.docs.toList();

            // ✅ local sort (same behaviour)
            tickets.sort((a, b) {
              final aDate =
                  (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
              final bDate =
                  (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
              return bDate.compareTo(aDate);
            });

            if (tickets.isEmpty) {
              return Center(
                child: Text(
                  "No Support Tickets Found",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      ticket['subject'] ?? '',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "Status: ${ticket['status'] ?? ''}  |  Priority: ${ticket['priority'] ?? ''}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    onTap: () => _openTicket(context, ticket),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _openTicket(BuildContext context, QueryDocumentSnapshot ticket) {
    final responseController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          ticket['subject'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ticket['message'] ?? '',
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 20),
              TextField(
                controller: responseController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Reply",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('support_tickets')
                  .doc(ticket.id)
                  .update({
                "status": "in_progress",
                "lastResponse": responseController.text,
                "lastResponder": "Admin",
                "updatedAt": FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);
            },
            child: const Text("Send Reply"),
          ),
        ],
      ),
    );
  }
}