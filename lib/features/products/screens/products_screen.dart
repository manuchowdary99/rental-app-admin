import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/widgets/admin_widgets.dart';
import '../services/product_service.dart';
import '../models/product.dart';

import '../../categories/services/category_service.dart';
import '../../categories/models/category.dart';
import '../../navigation/widgets/admin_app_drawer.dart';

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
  final TextEditingController _productSearchController =
      TextEditingController();

  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String _searchQuery = '';
  String _statusFilter = 'All';

  static const List<String> _statusFilters = [
    'All',
    'Approved',
    'Pending',
    'Rejected',
    'Flagged',
  ];

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
        title: const Text('Products Management'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
      ),
      drawer: const AdminAppDrawer(),
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
            _buildFiltersBar(context),
            Expanded(child: _buildProductsList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProductForm(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 640;

          final nameField = TextField(
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
          );

          final priceField = TextField(
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
          );

          final categoryDropdown = StreamBuilder<List<Category>>(
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
                  final selected = categories.firstWhere((c) => c.id == value);

                  setState(() {
                    _selectedCategoryId = selected.id;
                    _selectedCategoryName = selected.name;
                  });
                },
              );
            },
          );

          final addButton = SizedBox(
            width: isCompact ? double.infinity : null,
            child: ElevatedButton.icon(
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
          );

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              children: [
                if (isCompact) ...[
                  nameField,
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: priceField),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: nameField),
                      const SizedBox(width: 12),
                      SizedBox(width: 150, child: priceField),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                if (isCompact) ...[
                  categoryDropdown,
                  const SizedBox(height: 12),
                  addButton,
                ] else ...[
                  Row(
                    children: [
                      Expanded(child: categoryDropdown),
                      const SizedBox(width: 12),
                      addButton,
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltersBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _productSearchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim().toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search products or owner',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _productSearchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: scheme.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: scheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: scheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: scheme.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((filter) {
                final isSelected = _statusFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _statusFilter = filter),
                    selectedColor: scheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? scheme.onPrimary : scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: scheme.surfaceContainerHigh,
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : scheme.outlineVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // =============================
  // PRODUCTS LIST
  // =============================
  Widget _buildProductsList(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return StreamBuilder<List<Product>>(
      stream: _productService.allProductsStream(),
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
                  'No products found yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final filteredProducts = _applyFilters(products);

        if (filteredProducts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 80, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'No products match your filters',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 4),
                Text(
                  'Try adjusting the search or status filters',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final product = filteredProducts[index];

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
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${product.price.toStringAsFixed(2)} • ${product.categoryName}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusChip(
                          text: _formatStatus(product.status),
                          color: _statusColor(product.status, scheme),
                        ),
                        if (product.isFlagged)
                          const StatusChip(
                            text: 'Flagged',
                            color: Colors.red,
                            icon: Icons.flag,
                          ),
                      ],
                    ),
                  ],
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
  List<Product> _applyFilters(List<Product> products) {
    final query = _searchQuery;

    return products.where((product) {
      final name = product.name.toLowerCase();
      final category = product.categoryName.toLowerCase();
      final matchesSearch =
          query.isEmpty || name.contains(query) || category.contains(query);

      final matchesStatus = () {
        switch (_statusFilter) {
          case 'Approved':
            return product.status == 'approved';
          case 'Pending':
            return product.status == 'pending';
          case 'Rejected':
            return product.status == 'rejected';
          case 'Flagged':
            return product.isFlagged;
          default:
            return true;
        }
      }();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Color _statusColor(String status, ColorScheme scheme) {
    switch (status.toLowerCase()) {
      case 'approved':
        return scheme.primary;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return scheme.error;
      default:
        return scheme.outline;
    }
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return 'Unknown';
    return status[0].toUpperCase() + status.substring(1);
  }

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
    _productSearchController.dispose();
    super.dispose();
  }
}
