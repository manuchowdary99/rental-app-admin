import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rental_admin_app/app/admin_app.dart';
import 'package:rental_admin_app/core/services/auth_service.dart';

void main() {
  testWidgets('Admin app builds successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(
              const AdminAuthState.unauthenticated(),
            ),
          ),
        ],
        child: const AdminApp(),
      ),
    );

    // Verify that the app builds without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
