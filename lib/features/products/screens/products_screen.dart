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

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedCategoryName;

  // =============================
  // UI
  // =============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6EE),
      appBar: AppBar(
        title: const Text('Products (Approved)'),
        backgroundColor: const Color(0xFF781C2E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildAddProductForm(),
          Expanded(child: _buildProductsList()),
        ],
      ),
    );
  }

  // =============================
  // ADD PRODUCT FORM
  // =============================
  Widget _buildAddProductForm() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              // PRODUCT NAME
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Product name',
                    prefixIcon: const Icon(Icons.inventory_2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),

              // PRICE
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Price',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              // CATEGORY DROPDOWN
              Expanded(
                child: StreamBuilder<List<Category>>(
                  stream: _categoryService.categoriesStream,
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? [];

                    return DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      hint: const Text('Select Category'),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat.id,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        final selected =
                            categories.firstWhere((c) => c.id == value);

                        setState(() {
                          _selectedCategoryId = selected.id;
                          _selectedCategoryName = selected.name;
                        });
                      },
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              // ADD BUTTON
              ElevatedButton.icon(
                onPressed: _canAddProduct() ? _addProduct : null,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF781C2E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =============================
  // PRODUCTS LIST (APPROVED)
  // =============================
  Widget _buildProductsList() {
    return StreamBuilder<List<Product>>(
      stream: _productService.approvedProductsStream(),
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
                SizedBox(height: 12),
                Text(
                  'No approved products yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF781C2E),
                  child: Text(
                    product.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(product.name),
                subtitle: Text(
                  '₹${product.price.toStringAsFixed(2)} • ${product.categoryName}',
                ),
                onTap: () => _showProductDetails(product),
              ),
            );
          },
        );
      },
    );
  }

  // =============================
  // LOGIC
  // =============================
  bool _canAddProduct() {
    return _nameController.text.trim().isNotEmpty &&
        _priceController.text.trim().isNotEmpty &&
        double.tryParse(_priceController.text) != null &&
        _selectedCategoryId != null &&
        _selectedCategoryName != null;
  }

  Future<void> _addProduct() async {
    await _productService.addProduct(
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text),
      categoryId: _selectedCategoryId!,
      categoryName: _selectedCategoryName!,
    );

    _nameController.clear();
    _priceController.clear();

    setState(() {
      _selectedCategoryId = null;
      _selectedCategoryName = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Product submitted for admin approval'),
      ),
    );
  }

  // =============================
  // DETAILS POPUP
  // =============================
  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Product Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${product.name}'),
              const SizedBox(height: 6),
              Text('Category: ${product.categoryName}'),
              const SizedBox(height: 6),
              Text('Price: ₹${product.price.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              Text('Status: ${product.status.toUpperCase()}'),
              const SizedBox(height: 6),
              Text(
                'Created: ${product.createdAt.toString().split(" ").first}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
