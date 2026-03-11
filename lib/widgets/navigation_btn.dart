import 'package:flutter/material.dart';

class CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onAddPressed;
  final IconData centerIcon; // Custom icon (e.g., Icons.add or Icons.check)

  const CustomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onAddPressed,
    this.centerIcon = Icons.add, // Default to plus icon
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFF4A5568), // Your standard nav color
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The Row of Icons
          Row(
            children: [
              _navItem(0, Icons.home_outlined, 'Home'),
              _navItem(1, Icons.pets, 'My Pets'),
              const SizedBox(width: 70), // Gap for the center button
              _navItem(2, Icons.description_outlined, 'Records'),
              _navItem(3, Icons.person_outline, 'Account'),
            ],
          ),
          // The Center Floating Button
          Positioned(
            top: -25,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: onAddPressed,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFB5714A), // Brown accent
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Icon(centerIcon, color: Colors.white, size: 30),
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
      child: InkWell(
        onTap: () => onItemSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? Colors.white : Colors.white54, size: 24),
            Text(label, style: TextStyle(color: active ? Colors.white : Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}