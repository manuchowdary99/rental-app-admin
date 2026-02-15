import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../navigation/widgets/admin_app_drawer.dart';

class AdminSupportFaqScreen extends StatelessWidget {
  const AdminSupportFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support FAQs'),
      ),
      drawer: const AdminAppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF781C2E),
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text("Add FAQ"),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('support_faqs')
              .orderBy('displayOrder')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  "No FAQs available.\nClick 'Add FAQ' to create one.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // LEFT SIDE CONTENT
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['question'],
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (data['category'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF781C2E)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      data['category'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF781C2E),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 10),
                                Text(
                                  "Display Order: ${data['displayOrder']}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // RIGHT SIDE ACTIONS
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_rounded,
                                ),
                                color: const Color(0xFF781C2E),
                                onPressed: () => _showEditDialog(context, data),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                ),
                                color: Colors.red,
                                onPressed: () {
                                  FirebaseFirestore.instance
                                      .collection('support_faqs')
                                      .doc(data.id)
                                      .delete();
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /* =============================
     ADD FAQ DIALOG
  ============================= */

  void _showAddDialog(BuildContext context) {
    final questionController = TextEditingController();
    final answerController = TextEditingController();
    final orderController = TextEditingController();
    final categoryController = TextEditingController(text: "General");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Add FAQ"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  labelText: "Question",
                ),
              ),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(labelText: "Answer"),
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: "Category"),
              ),
              TextField(
                controller: orderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Display Order"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('support_faqs').add({
                "question": questionController.text,
                "answer": answerController.text,
                "category": categoryController.text,
                "displayOrder": int.parse(orderController.text),
                "updatedAt": FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  /* =============================
     EDIT FAQ DIALOG
  ============================= */

  void _showEditDialog(BuildContext context, QueryDocumentSnapshot doc) {
    final questionController = TextEditingController(text: doc['question']);
    final answerController = TextEditingController(text: doc['answer']);
    final orderController =
        TextEditingController(text: doc['displayOrder'].toString());
    final categoryController = TextEditingController(text: doc['category']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Edit FAQ"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: questionController),
              TextField(controller: answerController),
              TextField(controller: categoryController),
              TextField(
                controller: orderController,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('support_faqs')
                  .doc(doc.id)
                  .update({
                "question": questionController.text,
                "answer": answerController.text,
                "category": categoryController.text,
                "displayOrder": int.parse(orderController.text),
                "updatedAt": FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
            },
            child: const Text("Update"),
          )
        ],
      ),
    );
  }
}
