import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

void showEditWeightDialog(BuildContext context, String petId, QueryDocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  final weightController = TextEditingController(text: data['weight'].toString());
  
  DateTime selectedDate = (data['recordedDate'] as Timestamp).toDate();
  String dateString = data['date_string'] ?? "";

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Edit Weight'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: Text(dateString),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                    dateString = "${picked.day}.${picked.month}.${picked.year}";
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              // tryParse prevents the "Invalid double" crash if user enters letters
              final val = double.tryParse(weightController.text);
              if (val == null) return; 

              await doc.reference.update({
                'weight': val,
                'date_string': dateString,
                'recordedDate': Timestamp.fromDate(selectedDate),
              });

              // Safety check for web/async navigation
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}