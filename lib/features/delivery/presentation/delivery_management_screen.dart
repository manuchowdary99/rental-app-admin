import 'package:flutter/material.dart';

import '../../../core/widgets/admin_widgets.dart';

class DeliveryManagementScreen extends StatefulWidget {
  const DeliveryManagementScreen({super.key});

  @override
  State<DeliveryManagementScreen> createState() =>
      _DeliveryManagementScreenState();
}

class _DeliveryManagementScreenState extends State<DeliveryManagementScreen> {
  String _filterStatus = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6EE),
      body: SafeArea(
        child: Column(
          children: [
            /// TOP SECTION (SCROLL SAFE)
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildStatsRow(),
                  _buildFilterChips(),
                ],
              ),
            ),

            /// DELIVERY PARTNERS LIST
            Expanded(child: _buildDeliveryPartnersList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPartner,
        backgroundColor: const Color(0xFF781C2E),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
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
            child: const Icon(
              Icons.delivery_dining_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Partners',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage delivery team',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- STATS ROW (FIXED) ----------------
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: const [
          Expanded(
            child: StatCard(
              title: 'Total',
              value: '12',
              icon: Icons.people_outline_rounded,
              color: Color(0xFF781C2E),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: StatCard(
              title: 'Available',
              value: '8',
              icon: Icons.check_circle_rounded,
              color: Color(0xFF8B2635),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: StatCard(
              title: 'On Duty',
              value: '4',
              icon: Icons.local_shipping_rounded,
              color: Color(0xFF9E2F3C),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- FILTER CHIPS ----------------
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('All'),
            _filterChip('Available'),
            _filterChip('On Delivery'),
            _filterChip('Off Duty'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String filter) {
    final selected = _filterStatus == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filterStatus = filter),
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
            filter,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- DELIVERY LIST ----------------
  Widget _buildDeliveryPartnersList() {
    final partners = _generateDummyPartners().where((p) {
      if (_filterStatus == 'All') return true;
      return p['status'] == _filterStatus;
    }).toList();

    if (partners.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.delivery_dining_rounded,
          title: 'No delivery partners',
          subtitle: 'Add delivery partners to manage your fleet',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: partners.length,
      itemBuilder: (context, index) => _buildPartnerCard(partners[index]),
    );
  }

  Widget _buildPartnerCard(Map<String, dynamic> partner) {
    return AdminCard(
      child: Text(
        partner['name'],
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ---------------- ACTIONS ----------------
  void _addNewPartner() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add new partner feature coming soon'),
        backgroundColor: Color(0xFF781C2E),
      ),
    );
  }

  List<Map<String, dynamic>> _generateDummyPartners() => [
    {'name': 'Mike Wilson', 'status': 'On Delivery'},
    {'name': 'Sarah Lee', 'status': 'Available'},
    {'name': 'Alex Rodriguez', 'status': 'Off Duty'},
  ];
}
