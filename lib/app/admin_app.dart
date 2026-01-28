import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/auth_service.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/complaints/presentation/complaints_management_screen.dart';
import '../features/kyc/presentation/admin_kyc_screen.dart';
import '../features/navigation/presentation/admin_main_navigation.dart';
import '../features/users/presentation/users_management_screen.dart';

final authStateChangesProvider = StreamProvider<AdminAuthState>(
  (ref) => ref.read(authServiceProvider).adminAuthStateChanges(),
);

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Console',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF781C2E),
        ),
      ),
      routes: {
        '/users': (context) => const UsersManagementScreen(),
        '/complaints': (context) => const ComplaintsManagementScreen(),
        '/kyc': (context) => const AdminKycScreen(),
      },
      home: authState.when(
        data: (state) {
          switch (state.status) {
            case AdminAuthStatus.authenticated:
              return const AdminMainNavigation();
            case AdminAuthStatus.checking:
              return const _AuthLoadingScreen();
            case AdminAuthStatus.unauthorized:
              return LoginScreen(
                initialError: state.message ?? 'You do not have admin access.',
              );
            case AdminAuthStatus.error:
              return LoginScreen(
                initialError: state.message ?? 'Unable to verify admin access.',
              );
            case AdminAuthStatus.unauthenticated:
            default:
              return const LoginScreen();
          }
        },
        loading: () => const _AuthLoadingScreen(),
        error: (e, _) => LoginScreen(
          initialError: 'Unexpected error: $e',
        ),
      ),
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
