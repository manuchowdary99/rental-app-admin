import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/widgets/admin_widgets.dart';
import '../../../core/services/auth_service.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6EE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(ref),
              const SizedBox(height: 24),
              _buildStatsCards(),
              const SizedBox(height: 32),
              _buildRecentActivity(),
              const SizedBox(height: 24),
              _buildOrdersDistribution(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref) {
    return Row(
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
            Icons.dashboard_rounded,
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
                'Admin Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                'Rental platform overview',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () => ref.read(authServiceProvider).signOut(),
            child: const Icon(
              Icons.logout_rounded,
              color: Color(0xFF781C2E),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, ordersSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, usersSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('complaints')
                  .snapshots(),
              builder: (context, complaintsSnapshot) {
                // Calculate real-time stats
                String totalUsers = '0';
                String activeRentals = '0';
                String ongoingOrders = '0';
                String openComplaints = '0';

                if (usersSnapshot.hasData) {
                  totalUsers = usersSnapshot.data!.docs.length.toString();
                }

                if (ordersSnapshot.hasData) {
                  final orders = ordersSnapshot.data!.docs;

                  // Count active rentals (confirmed, picked up, in use)
                  final activeCount = orders.where((doc) {
                    final status =
                        (doc.data() as Map<String, dynamic>)['status']
                            ?.toString()
                            .toLowerCase();
                    return status == 'confirmed' ||
                        status == 'picked up' ||
                        status == 'in use';
                  }).length;
                  activeRentals = activeCount.toString();

                  // Count ongoing orders (requested, confirmed, picked up)
                  final ongoingCount = orders.where((doc) {
                    final status =
                        (doc.data() as Map<String, dynamic>)['status']
                            ?.toString()
                            .toLowerCase();
                    return status == 'requested' ||
                        status == 'confirmed' ||
                        status == 'picked up';
                  }).length;
                  ongoingOrders = ongoingCount.toString();
                }

                if (complaintsSnapshot.hasData) {
                  final complaints = complaintsSnapshot.data!.docs;
                  final openCount = complaints.where((doc) {
                    final status =
                        (doc.data() as Map<String, dynamic>)['status']
                            ?.toString()
                            .toLowerCase();
                    return status == 'open' || status == 'in progress';
                  }).length;
                  openComplaints = openCount.toString();
                }

                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    StatCard(
                      title: 'Total Users',
                      value: totalUsers,
                      icon: Icons.people_rounded,
                      color: const Color(0xFF781C2E),
                      subtitle: 'Registered users',
                    ),
                    StatCard(
                      title: 'Active Rentals',
                      value: activeRentals,
                      icon: Icons.shopping_bag_rounded,
                      color: const Color(0xFF8B2635),
                      subtitle: 'Currently active',
                    ),
                    StatCard(
                      title: 'Ongoing Orders',
                      value: ongoingOrders,
                      icon: Icons.local_shipping_rounded,
                      color: const Color(0xFF9E2F3C),
                      subtitle: 'In process',
                    ),
                    StatCard(
                      title: 'Open Complaints',
                      value: openComplaints,
                      icon: Icons.support_agent_rounded,
                      color: const Color(0xFFB13843),
                      subtitle: 'Needs attention',
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Recent Orders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {}, // Navigate to orders
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF781C2E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          children: List.generate(5, (index) => _buildRecentOrderItem(index)),
        ),
      ],
    );
  }

  Widget _buildRecentOrderItem(int index) {
    final orders = [
      {
        'id': '#ORD-2024-001',
        'user': 'John Doe',
        'item': 'Camera Equipment',
        'status': 'Delivered',
        'color': const Color(0xFF781C2E),
        'time': '2 hours ago',
      },
      {
        'id': '#ORD-2024-002',
        'user': 'Sarah Smith',
        'item': 'Power Tools',
        'status': 'In Transit',
        'color': const Color(0xFF8B2635),
        'time': '4 hours ago',
      },
      {
        'id': '#ORD-2024-003',
        'user': 'Mike Johnson',
        'item': 'Event Supplies',
        'status': 'Picked Up',
        'color': const Color(0xFF9E2F3C),
        'time': '6 hours ago',
      },
      {
        'id': '#ORD-2024-004',
        'user': 'Emily Davis',
        'item': 'Camping Gear',
        'status': 'Requested',
        'color': const Color(0xFFB13843),
        'time': '8 hours ago',
      },
      {
        'id': '#ORD-2024-005',
        'user': 'Alex Wilson',
        'item': 'Sports Equipment',
        'status': 'Returned',
        'color': const Color(0xFF781C2E),
        'time': '10 hours ago',
      },
    ];

    final order = orders[index];

    return AdminCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: order['color'] as Color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getStatusIcon(order['status'] as String),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      order['id'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      order['time'] as String,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${order['user']} - ${order['item']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                StatusChip(
                  text: order['status'] as String,
                  color: order['color'] as Color,
                  isSmall: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersDistribution() {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Orders Status Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          _buildDistributionItem('Delivered', 45, const Color(0xFF781C2E)),
          const SizedBox(height: 12),
          _buildDistributionItem('In Use', 28, const Color(0xFF8B2635)),
          const SizedBox(height: 12),
          _buildDistributionItem('Pending', 18, const Color(0xFF9E2F3C)),
          const SizedBox(height: 12),
          _buildDistributionItem('Returned', 9, const Color(0xFFB13843)),
          const SizedBox(height: 16),
          Container(
            height: 60,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F6EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.trending_up_rounded, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  'Orders increased by 23% this week',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionItem(String label, int percentage, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'in transit':
        return Icons.local_shipping_rounded;
      case 'picked up':
        return Icons.inventory_rounded;
      case 'requested':
        return Icons.schedule_rounded;
      case 'returned':
        return Icons.assignment_return_rounded;
      default:
        return Icons.circle;
    }
  }
}
