import 'package:flutter/material.dart';

class AuthInputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Iterable<String>? autofillHints; // 👈 Good for UX (Email/Password)

  const AuthInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          validator: validator,
          autofillHints: autofillHints,
          // 👈 Shows error after the first manual validation failure
          autovalidateMode: AutovalidateMode.onUserInteraction, 
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            
            // Standard Borders
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.white, width: 1.5),
            ),
            
            // Error Borders
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFCF6679), width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFCF6679), width: 1.8),
            ),
            
            // Error Text Styling
            errorStyle: const TextStyle(
              color: Color(0xFFCF6679),
              fontWeight: FontWeight.w600, // 👈 Makes it pop on dark backgrounds
              fontSize: 12,
            ),
            errorMaxLines: 2, // 👈 Prevents text cutting off
          ),
        ),
      ],
    );
  }
}