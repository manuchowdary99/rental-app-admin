import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  final _firestore = FirebaseFirestore.instance.collection('products');

  Stream<List<Product>> get productsStream => 
    _firestore.orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) => snapshot.docs.map(Product.fromFirestore).toList()
    );

  Future<void> addProduct(String name, String categoryId, double price) async {
    await _firestore.add({
      'name': name.trim(),
      'categoryId': categoryId,
      'price': price,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleProduct(String id, bool isActive) async {
    await _firestore.doc(id).update({'isActive': !isActive});
  }

  Future<void> deleteProduct(String id) async {
    await _firestore.doc(id).delete();
  }
}
