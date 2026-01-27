import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_service.dart';
import '../../users/presentation/users_list_screen.dart';
import '../../users/presentation/admins_management_screen.dart';
import '../../items/presentation/items_list_screen.dart';
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
            colors: [Color(0xFF781C2E), Color(0xFF5A1521)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ================= HEADER =================
              Container(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width < 600 ? 16 : 24,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.dashboard_rounded,
                        color: Colors.white,
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
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Orders & platform management',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        ref.read(authServiceProvider).signOut();
                      },
                    ),
                  ],
                ),
              ),

              // ================= DASHBOARD BODY =================
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9F6EE),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: GridView.count(
                    padding: const EdgeInsets.all(20),
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 800 ? 3 : 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1,
                    children: [
                      _card(
                        context,
                        'Users',
                        'Manage all users',
                        Icons.people_rounded,
                        const Color(0xFF781C2E),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UsersListScreen(),
                          ),
                        ),
                      ),
                      _card(
                        context,
                        'Admins',
                        'Admin roles',
                        Icons.admin_panel_settings_rounded,
                        const Color(0xFF38BDF8),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminsManagementScreen(),
                          ),
                        ),
                      ),
                      _card(
                        context,
                        'Items',
                        'Product inventory',
                        Icons.inventory_2_rounded,
                        const Color(0xFF10B981),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ItemsListScreen(),
                          ),
                        ),
                      ),
                      _card(
                        context,
                        'Complaints',
                        'Customer issues',
                        Icons.support_agent_rounded,
                        const Color(0xFFEF4444),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ComplaintsListScreen(),
                          ),
                        ),
                      ),
                      _card(
                        context,
                        'Analytics',
                        'System overview',
                        Icons.analytics_rounded,
                        const Color(0xFF8B5CF6),
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Analytics coming soon'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= CARD WIDGET =================

  Widget _card(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
