import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ItemsListScreen extends StatelessWidget {
  const ItemsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final itemsRef = FirebaseFirestore.instance.collection('items');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern AppBar
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Items Management',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Manage rental items and listings',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Items List
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: itemsRef.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _buildErrorState('Error: ${snapshot.error}');
                      }
                      if (!snapshot.hasData) {
                        return _buildLoadingState();
                      }

                      final docs = snapshot.data!.docs;

                      if (docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildItemCard(context, doc, data, itemsRef);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
    CollectionReference itemsRef,
  ) {
    final title = data['title']?.toString() ?? 'No Title';
    final ownerId = data['ownerId']?.toString() ?? 'Unknown Owner';
    final status = data['status'] as String? ?? 'available';
    final pricePerDay = (data['rentalPricePerDay'] ?? 0).toDouble();
    final imageUrl = data['imageUrl'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Item Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                    image: imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imageUrl == null
                      ? Icon(
                          Icons.inventory_2_rounded,
                          color: Colors.grey[400],
                          size: 30,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // Item Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Owner: ${ownerId.length > 20 ? '${ownerId.substring(0, 20)}...' : ownerId}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${pricePerDay.toStringAsFixed(2)}/day',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Actions
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        itemsRef.doc(doc.id).update({'status': value});
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'pending',
                          child: Row(
                            children: [
                              Icon(
                                Icons.pending_outlined,
                                size: 18,
                                color: Color(0xFFF59E0B),
                              ),
                              SizedBox(width: 8),
                              Text('Set as Pending'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'approved',
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 18,
                                color: Color(0xFF10B981),
                              ),
                              SizedBox(width: 8),
                              Text('Set as Approved'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'available',
                          child: Row(
                            children: [
                              Icon(
                                Icons.inventory_rounded,
                                size: 18,
                                color: Color(0xFF667eea),
                              ),
                              SizedBox(width: 8),
                              Text('Set as Available'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'rented',
                          child: Row(
                            children: [
                              Icon(
                                Icons.handshake_outlined,
                                size: 18,
                                color: Color(0xFF8B5CF6),
                              ),
                              SizedBox(width: 8),
                              Text('Set as Rented'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'returned',
                          child: Row(
                            children: [
                              Icon(
                                Icons.assignment_return_outlined,
                                size: 18,
                                color: Color(0xFF06B6D4),
                              ),
                              SizedBox(width: 8),
                              Text('Set as Returned'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.settings_outlined,
                              size: 18,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Change Status',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'approved':
      case 'available':
        return const Color(0xFF10B981);
      case 'rented':
        return const Color(0xFF8B5CF6);
      case 'returned':
        return const Color(0xFF06B6D4);
      default:
        return const Color(0xFF667eea);
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading items...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Items Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Items will appear here once they are listed',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
