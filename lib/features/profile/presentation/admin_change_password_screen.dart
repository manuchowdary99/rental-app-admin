import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/admin_widgets.dart';
import '../providers/admin_security_providers.dart';

class AdminChangePasswordScreen extends ConsumerStatefulWidget {
  const AdminChangePasswordScreen({super.key});

  @override
  ConsumerState<AdminChangePasswordScreen> createState() =>
      _AdminChangePasswordScreenState();
}

class _AdminChangePasswordScreenState
    extends ConsumerState<AdminChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _currentController;
  late final TextEditingController _newController;
  late final TextEditingController _confirmController;

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    _currentController = TextEditingController();
    _newController = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(adminChangePasswordControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      backgroundColor: const Color(0xFFF7F5F0),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            const Text(
              'Keep your admin account secure by updating the password regularly.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 20),
            AdminCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Password tips',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('- Use at least 8 characters with numbers and symbols.'),
                  SizedBox(height: 4),
                  Text('- Avoid common phrases or reused passwords.'),
                  SizedBox(height: 4),
                  Text('- Do not share your admin credentials.'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _PasswordField(
                    label: 'Current password',
                    controller: _currentController,
                    obscureText: !_showCurrent,
                    onToggleVisibility: () {
                      setState(() => _showCurrent = !_showCurrent);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter your current password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _PasswordField(
                    label: 'New password',
                    controller: _newController,
                    obscureText: !_showNew,
                    onToggleVisibility: () {
                      setState(() => _showNew = !_showNew);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter a new password';
                      }
                      if (value.length < 8) {
                        return 'Use at least 8 characters';
                      }
                      final hasNumber = value.contains(RegExp(r'[0-9]'));
                      final hasLetter = value.contains(RegExp(r'[A-Za-z]'));
                      if (!hasNumber || !hasLetter) {
                        return 'Use a mix of letters and numbers';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _PasswordField(
                    label: 'Confirm new password',
                    controller: _confirmController,
                    obscureText: !_showConfirm,
                    onToggleVisibility: () {
                      setState(() => _showConfirm = !_showConfirm);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirm your new password';
                      }
                      if (value != _newController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            if (controllerState.hasError) ...[
              const SizedBox(height: 16),
              Text(
                controllerState.error.toString(),
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
            const SizedBox(height: 24),
            AdminButton(
              text: 'Update password',
              icon: Icons.lock_reset_rounded,
              isLoading: controllerState.isLoading,
              onPressed: controllerState.isLoading
                  ? null
                  : () => _handleSubmit(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    try {
      await ref.read(adminChangePasswordControllerProvider.notifier).change(
            currentPassword: _currentController.text,
            newPassword: _newController.text,
          );

      if (!mounted) return;
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update password: $error')),
      );
    }
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscureText,
    required this.onToggleVisibility,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF781C2E), width: 1.4),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }
}
