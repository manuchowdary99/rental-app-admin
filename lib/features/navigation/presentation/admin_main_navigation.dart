import 'package:flutter/material.dart';

import '../../dashboard/presentation/admin_dashboard_screen.dart';
import '../../rentals/presentation/rentals_management_screen.dart';
import '../../delivery/presentation/delivery_management_screen.dart';
import '../../users/presentation/users_management_screen.dart';
import '../../complaints/presentation/complaints_management_screen.dart';
import '../../categories/screens/categories_screen.dart';
import '../../products/screens/products_screen.dart';

class AdminMainNavigation extends StatefulWidget {
  const AdminMainNavigation({super.key});

  @override
  State<AdminMainNavigation> createState() => _AdminMainNavigationState();
}

class _AdminMainNavigationState extends State<AdminMainNavigation> {
  int selectedIndex = 0;

  final screens = [
    const AdminDashboardScreen(),
    const RentalsManagementScreen(),
    const DeliveryManagementScreen(),
    const UsersManagementScreen(),
    const ComplaintsManagementScreen(),
    const CategoriesScreen(),
    const ProductsScreen(),
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _showSearch(context),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF781C2E), const Color(0xFF5A1521)],
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
            ),
            // Menu Items
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
                ],
              ),
            ),
            // Footer
            Divider(height: 1, thickness: 1, color: Colors.grey[300]),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red[400]),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: screens[selectedIndex],
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final isSelected = selectedIndex == index;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF781C2E).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFF781C2E) : Colors.grey[600],
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: isSelected ? 16 : 15,
          color: isSelected ? const Color(0xFF781C2E) : Colors.grey[800],
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
      selected: isSelected,
      onTap: () {
        setState(() => selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }

  String _getTitle(int index) {
    const titles = [
      'Dashboard', 'Rentals', 'Delivery', 'Users',
      'Complaints', 'Categories', 'Products'
    ];
    return titles[index];
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _SearchDelegate(
        titles: const [
          'Dashboard', 'Rentals', 'Delivery', 'Users',
          'Complaints', 'Categories', 'Products'
        ],
        onPageSelected: (index) {
          setState(() => selectedIndex = index);
        },
      ),
    );
  }
}

// ✅ FIXED SearchDelegate - No more type errors!
class _SearchDelegate extends SearchDelegate<String> {
  final List<String> titles;
  final Function(int) onPageSelected;

  _SearchDelegate({
    required this.titles,
    required this.onPageSelected,
  });

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () => query = '',
    ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, ''),
  );

  @override
  Widget buildResults(BuildContext context) {
    final results = <String>[];
    for (final title in titles) {
      if (title.toLowerCase().contains(query.toLowerCase())) {
        results.add(title);
      }
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final title = results[index];
        final pageIndex = titles.indexOf(title);
        return ListTile(
          leading: const Icon(Icons.search, color: Color(0xFF781C2E)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          onTap: () {
            onPageSelected(pageIndex);
            close(context, '');
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = <String>[];
    for (final title in titles) {
      if (title.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(title);
      }
    }

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final title = suggestions[index];
        return ListTile(
          leading: const Icon(Icons.search, color: Color(0xFF781C2E)),
          title: Text(title),
          onTap: () {
            query = title;
            showResults(context);
          },
        );
      },
    );
  }
}
