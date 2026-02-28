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
    required String userId,
    required String userName,
  }) async {
    bool flagged = false;
    int riskScore = 0;
    String status = 'pending';

    // 🔥 AUTO FLAG RULES
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
      isActive: false,
      isFlagged: flagged,
      riskScore: riskScore,
      status: status,
      createdAt: DateTime.now(),
    );

    await _firestore.collection(_collection).add({
      ...product.toFirestore(),
      'userId': userId,
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

  Stream<List<Product>> userProductsStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapProducts);
  }

  // ---------------- ADMIN ACTIONS ----------------

  /// Generic status update (used from products_screen)
  Future<void> updateStatus(String productId, String status) async {
    Map<String, dynamic> updateData = {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == 'approved') {
      updateData['isActive'] = true;
      updateData['isFlagged'] = false;
      updateData['riskScore'] = 0;
      updateData['approvedAt'] = FieldValue.serverTimestamp();
    }

    if (status == 'pending') {
      updateData['isActive'] = false;
    }

    if (status == 'rejected') {
      updateData['isActive'] = false;
      updateData['rejectedAt'] = FieldValue.serverTimestamp();
    }

    await _firestore.collection(_collection).doc(productId).update(updateData);
  }

  /// Toggle Flag anytime (admin can flag/unflag later)
  Future<void> toggleFlag(String productId, bool currentFlag) async {
    await _firestore.collection(_collection).doc(productId).update({
      'isFlagged': !currentFlag,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> approveProduct(String productId) async {
    await updateStatus(productId, 'approved');
  }

  Future<void> rejectProduct(String productId, {String? reason}) async {
    await _firestore.collection(_collection).doc(productId).update({
      'status': 'rejected',
      'isActive': false,
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectionReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleProduct(String productId, bool isActive) async {
    await _firestore.collection(_collection).doc(productId).update({
      'isActive': !isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore.collection(_collection).doc(productId).delete();
  }

  // ---------------- MAPPER ----------------
  List<Product> _mapProducts(QuerySnapshot snapshot) {
    return snapshot.docs
        .map((doc) => Product.fromFirestore(doc))
        .toList();
  }
}