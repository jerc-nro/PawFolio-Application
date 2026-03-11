import 'package:flutter/material.dart';
import 'package:pawfolio/views/Homepage/Home_screen.dart';
import '../LandingPage/Signup_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<UserProvider>();

    try {
      await provider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;
      
      // Navigate only on SUCCESS
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    
    } catch (e) {
      debugPrint("Error: $e");

      if (!mounted) return;

      // Friendly Error Mapping - Now correctly inside the catch block
      String errorMsg = "An unexpected error occurred.";
      final eString = e.toString().toLowerCase();

      if (eString.contains('invalid-credential') || 
          eString.contains('user-not-found') || 
          eString.contains('wrong-password')) {
        errorMsg = "Invalid email or password.";
      } else if (eString.contains('network-request-failed')) {
        errorMsg = "No internet connection.";
      } else if (eString.contains('too-many-requests')) {
        errorMsg = "Too many attempts. Try again later.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: const Color(0xFF7B2B2B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } // End of catch
  }


  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
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
              return null;
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF8B947E), fontSize: 13),
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
                  _buildInputField(label: "EMAIL", hint: "example@gmail.com", controller: _emailController),
                  _buildInputField(label: "PASSWORD", hint: "Enter password", controller: _passwordController, isPassword: true),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF425C7D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: SizedBox(
                      height: 20,
                      child: isLoading
                          ? const AspectRatio(aspectRatio: 1, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("LOG IN", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?", style: TextStyle(color: Colors.white)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupPage())),
                        child: const Text("Sign Up", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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