import 'package:flutter/material.dart';

import '../../dashboard/presentation/admin_dashboard_screen.dart';
import '../../rentals/presentation/rentals_management_screen.dart';
import '../../delivery/presentation/delivery_management_screen.dart';
import '../../users/presentation/users_management_screen.dart';
import '../../complaints/presentation/complaints_management_screen.dart';

import '../../categories/screens/categories_screen.dart';
import '../../products/screens/products_screen.dart';
import '../../products/screens/pending_products_screen.dart';

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
  final screens = [
    const AdminDashboardScreen(),        // 0
    const RentalsManagementScreen(),    // 1
    const DeliveryManagementScreen(),   // 2
    const UsersManagementScreen(),      // 3
    const ComplaintsManagementScreen(),// 4
    const CategoriesScreen(),           // 5
    const ProductsScreen(),             // 6
    PendingProductsScreen(),            // 7  🧾 NEW
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // =============================
  // UI
  // =============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9F6EE),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          _getTitle(selectedIndex),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF781C2E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: _buildDrawer(context),
      body: screens[selectedIndex],
    );
  }

  // =============================
  // DRAWER
  // =============================
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(Icons.dashboard_rounded, 'Dashboard', 0),
                _buildDrawerItem(Icons.assignment_rounded, 'Rentals', 1),
                _buildDrawerItem(Icons.delivery_dining_rounded, 'Delivery', 2),
                _buildDrawerItem(Icons.people_rounded, 'Users', 3),
                _buildDrawerItem(Icons.support_agent_rounded, 'Complaints', 4),
                _buildDrawerItem(Icons.category_rounded, 'Categories', 5),
                _buildDrawerItem(Icons.inventory_2_rounded, 'Products', 6),

                // 🧾 NEW MENU ITEM
                _buildDrawerItem(Icons.verified_rounded, 'Pending Approvals', 7),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red[400]),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // =============================
  // HEADER
  // =============================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF781C2E), Color(0xFF5A1521)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white70,
            child: Icon(
              Icons.admin_panel_settings,
              color: Color(0xFF781C2E),
              size: 32,
            ),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Panel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Rental Management',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =============================
  // DRAWER ITEM
  // =============================
  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final isSelected = selectedIndex == index;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF781C2E).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color:
              isSelected ? const Color(0xFF781C2E) : Colors.grey[600],
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: isSelected ? 16 : 15,
          color: isSelected
              ? const Color(0xFF781C2E)
              : Colors.grey[800],
        ),
      ),
      trailing: isSelected
          ? Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF781C2E),
                borderRadius: BorderRadius.circular(2),
              ),
            )
          : null,
      onTap: () {
        setState(() => selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }

  // =============================
  // TITLES
  // =============================
  String _getTitle(int index) {
    const titles = [
      'Dashboard',
      'Rentals',
      'Delivery',
      'Users',
      'Complaints',
      'Categories',
      'Products',
      'Pending Approvals', // NEW
    ];
    return titles[index];
  }
}
