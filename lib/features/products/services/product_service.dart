import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'products';

  // ---------------- CREATE PRODUCT ----------------
  Future<void> addProduct({
    required String name,
    required double price,
    required String categoryId,
    required String categoryName,
    required String userId, // Add user ownership
    required String userName, // Add user name for easy reference
  }) async {
    bool flagged = false;
    int riskScore = 0;
    String status = 'pending'; // Always start as pending

    // AUTO FLAG RULES for higher risk scoring
    if (price > 100000) {
      flagged = true;
      riskScore += 50;
    }

    if (name.toLowerCase().contains('sofa') &&
        categoryName.toLowerCase() != 'furniture') {
      flagged = true;
      riskScore += 50;
    }

    final product = Product(
      id: '',
      name: name,
      price: price,
      categoryId: categoryId,
      categoryName: categoryName,
      isActive: false, // Not active until approved
      isFlagged: flagged,
      riskScore: riskScore,
      status: status,
      createdAt: DateTime.now(),
    );

    await _firestore.collection(_collection).add({
      ...product.toFirestore(),
      'userId': userId, // Add ownership
      'userName': userName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------- STREAMS ----------------
  Stream<List<Product>> approvedProductsStream() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map(_mapProducts);
  }

  Stream<List<Product>> pendingProductsStream() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(_mapProducts);
  }

  Stream<List<Product>> flaggedProductsStream() {
    return _firestore
        .collection(_collection)
        .where('isFlagged', isEqualTo: true)
        .snapshots()
        .map(_mapProducts);
  }

  Stream<List<Product>> allProductsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapProducts);
  }

  // Get user's own products for editing
  Stream<List<Product>> userProductsStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapProducts);
  }

  // ---------------- ACTIONS ----------------
  Future<void> approveProduct(String productId) async {
    await _firestore.collection(_collection).doc(productId).update({
      'status': 'approved',
      'isActive': true, // Make active when approved
      'isFlagged': false,
      'riskScore': 0,
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectProduct(String productId, {String? reason}) async {
    await _firestore.collection(_collection).doc(productId).update({
      'status': 'rejected',
      'isActive': false,
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectionReason': reason,
    });
  }

  Future<void> toggleProduct(String productId, bool isActive) async {
    await _firestore.collection(_collection).doc(productId).update({
      'isActive': !isActive,
    });
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore.collection(_collection).doc(productId).delete();
  }

  // ---------------- MAPPER ----------------
  List<Product> _mapProducts(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }
}
