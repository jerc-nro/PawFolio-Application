import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pawfolio/core/main_navigation_screen.dart';
import '../providers/auth_provider.dart';
import '../widgets/login_form.dart';
import 'signup_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _goToSignup() async {
    final registeredEmail = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const SignupPage()),
    );
    if (registeredEmail != null && mounted) {
      _emailController.text = registeredEmail;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only listen for successful login navigation — no watch at all
    // so this page NEVER rebuilds due to auth state changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.user != null && previous?.user == null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFD7CCC8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
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
                Image.asset('assets/images/logo.png', height: 110),
                const SizedBox(height: 25),
                LoginForm(
                  emailController:    _emailController,
                  passwordController: _passwordController,
                ),
                const SizedBox(height: 15),
                _buildDivider(),
                const SizedBox(height: 15),
                _buildGoogleButton(),
                const SizedBox(height: 10),
                _buildSignUpRedirect(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() => const Row(children: [
        Expanded(child: Divider(color: Colors.white54)),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text('OR',
                style: TextStyle(color: Colors.white, fontSize: 12))),
        Expanded(child: Divider(color: Colors.white54)),
      ]);

  Widget _buildGoogleButton() => OutlinedButton.icon(
        onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
        icon: Image.asset('assets/images/google_logo.png', height: 24),
        label: const Text('Continue with Google',
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

  Widget _buildSignUpRedirect() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Don't have an account?",
              style: TextStyle(color: Colors.white)),
          TextButton(
            onPressed: _goToSignup,
            child: const Text('Sign Up',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      );
}
