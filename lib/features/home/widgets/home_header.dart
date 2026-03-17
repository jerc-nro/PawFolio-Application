import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final String username;
  final int totalPets;
  const HomeHeader({super.key, required this.username, required this.totalPets});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GOOD MORNING',
                    style: TextStyle(fontSize: 11, color: Color(0xFF8B947E),
                        fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                const SizedBox(height: 2),
                Text('Hi, $username!',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                        color: Color(0xFF2D3A4A))),
                const SizedBox(height: 4),
                Row(children: [
                  const Text('🐾 ', style: TextStyle(fontSize: 13)),
                  Text('$totalPets pets registered',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF7A6E65))),
                ]),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF2D3A4A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              const Text('TOTAL', style: TextStyle(fontSize: 9, color: Colors.white60,
                  fontWeight: FontWeight.w600, letterSpacing: 1)),
              Text('$totalPets', style: const TextStyle(fontSize: 22,
                  fontWeight: FontWeight.w800, color: Colors.white)),
            ]),
          ),
        ],
      ),
    );
  }
}