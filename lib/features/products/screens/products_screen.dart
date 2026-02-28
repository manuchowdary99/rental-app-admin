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
      ),
      drawer: const AdminAppDrawer(),
      body: Column(
        children: [
          _buildAddProductForm(context),
          _buildFiltersBar(context),
          Expanded(child: _buildProductsList(context)),
        ],
      ),
    );
  }

  Widget _buildAddProductForm(BuildContext context) {
    return const SizedBox();
  }

  Widget _buildFiltersBar(BuildContext context) {
    return const SizedBox();
  }

  Widget _buildProductsList(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<Product>>(
      stream: _productService.allProductsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data!;
        final filteredProducts = _applyFilters(products);

        return ListView.builder(
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final product = filteredProducts[index];

            return AdminCard(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: scheme.primary,
                  child: Text(
                    product.name[0].toUpperCase(),
                    style: TextStyle(color: scheme.onPrimary),
                  ),
                ),
                title: Text(product.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '₹${product.price.toStringAsFixed(2)} • ${product.categoryName}'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        StatusChip(
                          text: product.status.toUpperCase(),
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
                trailing: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      color: scheme.onSurfaceVariant),
                  onSelected: (value) async {
                    if (value == 'approve') {
                      await _productService.approveProduct(product.id);
                    } else if (value == 'reject') {
                      await _productService.rejectProduct(product.id);
                    } else if (value == 'pending') {
                      await _productService.updateStatus(
                          product.id, 'pending');
                    } else if (value == 'flag') {
                      await _productService.toggleFlag(
                          product.id, product.isFlagged);
                    }
                  },
                  itemBuilder: (context) => [
                    if (product.status != 'approved')
                      const PopupMenuItem(
                          value: 'approve', child: Text('Approve')),
                    if (product.status != 'pending')
                      const PopupMenuItem(
                          value: 'pending', child: Text('Move to Pending')),
                    if (product.status != 'rejected')
                      const PopupMenuItem(
                          value: 'reject', child: Text('Reject')),
                    PopupMenuItem(
                      value: 'flag',
                      child:
                          Text(product.isFlagged ? 'Unflag' : 'Flag'),
                    ),
                  ],
                ),
                onTap: () => _showProductDetails(product),
              ),
            );
          },
        );
      },
    );
  }

  List<Product> _applyFilters(List<Product> products) {
    return products.where((product) {
      if (_statusFilter == 'Approved' &&
          product.status != 'approved') return false;
      if (_statusFilter == 'Pending' &&
          product.status != 'pending') return false;
      if (_statusFilter == 'Rejected' &&
          product.status != 'rejected') return false;
      if (_statusFilter == 'Flagged' &&
          !product.isFlagged) return false;
      return true;
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

  // 🔥 UPDATED DETAILED POPUP
  void _showProductDetails(Product product) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Product Details"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow("Name", product.name),
              _detailRow(
                  "Price",
                  "₹${product.price.toStringAsFixed(2)}"),
              _detailRow("Category", product.categoryName),
              _detailRow(
                  "Status",
                  product.status.toUpperCase()),
              _detailRow(
                  "Flagged",
                  product.isFlagged
                      ? "YES ⚠"
                      : "No"),
              _detailRow(
                  "Created",
                  product.createdAt
                      .toString()
                      .split(" ")
                      .first),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
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