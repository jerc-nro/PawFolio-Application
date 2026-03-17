import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pawfolio/core/loading_screen.dart';
import '../providers/auth_provider.dart';
import '../widgets/signup_form.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(message,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF7B2B2B),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 32, left: 40, right: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        duration: const Duration(seconds: 4),
        elevation: 8,
      ));
  }

  // Called by SignupForm when signup succeeds — returns email to LoginPage
  void _onSignupSuccess(String email) {
    Navigator.of(context).pop(email); // Pops back and passes email to LoginPage
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Listen for state changes to trigger error messages
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        _showErrorToast(next.error!);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFD7CCC8),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Container(
                width: 350,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B947E),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(0, 5))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset("assets/images/logo.png", height: 100),
                    const SizedBox(height: 25),
                    
                    // SignupForm handles the user input and the 'verification sent' view
                    SignupForm(onSignupSuccess: _onSignupSuccess),
                    
                    const SizedBox(height: 15),
                    _buildDivider(),
                    const SizedBox(height: 15),
                    
                    // Google Sign-In button
                    _buildGoogleButton(authState.isLoading),
                    
                    const SizedBox(height: 10),
                    _buildLoginRedirect(),
                  ],
                ),
              ),
            ),
          ),
          
          // Only show the overlay loader for non-signup actions (like Google sign-in)
          // because the SignupForm has its own internal success UI.
          if (authState.isLoading && !authState.isSigningUp)
            const Positioned.fill(child: LoadingScreen()),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Row(children: [
        Expanded(child: Divider(color: Colors.white54)),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text("OR",
                style: TextStyle(color: Colors.white, fontSize: 12))),
        Expanded(child: Divider(color: Colors.white54)),
      ]);

  Widget _buildGoogleButton(bool isLoading) => OutlinedButton.icon(
        onPressed: isLoading
            ? null
            : () => ref.read(authProvider.notifier).signInWithGoogle(),
        icon: Image.asset('assets/images/google_logo.png', height: 24),
        label: const Text("Continue with Google",
            style: TextStyle(fontSize: 16)),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Color(0xFF8B947E), width: 1.5),
        ),
      );

  Widget _buildLoginRedirect() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Already have an account?",
              style: TextStyle(color: Colors.white)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Login",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      );
}