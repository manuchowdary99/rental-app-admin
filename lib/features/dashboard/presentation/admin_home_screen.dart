import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_service.dart';
import '../../users/presentation/users_list_screen.dart';
import '../../users/presentation/admins_management_screen.dart';
import '../../items/presentation/items_list_screen.dart';
import '../../orders/presentation/admin_orders_screen.dart';
import '../../subscriptions/presentation/admin_subscriptions_screen.dart';
import '../../support/presentation/admin_support_faq_screen.dart';
import '../../support/presentation/admin_support_tickets_screen.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;

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
              Padding(
                padding: EdgeInsets.all(width < 600 ? 16 : 24),
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
                            'Platform management & monitoring',
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

              // ================= BODY =================
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
                    crossAxisCount: width > 1000
                        ? 4
                        : width > 700
                            ? 3
                            : 2,
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
                        'Admin roles & access',
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
                        'Orders',
                        'View & manage orders',
                        Icons.receipt_long_rounded,
                        const Color(0xFFF59E0B),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminOrdersScreen(),
                          ),
                        ),
                      ),

                      _card(
                        context,
                        'Subscriptions',
                        'Manage plans',
                        Icons.subscriptions_rounded,
                        const Color(0xFF6366F1),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AdminSubscriptionsScreen(),
                          ),
                        ),
                      ),

                      _card(
                        context,
                        'FAQs',
                        'Help center content',
                        Icons.help_outline_rounded,
                        const Color(0xFF8B5CF6),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AdminSupportFaqScreen(),
                          ),
                        ),
                      ),

                      _card(
                        context,
                        'Support Tickets',
                        'Customer issues',
                        Icons.support_agent_rounded,
                        const Color(0xFFEF4444),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AdminSupportTicketsScreen(),
                          ),
                        ),
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

  // ================= CARD =================

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
              color: color.withOpacity(0.15),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.75)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
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
