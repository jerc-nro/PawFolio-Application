import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

const _kNavy   = Color(0xFF45617D);
const _kBrown  = Color(0xFFBA7F57);
const _kSage   = Color(0xFF8B947E);
const _kBg     = Color(0xFFD7CCC8);
const _kLabel  = Color(0xFF8A7060);
const _kDivider = Color(0xFFE8DDD6);

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey        = GlobalKey<FormState>();
  final _nameCtrl       = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  final _confirmCtrl    = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  bool _done            = false; // verification email sent state

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
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
        duration: const Duration(seconds: 4),
      ));
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    try {
      await ref.read(authProvider.notifier).signUpAndMarkNew(
            _emailCtrl.text.trim(),
            _passwordCtrl.text,
            _nameCtrl.text.trim(),
          );
      if (mounted) setState(() => _done = true);
    } catch (_) {
      // error handled by ref.listen below
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

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
                horizontal: 24, vertical: 40),
            child: Column(
              children: [
                Image.asset('assets/images/logo.png', height: 90),
                const SizedBox(height: 8),
                Text(
                  _done ? 'Check your email' : 'Create Account',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _kNavy),
                ),
                const SizedBox(height: 4),
                Text(
                  _done
                      ? 'We sent a verification link to your email'
                      : 'Join Pawfolio today',
                  style: const TextStyle(
                      fontSize: 13, color: _kLabel),
                ),
                const SizedBox(height: 28),

                // ── Verification success state ────────────────────────
                if (_done)
                  _VerificationSentCard(
                    email: _emailCtrl.text.trim(),
                    onBackToLogin: () =>
                        Navigator.of(context).pop(_emailCtrl.text.trim()),
                  )
                else ...[
                  // ── Signup form card ──────────────────────────────────
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
                          _fieldLabel('Full Name'),
                          TextFormField(
                            controller: _nameCtrl,
                            textCapitalization:
                                TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDeco(
                                'e.g. Maria Santos',
                                Icons.person_outline),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Name is required';
                              }
                              if (v.trim().length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          _fieldLabel('Email'),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDeco(
                                'you@email.com',
                                Icons.email_outlined),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!RegExp(
                                      r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$')
                                  .hasMatch(v.trim())) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          _fieldLabel('Password'),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDeco(
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
                                onPressed: () => setState(() =>
                                    _obscurePassword =
                                        !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Password is required';
                              }
                              if (v.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              if (!RegExp(r'[A-Z]').hasMatch(v)) {
                                return 'Include at least one uppercase letter';
                              }
                              if (!RegExp(r'[0-9]').hasMatch(v)) {
                                return 'Include at least one number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          _fieldLabel('Confirm Password'),
                          TextFormField(
                            controller: _confirmCtrl,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _signUp(),
                            decoration: _inputDeco(
                              '••••••••',
                              Icons.lock_outline,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: _kLabel,
                                ),
                                onPressed: () => setState(() =>
                                    _obscureConfirm =
                                        !_obscureConfirm),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (v != _passwordCtrl.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Password rules hint
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _kNavy.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: _kNavy.withOpacity(0.12)),
                            ),
                            child: const Text(
                              'Password must be at least 8 characters, '
                              'include an uppercase letter and a number.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: _kLabel,
                                  height: 1.5),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Create account button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _signUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kBrown,
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
                                  : const Text('Create Account',
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
                  _orDivider(),
                  const SizedBox(height: 20),

                  // Google
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
                      side: const BorderSide(
                          color: _kDivider, width: 1.5),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Already have account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account?',
                          style: TextStyle(
                              color: _kLabel, fontSize: 13)),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Sign In',
                            style: TextStyle(
                                color: _kNavy,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // Loading overlay
        if (isLoading)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(color: _kSage),
            ),
          ),
      ]),
    );
  }

  Widget _fieldLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _kLabel,
                letterSpacing: 0.8)),
      );

  InputDecoration _inputDeco(String hint, IconData icon) =>
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
        Expanded(child: Divider(color: _kDivider, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR',
              style: TextStyle(
                  color: _kLabel,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Divider(color: _kDivider, thickness: 1)),
      ]);
}

// ─── Verification sent card ───────────────────────────────────────────────────
class _VerificationSentCard extends StatelessWidget {
  final String email;
  final VoidCallback onBackToLogin;
  const _VerificationSentCard(
      {required this.email, required this.onBackToLogin});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: _kNavy.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              color: _kNavy, size: 32),
        ),
        const SizedBox(height: 16),
        const Text('Verification email sent!',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kNavy)),
        const SizedBox(height: 8),
        Text(
          'We sent a link to $email.\n'
          'Click the link to verify your account, then sign in.',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 13, color: _kLabel, height: 1.5),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: onBackToLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kNavy,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Back to Sign In',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}