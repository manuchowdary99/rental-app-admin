import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  final _db = FirebaseFirestore.instance;
  final _collection = 'products';

  // ---------------- ADD PRODUCT ----------------
  // Always adds as PENDING (admin must approve)
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
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------- APPROVED PRODUCTS ----------------
  Stream<List<Product>> approvedProductsStream() {
    return _db
        .collection(_collection)
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
    });
  }

  // ---------------- PENDING PRODUCTS ----------------
  Stream<List<Product>> pendingProductsStream() {
    return _db
        .collection(_collection)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
    });
  }

  // ---------------- FLAGGED PRODUCTS ----------------
  Stream<List<Product>> flaggedProductsStream() {
    return _db
        .collection(_collection)
        .where('status', isEqualTo: 'flagged')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
    });
  }

  // ---------------- ADMIN ACTIONS ----------------

  Future<void> approveProduct(String productId) async {
    await _db.collection(_collection).doc(productId).update({
      'status': 'approved',
    });
  }

  Future<void> rejectProduct(String productId) async {
    await _db.collection(_collection).doc(productId).update({
      'status': 'rejected',
    });
  }

  Future<void> flagProduct(String productId, int riskScore) async {
    await _db.collection(_collection).doc(productId).update({
      'status': 'flagged',
      'riskScore': riskScore,
    });
  }

  Future<void> deleteProduct(String productId) async {
    await _db.collection(_collection).doc(productId).delete();
  }
}
