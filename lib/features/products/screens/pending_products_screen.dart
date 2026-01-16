import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../models/product.dart';

class PendingProductsScreen extends StatelessWidget {
  final ProductService _productService = ProductService();

  PendingProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Products"),
        backgroundColor: const Color(0xFF781C2E),
      ),
      body: StreamBuilder<List<Product>>(
        stream: _productService.pendingProductsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data!;

          if (products.isEmpty) {
            return const Center(child: Text("No pending approvals 🎉"));
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(product.name),
                  subtitle: Text(
                      "₹${product.price} • ${product.categoryName}\nRisk Score: ${product.riskScore}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () =>
                            _productService.approveProduct(product.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () =>
                            _productService.rejectProduct(product.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
