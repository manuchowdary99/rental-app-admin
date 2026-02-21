import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/theme_provider.dart';
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
import '../../profile/presentation/admin_profile_screen.dart';

class AdminAppDrawer extends ConsumerWidget {
  const AdminAppDrawer({
    super.key,
    this.selectedIndex,
    this.onSelectDestination,
  });

  final int? selectedIndex;
  final ValueChanged<int>? onSelectDestination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              children: [
                _buildSection('PROFILE', context),
                _buildItem(context, icon: Icons.person_rounded, title: 'Profile', index: 10),

                _buildSection('ANALYTICS', context),
                _analyticsItem(context),

                _buildSection('MANAGEMENT', context),
                _buildItem(context, icon: Icons.people_rounded, title: 'Users', index: 1),
                _buildItem(context, icon: Icons.receipt_long_rounded, title: 'Orders', index: 6),
                _buildItem(context, icon: Icons.subscriptions_rounded, title: 'Subscriptions', index: 7),

                _buildSection('CATALOG', context),
                _buildItem(context, icon: Icons.category_rounded, title: 'Categories', index: 2),
                _buildItem(context, icon: Icons.inventory_2_rounded, title: 'Products', index: 3),
                _buildItem(context, icon: Icons.verified_rounded, title: 'Pending Approvals', index: 4),

                _buildSection('SECURITY', context),
                _buildItem(context, icon: Icons.verified_user_rounded, title: 'KYC Verification', index: 5),

                _buildSection('SUPPORT', context),
                _buildItem(context, icon: Icons.help_outline, title: 'FAQs', index: 8),
                _buildItem(context, icon: Icons.support_agent_rounded, title: 'Support Tickets', index: 9),

                _buildThemeToggle(context, ref),
              ],
            ),
          ),

          /// ✅ FIXED LOGOUT (important)
          _logoutTile(context, ref),
        ],
      ),
    );
  }

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
            child: Icon(Icons.admin_panel_settings, color: theme.colorScheme.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Admin Panel',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  )),
              Text('Enterprise Dashboard',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.8),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, BuildContext context) {
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

  Widget _analyticsItem(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('kyc').where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return _buildItem(context,
            icon: Icons.analytics_rounded, title: 'Analytics', index: 0, badge: count > 0 ? '$count' : null);
      },
    );
  }

  Widget _buildItem(BuildContext context,
      {required IconData icon, required String title, required int index, String? badge}) {
    final theme = Theme.of(context);
    final isActive = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _handleSelection(context, index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? theme.colorScheme.primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.7)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: theme.colorScheme.onSurface)),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration:
                      BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(12)),
                  child: Text(badge,
                      style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return ListTile(
      leading: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: theme.colorScheme.primary),
      title: const Text('Dark mode'),
      trailing: Switch.adaptive(
        value: isDark,
        onChanged: (value) =>
            ref.read(themeModeProvider.notifier).state = value ? ThemeMode.dark : ThemeMode.light,
      ),
    );
  }

  /// ⭐⭐⭐ FIXED LOGOUT (THIS IS THE IMPORTANT PART)
  Widget _logoutTile(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: ListTile(
        leading: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
        title: Text('Sign out',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            )),
        onTap: () async {
          try {
            /// ⭐ logout FIRST (prevents freeze)
            await ref.read(authServiceProvider).signOut();

            /// ⭐ reset navigation AFTER logout
            if (context.mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          } catch (e) {
            debugPrint("Logout error: $e");
          }
        },
      ),
    );
  }

  void _handleSelection(BuildContext context, int index) {
    Navigator.pop(context);

    if (onSelectDestination != null) {
      onSelectDestination!(index);
      return;
    }

    final screen = _screenForIndex(index);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => route.isFirst,
    );
  }

  Widget _screenForIndex(int index) {
    switch (index) {
      case 0:
        return const AnalyticsDashboardScreen();
      case 1:
        return const UsersManagementScreen();
      case 2:
        return const CategoriesScreen();
      case 3:
        return const ProductsScreen();
      case 4:
        return PendingProductsScreen();
      case 5:
        return const AdminKycScreen();
      case 6:
        return const AdminOrdersScreen();
      case 7:
        return const AdminSubscriptionsScreen();
      case 8:
        return const AdminSupportFaqScreen();
      case 9:
        return const AdminSupportTicketsScreen();
      case 10:
        return const AdminProfileScreen();
      default:
        return const AnalyticsDashboardScreen();
    }
  }
}