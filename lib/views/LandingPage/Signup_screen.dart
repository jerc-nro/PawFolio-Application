import 'package:flutter/material.dart';
import 'package:pawfolio/views/LandingPage/Login_screen.dart';
import 'package:pawfolio/views/Homepage/Home_screen.dart';
import 'package:provider/provider.dart';
import 'package:pawfolio/providers/user_provider.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signup() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<UserProvider>();

    try {
      await provider.signup(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _usernameController.text.trim(),
      );

      if (!mounted) return;
      if (provider.isLoggedIn) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } catch (e) {
      if (!mounted) return;

      String errorMsg = "Could not create account.";
      final eString = e.toString().toLowerCase();

      if (eString.contains('email-already-in-use')) {
        errorMsg = "This email is already registered.";
      } else if (eString.contains('weak-password')) {
        errorMsg = "The password provided is too weak.";
      } else if (eString.contains('network-request-failed')) {
        errorMsg = "Check your internet connection.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: const Color(0xFF7B2B2B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildInputField({required String label, required String hint, required TextEditingController controller, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            obscureText: isPassword,
            style: const TextStyle(fontSize: 14),
            validator: (value) {
              final val = value?.trim() ?? '';
              if (val.isEmpty) return '$label is required';
              if (label == "EMAIL") {
                final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!regex.hasMatch(val)) return 'Enter a valid email';
              }
              if (label == "PASSWORD" && val.length < 8) return 'Min 8 characters';
              if (label == "CONFIRM PASSWORD" && val != _passwordController.text.trim()) return 'Passwords do not match';
              return null;
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              errorStyle: const TextStyle(color: Color(0xFF7B2B2B), fontWeight: FontWeight.bold),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<UserProvider>().isLoading;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF8B947E),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15)],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Image.asset("assets/images/logo.png", height: 110),
                  const SizedBox(height: 20),
                  _buildInputField(label: "USERNAME", hint: "User123", controller: _usernameController),
                  _buildInputField(label: "EMAIL", hint: "example@gmail.com", controller: _emailController),
                  _buildInputField(label: "PASSWORD", hint: "Enter password", controller: _passwordController, isPassword: true),
                  _buildInputField(label: "CONFIRM PASSWORD", hint: "Re-enter password", controller: _confirmPasswordController, isPassword: true),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: isLoading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF425C7D),
                      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: SizedBox(
                      height: 20,
                      child: isLoading
                          ? const AspectRatio(aspectRatio: 1, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("SIGN UP", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?", style: TextStyle(color: Colors.white)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                        child: const Text("Log In", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}