// lib/core/widgets/custom_nav_bar.dart
import 'package:flutter/material.dart';

class CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onAddPressed;
  final IconData centerIcon;

  const CustomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onAddPressed,
    this.centerIcon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85, // Slightly taller to accommodate labels comfortably
      decoration: const BoxDecoration(
        color: Color(0xFF4A5568),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              _navItem(0, Icons.home_outlined, 'Home'),
              _navItem(1, Icons.pets_outlined, 'My Pets'),
              const SizedBox(width: 80), // Match the FAB size
              _navItem(2, Icons.description_outlined, 'Records'),
              _navItem(3, Icons.person_outline, 'Account'),
            ],
          ),
          Positioned(
            top: -30, // Lift it out of the bar
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: onAddPressed,
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB5714A),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                    ],
                  ),
                  child: Icon(centerIcon, color: Colors.white, size: 35),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onItemSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? Colors.white : Colors.white54, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white54,
                fontSize: 11,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}