import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // Add this to pubspec.yaml
import 'package:pawfolio/providers/user_provider.dart';
import 'package:pawfolio/widgets/pass_confirm.dart';
import 'package:pawfolio/utils/helpers/ui_helper.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool isEditingUser = false;
  late TextEditingController userController;
  late TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    userController = TextEditingController(text: user?.username);
    emailController = TextEditingController(text: user?.email);
  }

  void _showSnackBar(String msg, Color col) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: col));

  /// Logic to handle Logout with confirmation
  Future<void> _handleLogout() async {
    bool confirm = await _confirmAction(
      "Logout", 
      "Are you sure you want to log out of your account?"
    );

    if (confirm && mounted) {
      context.read<UserProvider>().logout();
    }
  }

  Future<void> _updatePass() async {
    final res = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const PasswordChangeDialog(),
    );
    
    if (res == null || res['current'] == null || res['new'] == null) return;

    bool confirm = await UIHelper.confirmAction(
      context, 
      "Change Password?", 
      "You will be logged out after the change for security."
    );

    if (confirm) {
      try {
        await context.read<UserProvider>().updatePassword(res['current']!, res['new']!);
        
        if (mounted) {
          UIHelper.showSnackBar(context, "Password updated! Please log in again.");
        }
      } catch (e) {
        if (mounted) {
          UIHelper.showSnackBar(context, "Update failed: Check your current password.", isError: true);
        }
      }
    }
  }

  Future<bool> _confirmAction(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false), 
                child: const Text("CANCEL", style: TextStyle(color: Colors.grey))
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true), 
                child: const Text("CONFIRM", style: TextStyle(color: Color(0xFF7B2B2B), fontWeight: FontWeight.bold))
              ),
            ],
          ),
        ) ?? false;
  }

  Future<void> _updateName() async {
    bool confirm = await _confirmAction("Change Username?", "Are you sure you want to change your name to ${userController.text}?");
    if (!confirm) return;

    try {
      await context.read<UserProvider>().updateUsername(userController.text);
      setState(() => isEditingUser = false);
      _showSnackBar("Username updated!", Colors.green);
    } catch (e) {
      _showSnackBar("Error updating username", Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    const accentRed = Color(0xFF7B2B2B);
    const bgColor = Color(0xFFD7CCC8); 
    const cardColor = Color(0xFF949B86);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                        child: const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, size: 50, color: Colors.grey),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, 10),
                        child: GestureDetector(
                          onTap: () {
                            // Logic for profile picture update
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: accentRed, borderRadius: BorderRadius.circular(10)),
                            child: const Text("Edit", style: TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(userProvider.user?.username ?? "User", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(userProvider.user?.email ?? "", style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w300)),
                  const SizedBox(height: 25),

                  _buildRow("USERNAME", userController, isEditingUser,
                      onEdit: () => setState(() => isEditingUser = true),
                      onSave: _updateName,
                      onCancel: () => setState(() {
                            isEditingUser = false;
                            userController.text = userProvider.user?.username ?? "";
                          })),
                  
                  _buildRow("EMAIL", emailController, false, isEnabled: false),
                  
                  _buildRow("PASSWORD", TextEditingController(text: "********"), false, isPassword: true, onEdit: _updatePass),

                  const SizedBox(height: 20),
                  if (userProvider.isLoading) const CircularProgressIndicator(color: Colors.white)
                  else ...[
                    // Updated LOGOUT button to use confirmation handler
                    _btn("LOGOUT", accentRed, _handleLogout),
                    const SizedBox(height: 12),
                    _btn("ARCHIVE", const Color(0xFF455A71), () {}),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, TextEditingController ctr, bool isEdit, {VoidCallback? onEdit, VoidCallback? onSave, VoidCallback? onCancel, bool isPassword = false, bool isEnabled = true}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: Container(
            height: 48, 
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: isEnabled ? Colors.white : Colors.white.withOpacity(0.6), 
              borderRadius: BorderRadius.circular(12)
            ),
            alignment: Alignment.centerLeft,
            child: isEdit 
              ? TextField(
                  controller: ctr, 
                  autofocus: true,
                  style: const TextStyle(color: Colors.black), 
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true)
                ) 
              : Text(isPassword ? "••••••••" : ctr.text, style: const TextStyle(color: Colors.black87)),
          ),
        ),
        if (isEnabled) ...[
          const SizedBox(width: 8),
          isEdit ? Row(children: [
            GestureDetector(onTap: onSave, child: const Icon(Icons.check_circle, color: Colors.white, size: 28)),
            const SizedBox(width: 8),
            GestureDetector(onTap: onCancel, child: const Icon(Icons.cancel, color: Colors.white70, size: 28)),
          ]) : ElevatedButton(
            onPressed: onEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B2B2B), 
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
            ),
            child: const Text("EDIT", style: TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ]
      ]),
      const SizedBox(height: 18),
    ]);
  }

  Widget _btn(String txt, Color col, VoidCallback tap) => SizedBox(
    width: double.infinity, 
    height: 50, 
    child: ElevatedButton(
      onPressed: tap, 
      style: ElevatedButton.styleFrom(backgroundColor: col, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), 
      child: Text(txt, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
    )
  );
}