import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'auth_input_fields.dart';

class LoginForm extends ConsumerStatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
  });

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  // Local loading state — NOT tied to the provider
  // This means provider state changes never rebuild this widget
  bool _loading = false;

  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13)),
          ),
        ]),
        backgroundColor: const Color(0xFF7B2B2B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        duration: const Duration(seconds: 4),
      ));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_loading) return;

    setState(() => _loading = true);

    await ref.read(authProvider.notifier).signIn(
          widget.emailController.text.trim(),
          widget.passwordController.text.trim(),
        );

    if (!mounted) return;

    // Read error ONCE after the call — no watch, no rebuild
    final error = ref.read(authProvider).error;
    if (error != null) {
      _showErrorToast('Incorrect email or password.');
    }

    setState(() => _loading = false);
  }

  Future<void> _handleForgotPassword() async {
    final email = widget.emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showErrorToast('Please enter your email address first.');
      return;
    }
    try {
      await ref.read(authProvider.notifier).sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('Reset link sent to $email'),
            backgroundColor: const Color(0xFF425C7D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            duration: const Duration(seconds: 4),
          ));
      }
    } catch (_) {
      if (mounted) _showErrorToast('Could not send reset email. Check the address.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only watch rememberMe for the checkbox — nothing else
    // isLoading is local state now, so no provider rebuild on login attempt
    final rememberMe = ref.watch(authProvider.select((s) => s.rememberMe));

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuthInputField(
            label: 'EMAIL',
            hint: 'example@gmail.com',
            controller: widget.emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (val) =>
                (val == null || val.isEmpty) ? 'Email is required' : null,
          ),
          const SizedBox(height: 15),
          AuthInputField(
            label: 'PASSWORD',
            hint: 'Enter password',
            controller: widget.passwordController,
            isPassword: _obscurePassword,
            validator: (val) =>
                (val == null || val.isEmpty) ? 'Password is required' : null,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white70,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),

          // Remember Me & Forgot Password
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: rememberMe,
                      onChanged: (val) => ref
                          .read(authProvider.notifier)
                          .toggleRememberMe(val ?? false),
                      activeColor: const Color(0xFF425C7D),
                      side: const BorderSide(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Remember me',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
                TextButton(
                  onPressed: _handleForgotPassword,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Text('Forgot Password?',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF425C7D),
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              elevation: 2,
            ),
            child: _loading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('LOGIN',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.2)),
          ),
        ],
      ),
    );
  }
}
