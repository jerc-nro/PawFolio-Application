
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pawfolio/core/loading_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pets/screens/archived_pet_page.dart';
import '../../records/providers/notification_settings_provider.dart';
import '../../records/screen/notification_settings_screen.dart';
import '../providers/account_controller.dart';
import '../widgets/actions_card.dart';
import '../widgets/edit_fields_card.dart';
import '../widgets/profile_card.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF45617D);
const _kBg = Color(0xFFF5F2EE);
const _kRed = Color(0xFFBD4B4B);
const _kDivider = Color(0xFFE0D4CB);

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final accountState = ref.watch(accountControllerProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5D4037)),
        centerTitle: false,
        title: const Text(
          'Account',
          style: TextStyle(
            color: Color(0xFF5D4037),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      endDrawer: const _SettingsDrawer(),
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
                      ProfileCard(
                        onResendVerification: () =>
                            _resendVerification(context, ref),
                      ),
                      const SizedBox(height: 16),
                      const EditFieldsCard(),
                      const SizedBox(height: 16),
                      ActionsCard(
                        onChangePassword: authState.user?.isGoogleUser == true
                            ? null
                            : () => _changePassword(context, ref),
                        onArchive: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ArchivedPetsPage(),
                          ),
                        ),
                        onLogout: () => _logout(context, ref),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            if (accountState.isLoading || authState.isLoading)
              const LoadingScreen(),
          ],
        ),
      ),
    );
  }

  // ─── Logic Handlers ────────────────────────────────────────────────────────

  void _logout(BuildContext context, WidgetRef ref) async {
    final confirm = await _showConfirmDialog(
      context,
      title: 'Sign Out',
      content: 'Are you sure you want to sign out?',
      actionLabel: 'Sign Out',
      actionColor: _kNavy,
    );
    if (confirm == true) await ref.read(authProvider.notifier).signOut();
  }

  void _resendVerification(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).sendEmailVerification();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent!')),
      );
    }
  }

  void _changePassword(BuildContext context, WidgetRef ref) async {
    final email = ref.read(authProvider).user?.email;
    if (email == null) return;

    final confirm = await _showConfirmDialog(
      context,
      title: 'Reset Password',
      content: 'A password reset link will be sent to:\n$email',
      actionLabel: 'Send Link',
      actionColor: _kNavy,
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).sendPasswordResetEmail(email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent!')),
        );
      }
    }
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    required String actionLabel,
    required Color actionColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(actionLabel, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Settings Drawer ──────────────────────────────────────────────────────────

class _SettingsDrawer extends ConsumerWidget {
  const _SettingsDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationSettingsProvider);
    final uid = ref.watch(authProvider).user?.userID;

    return Drawer(
      width: 300,
      backgroundColor: const Color(0xFFF5F0EE),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(),
            const SizedBox(height: 8),
            _DrawerSection(
              label: 'NOTIFICATIONS',
              children: [
                _DrawerToggleTile(
                  icon: Icons.notifications_outlined,
                  title: 'Push Notifications',
                  subtitle: notifState.enabled ? 'Reminders enabled' : 'Reminders disabled',
                  value: notifState.enabled,
                  loading: notifState.loading,
                  onChanged: (val) => ref.read(notificationSettingsProvider.notifier).toggle(),
                ),
                ListTile(
                  leading: const Icon(Icons.settings_suggest_outlined, size: 20, color: _kNavy),
                  title: const Text('Manage Preferences', style: TextStyle(fontSize: 13)),
                  onTap: () {
                    Navigator.pop(context);
                    showNotificationSettings(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            _DrawerSection(
              label: 'DANGER ZONE',
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: _kRed),
                  title: const Text('Delete Account', style: TextStyle(color: _kRed, fontWeight: FontWeight.w600)),
                  onTap: () => _handleDeleteAccount(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: const BoxDecoration(
        color: _kNavy,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
          const SizedBox(height: 12),
          const Text('Settings',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          Text('App preferences',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
        ],
      ),
    );
  }

  void _handleDeleteAccount(BuildContext context, WidgetRef ref) async {
    // Implement the two-step delete logic here as shown in previous snippets
    // Ensure you call NotificationService.cancelAll() before ref.deleteAccount()
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _DrawerSection extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _DrawerSection({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        ...children,
      ],
    );
  }
}

class _DrawerToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool loading;
  final ValueChanged<bool> onChanged;

  const _DrawerToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.loading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: _kNavy, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Switch(value: value, onChanged: onChanged, activeColor: _kNavy),
    );
  }
}