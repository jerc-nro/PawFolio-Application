import 'package:flutter/material.dart';

/// Maps display label → Firestore value (both UPPERCASE now)
const Map<String, String> statusFilterValues = {
  'ALL':       'ALL',
  'UPCOMING':  'UPCOMING',
  'ONGOING':   'ONGOING',
  'OVERDUE':   'OVERDUE',
  'COMPLETED': 'COMPLETED',
};

/// Returns the display label - just returns uppercase as-is
String statusDisplayLabel(String? firestoreValue) {
  if (firestoreValue == null || firestoreValue.isEmpty) {
    return 'UNKNOWN';
  }
  return firestoreValue.toUpperCase().trim();
}

/// Returns the color for a status value
Color statusColor(String? status) {
  if (status == null || status.isEmpty) return Colors.grey;
  
  final upper = status.toUpperCase().trim();
  if (upper == 'COMPLETED') return const Color(0xFF388E3C);
  if (upper == 'ONGOING')   return const Color(0xFFD32F2F);
  if (upper == 'OVERDUE')   return const Color(0xFFBD4B4B);
  if (upper == 'UPCOMING')  return const Color(0xFFFFB300);
  return Colors.grey;
}

class StatusFilterRow extends StatelessWidget {
  /// [selectedStatus] should be UPPERCASE (e.g., "UPCOMING", "COMPLETED")
  final String selectedStatus;
  /// [onStatusSelected] will receive UPPERCASE status
  final Function(String) onStatusSelected;

  const StatusFilterRow({
    super.key,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
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
          final isSelected = selectedStatus == firestoreValue;
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