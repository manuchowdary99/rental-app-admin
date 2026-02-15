import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSupportTicketsScreen extends StatelessWidget {
  const AdminSupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Material( // ✅ FIX: Provide Material ancestor
      color: const Color(0xFFF6F7FB),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('support_tickets')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tickets = snapshot.data!.docs;

          if (tickets.isEmpty) {
            return const Center(
              child: Text(
                "No Support Tickets Found",
                style: TextStyle(fontSize: 16),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Status: ${ticket['status']}  |  Priority: ${ticket['priority']}",
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _openTicket(context, ticket),
                ),
              );
            },
          );
        },
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
              Text(
                ticket['message'] ?? '',
                style: const TextStyle(fontSize: 14),
              ),
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
              backgroundColor: const Color(0xFF781C2E),
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
