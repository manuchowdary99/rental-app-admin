import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/widgets/admin_widgets.dart';
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Products (Approved)'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.surface,
              scheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildAddProductForm(context),
            Expanded(child: _buildProductsList(context)),
          ],
        ),
      ),
    );
  }

  // =============================
  // ADD PRODUCT FORM
  // =============================
  Widget _buildAddProductForm(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outlineVariant),
        ),
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
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
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
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
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
                        initialValue: _selectedCategoryId,
                        hint: const Text('Select Category'),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.category),
                          filled: true,
                          fillColor: scheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
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
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =============================
  // PRODUCTS LIST (APPROVED)
  // =============================
  Widget _buildProductsList(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];

            return AdminCard(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: scheme.primary,
                  child: Text(
                    product.name[0].toUpperCase(),
                    style: TextStyle(color: scheme.onPrimary),
                  ),
                ),
                title: Text(
                  product.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  '₹${product.price.toStringAsFixed(2)} • ${product.categoryName}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please login to add products'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    try {
      await _productService.addProduct(
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text),
        categoryId: _selectedCategoryId!,
        categoryName: _selectedCategoryName!,
        userId: user.uid,
        userName: user.displayName ?? user.email ?? 'Unknown User',
      );

      if (!mounted) return;

      _nameController.clear();
      _priceController.clear();

      setState(() {
        _selectedCategoryId = null;
        _selectedCategoryName = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Product submitted for admin approval'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding product: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // =============================
  // DETAILS POPUP
  // =============================
  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;

        return AlertDialog(
          backgroundColor: scheme.surfaceContainerHigh,
          title: Text(
            'Product Details',
            style: theme.textTheme.titleLarge?.copyWith(
              color: scheme.onSurface,
            ),
          ),
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
