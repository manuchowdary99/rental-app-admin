import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/navigation/presentation/admin_main_navigation.dart';

import 'firebase_options.dart';
import 'core/services/auth_service.dart';
import 'features/auth/presentation/login_screen.dart';

// MANAGEMENT SCREENS
import 'features/users/presentation/users_management_screen.dart';
import 'features/complaints/presentation/complaints_management_screen.dart';

final authStateChangesProvider = StreamProvider<AdminAuthState>(
  (ref) => ref.read(authServiceProvider).adminAuthStateChanges(),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: AdminApp()));
}

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
        "/users": (context) => const UsersManagementScreen(),
        "/complaints": (context) => const ComplaintsManagementScreen(),
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
  const _AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
