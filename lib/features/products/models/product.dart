import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String categoryId;
  final String? imageUrl;
  final double price;
  final bool isActive;
  final Timestamp createdAt;

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    this.imageUrl,
    required this.price,
    required this.isActive,
    required this.createdAt,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      categoryId: data['categoryId'] ?? '',
      imageUrl: data['imageUrl'],
      price: (data['price'] ?? 0).toDouble(),
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'categoryId': categoryId,
    'imageUrl': imageUrl,
    'price': price,
    'isActive': isActive,
    'createdAt': createdAt,
  };
}
