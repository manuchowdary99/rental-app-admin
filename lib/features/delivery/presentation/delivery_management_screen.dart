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
            _buildHeader(),
            _buildStatsRow(),
            _buildFilterChips(),
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

  Widget _buildHeader() {
    return Container(
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
              size: 24,
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

  Widget _buildStatsRow() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: const Row(
        children: [
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

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All'),
            const SizedBox(width: 8),
            _buildFilterChip('Available'),
            const SizedBox(width: 8),
            _buildFilterChip('On Delivery'),
            const SizedBox(width: 8),
            _buildFilterChip('Off Duty'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = _filterStatus == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterStatus = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF781C2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF781C2E) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          filter,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryPartnersList() {
    final partners = _generateDummyPartners();

    final filteredPartners = partners.where((partner) {
      if (_filterStatus == 'All') return true;
      return partner['status'] == _filterStatus;
    }).toList();

    if (filteredPartners.isEmpty) {
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
      itemCount: filteredPartners.length,
      itemBuilder: (context, index) {
        final partner = filteredPartners[index];
        return _buildPartnerCard(partner);
      },
    );
  }

  Widget _buildPartnerCard(Map<String, dynamic> partner) {
    return AdminCard(
      onTap: () => _showPartnerDetails(partner),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getStatusColor(partner['status']),
                      _getStatusColor(partner['status']).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor(
                        partner['status'],
                      ).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: partner['avatar'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          partner['avatar'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            partner['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        StatusChip(
                          text: partner['status'],
                          color: _getStatusColor(partner['status']),
                          isSmall: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      partner['phone'],
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPartnerStat(
                  'Rating',
                  '${partner['rating']}/5',
                  Icons.star_rounded,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey[200]),
              Expanded(
                child: _buildPartnerStat(
                  'Deliveries',
                  '${partner['totalDeliveries']}',
                  Icons.local_shipping_rounded,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey[200]),
              Expanded(
                child: _buildPartnerStat(
                  'Location',
                  partner['currentLocation'],
                  Icons.location_on_rounded,
                ),
              ),
            ],
          ),
          if (partner['currentOrder'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F6EE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.assignment_rounded,
                    color: Color(0xFF781C2E),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Current Order: ${partner['currentOrder']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF781C2E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPartnerStat(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showPartnerDetails(Map<String, dynamic> partner) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: _buildPartnerDetailsContent(partner),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPartnerDetailsContent(Map<String, dynamic> partner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Partner Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            StatusChip(
              text: partner['status'],
              color: _getStatusColor(partner['status']),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Partner Info
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getStatusColor(partner['status']),
                          _getStatusColor(partner['status']).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partner['name'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          partner['phone'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _buildDetailRow('Partner ID', partner['id']),
              const SizedBox(height: 12),
              _buildDetailRow('Vehicle Type', partner['vehicleType']),
              const SizedBox(height: 12),
              _buildDetailRow('License Plate', partner['licensePlate']),
              const SizedBox(height: 12),
              _buildDetailRow('Rating', '${partner['rating']}/5 ⭐'),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Total Deliveries',
                '${partner['totalDeliveries']}',
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Joined Date', partner['joinedDate']),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Recent Deliveries
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Deliveries',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(3, (index) {
                final deliveries = [
                  {
                    'order': '#ORD-2024-001',
                    'status': 'Completed',
                    'time': '2 hours ago',
                  },
                  {
                    'order': '#ORD-2024-002',
                    'status': 'Completed',
                    'time': '1 day ago',
                  },
                  {
                    'order': '#ORD-2024-003',
                    'status': 'Completed',
                    'time': '2 days ago',
                  },
                ];
                return _buildDeliveryItem(deliveries[index]);
              }),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Actions
        if (partner['status'] != 'Off Duty') ...[
          Row(
            children: [
              Expanded(
                child: AdminButton(
                  text: partner['status'] == 'Available'
                      ? 'Assign Order'
                      : 'View Current Order',
                  onPressed: () => _assignOrder(partner),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminButton(
                  text: 'Call Partner',
                  isOutlined: true,
                  icon: Icons.phone_rounded,
                  onPressed: () => _callPartner(partner),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: AdminButton(
            text: partner['status'] == 'Off Duty'
                ? 'Activate Partner'
                : 'Set Off Duty',
            color: partner['status'] == 'Off Duty'
                ? Colors.green
                : Colors.orange,
            icon: partner['status'] == 'Off Duty'
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            onPressed: () => _togglePartnerStatus(partner),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryItem(Map<String, dynamic> delivery) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6EE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              delivery['order'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Text(
            delivery['time'],
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _addNewPartner() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add new partner feature coming soon'),
        backgroundColor: Color(0xFF781C2E),
      ),
    );
  }

  void _assignOrder(Map<String, dynamic> partner) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order assigned successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _callPartner(Map<String, dynamic> partner) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${partner['name']}...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _togglePartnerStatus(Map<String, dynamic> partner) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partner status updated'),
        backgroundColor: partner['status'] == 'Off Duty'
            ? Colors.green
            : Colors.orange,
      ),
    );
  }

  List<Map<String, dynamic>> _generateDummyPartners() {
    return [
      {
        'id': 'DP-001',
        'name': 'Mike Wilson',
        'phone': '+1234567890',
        'status': 'On Delivery',
        'rating': 4.8,
        'totalDeliveries': 156,
        'currentLocation': 'Downtown',
        'vehicleType': 'Motorcycle',
        'licensePlate': 'ABC-123',
        'joinedDate': '15 Jan 2024',
        'currentOrder': '#ORD-2024-001',
        'avatar': null,
      },
      {
        'id': 'DP-002',
        'name': 'Sarah Lee',
        'phone': '+1234567891',
        'status': 'Available',
        'rating': 4.9,
        'totalDeliveries': 203,
        'currentLocation': 'Midtown',
        'vehicleType': 'Van',
        'licensePlate': 'XYZ-456',
        'joinedDate': '02 Feb 2024',
        'currentOrder': null,
        'avatar': null,
      },
      {
        'id': 'DP-003',
        'name': 'John Carter',
        'phone': '+1234567892',
        'status': 'On Delivery',
        'rating': 4.7,
        'totalDeliveries': 98,
        'currentLocation': 'Uptown',
        'vehicleType': 'Truck',
        'licensePlate': 'DEF-789',
        'joinedDate': '10 Mar 2024',
        'currentOrder': '#ORD-2024-002',
        'avatar': null,
      },
      {
        'id': 'DP-004',
        'name': 'Emma Davis',
        'phone': '+1234567893',
        'status': 'Available',
        'rating': 4.6,
        'totalDeliveries': 67,
        'currentLocation': 'Eastside',
        'vehicleType': 'Motorcycle',
        'licensePlate': 'GHI-012',
        'joinedDate': '25 Apr 2024',
        'currentOrder': null,
        'avatar': null,
      },
      {
        'id': 'DP-005',
        'name': 'Alex Rodriguez',
        'phone': '+1234567894',
        'status': 'Off Duty',
        'rating': 4.5,
        'totalDeliveries': 89,
        'currentLocation': 'Westside',
        'vehicleType': 'Van',
        'licensePlate': 'JKL-345',
        'joinedDate': '08 May 2024',
        'currentOrder': null,
        'avatar': null,
      },
    ];
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return const Color(0xFF781C2E);
      case 'on delivery':
        return const Color(0xFF8B2635);
      case 'off duty':
        return const Color(0xFFB13843);
      default:
        return const Color(0xFF781C2E);
    }
  }
}
