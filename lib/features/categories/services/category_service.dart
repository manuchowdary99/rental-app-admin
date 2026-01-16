import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';

class CategoryService {
  final _firestore =
      FirebaseFirestore.instance.collection('categories');

  Stream<List<Category>> get categoriesStream {
    return _firestore
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Category.fromFirestore).toList());
  }

  Future<void> addCategory(String name) async {
    await _firestore.add({
      'name': name.trim(),
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleCategory(String id, bool isActive) async {
    await _firestore.doc(id).update({
      'isActive': !isActive,
    });
  }

  Future<void> deleteCategory(String id) async {
    await _firestore.doc(id).delete();
  }
}
