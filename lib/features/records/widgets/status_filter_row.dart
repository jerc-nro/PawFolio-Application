import 'package:flutter/material.dart';

class StatusFilterRow extends StatelessWidget {
  final String selectedStatus;
  final Function(String) onStatusSelected;

  const StatusFilterRow({
    super.key,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> statuses = [
      "ALL",
      "UPCOMING",
      "ONGOING",
      "OVERDUE",
      "COMPLETED",
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: statuses.map((status) {
          final bool isSelected = selectedStatus == status;
          final Color activeColor = status == "OVERDUE"
              ? const Color(0xFFBD4B4B)
              : const Color(0xFF455A64);

          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: ChoiceChip(
              showCheckmark: false,
              label: Text(
                status,
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
                if (selected) onStatusSelected(status);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}