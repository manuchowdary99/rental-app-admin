import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/kyc_service.dart';
import '../services/kyc_storage_service.dart';
import '../models/kyc.dart';

class UserKycScreen extends StatefulWidget {
  const UserKycScreen({super.key});

  @override
  State<UserKycScreen> createState() => _UserKycScreenState();
}

class _UserKycScreenState extends State<UserKycScreen> {
  final _fullNameController = TextEditingController();
  final _idNumberController = TextEditingController();

  String _idType = 'Aadhar';

  File? _idImage;
  File? _selfieImage;

  final _picker = ImagePicker();
  final _kycService = KycService();
  final _storageService = KycStorageService();

  bool _loading = false;

  Future<void> _pickImage(bool isSelfie) async {
    final picked = await _picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() {
        if (isSelfie) {
          _selfieImage = File(picked.path);
        } else {
          _idImage = File(picked.path);
        }
      });
    }
  }

  Future<void> _submitKyc() async {
    if (_idImage == null || _selfieImage == null) return;

    setState(() => _loading = true);

    final userId = FirebaseAuth.instance.currentUser!.uid;

    final idUrl =
        await _storageService.uploadImage(_idImage!, 'id');
    final selfieUrl =
        await _storageService.uploadImage(_selfieImage!, 'selfie');

    final kyc = KYC(
      userId: userId,
      fullName: _fullNameController.text,
      idType: _idType,
      idNumber: _idNumberController.text,
      idImageUrl: idUrl,
      selfieUrl: selfieUrl,
      status: 'pending',
      submittedAt: DateTime.now() as dynamic,
    );

    await _kycService.submitKyc(kyc);

    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('KYC Submitted Successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit KYC'),
        backgroundColor: const Color(0xFF781C2E),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _idType,
              items: const [
                DropdownMenuItem(value: 'Aadhar', child: Text('Aadhar')),
                DropdownMenuItem(value: 'Passport', child: Text('Passport')),
                DropdownMenuItem(value: 'License', child: Text('License')),
              ],
              onChanged: (v) => setState(() => _idType = v!),
              decoration: const InputDecoration(labelText: 'ID Type'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _idNumberController,
              decoration: const InputDecoration(labelText: 'ID Number'),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () => _pickImage(false),
              icon: const Icon(Icons.credit_card),
              label: Text(_idImage == null
                  ? 'Capture ID Image'
                  : 'ID Image Selected'),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () => _pickImage(true),
              icon: const Icon(Icons.camera_alt),
              label: Text(_selfieImage == null
                  ? 'Capture Selfie'
                  : 'Selfie Selected'),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _loading ? null : _submitKyc,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF781C2E),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit KYC'),
            ),
          ],
        ),
      ),
    );
  }
}
