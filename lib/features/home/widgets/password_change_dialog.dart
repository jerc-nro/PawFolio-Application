import 'package:flutter/material.dart';

class PasswordChangeDialog extends StatefulWidget {
  const PasswordChangeDialog({super.key});

  @override
  State<PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<PasswordChangeDialog> {
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _isObscured = true;
  String? _errorMessage;

  void _handleConfirm() {
    setState(() => _errorMessage = null);

    if (_currentPassController.text.isEmpty || 
        _newPassController.text.isEmpty || 
        _confirmPassController.text.isEmpty) {
      setState(() => _errorMessage = "All fields are required");
      return;
    }

    if (_newPassController.text != _confirmPassController.text) {
      setState(() => _errorMessage = "New passwords do not match");
      return;
    }

    Navigator.pop(context, {
      'current': _currentPassController.text,
      'new': _newPassController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Matching your navigation bar/background slate grey
      backgroundColor: const Color(0xFF4A5568), 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text(
        "CHANGE PASSWORD", 
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white, 
          fontSize: 18, 
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2
        )
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!, 
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)
                ),
              ),
            _buildDialogField(_currentPassController, "Current Password"),
            const SizedBox(height: 12),
            _buildDialogField(_newPassController, "New Password"),
            const SizedBox(height: 12),
            _buildDialogField(_confirmPassController, "Confirm New Password"),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _handleConfirm,
                style: ElevatedButton.styleFrom(
                  // Your "High Importance" action color
                  backgroundColor: const Color(0xFF7B2B2B), 
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text("UPDATE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDialogField(TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            hint.toUpperCase(),
            style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: _isObscured,
          style: const TextStyle(color: Colors.black, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            suffixIcon: IconButton(
              icon: Icon(
                _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
                color: Colors.grey, 
                size: 18
              ),
              onPressed: () => setState(() => _isObscured = !_isObscured),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: BorderSide.none
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}