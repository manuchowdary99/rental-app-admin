import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/widgets/admin_widgets.dart';
import 'admin_order_details_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _selectedType = 'all'; // all | rental | sale
  String _selectedStatus = 'all'; // all | active | completed

  final Map<String, String> _userCache = {};

  // -------- SAFE HELPERS --------
  String _safeText(dynamic v, {String fallback = '—'}) {
    if (v == null) return fallback;
    return v.toString();
  }

  String _safeUpper(dynamic v, {String fallback = '—'}) {
    if (v == null) return fallback;
    return v.toString().toUpperCase();
  }

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6EE),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildStatsRow(),
            const SizedBox(height: 16),
            _buildTypeFilters(),
            const SizedBox(height: 8),
            _buildStatusFilters(),
            const SizedBox(height: 12),
            Expanded(child: _buildOrdersList()),
          ],
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: const [
          Icon(Icons.receipt_long_rounded, size: 28, color: Color(0xFF781C2E)),
          SizedBox(width: 12),
          Text(
            'Orders',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- STATS ----------------
  Widget _buildStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        int total = 0;
        int completed = 0;

        if (snapshot.hasData) {
          total = snapshot.data!.docs.length;
          for (final d in snapshot.data!.docs) {
            final data = d.data() as Map<String, dynamic>;
            if (data['paymentStatus'] == 'completed') {
              completed++;
            }
          }
        }

        final active = total - completed;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total',
                  value: total.toString(),
                  icon: Icons.list_alt_rounded,
                  color: const Color(0xFF781C2E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Active',
                  value: active.toString(),
                  icon: Icons.timelapse_rounded,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Completed',
                  value: completed.toString(),
                  icon: Icons.check_circle_rounded,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- FILTERS ----------------
  Widget _buildTypeFilters() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _filterChip('All', _selectedType == 'all',
            () => setState(() => _selectedType = 'all')),
        const SizedBox(width: 8),
        _filterChip('Rentals', _selectedType == 'rental',
            () => setState(() => _selectedType = 'rental')),
        const SizedBox(width: 8),
        _filterChip('Sales', _selectedType == 'sale',
            () => setState(() => _selectedType = 'sale')),
      ],
    );
  }

  Widget _buildStatusFilters() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _filterChip('All', _selectedStatus == 'all',
            () => setState(() => _selectedStatus = 'all')),
        const SizedBox(width: 8),
        _filterChip('Active', _selectedStatus == 'active',
            () => setState(() => _selectedStatus = 'active')),
        const SizedBox(width: 8),
        _filterChip('Completed', _selectedStatus == 'completed',
            () => setState(() => _selectedStatus = 'completed')),
      ],
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF781C2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF781C2E) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  // ---------------- ORDERS LIST ----------------
  Widget _buildOrdersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoadingState(message: 'Loading orders...');
        }

        final filtered = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          if (_selectedType != 'all' && data['orderType'] != _selectedType) {
            return false;
          }

          if (_selectedStatus == 'completed' &&
              data['paymentStatus'] != 'completed') {
            return false;
          }

          if (_selectedStatus == 'active' &&
              data['paymentStatus'] == 'completed') {
            return false;
          }

          return true;
        }).toList();

        if (filtered.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'No orders',
            subtitle: 'No orders match the selected filters',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final doc = filtered[index];
            return _orderCard(doc.id, doc.data() as Map<String, dynamic>);
          },
        );
      },
    );
  }

  // ---------------- ORDER CARD ----------------
  Widget _orderCard(String orderId, Map<String, dynamic> data) {
    final userId = data['userId'];

    if (userId != null && !_userCache.containsKey(userId)) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get()
          .then((u) {
        _userCache[userId] = u.data()?['displayName'] ?? 'Unknown';
        if (mounted) setState(() {});
      });
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminOrderDetailsScreen(orderId: orderId),
          ),
        );
      },
      child: AdminCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _safeText(data['orderNumber'], fallback: orderId),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              userId == null
                  ? 'Unknown user'
                  : _userCache[userId] ?? 'Loading...',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                StatusChip(
                  text: _safeUpper(data['orderType'], fallback: 'UNKNOWN'),
                  color: data['orderType'] == 'rental'
                      ? Colors.orange
                      : Colors.green,
                  isSmall: true,
                ),
                const SizedBox(width: 8),
                StatusChip(
                  text: _safeUpper(data['paymentStatus'], fallback: 'PENDING'),
                  color: data['paymentStatus'] == 'completed'
                      ? Colors.green
                      : Colors.orange,
                  isSmall: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
