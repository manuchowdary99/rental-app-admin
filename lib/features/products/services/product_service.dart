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
  }) async {
    bool flagged = false;
    int riskScore = 0;
    String status = 'approved';

    // AUTO FLAG RULES
    if (price > 100000) {
      flagged = true;
      riskScore += 50;
    }

    if (name.toLowerCase().contains('sofa') &&
        categoryName.toLowerCase() != 'furniture') {
      flagged = true;
      riskScore += 50;
    }

    if (flagged) {
      status = 'pending';
    }

    final product = Product(
      id: '',
      name: name,
      price: price,
      categoryId: categoryId,
      categoryName: categoryName,
      isActive: true,
      isFlagged: flagged,
      riskScore: riskScore,
      status: status,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(_collection)
        .add(product.toFirestore());
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

  // ---------------- ACTIONS ----------------
  Future<void> approveProduct(String productId) async {
    await _firestore.collection(_collection).doc(productId).update({
      'status': 'approved',
      'isFlagged': false,
      'riskScore': 0,
    });
  }

  Future<void> rejectProduct(String productId) async {
    await _firestore.collection(_collection).doc(productId).update({
      'status': 'rejected',
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
    return snapshot.docs
        .map((doc) => Product.fromFirestore(doc))
        .toList();
  }
}
