import 'package:flutter/material.dart';
import '../services/kyc_service.dart';
import '../models/kyc.dart';

class AdminKycScreen extends StatelessWidget {
  AdminKycScreen({super.key});

  final KycService _service = KycService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Verification'),
        backgroundColor: const Color(0xFF781C2E),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<KYC>>(
        stream: _service.kycStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final kycList = snapshot.data!;

          if (kycList.isEmpty) {
            return const Center(child: Text('No KYC requests'));
          }

          return ListView.builder(
            itemCount: kycList.length,
            itemBuilder: (context, index) {
              final kyc = kycList[index];

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(kyc.fullName),
                  subtitle: Text('${kyc.idType} • ${kyc.status.toUpperCase()}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () =>
                            _service.updateStatus(kyc.userId, 'approved'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () =>
                            _service.updateStatus(kyc.userId, 'rejected'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
