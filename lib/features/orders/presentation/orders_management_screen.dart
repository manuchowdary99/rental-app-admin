import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/widgets/admin_widgets.dart';

class OrdersManagementScreen extends StatefulWidget {
  const OrdersManagementScreen({super.key});

  @override
  State<OrdersManagementScreen> createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen> {
  String _filterStatus = 'All';

  // ================= ORDER ACTIONS =================

  Future<void> approveOrder(Map<String, dynamic> order) async {
    final batch = FirebaseFirestore.instance.batch();

    batch.update(
      FirebaseFirestore.instance.collection('orders').doc(order['id']),
      {'status': 'confirmed', 'updatedAt': FieldValue.serverTimestamp()},
    );

    if (order['itemId'] != null) {
      batch.update(
        FirebaseFirestore.instance.collection('items').doc(order['itemId']),
        {'status': 'rented', 'updatedAt': FieldValue.serverTimestamp()},
      );
    }

    await batch.commit();
  }

  Future<void> rejectOrder(Map<String, dynamic> order) async {
    final batch = FirebaseFirestore.instance.batch();

    batch.update(
      FirebaseFirestore.instance.collection('orders').doc(order['id']),
      {'status': 'rejected', 'updatedAt': FieldValue.serverTimestamp()},
    );

    if (order['itemId'] != null) {
      batch.update(
        FirebaseFirestore.instance.collection('items').doc(order['itemId']),
        {'status': 'available', 'updatedAt': FieldValue.serverTimestamp()},
      );
    }

    await batch.commit();
  }

  Future<void> markPickedUp(Map<String, dynamic> order) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(order['id'])
        .update({
          'status': 'picked up',
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> markInUse(Map<String, dynamic> order) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(order['id'])
        .update({
          'status': 'in use',
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> markCompleted(Map<String, dynamic> order) async {
    final batch = FirebaseFirestore.instance.batch();

    batch.update(
      FirebaseFirestore.instance.collection('orders').doc(order['id']),
      {'status': 'completed', 'updatedAt': FieldValue.serverTimestamp()},
    );

    if (order['itemId'] != null) {
      batch.update(
        FirebaseFirestore.instance.collection('items').doc(order['itemId']),
        {'status': 'available', 'updatedAt': FieldValue.serverTimestamp()},
      );
    }

    await batch.commit();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6EE),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterChips(),
            Expanded(child: _buildOrdersList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF781C2E), Color(0xFF5A1521)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF781C2E).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.shopping_bag, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Orders Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Track and manage rental orders',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= FILTERS =================

  Widget _buildFilterChips() {
    final filters = [
      'All',
      'Requested',
      'Confirmed',
      'Picked Up',
      'In Use',
      'Completed',
      'Rejected',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((f) {
          final selected = _filterStatus == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f),
              selected: selected,
              onSelected: (_) => setState(() => _filterStatus = f),
              selectedColor: const Color(0xFF781C2E),
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ================= ORDERS LIST =================

  Widget _buildOrdersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();

        final filtered = _filterStatus == 'All'
            ? orders
            : orders
                  .where(
                    (o) =>
                        (o['status'] ?? '').toString().toLowerCase() ==
                        _filterStatus.toLowerCase(),
                  )
                  .toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No orders'));
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, i) => _buildOrderCard(filtered[i]),
        );
      },
    );
  }

  // ================= ORDER CARD =================

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = (order['status'] ?? '').toString().toLowerCase();

    return Card(
      margin: const EdgeInsets.all(12),
      child: Column(
        children: [
          ListTile(
            title: Text(order['itemName'] ?? 'Item'),
            subtitle: Text(order['customerName'] ?? ''),
            trailing: Text(status),
          ),

          if (status == 'requested')
            _button(
              'Approve',
              const Color(0xFF781C2E),
              () => approveOrder(order),
            ),
          if (status == 'requested')
            _button(
              'Reject',
              const Color(0xFFDC2626),
              () => rejectOrder(order),
            ),

          if (status == 'confirmed')
            _button(
              'Mark Picked Up',
              const Color(0xFF8B2635),
              () => markPickedUp(order),
            ),

          if (status == 'picked up')
            _button(
              'Start Rental',
              const Color(0xFF9E2F3C),
              () => markInUse(order),
            ),

          if (status == 'in use')
            _button(
              'Complete Order',
              const Color(0xFF6B1926),
              () => markCompleted(order),
            ),
        ],
      ),
    );
  }

  Widget _button(String text, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: color.withOpacity(0.3),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: onTap,
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
