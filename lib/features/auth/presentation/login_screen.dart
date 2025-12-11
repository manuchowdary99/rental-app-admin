import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Admin Login',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter email',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter email' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter password',
                      ),
                      obscureText: true,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter password' : null,
                    ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Login as Admin'),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _loading ? null : _loginWithGoogle,
                      icon: const Icon(Icons.g_mobiledata),
                      label: const Text('Login with Google'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).signInAsAdmin(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text.trim(),
          );
    } catch (e) {
      setState(() {
        _error = 'Admin login failed';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).signInWithGoogleAsAdmin();
    } catch (e) {
      setState(() {
        _error = 'Google admin login failed';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}
