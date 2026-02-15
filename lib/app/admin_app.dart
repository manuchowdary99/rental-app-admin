import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/auth_service.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/navigation/presentation/admin_main_navigation.dart';
import '../features/users/presentation/users_management_screen.dart';
import '../features/kyc/presentation/admin_kyc_screen.dart';
import '../features/orders/presentation/admin_orders_screen.dart';
import '../features/support/presentation/admin_support_tickets_screen.dart';
import '../features/profile/presentation/admin_profile_screen.dart';
import '../features/profile/presentation/admin_profile_edit_screen.dart';
import '../features/profile/presentation/admin_change_password_screen.dart';

final authStateChangesProvider = StreamProvider<AdminAuthState>(
  (ref) => ref.read(authServiceProvider).adminAuthStateChanges(),
);

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Console',

      // ✅ Professional Theme Setup
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // ✅ Named Routes
      routes: {
        '/users': (context) => const UsersManagementScreen(),
        '/kyc': (context) => const AdminKycScreen(),
        '/orders': (context) => const AdminOrdersScreen(),
        '/support-tickets': (context) => const AdminSupportTicketsScreen(),
        '/admin-profile': (context) => const AdminProfileScreen(),
        '/admin-profile/edit': (context) => const AdminProfileEditScreen(),
        '/admin-profile/change-password': (context) =>
            const AdminChangePasswordScreen(),
      },

      // ✅ Authentication Handling
      home: authState.when(
        data: (state) {
          switch (state.status) {
            case AdminAuthStatus.authenticated:
              return const AdminMainNavigation();

            case AdminAuthStatus.unauthenticated:
            default:
              return const LoginScreen();
          }
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => LoginScreen(
          initialError: 'Error: $e',
        ),
      ),
    );
  }
}
