import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'core/services/auth_service.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/dashboard/presentation/admin_home_screen.dart';

final authStateChangesProvider =
    StreamProvider<User?>((ref) => ref.watch(authServiceProvider).authStateChanges());

void main() async {
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
      title: 'Rental Admin',
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const LoginScreen();
          }
          return const AdminHomeScreen();
        },
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
