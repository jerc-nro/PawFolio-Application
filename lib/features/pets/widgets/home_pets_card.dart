import 'package:flutter/material.dart';
import 'package:pawfolio/models/pet_model.dart';

class PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback? onTap; // Added callback for navigation

  const PetCard({
    super.key, 
    required this.pet, 
    this.onTap,
  });

  // Helper to get the correct emoji based on pet type
  String get _emoji {
    switch (pet.type.toUpperCase()) {
      case 'CAT':
        return '🐱';
      case 'DOG':
        return '🐶';
      default:
        return '🐾';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12, 
              blurRadius: 6, 
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Emoji avatar with themed background
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8DDD6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(_emoji, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 8),
                // Name + breed
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A5568),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        pet.breed,
                        style: const TextStyle(
                          fontSize: 10, 
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            // INFO button / Label
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF4A5568), // Matches nav bar slate grey
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'INFO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}