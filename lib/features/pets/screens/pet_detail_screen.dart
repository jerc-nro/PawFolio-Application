import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/pet_model.dart';
import '../../records/widgets/record_category.dart';
import '../widgets/my_pets_card.dart'; 
import 'grooming_history_view.dart';
import 'pet_profile_page.dart';
import 'pet_profile_page.dart';

class PetDetailScreen extends ConsumerStatefulWidget {
  final Pet pet;
  final RecordCategory? category;
  final bool isAddMode;

  const PetDetailScreen({
    super.key,
    required this.pet,
    this.category,
    this.isAddMode = false,
  });

  @override
  ConsumerState<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends ConsumerState<PetDetailScreen> {
  
  @override
  void initState() {
    super.initState();
    
    // TRIGGER: If we are in "Add Mode", show the specific form dialog immediately
    if (widget.isAddMode && widget.category != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddRecordDialog(context, widget.category!);
      });
    }
  }

  void _showAddRecordDialog(BuildContext context, RecordCategory category) {
    // This is where you call your Medication/Vaccination form dialog
    // Example: showDialog(context: context, builder: (_) => MedicationForm(pet: widget.pet));
    debugPrint("Automatically opening Add Form for ${category.label}");
  }

  @override
  Widget build(BuildContext context) {
    const Color cardBlue = Color(0xFF546E7A);
    const Color navBlue = Color(0xFF455A64);

    return Scaffold(
      backgroundColor: const Color(0xFFD7CCC8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Back Button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const CircleAvatar(
                    backgroundColor: navBlue,
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Reusing MyPetsCard
              MyPetsCard(
                pet: widget.pet,
                onTap: () {}, 
                onArchive: (_) {}, 
              ),

              const SizedBox(height: 30),

              // Navigation Options
              _buildHistoryButton(
                context,
                icon: Icons.info_outline,
                label: "Information",
                color: cardBlue,
                destination: PetProfilePage(pet: widget.pet),
              ),

              _buildHistoryButton(
                context,
                icon: Icons.medical_services_outlined,
                label: "Medical History",
                color: cardBlue,
                destination: PetProfilePage(pet: widget.pet),
              ),

              _buildHistoryButton(
                context,
                icon: Icons.content_cut,
                label: "Grooming History",
                color: cardBlue,
                destination: GroomingHistoryView(pet: widget.pet),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Widget destination,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 85,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              CircleAvatar(
                backgroundColor: Colors.white24,
                radius: 25,
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 20),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}