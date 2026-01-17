import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class KycStorageService {
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  Future<String> uploadImage(File file, String type) async {
    final userId = _auth.currentUser!.uid;

    final ref = _storage.ref().child(
      'kyc/$userId/$type-${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
}
