import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/pet_model.dart';
import '../../../models/record_model.dart';
import '../providers/notification_settings_provider.dart';
import '../theme/records_theme.dart';

/// Show as a bottom sheet over the main navigation.
/// Call this from wherever you have the settings icon.
///
/// Example:
///   showNotificationSettings(context);
void showNotificationSettings(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const NotificationSettingsSheet(),
  );
}

class NotificationSettingsSheet extends ConsumerWidget {
  const NotificationSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationSettingsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag handle ──────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Title ────────────────────────────────────────────────────
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notifications_outlined,
                  color: RecordsPalette.steel, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: RecordsPalette.ink,
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // ── Main toggle ───────────────────────────────────────────────
          _ToggleTile(
            icon: Icons.notifications_active_outlined,
            title: 'Enable Notifications',
            subtitle: state.enabled
                ? 'You\'ll be reminded about upcoming records and birthdays.'
                : 'Turn on to get reminders for medications, vet visits, and more.',
            value: state.loading ? false : state.enabled,
            loading: state.loading,
            onChanged: state.loading
                ? null
                : (_) async {
                    await ref
                        .read(notificationSettingsProvider.notifier)
                        .toggle();
                  },
          ),

          if (state.enabled) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // ── What gets notified ────────────────────────────────────
            const Text(
              'You\'ll be notified for:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: RecordsPalette.muted,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.science_outlined,
                color: const Color(0xFFBA7F57),
                label: 'Medications — on the day, at 9:00 AM'),
            _InfoRow(icon: Icons.verified_outlined,
                color: const Color(0xFF5A9E62),
                label: 'Vaccinations — 1 day before'),
            _InfoRow(icon: Icons.local_hospital_outlined,
                color: const Color(0xFF45617D),
                label: 'Vet visits — 1 day before'),
            _InfoRow(icon: Icons.content_cut_outlined,
                color: const Color(0xFF8B6FAB),
                label: 'Grooming — 1 day before'),
            _InfoRow(icon: Icons.shield_outlined,
                color: const Color(0xFF5C6BAD),
                label: 'Preventatives — 1 day before'),
            _InfoRow(icon: Icons.cake_outlined,
                color: const Color(0xFFC0392B),
                label: 'Birthdays — on the day, at 8:00 AM'),
          ],

          const SizedBox(height: 24),

          // ── Close button ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: RecordsPalette.steel,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Done',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Toggle tile ───────────────────────────────────────────────────────────────
class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool loading;
  final ValueChanged<bool>? onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.loading,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: value
            ? RecordsPalette.steel.withOpacity(0.06)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? RecordsPalette.steel : RecordsPalette.linenDeep,
          width: value ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value
                ? RecordsPalette.steel.withOpacity(0.12)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              size: 20,
              color: value ? RecordsPalette.steel : Colors.grey.shade400),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: RecordsPalette.ink)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 11,
                      color: RecordsPalette.muted.withOpacity(0.8))),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (loading)
          const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: RecordsPalette.steel))
        else
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: RecordsPalette.steel,
          ),
      ]),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _InfoRow({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: RecordsPalette.ink)),
      ]),
    );
  }
}