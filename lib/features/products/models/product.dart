import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final String categoryId;
  final String categoryName;
  final String ownerId;
  final String status; // pending, approved, rejected, flagged
  final int riskScore;
  final bool isActive;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    required this.categoryName,
    required this.ownerId,
    required this.status,
    required this.riskScore,
    required this.isActive,
    required this.createdAt,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Product(
      id: doc.id,
      name: data['name'],
      price: (data['price'] as num).toDouble(),
      categoryId: data['categoryId'],
      categoryName: data['categoryName'],
      ownerId: data['ownerId'],
      status: data['status'],
      riskScore: data['riskScore'] ?? 0,
      isActive: data['isActive'] ?? false,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
