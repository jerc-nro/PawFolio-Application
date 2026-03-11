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
    final List<String> statuses = ["ALL", "UPCOMING", "ONGOING", "COMPLETED"];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((status) {
          final bool isSelected = selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.blueGrey,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF455A64), // navBlue
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.grey.shade300,
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