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
            Expanded(child: _buildOrdersList()),
          ],
        ),
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
              Icons.shopping_bag_rounded,
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
                  'Orders Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
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

  Widget _buildStatsRow() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: const Row(
        children: [
          Expanded(
            child: StatCard(
              title: 'Total',
              value: '156',
              icon: Icons.shopping_bag_outlined,
              color: Color(0xFF781C2E),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: StatCard(
              title: 'Active',
              value: '89',
              icon: Icons.trending_up_rounded,
              color: Color(0xFF8B2635),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: StatCard(
              title: 'Pending',
              value: '23',
              icon: Icons.schedule_rounded,
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
            _buildFilterChip('Requested'),
            const SizedBox(width: 8),
            _buildFilterChip('Confirmed'),
            const SizedBox(width: 8),
            _buildFilterChip('Picked Up'),
            const SizedBox(width: 8),
            _buildFilterChip('In Use'),
            const SizedBox(width: 8),
            _buildFilterChip('Returned'),
            const SizedBox(width: 8),
            _buildFilterChip('Completed'),
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

  Widget _buildOrdersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Something went wrong',
              subtitle: 'Unable to load orders at this time',
            ),
          );
        }

        if (!snapshot.hasData) {
          return const LoadingState(message: 'Loading orders...');
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'No orders found',
              subtitle: 'Orders will appear here once users start renting',
            ),
          );
        }

        // Generate dummy orders for demonstration
        final dummyOrders = _generateDummyOrders();

        // Apply filter
        final filteredOrders = dummyOrders.where((order) {
          if (_filterStatus == 'All') return true;
          return order['status'] == _filterStatus;
        }).toList();

        if (filteredOrders.isEmpty) {
          return const Center(
            child: EmptyState(
              icon: Icons.filter_list_off_rounded,
              title: 'No orders match filter',
              subtitle: 'Try selecting a different status filter',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            final order = filteredOrders[index];
            return _buildOrderCard(order);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return AdminCard(
      onTap: () => _showOrderDetails(order),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getStatusColor(order['status']),
                      _getStatusColor(order['status']).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStatusIcon(order['status']),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['id'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      order['itemName'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Customer: ${order['customerName']}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              StatusChip(
                text: order['status'],
                color: _getStatusColor(order['status']),
                isSmall: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOrderDetail(
                  'Rental Period',
                  '${order['startDate']} - ${order['endDate']}',
                  Icons.calendar_today_rounded,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey[200]),
              Expanded(
                child: _buildOrderDetail(
                  'Total Amount',
                  '\$${order['totalAmount']}',
                  Icons.attach_money_rounded,
                ),
              ),
            ],
          ),
          if (order['deliveryPartner'] != null) ...[
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
                    Icons.delivery_dining_rounded,
                    color: Color(0xFF781C2E),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Assigned to: ${order['deliveryPartner']}',
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

  Widget _buildOrderDetail(String title, String value, IconData icon) {
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

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
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
                    child: _buildOrderDetailsContent(order),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderDetailsContent(Map<String, dynamic> order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Order Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            StatusChip(
              text: order['status'],
              color: _getStatusColor(order['status']),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Order Info
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order['id'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Item', order['itemName']),
              const SizedBox(height: 12),
              _buildDetailRow('Customer', order['customerName']),
              const SizedBox(height: 12),
              _buildDetailRow('Phone', order['customerPhone']),
              const SizedBox(height: 12),
              _buildDetailRow('Start Date', order['startDate']),
              const SizedBox(height: 12),
              _buildDetailRow('End Date', order['endDate']),
              const SizedBox(height: 12),
              _buildDetailRow('Total Amount', '\$${order['totalAmount']}'),
              if (order['deliveryPartner'] != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow('Delivery Partner', order['deliveryPartner']),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Order Timeline
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Timeline',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              _buildTimelineItem('Order Requested', true, '2 hours ago'),
              _buildTimelineItem('Order Confirmed', true, '1.5 hours ago'),
              _buildTimelineItem(
                'Assigned to Delivery Partner',
                order['status'] != 'Requested',
                '1 hour ago',
              ),
              _buildTimelineItem(
                'Item Picked Up',
                order['status'] == 'In Use' ||
                    order['status'] == 'Returned' ||
                    order['status'] == 'Completed',
                order['status'] == 'In Use' ? '30 mins ago' : null,
              ),
              _buildTimelineItem(
                'Item in Use',
                order['status'] == 'In Use' ||
                    order['status'] == 'Returned' ||
                    order['status'] == 'Completed',
                order['status'] == 'In Use' ? 'Currently' : null,
              ),
              _buildTimelineItem(
                'Item Returned',
                order['status'] == 'Returned' || order['status'] == 'Completed',
                null,
              ),
              _buildTimelineItem(
                'Order Completed',
                order['status'] == 'Completed',
                null,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Actions
        if (order['status'] != 'Completed' &&
            order['status'] != 'Cancelled') ...[
          Row(
            children: [
              Expanded(
                child: AdminButton(
                  text: _getNextActionText(order['status']),
                  onPressed: () => _performOrderAction(order),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminButton(
                  text: 'Reassign',
                  isOutlined: true,
                  icon: Icons.person_add_rounded,
                  onPressed: () => _reassignOrder(order),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: AdminButton(
              text: 'Cancel Order',
              color: Colors.red,
              icon: Icons.cancel_rounded,
              onPressed: () => _cancelOrder(order),
            ),
          ),
        ],
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

  Widget _buildTimelineItem(String title, bool isCompleted, String? timestamp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: isCompleted
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? const Color(0xFF1E293B) : Colors.grey,
                  ),
                ),
                if (timestamp != null)
                  Text(
                    timestamp,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getNextActionText(String status) {
    switch (status) {
      case 'Requested':
        return 'Confirm Order';
      case 'Confirmed':
        return 'Mark Picked Up';
      case 'Picked Up':
        return 'Mark In Use';
      case 'In Use':
        return 'Mark Returned';
      case 'Returned':
        return 'Complete Order';
      default:
        return 'Update Status';
    }
  }

  void _performOrderAction(Map<String, dynamic> order) {
    // Simulate order action
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order status updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _reassignOrder(Map<String, dynamic> order) {
    // Show reassignment dialog
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order reassigned successfully'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _cancelOrder(Map<String, dynamic> order) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order cancelled'),
        backgroundColor: Colors.red,
      ),
    );
  }

  List<Map<String, dynamic>> _generateDummyOrders() {
    return [
      {
        'id': '#ORD-2024-001',
        'itemName': 'Professional Camera Set',
        'customerName': 'John Doe',
        'customerPhone': '+1234567890',
        'status': 'In Use',
        'startDate': '15 Dec 2024',
        'endDate': '18 Dec 2024',
        'totalAmount': '450',
        'deliveryPartner': 'Mike Wilson',
      },
      {
        'id': '#ORD-2024-002',
        'itemName': 'Power Drill Kit',
        'customerName': 'Sarah Smith',
        'customerPhone': '+1234567891',
        'status': 'Picked Up',
        'startDate': '14 Dec 2024',
        'endDate': '16 Dec 2024',
        'totalAmount': '120',
        'deliveryPartner': 'John Carter',
      },
      {
        'id': '#ORD-2024-003',
        'itemName': 'Party Tent Large',
        'customerName': 'Mike Johnson',
        'customerPhone': '+1234567892',
        'status': 'Confirmed',
        'startDate': '16 Dec 2024',
        'endDate': '20 Dec 2024',
        'totalAmount': '280',
        'deliveryPartner': 'Sarah Lee',
      },
      {
        'id': '#ORD-2024-004',
        'itemName': 'Camping Equipment Bundle',
        'customerName': 'Emily Davis',
        'customerPhone': '+1234567893',
        'status': 'Requested',
        'startDate': '17 Dec 2024',
        'endDate': '19 Dec 2024',
        'totalAmount': '200',
        'deliveryPartner': null,
      },
      {
        'id': '#ORD-2024-005',
        'itemName': 'Sound System Pro',
        'customerName': 'Alex Wilson',
        'customerPhone': '+1234567894',
        'status': 'Completed',
        'startDate': '10 Dec 2024',
        'endDate': '13 Dec 2024',
        'totalAmount': '350',
        'deliveryPartner': 'Mike Wilson',
      },
    ];
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return const Color(0xFFB13843);
      case 'confirmed':
        return const Color(0xFF781C2E);
      case 'picked up':
        return const Color(0xFF8B2635);
      case 'in use':
        return const Color(0xFF9E2F3C);
      case 'returned':
        return const Color(0xFF781C2E);
      case 'completed':
        return const Color(0xFF6B1926);
      case 'cancelled':
        return const Color(0xFFB13843);
      default:
        return const Color(0xFF781C2E);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return Icons.schedule_rounded;
      case 'confirmed':
        return Icons.check_circle_rounded;
      case 'picked up':
        return Icons.inventory_rounded;
      case 'in use':
        return Icons.play_circle_rounded;
      case 'returned':
        return Icons.assignment_return_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }
}
