import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import 'auth_input_fields.dart';

class SignupForm extends ConsumerStatefulWidget {
  final void Function(String email) onSignupSuccess;
  const SignupForm({super.key, required this.onSignupSuccess});

  @override
  ConsumerState<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends ConsumerState<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _verificationSent = false;
  String _submittedEmail = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    _submittedEmail = _emailController.text.trim();

    try {
      await ref.read(authProvider.notifier).signUp(
            _submittedEmail,
            _passwordController.text.trim(),
            _usernameController.text.trim(),
          );

      if (mounted) {
        setState(() => _verificationSent = true);
      }
    } catch (e) {
      // Error is handled by the SignupPage listener
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    if (_verificationSent) {
      return _buildVerificationSentUI(isLoading);
    }

    return Form(
      key: _formKey,
      child: Column(
        children: [
          AuthInputField(
            label: "USERNAME",
            hint: "User123",
            controller: _usernameController,
            validator: (val) => (val == null || val.trim().isEmpty)
                ? "Username is required"
                : null,
          ),
          const SizedBox(height: 15),
          AuthInputField(
            label: "EMAIL",
            hint: "example@gmail.com",
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return "Email is required";
              if (!val.contains('@') || !val.contains('.')) {
                return "Enter a valid email";
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          AuthInputField(
            label: "PASSWORD",
            hint: "At least 8 characters",
            controller: _passwordController,
            isPassword: _obscurePassword,
            validator: (val) => (val == null || val.length < 8)
                ? "Password must be at least 8 characters"
                : null,
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
          const SizedBox(height: 15),
          AuthInputField(
            label: "CONFIRM PASSWORD",
            hint: "Re-enter password",
            controller: _confirmPasswordController,
            isPassword: _obscureConfirmPassword,
            validator: (val) => val != _passwordController.text
                ? "Passwords do not match"
                : null,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.white70,
                size: 20,
              ),
              onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
          
          // Note: "Remember this device" is usually handled at the Login stage 
          // because a user cannot maintain a session until they verify their email.
          
          const SizedBox(height: 25),
          _buildSignupButton(isLoading),
        ],
      ),
    );
  }

  Widget _buildVerificationSentUI(bool isLoading) {
    return Column(
      children: [
        const Icon(Icons.mark_email_read_outlined,
            size: 64, color: Colors.white),
        const SizedBox(height: 16),
        const Text(
          "Verify your email",
          style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          "We sent a verification link to\n$_submittedEmail",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 25),
        ElevatedButton(
          onPressed: () => widget.onSignupSuccess(_submittedEmail),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF425C7D),
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30)),
            elevation: 2,
          ),
          child: const Text(
            "GO TO LOGIN",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          "Once verified, you can check 'Remember this device' on the login screen to stay signed in.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSignupButton(bool isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF425C7D),
        disabledBackgroundColor: const Color(0xFF425C7D).withOpacity(0.6),
        minimumSize: const Size(double.infinity, 55),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 2,
      ),
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
          : const Text(
              "SIGN UP",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
    );
  }
}