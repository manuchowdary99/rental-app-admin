import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../models/product.dart';

class FlaggedProductsScreen extends StatefulWidget {
  const FlaggedProductsScreen({super.key});

  @override
  State<FlaggedProductsScreen> createState() =>
      _FlaggedProductsScreenState();
}

class _FlaggedProductsScreenState
    extends State<FlaggedProductsScreen> {
  final ProductService _productService = ProductService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6EE),
      appBar: AppBar(
        title: const Text('Flagged Products'),
        backgroundColor: const Color(0xFF781C2E),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Product>>(
        stream: _productService.productsByStatus('flagged'),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(
              child: Text(
                '🎉 No flagged products!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Text(
                      product.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    product.name,
                    style:
                        const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Category: ${product.categoryName}'),
                      Text(
                          'Price: ₹${product.price.toStringAsFixed(2)}'),
                      Text(
                        'Risk Score: ${product.riskScore}',
                        style:
                            const TextStyle(color: Colors.red),
                      ),
                      Text(
                        'Status: ${product.status.toUpperCase()}',
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        onPressed: () =>
                            _approveProduct(product.id),
                        child: const Text('Approve'),
                      ),
                      const SizedBox(height: 6),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () =>
                            _rejectProduct(product.id),
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
                  onTap: () => _showProductDetails(product),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ---------------- ADMIN ACTIONS ----------------

  void _approveProduct(String productId) async {
    await _productService.approveProduct(productId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Product Approved'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectProduct(String productId) async {
    await _productService.rejectProduct(productId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❌ Product Rejected'),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ---------------- DETAILS POPUP ----------------

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Product Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${product.name}'),
            const SizedBox(height: 8),
            Text('Category: ${product.categoryName}'),
            const SizedBox(height: 8),
            Text('Price: ₹${product.price.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Risk Score: ${product.riskScore}'),
            const SizedBox(height: 8),
            Text('Status: ${product.status.toUpperCase()}'),
            const SizedBox(height: 8),
            Text(
              'Created: ${product.createdAt.toDate().toString().split(" ").first}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
