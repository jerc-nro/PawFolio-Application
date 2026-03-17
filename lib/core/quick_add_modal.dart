import 'package:flutter/material.dart';
import 'package:pawfolio/features/records/widgets/select_pet_dialog.dart';
import 'package:pawfolio/features/records/widgets/record_category.dart';
import '../../features/pets/screens/add_pet_page.dart';

class QuickAddModal {
  // Theme Constants
  static const Color kHeader = Color(0xFF4A6580);
  static const Color kBg = Color(0xFFF5F2EE);
  static const Color kAccentGreen = Color(0xFF7A8C6A);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _QuickAddContent(),
    );
  }
}

class _QuickAddContent extends StatelessWidget {
  const _QuickAddContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: QuickAddModal.kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minimalist Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'QUICK ADD',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: QuickAddModal.kHeader,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),

          // Record Options
          // Change these lines in your _QuickAddContent Column:
          _buildOption(context, 'Medication', Icons.medication_outlined),
          _buildOption(context, 'Vaccination', Icons.vaccines_outlined),
          _buildOption(context, 'Preventatives', Icons.shield_outlined),
          _buildOption(context, 'Vet Visit', Icons.medical_services_outlined),
          _buildOption(context, 'Grooming', Icons.content_cut_outlined), // Changed from 'Groom Visit'
          _buildOption(context, 'Weight', Icons.monitor_weight_outlined),  // Added to match your list

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.black12),
          ),

          // Standout "Add New Pet" Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Close bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddPetPage()),
                );
              },
              icon: const Icon(Icons.add, color: QuickAddModal.kAccentGreen),
              label: const Text(
                "ADD NEW PET",
                style: TextStyle(
                  color: QuickAddModal.kAccentGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                side: const BorderSide(color: QuickAddModal.kAccentGreen, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

Widget _buildOption(BuildContext context, String title, IconData icon) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: ListTile(
      onTap: () {
        // 1. Find matching category from your master list
        final fullCategory = kRecordCategories.firstWhere(
          (cat) => cat.label.toLowerCase() == title.toLowerCase(),
          orElse: () => RecordCategory(
            label: title,
            subtitle: 'Add new $title entry',
            filterKey: title.toLowerCase().replaceAll(' ', '_'),
            icon: icon,
            cardColor: const Color(0xFFE0E0E0),
            iconBg: const Color(0xFFBDBDBD),
          ),
        );

        // 2. Pop the BottomSheet first to avoid UI overlap
        Navigator.pop(context);

        // 3. Push the SelectPetDialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SelectPetDialog(
              category: fullCategory,
              isAddMode: true, // This flag tells the next screen we are ADDING
            ),
          ),
        );
      },
      leading: Icon(icon, color: QuickAddModal.kHeader),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600, 
          color: Colors.black87
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right, 
        color: Colors.black26, 
        size: 20
      ),
    ),
  );
}
}