import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final String username;
  final int totalPets;
  const HomeHeader({super.key, required this.username, required this.totalPets});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A7060),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3)),
                const SizedBox(height: 2),
                Text('Hi, $username 👋',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D3A4A))),
                const SizedBox(height: 4),
                Text(
                  totalPets == 0
                      ? 'No pets yet — add one!'
                      : '$totalPets ${totalPets == 1 ? 'pet' : 'pets'} registered',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF8A7060)),
                ),
              ],
            ),
          ),
          // Minimal pet count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF45617D),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$totalPets',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1)),
                const SizedBox(height: 2),
                const Text('PETS',
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.white60,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}