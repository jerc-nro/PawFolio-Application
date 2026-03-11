import 'package:flutter/material.dart';
import '../models/pet_model.dart';

class PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback? onTap;
  final Function(Pet)? onArchive; 

  const PetCard({
    super.key,
    required this.pet,
    this.onTap,
    this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    // If onArchive is null, we disable the swipe capability
    final bool canSwipe = onArchive != null;

    return Dismissible(
      key: Key(pet.petID), 
      direction: canSwipe ? DismissDirection.endToStart : DismissDirection.none,
      
      onDismissed: (direction) {
        if (onArchive != null) onArchive!(pet);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${pet.name} archived")),
        );
      },

      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.shade700,
          borderRadius: BorderRadius.circular(30),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 30),
        child: const Icon(Icons.archive, color: Colors.white, size: 30),
      ),

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF546E7A),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D8D76),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.pets, size: 50, color: Colors.white),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Name', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      Text(
                        pet.name,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('Type and Breed', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      Text(
                        "${pet.type} | ${pet.breed}",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('Date of Birth', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      Text(
                        pet.birthDate,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}