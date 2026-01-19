import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'core/services/auth_service.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/navigation/presentation/admin_main_navigation.dart';

// MANAGEMENT SCREENS
import 'features/users/presentation/users_management_screen.dart';
import 'features/kyc/presentation/kyc_verification_screen.dart';
import 'features/complaints/presentation/complaints_management_screen.dart';

final authStateChangesProvider = StreamProvider<User?>(
  (ref) => ref.read(authServiceProvider).authStateChanges(),
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
        "/kyc": (context) => const KycVerificationScreen(),
        "/complaints": (context) => const ComplaintsManagementScreen(),
      },
      home: authState.when(
        data: (user) =>
            user == null ? const LoginScreen() : const AdminMainNavigation(),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          body: Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
