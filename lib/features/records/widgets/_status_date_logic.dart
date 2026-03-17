// Shared date-status logic used by all record dialogs.
import 'package:flutter/material.dart';

enum DateRelation { past, today, future, none }

/// Parse dd.MM.yyyy → DateTime, return null if empty/invalid.
DateTime? parseDMY(String s) {
  if (s.trim().isEmpty) return null;
  try {
    final p = s.split('.');
    if (p.length != 3) return null;
    return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
  } catch (_) {
    return null;
  }
}

/// Compare a parsed date against today (time-stripped).
DateRelation dateRelation(DateTime? d) {
  if (d == null) return DateRelation.none;
  final today = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final cmp = DateTime(d.year, d.month, d.day);
  if (cmp.isBefore(today)) return DateRelation.past;
  if (cmp.isAfter(today))  return DateRelation.future;
  return DateRelation.today;
}

/// Returns whether a status option is selectable given the date relation.
/// past   → Completed ✓  Ongoing ✓  Upcoming ✗
/// today  → all ✓
/// future → Completed ✗  Ongoing ✓  Upcoming ✓
/// none   → all ✓  (date not chosen yet — don't restrict)
bool statusAllowed(String status, DateRelation rel) {
  switch (rel) {
    case DateRelation.past:
      return status != 'UPCOMING';
    case DateRelation.future:
      return status != 'COMPLETED';
    case DateRelation.today:
    case DateRelation.none:
      return true;
  }
}

/// Auto-correct status when date changes, returns corrected status (or same).
String autoCorrectStatus(String current, DateRelation rel) {
  if (!statusAllowed(current, rel)) {
    if (rel == DateRelation.past)   return 'COMPLETED';
    if (rel == DateRelation.future) return 'UPCOMING';
  }
  return current;
}

/// Smart status button — greyed out & unclickable when disabled.
/// Shows an inline warning when the user tries to tap a disabled button.
Widget smartStatusBtn({
  required String label,
  required Color color,
  required String current,
  required DateRelation rel,
  required void Function(String) onSelect,
  required BuildContext context,
}) {
  final value    = label.toUpperCase();
  final selected = current == value;
  final allowed  = statusAllowed(value, rel);

  return GestureDetector(
    onTap: () {
      if (!allowed) {
        // Show inline snackbar hint
        final msg = rel == DateRelation.future
            ? "Future records cannot be marked as Completed."
            : "Past records cannot be marked as Upcoming.";
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(msg,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            backgroundColor: const Color(0xFF455A64),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            duration: const Duration(seconds: 3),
          ));
        return;
      }
      onSelect(value);
    },
    child: Opacity(
      opacity: allowed ? 1.0 : 0.3,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected && allowed ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected && allowed ? Colors.white : color,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      ),
    ),
  );
}
