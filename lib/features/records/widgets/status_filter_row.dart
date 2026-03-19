import 'package:flutter/material.dart';

/// Maps display label (uppercase) → Firestore value (title-case).
/// The filter providers and Firestore queries should always use the
/// Firestore value so they match what is actually stored in the DB.
const Map<String, String> statusFilterValues = {
  'ALL':       'ALL',
  'UPCOMING':  'Upcoming',
  'ONGOING':   'Ongoing',
  'OVERDUE':   'Overdue',
  'COMPLETED': 'Completed',
};

/// Returns the display label for a given Firestore status value.
String statusDisplayLabel(String firestoreValue) {
  return statusFilterValues.entries
      .firstWhere(
        (e) => e.value == firestoreValue,
        orElse: () => MapEntry(firestoreValue.toUpperCase(), firestoreValue),
      )
      .key;
}

/// Returns the color for a status value (accepts both display and Firestore forms).
Color statusColor(String status) {
  final normalized = status.toLowerCase();
  if (normalized == 'completed') return const Color(0xFF388E3C);
  if (normalized == 'ongoing')   return const Color(0xFFD32F2F);
  if (normalized == 'overdue')   return const Color(0xFFBD4B4B);
  if (normalized == 'upcoming')  return const Color(0xFFFFB300);
  return Colors.grey;
}

class StatusFilterRow extends StatelessWidget {
  /// [selectedStatus] should be the **Firestore** value (title-case) or "ALL".
  final String selectedStatus;
  /// [onStatusSelected] will receive the **Firestore** value (title-case) or "ALL".
  final Function(String) onStatusSelected;

  const StatusFilterRow({
    super.key,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Display order of chips
    const List<String> labels = [
      'ALL',
      'UPCOMING',
      'ONGOING',
      'OVERDUE',
      'COMPLETED',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: labels.map((label) {
          final firestoreValue = statusFilterValues[label]!;
          final bool isSelected = selectedStatus == firestoreValue;
          final Color activeColor = label == 'OVERDUE'
              ? const Color(0xFFBD4B4B)
              : const Color(0xFF455A64);

          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: ChoiceChip(
              showCheckmark: false,
              label: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: isSelected ? Colors.white : const Color(0xFF455A64),
                ),
              ),
              selected: isSelected,
              selectedColor: activeColor,
              backgroundColor: Colors.white,
              elevation: isSelected ? 4 : 0,
              pressElevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              onSelected: (bool selected) {
                if (selected) onStatusSelected(firestoreValue);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}