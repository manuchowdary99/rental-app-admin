import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_service.dart';

class AdminChangePasswordController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> change({
    required String currentPassword,
    required String newPassword,
  }) async {
    final authService = ref.read(authServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
  }
}

final adminChangePasswordControllerProvider =
    AutoDisposeAsyncNotifierProvider<AdminChangePasswordController, void>(
  AdminChangePasswordController.new,
);
