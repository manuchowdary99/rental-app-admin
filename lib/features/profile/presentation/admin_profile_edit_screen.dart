import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/admin_profile.dart';
import '../../../core/widgets/admin_widgets.dart';
import '../providers/admin_profile_providers.dart';

class AdminProfileEditScreen extends ConsumerStatefulWidget {
  const AdminProfileEditScreen({super.key});

  @override
  ConsumerState<AdminProfileEditScreen> createState() =>
      _AdminProfileEditScreenState();
}

class _AdminProfileEditScreenState
    extends ConsumerState<AdminProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _titleController;
  late final TextEditingController _phoneController;
  late final TextEditingController _timezoneController;
  late final TextEditingController _bioController;

  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _titleController = TextEditingController();
    _phoneController = TextEditingController();
    _timezoneController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _phoneController.dispose();
    _timezoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _hydrate(AdminProfile profile) {
    if (_seeded) return;
    _nameController.text = profile.displayName;
    _titleController.text = profile.title ?? '';
    _phoneController.text = profile.phoneNumber ?? '';
    _timezoneController.text = profile.timezone ?? '';
    _bioController.text = profile.bio ?? '';
    _seeded = true;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(adminProfileProvider);
    final controllerState = ref.watch(adminProfileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Edit Admin Profile'),
      ),
      backgroundColor: const Color(0xFFF7F5F0),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            _hydrate(profile);
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                children: [
                  const Text(
                    'Identity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Full name',
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Use at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Title (optional)',
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Contact details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Phone number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final digitsOnly =
                            value.replaceAll(RegExp(r'[^0-9+]'), '');
                        if (digitsOnly.length < 8) {
                          return 'Enter a valid phone number';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Timezone',
                    controller: _timezoneController,
                    textInputAction: TextInputAction.next,
                    hintText: 'ex: GMT+5:30 / IST',
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Bio',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Short bio',
                    controller: _bioController,
                    maxLines: 5,
                    maxLength: 280,
                    hintText:
                        'Share context on what you focus on inside the admin team.',
                  ),
                  if (controllerState.hasError) ...[
                    const SizedBox(height: 12),
                    Text(
                      controllerState.error.toString(),
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                  const SizedBox(height: 24),
                  AdminButton(
                    text: 'Save changes',
                    icon: Icons.save_outlined,
                    isLoading: controllerState.isLoading,
                    onPressed: controllerState.isLoading
                        ? null
                        : () => _handleSubmit(context),
                  ),
                ],
              ),
            );
          },
          loading: () => const LoadingState(message: 'Loading profile...'),
          error: (error, _) => Center(
            child: EmptyState(
              icon: Icons.person_off_rounded,
              title: 'Unable to load profile',
              subtitle: error.toString(),
              action: AdminButton(
                text: 'Retry',
                onPressed: () => ref.invalidate(adminProfileProvider),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
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
      ),
    );
  }

  Future<void> _handleSubmit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final input = AdminProfileUpdateInput(
      displayName: _nameController.text.trim(),
      title: _nullIfEmpty(_titleController.text),
      phoneNumber: _nullIfEmpty(_phoneController.text),
      timezone: _nullIfEmpty(_timezoneController.text),
      bio: _nullIfEmpty(_bioController.text),
    );

    FocusScope.of(context).unfocus();

    try {
      await ref.read(adminProfileControllerProvider.notifier).save(input);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $error')),
      );
    }
  }

  String? _nullIfEmpty(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
