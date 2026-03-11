import 'package:flutter/material.dart';
import 'package:pawfolio/views/grooming.dart';
import 'package:pawfolio/views/pet_records_screen.dart';
import '../../models/pet_model.dart'; 
import '../widgets/pet_info_card.dart'; // Make sure the path is correct
import '../views/INFORMATION.dart';

class PetDetailScreen extends StatelessWidget {
  final Pet pet;

  const PetDetailScreen({super.key, required this.pet});

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
              
              // Now Swipe is DISABLED here because onArchive is null
              PetCard(
                pet: pet, 
                onTap: null, 
                onArchive: null, 
              ),
              
              const SizedBox(height: 30),
              
              _buildHistoryButton(
                Icons.info_outline, 
                "Information", 
                cardBlue, 
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PetProfilePage(pet: pet), // Pass the pet here
                    ),
                  );
                },
              ),
              
              _buildHistoryButton(
                Icons.medical_services_outlined, 
                "Medical History", 
                cardBlue,
                onTap: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => PetRecordsScreen(petId: pet.petID)
                  //   ),
                  // );
                },
              ),
              
             _buildHistoryButton(
                  Icons.content_cut, 
                  "Grooming History", 
                  cardBlue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // Passes the full Pet object; NO 'const' and NO '.petID'
                        builder: (context) => GroomingHistoryView(pet: pet), 
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryButton(IconData icon, String label, Color color, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: onTap,
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