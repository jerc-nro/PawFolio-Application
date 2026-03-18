import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../../../models/record_model.dart';

const _kNotifKey = 'notifications_enabled';

// ─── Notification toggle provider ────────────────────────────────────────────
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
    state = prefs.getBool(_kNotifKey) ?? false;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifKey, value);
  }
}

// ─── Palette ──────────────────────────────────────────────────────────────────
const _kNavy    = Color(0xFF45617D);
const _kBg      = Color(0xFFF5F2EE);
const _kRed     = Color(0xFFBD4B4B);
const _kLabel   = Color(0xFF8A7060);
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
        title: const Text('Account',
            style: TextStyle(
                color: Color(0xFF5D4037),
                fontWeight: FontWeight.w700,
                fontSize: 17)),
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
                  child: Column(children: [
                    ProfileCard(
                        onResendVerification: () =>
                            _resendVerification(context, ref)),
                    const SizedBox(height: 16),
                    const EditFieldsCard(),
                    const SizedBox(height: 16),
                    ActionsCard(
                      onChangePassword:
                          authState.user?.isGoogleUser == true
                              ? null
                              : () => _changePassword(context, ref),
                      onArchive: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ArchivedPetsPage())),
                      onLogout: () => _logout(context, ref),
                    ),
                    const SizedBox(height: 20),
                  ]),
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

  void _logout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(fontSize: 13, height: 1.5)),
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
    if (confirm == true) await ref.read(authProvider.notifier).signOut();
  }

  void _deleteAccount(BuildContext context, WidgetRef ref) async {
    final step1 = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Account',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: _kRed)),
            content: const Text(
                'Are you sure you want to permanently delete your account?\n\nAll your pets and records will be lost.',
                style: TextStyle(fontSize: 13, height: 1.5)),
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
        ) ??
        false;
    if (!step1 || !context.mounted) return;

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
                border:
                    Border.all(color: _kRed.withOpacity(0.2)),
              ),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.info_outline, color: _kRed, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will permanently delete your account and all data. This cannot be undone.',
                        style: TextStyle(
                            fontSize: 12, color: _kRed, height: 1.5)),
                    ),
                  ]),
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
        ) ??
        false;
    if (!step2 || !context.mounted) return;

    await NotificationService.cancelAll();
    await ref.read(authProvider.notifier).deleteAccount();
  }

  void _resendVerification(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).sendEmailVerification();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Verification email sent!'),
        backgroundColor: _kNavy,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
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
        content: Text('A password reset link will be sent to:\n$email',
            style: const TextStyle(fontSize: 13, height: 1.5)),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Password reset email sent!'),
          backgroundColor: _kNavy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }
}

// ─── Settings Drawer ──────────────────────────────────────────────────────────
class _SettingsDrawer extends ConsumerWidget {
  final VoidCallback onDeleteAccount;
  const _SettingsDrawer({required this.onDeleteAccount});

  static const _collections = [
    'vet_visits',
    'medications',
    'vaccinations',
    'preventatives',
    'groom_visits',
  ];

  // Fetch one real upcoming record of a given collection for test notification
  Future<PetRecord?> _fetchOneUpcoming(
      String uid, String collection) async {
    final db = FirebaseFirestore.instance;
    final pets = await db
        .collection('users')
        .doc(uid)
        .collection('pets')
        .where('isArchived', isEqualTo: false)
        .where('isAlive', isEqualTo: true)
        .get();

    for (final pet in pets.docs) {
      final snap = await db
          .collection('users')
          .doc(uid)
          .collection('pets')
          .doc(pet.id)
          .collection(collection)
          .where('status', isEqualTo: 'Upcoming')
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        return PetRecord.fromDoc(snap.docs.first, collection);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifEnabled = ref.watch(notificationEnabledProvider);
    final uid = ref.watch(authProvider).user?.userID;

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
            // ── Header ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              decoration: const BoxDecoration(
                color: _kNavy,
                borderRadius:
                    BorderRadius.only(topLeft: Radius.circular(24)),
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

            // ── Notifications ─────────────────────────────────
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
                  onChanged: (val) =>
                      _handleNotifToggle(context, ref, val),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Account ───────────────────────────────────────
            _DrawerSection(
              label: 'ACCOUNT',
              children: [
                _DrawerActionTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Delete Account',
                  subtitle: 'Permanently remove all data',
                  color: _kRed,
                  onTap: () {
                    Navigator.pop(context);
                    onDeleteAccount();
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Test Notifications ────────────────────────────
            _DrawerSection(
              label: 'TEST NOTIFICATIONS',
              children: [
                _DrawerActionTile(
                  icon: Icons.medication_outlined,
                  title: 'Test Medication Reminder',
                  subtitle: 'Fires a real upcoming medication alert',
                  color: _kNavy,
                  onTap: () async {
                    if (uid == null) return;
                    final record =
                        await _fetchOneUpcoming(uid, 'medications');
                    await _fireTestNotification(
                      context,
                      label: 'Medication Reminder',
                      action: () async {
                        if (record != null) {
                          await NotificationService
                              .testMedicationReminder(
                            petName: record.petName,
                            medName: record.title,
                          );
                        } else {
                          await NotificationService
                              .testMedicationReminder();
                        }
                      },
                    );
                  },
                ),
                Divider(
                    height: 1,
                    color: _kDivider,
                    indent: 16,
                    endIndent: 16),
                _DrawerActionTile(
                  icon: Icons.local_hospital_outlined,
                  title: 'Test Vet Visit Reminder',
                  subtitle: 'Fires a real upcoming vet visit alert',
                  color: _kNavy,
                  onTap: () async {
                    if (uid == null) return;
                    final record =
                        await _fetchOneUpcoming(uid, 'vet_visits');
                    await _fireTestNotification(
                      context,
                      label: 'Vet Visit Reminder',
                      action: () async {
                        await NotificationService.testVetVisitReminder(
                          petName:
                              record?.petName ?? 'Luna',
                        );
                      },
                    );
                  },
                ),
                Divider(
                    height: 1,
                    color: _kDivider,
                    indent: 16,
                    endIndent: 16),
                _DrawerActionTile(
                  icon: Icons.cake_outlined,
                  title: 'Test Birthday Reminder',
                  subtitle: 'Fires a sample birthday alert now',
                  color: _kNavy,
                  onTap: () async {
                    final user =
                        ref.read(authProvider).user;
                    await _fireTestNotification(
                      context,
                      label: 'Birthday Reminder',
                      action: () =>
                          NotificationService.testBirthdayReminder(
                        petName: user?.username ?? 'Mochi',
                      ),
                    );
                  },
                ),
              ],
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text('Pawfolio',
                  style: TextStyle(
                      fontSize: 11,
                      color: _kLabel.withOpacity(0.5),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Toggle: auto-enable when system permission granted ────────────────────
  Future<void> _handleNotifToggle(
      BuildContext context, WidgetRef ref, bool val) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(
          val ? 'Enable Notifications?' : 'Disable Notifications?',
          style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        content: Text(
          val
              ? 'You will receive reminders for medications, vet visits, birthdays, and more.'
              : 'You will no longer receive any pet reminders. You can re-enable this anytime.',
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
                  backgroundColor: val ? _kNavy : _kRed,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: Text(val ? 'Enable' : 'Disable',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700))),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    if (val) {
      // Request system permission — this shows the OS dialog if not yet granted
      await NotificationService.init();
      final allowed = await NotificationService.isAllowed();
      if (!allowed) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Please enable notifications in your device settings first.'),
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }
      // Auto-enable: persist true immediately after OS grants permission
      await ref.read(notificationEnabledProvider.notifier).set(true);
    } else {
      await NotificationService.cancelAll();
      await ref.read(notificationEnabledProvider.notifier).set(false);
    }
  }

  Future<void> _fireTestNotification(
    BuildContext context, {
    required String label,
    required Future<void> Function() action,
  }) async {
    final allowed = await NotificationService.isAllowed();
    if (!allowed) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Notifications are not enabled. Please enable them in Settings first.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }
    await action();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$label sent! Check your notification tray.'),
        backgroundColor: _kNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }
}

// ─── Drawer Helpers ───────────────────────────────────────────────────────────

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
  final String title, subtitle;
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: value
                ? _kNavy.withOpacity(0.1)
                : _kLabel.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: value ? _kNavy : _kLabel),
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
                  style:
                      const TextStyle(fontSize: 11, color: _kLabel)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: _kNavy,
          activeTrackColor: _kNavy.withOpacity(0.25),
          inactiveThumbColor: Colors.grey.shade400,
          inactiveTrackColor: Colors.grey.shade200,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ]),
    );
  }
}

class _DrawerActionTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    style:
                        const TextStyle(fontSize: 11, color: _kLabel)),
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