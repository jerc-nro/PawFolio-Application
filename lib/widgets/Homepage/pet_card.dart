import 'package:flutter/material.dart';
import '../../models/pet_model.dart';

class PetCard extends StatelessWidget {
  final Pet pet;
  const PetCard({super.key, required this.pet});

  String get _emoji {
    switch (pet.type.toLowerCase()) {
      case 'cat':  return '🐱';
      case 'dog':
      default:     return '🐶';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Emoji avatar
              Container(
                width: 36, height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8DDD6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(_emoji, style: const TextStyle(fontSize: 18)),
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
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A5568)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      pet.breed,
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          // INFO button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF4A5568),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('INFO',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}