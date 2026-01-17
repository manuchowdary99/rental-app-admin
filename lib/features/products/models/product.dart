import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final String categoryId;
  final String categoryName;
  final bool isActive;
  final bool isFlagged;
  final int riskScore;
  final String status; // pending | approved | rejected
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    required this.categoryName,
    required this.isActive,
    required this.isFlagged,
    required this.riskScore,
    required this.status,
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
      isActive: data['isActive'] ?? true,
      isFlagged: data['isFlagged'] ?? false,
      riskScore: data['riskScore'] ?? 0,
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'isActive': isActive,
      'isFlagged': isFlagged,
      'riskScore': riskScore,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
