import 'package:flutter/material.dart';

class UIHelper {
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
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
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
              TextButton(
                onPressed: () => Navigator.pop(context, true), 
                child: const Text("CONFIRM", style: TextStyle(color: Color(0xFF7B2B2B))),
              ),
            ],
          ),
        ) ?? false;
  }
}