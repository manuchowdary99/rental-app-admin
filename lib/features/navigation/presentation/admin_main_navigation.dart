import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../analytics/presentation/analytics_dashboard_screen.dart';
import '../../delivery/presentation/delivery_management_screen.dart';
import '../../users/presentation/users_management_screen.dart';
import '../../complaints/presentation/complaints_management_screen.dart';
import '../../categories/screens/categories_screen.dart';
import '../../products/screens/products_screen.dart';
import '../../products/screens/pending_products_screen.dart';
import '../../kyc/presentation/kyc_verification_screen.dart';
import '../../orders/presentation/admin_orders_screen.dart';
import '../../subscriptions/presentation/admin_subscriptions_screen.dart';

class AdminMainNavigation extends StatefulWidget {
  const AdminMainNavigation({super.key});

  @override
  State<AdminMainNavigation> createState() => _AdminMainNavigationState();
}

class _AdminMainNavigationState extends State<AdminMainNavigation> {
  int selectedIndex = 0;

  // =============================
  // SCREENS
  // =============================
  final List<Widget> screens = [
    const AnalyticsDashboardScreen(), // 0
    const DeliveryManagementScreen(), // 1
    const UsersManagementScreen(), // 2
    const ComplaintsManagementScreen(), // 3
    const CategoriesScreen(), // 4
    const ProductsScreen(), // 5
    PendingProductsScreen(), // 6
    const KycVerificationScreen(), // 7
    const AdminOrdersScreen(), // 8
    const AdminSubscriptionsScreen(), // 9
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(selectedIndex)),
        backgroundColor: const Color(0xFF781C2E),
        foregroundColor: Colors.white,
      ),
      drawer: _buildDrawer(context),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: screens[selectedIndex],
      ),
    );
  }

  // =============================
  // DRAWER
  // =============================
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              children: [
                _section("ANALYTICS"),
                _analyticsItem(),

                _section("MANAGEMENT"),
                _item(Icons.delivery_dining_rounded, "Delivery", 1),
                _item(Icons.people_rounded, "Users", 2),
                _item(Icons.support_agent_rounded, "Complaints", 3),
                _item(Icons.subscriptions_rounded, "Subscriptions", 9),

                _section("CATALOG"),
                _item(Icons.category_rounded, "Categories", 4),
                _item(Icons.inventory_2_rounded, "Products", 5),
                _item(Icons.verified_rounded, "Pending Approvals", 6),

                _section("SECURITY"),
                _item(Icons.verified_user_rounded, "KYC Verification", 7),
                _item(Icons.receipt_long_rounded, "Orders", 8),
              ],
            ),
          ),
          _logoutTile(context),
        ],
      ),
    );
  }

  // =============================
  // HEADER
  // =============================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF781C2E),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.admin_panel_settings,
              color: Color(0xFF781C2E),
              size: 28,
            ),
          ),
          SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Admin Panel",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Enterprise Dashboard",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =============================
  // ANALYTICS ITEM
  // =============================
  Widget _analyticsItem() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('kyc')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return _item(
          Icons.analytics_rounded,
          "Analytics",
          0,
          badge: count > 0 ? "$count" : null,
        );
      },
    );
  }

  // =============================
  // UI HELPERS
  // =============================
  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          letterSpacing: 1.4,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  Widget _item(
    IconData icon,
    String title,
    int index, {
    String? badge,
  }) {
    final isActive = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() => selectedIndex = index);
          Navigator.pop(context);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF781C2E).withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive
                    ? const Color(0xFF781C2E)
                    : Colors.grey[600],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? const Color(0xFF781C2E)
                        : Colors.black87,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================
  // LOGOUT
  // =============================
  Widget _logoutTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text(
          "Logout",
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  // =============================
  // TITLES
  // =============================
  String _getTitle(int index) {
    const titles = [
      "Analytics",
      "Delivery",
      "Users",
      "Complaints",
      "Categories",
      "Products",
      "Pending Approvals",
      "KYC Verification",
      "Orders",
      "Subscriptions",
    ];
    return titles[index];
  }
}
