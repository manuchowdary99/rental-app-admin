import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/widgets/admin_widgets.dart';

class AdminOrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const AdminOrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<AdminOrderDetailsScreen> createState() =>
      _AdminOrderDetailsScreenState();
}

class _AdminOrderDetailsScreenState extends State<AdminOrderDetailsScreen> {
  final Map<String, String> _userCache = {};

  // ================= MAIN =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6EE),
      appBar: AppBar(title: const Text('Order Details')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoadingState(message: 'Loading order...');
          }

          if (!snapshot.data!.exists) {
            return const EmptyState(
              icon: Icons.receipt_long,
              title: 'Order not found',
              subtitle: 'This order does not exist',
            );
          }

          final order = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _orderHeader(order),
                const SizedBox(height: 16),
                _statsRow(),
                const SizedBox(height: 16),
                _userSection(order),
                const SizedBox(height: 16),
                _itemsSection(),
                const SizedBox(height: 16),
                _rentalHistorySection(),
                const SizedBox(height: 16),
                _timelineSection(order),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= HEADER =================
  Widget _orderHeader(Map<String, dynamic> order) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order['orderNumber'] ?? widget.orderId,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              StatusChip(
                text: (order['orderType'] ?? '—').toUpperCase(),
                color: Colors.orange,
                isSmall: true,
              ),
              const SizedBox(width: 8),
              StatusChip(
                text: order['orderStatus'] ?? '—',
                color: Colors.green,
                isSmall: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= STATS ROW =================
  Widget _statsRow() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .collection('rentals')
          .doc('details')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final rental = snapshot.data!.data() as Map<String, dynamic>;

        return Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Deposit',
                value: '₹ ${rental['depositAmount'] ?? 0}',
                icon: Icons.account_balance_wallet,
                color: Colors.brown,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Return',
                value: rental['returnStatus'] ?? 'pending',
                icon: Icons.assignment_return,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Refund',
                value: rental['refundStatus'] ?? 'pending',
                icon: Icons.currency_rupee,
                color: Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  // ================= USER =================
  Widget _userSection(Map<String, dynamic> order) {
    final userId = order['userId'];
    if (userId == null) return const SizedBox.shrink();

    if (!_userCache.containsKey(userId)) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get()
          .then((doc) {
        _userCache[userId] = doc.data()?['displayName'] ?? 'Unknown User';
        if (mounted) setState(() {});
      });
    }

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(_userCache[userId] ?? 'Loading...'),
        ],
      ),
    );
  }

  // ================= ITEMS =================
  Widget _itemsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .collection('items')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        return AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Items',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...snapshot.data!.docs.map((doc) {
                final item = doc.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item['productName'] ?? 'Item'),
                      Text('₹ ${item['totalPrice'] ?? 0}'),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ================= RENTAL HISTORY =================
  Widget _rentalHistorySection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .collection('rentals')
          .doc('details')
          .snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic>? rental;

        if (snapshot.hasData && snapshot.data!.exists) {
          rental = snapshot.data!.data() as Map<String, dynamic>;
        }

        return AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rental History',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _row('Start Date', _fmt(rental?['startDate'])),
              _row('End Date', _fmt(rental?['endDate'])),
              _row('Deposit', '₹ ${rental?['depositAmount'] ?? 0}'),
              _row('Return Status', rental?['returnStatus'] ?? '—'),
              _row('Returned At', _fmt(rental?['returnedAt'])),
              _row('Refund Status', rental?['refundStatus'] ?? '—'),
              _row('Refunded At', _fmt(rental?['refundedAt'])),
              const SizedBox(height: 16),
              if (rental != null && rental['returnStatus'] != 'returned')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _markReturned,
                    child: const Text('Mark Returned'),
                  ),
                ),
              if (rental != null &&
                  rental['returnStatus'] == 'returned' &&
                  rental['refundStatus'] != 'refunded')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        _refundDeposit(rental?['depositAmount'] ?? 0),
                    child: const Text('Refund Deposit'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ================= TIMELINE =================
  Widget _timelineSection(Map<String, dynamic> order) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .collection('rentals')
          .doc('details')
          .snapshots(),
      builder: (context, snapshot) {
        final List<_TimelineEvent> events = [];

        events.add(
          _TimelineEvent(
            title: 'Order Created',
            time: order['createdAt'],
            icon: Icons.receipt_long,
          ),
        );

        if (snapshot.hasData && snapshot.data!.exists) {
          final rental = snapshot.data!.data() as Map<String, dynamic>;

          if (rental['returnedAt'] != null) {
            events.add(
              _TimelineEvent(
                title: 'Item Returned',
                time: rental['returnedAt'],
                icon: Icons.assignment_return,
              ),
            );
          }

          if (rental['refundedAt'] != null) {
            events.add(
              _TimelineEvent(
                title: 'Deposit Refunded',
                time: rental['refundedAt'],
                icon: Icons.currency_rupee,
              ),
            );
          }
        }

        events.sort((a, b) {
          final at = a.time?.millisecondsSinceEpoch ?? 0;
          final bt = b.time?.millisecondsSinceEpoch ?? 0;
          return at.compareTo(bt);
        });

        return AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Timeline',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...events.map(_timelineRow),
            ],
          ),
        );
      },
    );
  }

  Widget _timelineRow(_TimelineEvent event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(event.icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                _fmt(event.time),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= ACTIONS =================
  Future<void> _markReturned() async {
    final rentalRef = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .collection('rentals')
        .doc('details');

    await rentalRef.update({
      'returnStatus': 'returned',
      'returnedAt': Timestamp.now(),
    });

    if (mounted) setState(() {});
  }

  Future<void> _refundDeposit(int amount) async {
    final firestore = FirebaseFirestore.instance;
    final orderRef = firestore.collection('orders').doc(widget.orderId);
    final rentalRef = orderRef.collection('rentals').doc('details');

    final orderSnap = await orderRef.get();
    final userId = orderSnap['userId'];

    final batch = firestore.batch();

    batch.update(rentalRef, {
      'refundStatus': 'refunded',
      'refundedAt': Timestamp.now(),
    });

    batch.set(orderRef.collection('transactions').doc(), {
      'type': 'refund',
      'amount': amount,
      'createdAt': Timestamp.now(),
    });

    batch.set(
      firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(),
      {
        'title': 'Deposit Refunded',
        'body': '₹$amount has been refunded',
        'type': 'refund',
        'orderId': widget.orderId,
        'isRead': false,
        'createdAt': Timestamp.now(),
      },
    );

    await batch.commit();

    if (mounted) setState(() {});
  }

  // ================= HELPERS =================
  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _fmt(dynamic value) {
    if (value == null || value is! Timestamp) return '—';
    final d = value.toDate();
    return '${d.day.toString().padLeft(2, '0')} '
        '${_month(d.month)} ${d.year}, '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  String _month(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[m - 1];
  }
}

class _TimelineEvent {
  final String title;
  final Timestamp? time;
  final IconData icon;

  _TimelineEvent({
    required this.title,
    required this.time,
    required this.icon,
  });
}
