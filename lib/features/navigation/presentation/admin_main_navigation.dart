import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../analytics/presentation/analytics_dashboard_screen.dart';
import '../../users/presentation/users_management_screen.dart';
import '../../categories/screens/categories_screen.dart';
import '../../products/screens/products_screen.dart';
import '../../products/screens/pending_products_screen.dart';
import '../../kyc/presentation/admin_kyc_screen.dart';
import '../../orders/presentation/admin_orders_screen.dart';
import '../../subscriptions/presentation/admin_subscriptions_screen.dart';
import '../../support/presentation/admin_support_faq_screen.dart';
import '../../support/presentation/admin_support_tickets_screen.dart';

import '../../../core/theme/theme_provider.dart';

class AdminMainNavigation extends ConsumerStatefulWidget {
  const AdminMainNavigation({super.key});

  @override
  ConsumerState<AdminMainNavigation> createState() =>
      _AdminMainNavigationState();
}

class _AdminMainNavigationState
    extends ConsumerState<AdminMainNavigation> {
  int selectedIndex = 0;

  final List<Widget> screens = [
    const AnalyticsDashboardScreen(),
    const UsersManagementScreen(),
    const CategoriesScreen(),
    const ProductsScreen(),
    PendingProductsScreen(),
    const AdminKycScreen(),
    const AdminOrdersScreen(),
    const AdminSubscriptionsScreen(),
    const AdminSupportFaqScreen(),
    const AdminSupportTicketsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(selectedIndex)),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).state =
                  themeMode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: screens[selectedIndex],
      ),
    );
  }

  // =============================
  // DRAWER
  // =============================
  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              children: [
                _section("ANALYTICS", context),
                _analyticsItem(),

                _section("MANAGEMENT", context),
                _item(Icons.people_rounded, "Users", 1),
                _item(Icons.subscriptions_rounded, "Subscriptions", 7),

                _section("CATALOG", context),
                _item(Icons.category_rounded, "Categories", 2),
                _item(Icons.inventory_2_rounded, "Products", 3),
                _item(Icons.verified_rounded, "Pending Approvals", 4),

                _section("SECURITY", context),
                _item(Icons.verified_user_rounded, "KYC Verification", 5),
                _item(Icons.receipt_long_rounded, "Orders", 6),

                _section("SUPPORT", context),
                _item(Icons.help_outline, "FAQs", 8),
                _item(Icons.support_agent_rounded, "Support Tickets", 9),
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
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: theme.colorScheme.onPrimary,
            child: Icon(
              Icons.admin_panel_settings,
              color: theme.colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Admin Panel",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Enterprise Dashboard",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =============================
  // ANALYTICS BADGE
  // =============================
  Widget _analyticsItem() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('kyc')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final count =
            snapshot.hasData ? snapshot.data!.docs.length : 0;

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
  // SECTION LABEL
  // =============================
  Widget _section(String title, BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 1.4,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  // =============================
  // DRAWER ITEM
  // =============================
  Widget _item(
    IconData icon,
    String title,
    int index, {
    String? badge,
  }) {
    final theme = Theme.of(context);
    final isActive = selectedIndex == index;

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() => selectedIndex = index);
          Navigator.pop(context);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isActive
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onError,
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: OutlinedButton.icon(
        icon: Icon(Icons.logout,
            color: theme.colorScheme.error),
        label: Text(
          "Logout",
          style:
              TextStyle(color: theme.colorScheme.error),
        ),
        onPressed: () async {
          Navigator.pop(context);

          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Confirm Logout"),
              content: const Text(
                  "Are you sure you want to logout?"),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, true),
                  child: const Text("Logout"),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await FirebaseAuth.instance.signOut();
          }
        },
      ),
    );
  }

  String _getTitle(int index) {
    const titles = [
      "Analytics",
      "Users",
      "Categories",
      "Products",
      "Pending Approvals",
      "KYC Verification",
      "Orders",
      "Subscriptions",
      "FAQs",
      "Support Tickets",
    ];
    return titles[index];
  }
}
