import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class UIHelper {
  // FIX: Added the missing method from your error log
  static Uint8List decodeBase64(String base64String) {
    return base64Decode(base64String);
  }

  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static Future<bool> confirmAction(BuildContext context, String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("CONFIRM", style: TextStyle(color: Color(0xFF7B2B2B))),
          ),
        ],
      ),
    ) ?? false;
  }
}


class ToastHelper {
  // Success Toast
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      Colors.green.shade600,
      Icons.check_circle_outline,
    );
  }

  // Error Toast
  static void showError(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      Colors.red.shade600,
      Icons.error_outline,
    );
  }

  // Private generic method to reduce boilerplate
  static void _showSnackBar(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon,
  ) {
    // Clears existing snackbars to prevent queuing delays
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}