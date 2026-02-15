import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/widgets/admin_widgets.dart';
import 'admin_order_details_screen.dart';
import '../../navigation/widgets/admin_app_drawer.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _selectedType = 'all';
  String _selectedStatus = 'all';
  String _searchQuery = '';

  final Map<String, String> _userCache = {};

  // ---------------- SAFE HELPERS ----------------
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
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
        child: SafeArea(
          top: false,
          child: CustomScrollView(
            slivers: [
              // ================= HEADER (SCROLLS AWAY) =================
              SliverToBoxAdapter(child: _buildHeader(context)),

              // ================= STATS (SCROLLS AWAY) =================
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildStatsRow(),
                ),
              ),

              // ================= TYPE FILTERS (SCROLLS AWAY) =================
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTypeFilters(context),
                ),
              ),

              // ================= STICKY SEARCH + STATUS FILTER =================
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickySearchDelegate(
                  child: Column(
                    children: [
                      _buildSearchBar(context),
                      const SizedBox(height: 8),
                      _buildStatusFilters(context),
                    ],
                  ),
                ),
              ),

              // ================= ORDERS LIST =================
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: _buildOrdersSliver(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(Icons.receipt_long_rounded, size: 28, color: scheme.primary),
          const SizedBox(width: 12),
          Text(
            'Orders',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SEARCH ----------------
  Widget _buildSearchBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      onChanged: (value) {
        setState(() => _searchQuery = value.trim().toLowerCase());
      },
      decoration: InputDecoration(
        hintText: 'Search by order number or user',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ---------------- STATS ----------------
  Widget _buildStatsRow() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color statValueColor =
        isDarkMode ? Colors.white : const Color(0xFF1F2933);

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
                  valueColor: statValueColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Active',
                  value: active.toString(),
                  icon: Icons.timelapse_rounded,
                  color: Colors.orange,
                  valueColor: statValueColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Completed',
                  value: completed.toString(),
                  icon: Icons.check_circle_rounded,
                  color: Colors.green,
                  valueColor: statValueColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- FILTERS ----------------
  Widget _buildTypeFilters(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _filterChip(context, 'All', _selectedType == 'all',
            () => setState(() => _selectedType = 'all')),
        const SizedBox(width: 8),
        _filterChip(context, 'Rentals', _selectedType == 'rental',
            () => setState(() => _selectedType = 'rental')),
        const SizedBox(width: 8),
        _filterChip(context, 'Sales', _selectedType == 'sale',
            () => setState(() => _selectedType = 'sale')),
      ],
    );
  }

  Widget _buildStatusFilters(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _filterChip(context, 'All', _selectedStatus == 'all',
            () => setState(() => _selectedStatus = 'all')),
        const SizedBox(width: 8),
        _filterChip(context, 'Active', _selectedStatus == 'active',
            () => setState(() => _selectedStatus = 'active')),
        const SizedBox(width: 8),
        _filterChip(context, 'Completed', _selectedStatus == 'completed',
            () => setState(() => _selectedStatus = 'completed')),
      ],
    );
  }

  Widget _filterChip(
      BuildContext context, String label, bool selected, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // ---------------- ORDERS SLIVER ----------------
  Widget _buildOrdersSliver() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: LoadingState(message: 'Loading orders...'),
          );
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

          if (_searchQuery.isNotEmpty) {
            final orderNumber =
                (data['orderNumber'] ?? '').toString().toLowerCase();
            final userId = data['userId'] ?? '';
            final userName = (_userCache[userId] ?? '').toLowerCase();

            if (!orderNumber.contains(_searchQuery) &&
                !userId.toString().toLowerCase().contains(_searchQuery) &&
                !userName.contains(_searchQuery)) {
              return false;
            }
          }

          return true;
        }).toList();

        if (filtered.isEmpty) {
          return const SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'No orders',
              subtitle: 'No orders match the selected filters',
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final doc = filtered[index];
              return _orderCard(
                doc.id,
                doc.data() as Map<String, dynamic>,
              );
            },
            childCount: filtered.length,
          ),
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

// ================= STICKY HEADER DELEGATE =================
class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickySearchDelegate({required this.child});

  @override
  double get minExtent => 150;

  @override
  double get maxExtent => 150;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        boxShadow: [
          if (shrinkOffset > 0 || overlapsContent)
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchDelegate oldDelegate) {
    return false;
  }
}
