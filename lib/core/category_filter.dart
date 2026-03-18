import 'package:flutter/material.dart';

class CategoryFilter extends StatelessWidget {
  final Function(String) onFilterChanged;
  final String selectedCategory;

  const CategoryFilter({
    super.key,
    required this.onFilterChanged,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    // Categories should match exactly what your data/side-filter uses
    final categories = ['ALL', 'DOG', 'CAT'];

    return SizedBox(
      height: 40,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: categories.map((cat) {
            // Standardizing to uppercase for consistent comparison
            final bool isSelected = selectedCategory.toUpperCase() == cat.toUpperCase();

            return GestureDetector(
              onTap: () => onFilterChanged(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                constraints: const BoxConstraints(minWidth: 80),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4A6572) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected 
                    ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
                    : [],
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.grey.shade300,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}