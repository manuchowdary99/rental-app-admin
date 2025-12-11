import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_service.dart';
import '../../users/presentation/users_list_screen.dart';
import '../../users/presentation/admins_management_screen.dart';
import '../../items/presentation/items_list_screen.dart';
import '../../orders/presentation/orders_list_screen.dart';
import '../../complaints/presentation/complaints_list_screen.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern AppBar
              Container(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width < 600 ? 16 : 24,
                ),
                child: Row(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width < 600 ? 40 : 48,
                      height: MediaQuery.of(context).size.width < 600 ? 40 : 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.dashboard_rounded,
                        color: Colors.white,
                        size: MediaQuery.of(context).size.width < 600 ? 20 : 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: MediaQuery.of(context).size.width < 600
                                  ? 24
                                  : 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Rental Management System',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: MediaQuery.of(context).size.width < 600
                                  ? 14
                                  : 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          ref.read(authServiceProvider).signOut();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Dashboard Cards
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                      MediaQuery.of(context).size.width < 600 ? 16 : 24,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = constraints.maxWidth;
                        int crossAxisCount;
                        double childAspectRatio;

                        if (screenWidth > 800) {
                          crossAxisCount = 3;
                          childAspectRatio = 1.1;
                        } else if (screenWidth > 600) {
                          crossAxisCount = 2;
                          childAspectRatio = 1.0;
                        } else {
                          crossAxisCount = 2;
                          childAspectRatio = 0.9;
                        }

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: screenWidth < 600 ? 12 : 20,
                          mainAxisSpacing: screenWidth < 600 ? 12 : 20,
                          childAspectRatio: childAspectRatio,
                          children: [
                            _buildDashboardCard(
                              context,
                              'Users',
                              'Manage all users',
                              Icons.people_rounded,
                              const Color(0xFF667eea),
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const UsersListScreen(),
                                ),
                              ),
                            ),
                            _buildDashboardCard(
                              context,
                              'Admins',
                              'Admin roles',
                              Icons.admin_panel_settings_rounded,
                              const Color(0xFF38BDF8),
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AdminsManagementScreen(),
                                ),
                              ),
                            ),
                            _buildDashboardCard(
                              context,
                              'Items',
                              'Rental inventory',
                              Icons.inventory_2_rounded,
                              const Color(0xFF10B981),
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ItemsListScreen(),
                                ),
                              ),
                            ),
                            _buildDashboardCard(
                              context,
                              'Orders',
                              'Track orders',
                              Icons.receipt_long_rounded,
                              const Color(0xFFF59E0B),
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const OrdersListScreen(),
                                ),
                              ),
                            ),
                            _buildDashboardCard(
                              context,
                              'Complaints',
                              'Customer issues',
                              Icons.support_agent_rounded,
                              const Color(0xFFEF4444),
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ComplaintsListScreen(),
                                ),
                              ),
                            ),
                            _buildDashboardCard(
                              context,
                              'Analytics',
                              'System overview',
                              Icons.analytics_rounded,
                              const Color(0xFF8B5CF6),
                              () {
                                // TODO: Add analytics screen
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Analytics coming soon!'),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: isMobile ? 15 : 20,
              offset: Offset(0, isMobile ? 6 : 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: isMobile ? 8 : 10,
              offset: Offset(0, isMobile ? 2 : 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isMobile ? 48 : 60,
                height: isMobile ? 48 : 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: isMobile ? 8 : 12,
                      offset: Offset(0, isMobile ? 2 : 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isMobile ? 24 : 28,
                ),
              ),
              SizedBox(height: isMobile ? 8 : 16),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: isMobile ? 2 : 4),
              Flexible(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
