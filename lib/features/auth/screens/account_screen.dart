import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pawfolio/core/loading_screen.dart';
import 'package:pawfolio/features/records/screen/archived_records_page.dart';
import '../../pets/screens/archived_pet_page.dart';
import '../providers/account_controller.dart';
import '../providers/auth_provider.dart';
import '../widgets/actions_card.dart';
import '../widgets/edit_fields_card.dart';
import '../widgets/profile_card.dart';
import '../../../services/notification_services.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final accountState = ref.watch(accountControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFD7CCC8),
      // --- ADDED: APPBAR FOR BURGER BUTTON ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.brown),
      ),
      // --- ADDED: DRAWER (BURGER MENU) ---
      drawer: Drawer(
        backgroundColor: const Color(0xFFF5F5F5),
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFFD7CCC8)),
              child: Center(
                child: Text("Settings", 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown)),
              ),
            ),
            SwitchListTile(
              title: const Text("Push Notifications"),
              secondary: const Icon(Icons.notifications_outlined),
              value: true, // Connect to your notification provider
              onChanged: (val) => _handleNotificationToggle(val, ref),
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text("Delete Account", style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context); // Close drawer
                _deleteAccount(context, ref);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      ProfileCard(onResendVerification: () => _resendVerification(context, ref)),
                      const SizedBox(height: 16),
                      const EditFieldsCard(),
                      const SizedBox(height: 16),
                      ActionsCard(
                        onChangePassword: () => _changePassword(context, ref),
                        onArchive: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ArchivedPetsPage())),
                        onLogout: () => _logout(context, ref), // FIXED LOGIC BELOW
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            // Loading screen triggers based on state
            if (accountState.isLoading || authState.isLoading) const LoadingScreen(),
          ],
        ),
      ),
    );
  }

  void _handleNotificationToggle(bool enabled, WidgetRef ref) async {
    if (enabled) {
      final isAllowed = await NotificationService.isAllowed();
      if (!isAllowed) { /* Handle permission request */ }
    } else {
      await NotificationService.cancelAll();
    }
  }

  void _logout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Logout"),
        content: const Text("Tuloy ba? Sigurado ka na bang gusto mong mag-sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text("HINDI", style: TextStyle(color: Colors.grey))
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("OO, TULOY", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // The authProvider.isLoading becomes true here, showing the LoadingScreen automatically
      await ref.read(authProvider.notifier).signOut();
      // No need for manual navigation if your main.dart/router listens to authState changes
    }
  }

  void _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text("This action cannot be undone. All data will be removed. Tuloy?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await NotificationService.cancelAll();
      await ref.read(authProvider.notifier).deleteAccount();
    }
  }

  void _resendVerification(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).sendEmailVerification();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Verification email sent!")));
    }
  }

  void _changePassword(BuildContext context, WidgetRef ref) async {
    final email = ref.read(authProvider).user?.email;
    if (email == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reset Password"),
        content: Text("A reset link will be sent to $email."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("SEND")),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(authProvider.notifier).sendPasswordResetEmail(email);
    }
  }
}