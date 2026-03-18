import 'package:flutter/material.dart';

class AccountInfoRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isEditing;
  final bool isEnabled;
  final VoidCallback? onEdit;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;

  const AccountInfoRow({
    super.key,
    required this.label,
    required this.controller,
    this.isEditing = false,
    this.isEnabled = true,
    this.onEdit,
    this.onSave,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: isEditing && isEnabled,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: const InputDecoration(
                    disabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                ),
              ),
              if (isEnabled) ...[
                if (!isEditing)
                  IconButton(icon: const Icon(Icons.edit, color: Colors.white70), onPressed: onEdit)
                else ...[
                  IconButton(icon: const Icon(Icons.check, color: Colors.greenAccent), onPressed: onSave),
                  IconButton(icon: const Icon(Icons.close, color: Colors.redAccent), onPressed: onCancel),
                ]
              ]
            ],
          ),
        ],
      ),
    );
  }
}