import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'products';

  // ---------------- ADD PRODUCT ----------------
  Future<void> addProduct(
    String name,
    String categoryId,
    String categoryName,
    double price,
  ) async {
    await _db.collection(_collection).add({
      'name': name,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'price': price,
      'status': 'pending', // pending | approved | rejected | flagged
      'riskScore': 0,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------- GENERIC STATUS STREAM ----------------
  Stream<List<Product>> productsByStatus(String status) {
    return _db
        .collection(_collection)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
        );
  }

  // ---------------- BACKWARD COMPATIBILITY ----------------
  Stream<List<Product>> approvedProductsStream() =>
      productsByStatus('approved');

  Stream<List<Product>> pendingProductsStream() => productsByStatus('pending');

  Stream<List<Product>> flaggedProductsStream() => productsByStatus('flagged');

  // ---------------- ADMIN ACTIONS ----------------
  Future<void> approveProduct(String productId) async {
    await _db.collection(_collection).doc(productId).update({
      'status': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectProduct(String productId) async {
    await _db.collection(_collection).doc(productId).update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> flagProduct(String productId, int riskScore) async {
    await _db.collection(_collection).doc(productId).update({
      'status': 'flagged',
      'riskScore': riskScore,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProduct(String productId) async {
    await _db.collection(_collection).doc(productId).delete();
  }
}
