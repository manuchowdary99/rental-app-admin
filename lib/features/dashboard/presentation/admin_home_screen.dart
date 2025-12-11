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
      appBar: AppBar(
        title: const Text('Rental Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const UsersListScreen(),
                  ),
                );
              },
              child: const Text('Manage Users'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminsManagementScreen(),
                  ),
                );
              },
              child: const Text('Manage Admin Roles'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ItemsListScreen(),
                  ),
                );
              },
              child: const Text('Manage Items'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const OrdersListScreen(),
                  ),
                );
              },
              child: const Text('Manage Orders'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ComplaintsListScreen(),
                  ),
                );
              },
              child: const Text('Manage Complaints'),
            ),
          ],
        ),
      ),
    );
  }
}
