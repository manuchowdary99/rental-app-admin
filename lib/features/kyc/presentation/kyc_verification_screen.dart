import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KycVerificationScreen extends StatelessWidget {
  const KycVerificationScreen({super.key});

  Future<void> _updateStatus(
    String uid,
    String status,
  ) async {
    await FirebaseFirestore.instance
        .collection("kyc")
        .doc(uid)
        .update({
      "status": status,
      "verifiedAt": Timestamp.now(),
    });

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .update({
      "kycStatus": status,
      "role": status == "approved" ? "trusted" : "normal",
    });
  }

  void _showDocs(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("KYC Documents"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(data["idProofUrl"]),
            const SizedBox(height: 8),
            Image.network(data["selfieUrl"]),
            const SizedBox(height: 8),
            Image.network(data["addressProofUrl"]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("KYC Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("kyc")
            .where("status", isEqualTo: "pending")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No pending KYC requests"));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  title: Text("User: ${data["userId"]}"),
                  subtitle: const Text("Status: pending"),
                  onTap: () => _showDocs(context, data),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.check, color: Colors.green),
                        onPressed: () =>
                            _updateStatus(doc.id, "approved"),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.red),
                        onPressed: () =>
                            _updateStatus(doc.id, "rejected"),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
