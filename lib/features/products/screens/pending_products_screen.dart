import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/widgets/admin_widgets.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../../navigation/widgets/admin_app_drawer.dart';

class PendingProductsScreen extends StatelessWidget {
  final ProductService _productService = ProductService();

  PendingProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text("Pending Approvals"),
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
        child: StreamBuilder<List<Product>>(
          stream: _productService.pendingProductsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading products: ${snapshot.error}',
                  style: TextStyle(color: scheme.error),
                ),
              );
            }

            final products = snapshot.data ?? [];

            if (products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified,
                        size: 80, color: scheme.tertiary),
                    const SizedBox(height: 16),
                    Text(
                      "No pending approvals 🎉",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      "All products have been reviewed",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(context, products[index]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final int riskScore = product.riskScore;
    final bool isHighRisk = riskScore > 60;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => _showProductDetails(context, product),
        child: AdminCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 🔴 Only High Risk Badge
                  if (riskScore > 30)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            Colors.red.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(4),
                        border:
                            Border.all(color: Colors.red),
                      ),
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.priority_high,
                            size: 14,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'High Risk ($riskScore)',
                            style: theme
                                .textTheme.bodySmall
                                ?.copyWith(
                              fontWeight:
                                  FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Category: ${product.categoryName}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(
                  color:
                      scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              FutureBuilder<String>(
                future:
                    _getUserName(product.id),
                builder:
                    (context, snapshot) {
                  return Text(
                    'Owner: ${snapshot.data ?? 'Loading...'}',
                    style: theme
                        .textTheme.bodyMedium
                        ?.copyWith(
                      color: scheme
                          .onSurfaceVariant,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child:
                        ElevatedButton.icon(
                      onPressed: () =>
                          _rejectProduct(
                              context,
                              product.id),
                      icon: const Icon(
                          Icons.close,
                          size: 18),
                      label:
                          const Text('Reject'),
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            scheme.error,
                        foregroundColor:
                            scheme.onError,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          isHighRisk
                              ? null
                              : () =>
                                  _approveProduct(
                                      context,
                                      product
                                          .id),
                      icon: const Icon(
                          Icons.check,
                          size: 18),
                      label:
                          const Text('Approve'),
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            scheme.primary,
                        foregroundColor:
                            scheme
                                .onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔍 PRODUCT DETAILS POPUP
  void _showProductDetails(
      BuildContext context,
      Product product) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              scheme.surfaceContainerHigh,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
                    20),
          ),
          title: const Text(
              "Product Details"),
          content:
              SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                _detailRow(
                    "Name",
                    product.name),
                _detailRow(
                    "Price",
                    "₹${product.price.toStringAsFixed(2)}"),
                _detailRow(
                    "Category",
                    product.categoryName),
                _detailRow(
                    "Status",
                    product.status
                        .toUpperCase()),
                _detailRow(
                    "Risk Score",
                    product.riskScore
                        .toString()),
                _detailRow(
                    "Flagged",
                    product.isFlagged
                        ? "YES ⚠"
                        : "No"),
                _detailRow(
                    "Created",
                    product.createdAt
                        .toString()
                        .split(
                            " ")
                        .first),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                      context),
              child:
                  const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(
      String title,
      String value) {
    return Padding(
      padding:
          const EdgeInsets.only(
              bottom: 10),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Text(
            title,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(
              height: 2),
          Text(
            value,
            style:
                const TextStyle(
                    fontSize:
                        14),
          ),
        ],
      ),
    );
  }

  Future<String> _getUserName(
      String productId) async {
    try {
      final doc =
          await FirebaseFirestore
              .instance
              .collection(
                  'products')
              .doc(productId)
              .get();
      return doc.data()?[
              'userName'] ??
          'Unknown User';
    } catch (e) {
      return 'Unknown User';
    }
  }

  Future<void> _approveProduct(
      BuildContext context,
      String productId) async {
    await _productService
        .approveProduct(
            productId);
  }

  Future<void> _rejectProduct(
      BuildContext context,
      String productId) async {
    await _productService
        .rejectProduct(
            productId);
  }
}