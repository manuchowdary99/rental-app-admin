import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  final String? initialName;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
    this.initialName,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docRef =
        FirebaseFirestore.instance.collection('products').doc(widget.productId);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6EE),
      appBar: AppBar(
        title: const Text('Listing Details'),
        backgroundColor: const Color(0xFF781C2E),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _statusMessage(
              context,
              icon: Icons.error_outline,
              label: 'Failed to load product',
              description: snapshot.error.toString(),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return _statusMessage(
              context,
              icon: Icons.hide_source,
              label: 'Listing no longer exists',
              description:
                  'The product was removed or you no longer have permission to view it.',
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final images = _extractImages(data);
          final description = _extractDescription(data);
          final specs = _extractSpecifications(data);
          final highlights = _extractHighlights(data);

          final name =
              data['name']?.toString() ?? widget.initialName ?? 'Product';
          final category = data['categoryName']?.toString() ?? 'Uncategorized';
          final priceLabel = _formatCurrency(data['price']);
          final owner = data['userName']?.toString();
          final ownerId = data['userId']?.toString();
          final location =
              data['location']?.toString() ?? data['city']?.toString();
          final depositValue = data['depositAmount'];
          final deposit =
              depositValue == null ? null : _formatCurrency(depositValue);
          final status = data['status']?.toString() ?? 'pending';
          final active = data['isActive'] == true;
          final flagged = data['isFlagged'] == true;
          final riskScore = data['riskScore'];
          final createdAt = _formatTimestamp(data['createdAt']);
          final updatedAt = _formatTimestamp(data['updatedAt']);
          final rejectionReason = data['rejectionReason']?.toString();

          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF9F6EE), Color(0xFFF0E6D2)],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGallery(context, images, name),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D1B1B),
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          category,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[700],
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          priceLabel,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF781C2E),
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _statusChip(
                                status.toUpperCase(), const Color(0xFF781C2E)),
                            _statusChip(active ? 'ACTIVE' : 'INACTIVE',
                                active ? Colors.green : Colors.grey),
                            if (flagged)
                              _statusChip('FLAGGED', Colors.red,
                                  icon: Icons.flag_outlined),
                            if (riskScore != null)
                              _statusChip('RISK $riskScore', Colors.orange),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _sectionCard(
                    context,
                    title: 'Listing Overview',
                    children: [
                      _infoRow('Listing ID', widget.productId),
                      if (owner != null) _infoRow('Owner', owner),
                      if (ownerId != null) _infoRow('Owner ID', ownerId),
                      if (location != null) _infoRow('Location', location),
                      if (deposit != null) _infoRow('Deposit', deposit),
                      _infoRow('Status', status.toUpperCase()),
                      _infoRow('Active', active ? 'Yes' : 'No'),
                      _infoRow('Flagged', flagged ? 'Yes' : 'No'),
                      if (riskScore != null)
                        _infoRow('Risk Score', '$riskScore'),
                      _infoRow('Created', createdAt),
                      if (updatedAt != null) _infoRow('Updated', updatedAt),
                    ],
                  ),
                  if (rejectionReason != null && rejectionReason.isNotEmpty)
                    _sectionCard(
                      context,
                      title: 'Rejection Reason',
                      children: [
                        Text(
                          rejectionReason,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  if (description != null)
                    _sectionCard(
                      context,
                      title: 'Description',
                      children: [
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  if (specs.isNotEmpty)
                    _sectionCard(
                      context,
                      title: 'Specifications',
                      children: specs.entries
                          .map((entry) => _infoRow(entry.key, entry.value))
                          .toList(),
                    ),
                  if (highlights.isNotEmpty)
                    _sectionCard(
                      context,
                      title: 'Highlights',
                      children: highlights
                          .map((text) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 6),
                                      child: Icon(Icons.check_circle,
                                          size: 14, color: Color(0xFF781C2E)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        text,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGallery(BuildContext context, List<String> images, String name) {
    if (images.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFE7DAD0),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image_outlined, size: 48, color: Colors.brown[300]),
                const SizedBox(height: 8),
                const Text('No images uploaded yet'),
              ],
            ),
          ),
        ),
      );
    }

    final clampedIndex = _currentPage.clamp(0, images.length - 1);

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (_, index) {
                      final url = images[index];
                      return Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFE7DAD0),
                          alignment: Alignment.center,
                          child:
                              const Icon(Icons.broken_image_outlined, size: 40),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        name,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            images.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: index == clampedIndex ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: index == clampedIndex
                    ? const Color(0xFF781C2E)
                    : const Color(0xFFCCC2B8),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D1B1B),
                    ),
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF5B4C46),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF2D1B1B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusMessage(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFF781C2E).withOpacity(0.1),
              child: Icon(icon, color: const Color(0xFF781C2E), size: 38),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _extractImages(Map<String, dynamic> data) {
    final listKeys = ['images', 'imageUrls', 'photos', 'gallery', 'media'];
    for (final key in listKeys) {
      final raw = data[key];
      if (raw is List) {
        return raw
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    final singleKeys = ['coverImage', 'image', 'imageUrl', 'thumbnail'];
    for (final key in singleKeys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return [value];
      }
    }

    return const [];
  }

  String? _extractDescription(Map<String, dynamic> data) {
    const keys = ['description', 'summary', 'details', 'fullDescription'];
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  Map<String, String> _extractSpecifications(Map<String, dynamic> data) {
    final mapKeys = ['specifications', 'attributes', 'metadata', 'specs'];
    for (final key in mapKeys) {
      final value = data[key];
      if (value is Map) {
        return value.map((k, v) => MapEntry(k.toString(), _stringify(v)));
      }
    }
    return {};
  }

  List<String> _extractHighlights(Map<String, dynamic> data) {
    final listKeys = ['highlights', 'features', 'tags'];
    for (final key in listKeys) {
      final value = data[key];
      if (value is List) {
        return value
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    return const [];
  }

  String _formatCurrency(dynamic value) {
    if (value is num) {
      return '₹${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)}';
    }
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return '₹0';
  }

  String _formatTimestamp(dynamic value) {
    DateTime? date;
    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String && value.isNotEmpty) {
      return value;
    }

    if (date == null) return '—';
    return DateFormat('dd MMM yyyy • hh:mm a').format(date);
  }

  String _stringify(dynamic value) {
    if (value == null) return '—';
    if (value is num) {
      return value.toString();
    }
    if (value is Timestamp) {
      return _formatTimestamp(value);
    }
    if (value is bool) {
      return value ? 'Yes' : 'No';
    }
    return value.toString();
  }
}
