import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'signup_page.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const _kNavy   = Color(0xFF45617D);
const _kBrown  = Color(0xFFBA7F57);
const _kSage   = Color(0xFF8B947E);
const _kBg     = Color(0xFFD7CCC8);
const _kCream  = Color(0xFFDCCDC3);
const _kLabel  = Color(0xFF8A7060);
const _kDivider = Color(0xFFE8DDD6);

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey         = GlobalKey<FormState>();
  final _emailCtrl       = TextEditingController();
  final _passwordCtrl    = TextEditingController();
  bool _obscurePassword  = true;
  bool _rememberMe       = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(msg,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13)),
          ),
        ]),
        backgroundColor: const Color(0xFF7B2B2B),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ));
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authProvider.notifier).signIn(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
  }

  Future<void> _goToSignup() async {
    final registeredEmail = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const SignupPage()),
    );
    if (registeredEmail != null && mounted) {
      _emailCtrl.text = registeredEmail;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Show errors from provider
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        _showError(next.error!);
      }
    });

    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(children: [
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // ── Logo ─────────────────────────────────────────────
                Image.asset('assets/images/logo.png', height: 100),
                const SizedBox(height: 8),
                const Text('Welcome back',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _kNavy)),
                const SizedBox(height: 4),
                const Text('Sign in to your account',
                    style: TextStyle(fontSize: 13, color: _kLabel)),
                const SizedBox(height: 28),

                // ── Form card ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: _kNavy.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 6))
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email
                        _fieldLabel('Email'),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: _inputDecoration(
                              'you@email.com',
                              Icons.email_outlined),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!v.contains('@') || !v.contains('.')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password
                        _fieldLabel('Password'),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _signIn(),
                          decoration: _inputDecoration(
                            '••••••••',
                            Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: _kLabel,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword =
                                      !_obscurePassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password is required';
                            }
                            if (v.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        // Remember me + Forgot password
                        Row(children: [
                          SizedBox(
                            width: 24, height: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              activeColor: _kNavy,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              onChanged: (v) {
                                setState(() => _rememberMe = v ?? false);
                                ref
                                    .read(authProvider.notifier)
                                    .toggleRememberMe(v ?? false);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Remember me',
                              style: TextStyle(
                                  fontSize: 12, color: _kLabel)),
                          const Spacer(),
                          TextButton(
                            style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap),
                            onPressed: () =>
                                _showForgotPassword(context),
                            child: const Text('Forgot password?',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: _kNavy,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ]),

                        const SizedBox(height: 20),

                        // Sign in button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kNavy,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14)),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2))
                                : const Text('Sign In',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── OR divider ────────────────────────────────────────
                _orDivider(),
                const SizedBox(height: 20),

                // ── Google button ─────────────────────────────────────
                OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => ref
                          .read(authProvider.notifier)
                          .signInWithGoogle(),
                  icon: Image.asset('assets/images/google_logo.png',
                      height: 22),
                  label: const Text('Continue with Google',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3C3C3C))),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: _kDivider, width: 1.5),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Sign up redirect ──────────────────────────────────
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text("Don't have an account?",
                      style: TextStyle(
                          color: _kLabel, fontSize: 13)),
                  TextButton(
                    onPressed: isLoading ? null : _goToSignup,
                    child: const Text('Sign Up',
                        style: TextStyle(
                            color: _kNavy,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                ]),
              ],
            ),
          ),
        ),

        // Full-screen loading overlay (Google sign-in)
        if (isLoading && !authState.isSigningUp)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(color: _kSage),
            ),
          ),
      ]),
    );
  }

  void _showForgotPassword(BuildContext context) {
    final ctrl = TextEditingController(text: _emailCtrl.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your email and we\'ll send you a reset link.',
                style: TextStyle(fontSize: 13, color: _kLabel)),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration('Email', Icons.email_outlined),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: _kLabel))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (ctrl.text.trim().isNotEmpty) {
                ref
                    .read(authProvider.notifier)
                    .sendPasswordResetEmail(ctrl.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Password reset email sent!'),
                    backgroundColor: _kNavy,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _kNavy,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Send Link',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _kLabel,
                letterSpacing: 0.8)),
      );

  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kLabel, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: _kLabel),
        filled: true,
        fillColor: const Color(0xFFF5F0EE),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kDivider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kNavy, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.2)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
      );

  Widget _orDivider() => Row(children: [
        Expanded(
            child: Divider(color: _kDivider, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR',
              style: TextStyle(
                  color: _kLabel,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(
            child: Divider(color: _kDivider, thickness: 1)),
      ]);
}