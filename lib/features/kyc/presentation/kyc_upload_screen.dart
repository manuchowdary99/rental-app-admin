import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class KycUploadScreen extends StatefulWidget {
  const KycUploadScreen({super.key});

  @override
  State<KycUploadScreen> createState() => _KycUploadScreenState();
}

class _KycUploadScreenState extends State<KycUploadScreen> {
  File? idProof;
  File? selfie;
  File? addressProof;

  final picker = ImagePicker();

  Future<File?> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    return picked != null ? File(picked.path) : null;
  }

  Future<String> _upload(File file, String path) async {
    final ref = FirebaseStorage.instance.ref(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _submitKyc() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final idUrl = await _upload(idProof!, "kyc/$uid/id.jpg");
    final selfieUrl = await _upload(selfie!, "kyc/$uid/selfie.jpg");
    final addressUrl = await _upload(addressProof!, "kyc/$uid/address.jpg");

    await FirebaseFirestore.instance.collection("kyc").doc(uid).set({
      "userId": uid,
      "idProofUrl": idUrl,
      "selfieUrl": selfieUrl,
      "addressProofUrl": addressUrl,
      "status": "pending",
      "submittedAt": Timestamp.now(),
      "verifiedAt": null,
    });

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .update({
      "kycStatus": "pending",
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("KYC Submitted for Review")),
    );
  }

  Widget _tile(String title, VoidCallback onTap, bool selected) {
    return ListTile(
      title: Text(title),
      trailing: Icon(
        selected ? Icons.check_circle : Icons.upload,
        color: selected ? Colors.green : null,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("KYC Verification")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _tile("Upload ID Proof", () async {
              idProof = await _pickImage();
              setState(() {});
            }, idProof != null),
            _tile("Upload Selfie", () async {
              selfie = await _pickImage();
              setState(() {});
            }, selfie != null),
            _tile("Upload Address Proof", () async {
              addressProof = await _pickImage();
              setState(() {});
            }, addressProof != null),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: idProof != null &&
                      selfie != null &&
                      addressProof != null
                  ? _submitKyc
                  : null,
              child: const Text("Submit KYC"),
            ),
          ],
        ),
      ),
    );
  }
}
