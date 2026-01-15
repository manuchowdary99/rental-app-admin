import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../../categories/services/category_service.dart';
import '../../categories/models/category.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6EE),
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: const Color(0xFF781C2E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Add Product Form
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Product name',
                          prefixIcon: const Icon(Icons.inventory_2),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Price',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<Category>>(
                        stream: _categoryService.categoriesStream,
                        builder: (context, snapshot) {
                          final categories = snapshot.data ?? [];
                          return DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              hintText: 'Select Category',
                              prefixIcon: const Icon(Icons.category),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: categories.map((cat) => DropdownMenuItem(
                              value: cat.id,
                              child: Text(cat.name),
                            )).toList(),
                            onChanged: (value) => setState(() => _selectedCategory = value),
                            value: _selectedCategory,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _canAddProduct() ? _addProduct : null,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF781C2E)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Products List
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _productService.productsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final products = snapshot.data ?? [];
                
                if (products.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No products yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF781C2E),
                          child: Text(product.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(product.name),
                        subtitle: Text('₹${product.price} • ${product.isActive ? 'Active' : 'Inactive'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: product.isActive,
                              onChanged: (_) => _productService.toggleProduct(product.id, product.isActive),
                              activeColor: const Color(0xFF781C2E),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteProduct(product.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _canAddProduct() {
    return _nameController.text.trim().isNotEmpty &&
           _priceController.text.isNotEmpty &&
           double.tryParse(_priceController.text) != null &&
           _selectedCategory != null;
  }

  void _addProduct() {
    final price = double.parse(_priceController.text);
    _productService.addProduct(_nameController.text, _selectedCategory!, price);
    _nameController.clear();
    _priceController.clear();
    _selectedCategory = null;
  }

  void _deleteProduct(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _productService.deleteProduct(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
