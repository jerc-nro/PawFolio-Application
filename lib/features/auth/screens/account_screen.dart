import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pawfolio/core/loading_screen.dart';
import '../../pets/screens/archived_pet_page.dart';
import '../providers/account_controller.dart';
import '../providers/auth_provider.dart';
import '../widgets/actions_card.dart';
import '../widgets/edit_fields_card.dart';
import '../widgets/profile_card.dart';
import '../../../services/notification_services.dart';

// SharedPreferences key for notification toggle state
const _kNotifKey = 'notifications_enabled';

// ─── Notification toggle provider ────────────────────────────────────────────
// Reads persisted value on init; updates SharedPreferences on change.
final notificationEnabledProvider =
    StateNotifierProvider<_NotifNotifier, bool>(
  (ref) => _NotifNotifier(),
);

class _NotifNotifier extends StateNotifier<bool> {
  _NotifNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    // Default false — never enabled unless user explicitly turns it on
    state = prefs.getBool(_kNotifKey) ?? false;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifKey, value);
  }
}

// ─── Palette ──────────────────────────────────────────────────────────────────
const _kNavy   = Color(0xFF45617D);
const _kBrown  = Color(0xFFBA7F57);
const _kSage   = Color(0xFF8B947E);
const _kBg     = Color(0xFFF5F2EE);
const _kRed    = Color(0xFFBD4B4B);
const _kLabel  = Color(0xFF8A7060);
const _kDivider = Color(0xFFE0D4CB);

// ─── Screen ───────────────────────────────────────────────────────────────────
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState    = ref.watch(authProvider);
    final accountState = ref.watch(accountControllerProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5D4037)),
        title: const Text(
          'Account',
          style: TextStyle(
              color: Color(0xFF5D4037),
              fontWeight: FontWeight.w700,
              fontSize: 17),
        ),
      ),
      endDrawer: _SettingsDrawer(
        onDeleteAccount: () => _deleteAccount(context, ref),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        onChangePassword: () =>
                            _changePassword(context, ref),
                        onArchive: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ArchivedPetsPage()),
                        ),
                        onLogout: () => _logout(context, ref),
                      ),
                      const SizedBox(height: 20),
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

  // ── Logout ──────────────────────────────────────────────────────────────────
  void _logout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kNavy,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Sign Out',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authProvider.notifier).signOut();
      // Router/main.dart listening to authState handles navigation
    }
  }

  // ── Delete account (2-step) ─────────────────────────────────────────────────
  void _deleteAccount(BuildContext context, WidgetRef ref) async {
    // Step 1
    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: _kRed)),
        content: const Text(
          'Are you sure you want to permanently delete your account?\n\n'
          'All your pets and records will be lost.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kRed,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Continue',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700))),
        ],
      ),
    ) ?? false;
    if (!step1 || !context.mounted) return;

    // Step 2
    final step2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: const [
          Icon(Icons.warning_amber_rounded, color: _kRed, size: 20),
          SizedBox(width: 8),
          Text('Are you absolutely sure?',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kRed.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kRed.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.info_outline, color: _kRed, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This will permanently delete your account and all data. '
                  'This cannot be undone.',
                  style: TextStyle(
                      fontSize: 12, color: _kRed, height: 1.5)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Go back',
                style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kRed,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Delete Forever',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700))),
        ],
      ),
    ) ?? false;
    if (!step2 || !context.mounted) return;

    await NotificationService.cancelAll();
    await ref.read(authProvider.notifier).deleteAccount();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  void _resendVerification(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).sendEmailVerification();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Verification email sent!'),
          backgroundColor: _kNavy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _changePassword(BuildContext context, WidgetRef ref) async {
    final email = ref.read(authProvider).user?.email;
    if (email == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'A password reset link will be sent to:\n$email',
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kNavy,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Send Link',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(authProvider.notifier).sendPasswordResetEmail(email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password reset email sent!'),
            backgroundColor: _kNavy,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}

// ─── Settings Drawer ──────────────────────────────────────────────────────────
class _SettingsDrawer extends ConsumerWidget {
  final VoidCallback onDeleteAccount;
  const _SettingsDrawer({required this.onDeleteAccount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifEnabled = ref.watch(notificationEnabledProvider);

    return Drawer(
      width: 300,
      backgroundColor: const Color(0xFFF5F0EE),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.horizontal(left: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              decoration: const BoxDecoration(
                color: _kNavy,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.settings_outlined,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 12),
                  const Text('Settings',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('App preferences',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Notifications section ─────────────────────────────
            _DrawerSection(
              label: 'NOTIFICATIONS',
              children: [
                _DrawerToggleTile(
                  icon: Icons.notifications_outlined,
                  title: 'Push Notifications',
                  subtitle: notifEnabled
                      ? 'You will receive reminders'
                      : 'Tap to enable reminders',
                  value: notifEnabled,
                  onChanged: (val) async {
                    if (val) {
                      // Only enable if permission is granted
                      final allowed =
                          await NotificationService.isAllowed();
                      if (!allowed) {
                        // Show info that they need to enable in system settings
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text(
                                'Please enable notifications in your device settings.'),
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                        return;
                      }
                    } else {
                      await NotificationService.cancelAll();
                    }
                    ref
                        .read(notificationEnabledProvider.notifier)
                        .set(val);
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Account section ───────────────────────────────────
            _DrawerSection(
              label: 'ACCOUNT',
              children: [
                _DrawerActionTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Delete Account',
                  subtitle: 'Permanently remove all data',
                  color: _kRed,
                  onTap: () {
                    Navigator.pop(context); // close drawer first
                    onDeleteAccount();
                  },
                ),
              ],
            ),

            const Spacer(),

            // ── Footer ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                'Pawfolio',
                style: TextStyle(
                    fontSize: 11,
                    color: _kLabel.withOpacity(0.5),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Drawer Helpers ───────────────────────────────────────────────────────────

class _DrawerSection extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _DrawerSection(
      {required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _kLabel,
                  letterSpacing: 1.2)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kDivider),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _DrawerToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;

  const _DrawerToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: value
                ? _kNavy.withOpacity(0.1)
                : _kLabel.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              size: 18,
              color: value ? _kNavy : _kLabel),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C))),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: _kLabel)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: _kNavy,
          activeTrackColor: _kNavy.withOpacity(0.25),
          inactiveThumbColor: Colors.grey.shade400,
          inactiveTrackColor: Colors.grey.shade200,
          materialTapTargetSize:
              MaterialTapTargetSize.shrinkWrap,
        ),
      ]),
    );
  }
}

class _DrawerActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DrawerActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: _kLabel)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              size: 18, color: color.withOpacity(0.5)),
        ]),
      ),
    );
  }
}