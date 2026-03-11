import 'package:flutter/material.dart';

class CategoryFilter extends StatefulWidget {
  final ValueChanged<String> onFilterChanged;

  const CategoryFilter({super.key, required this.onFilterChanged});

  @override
  State<CategoryFilter> createState() => _CategoryFilterState();
}

class _CategoryFilterState extends State<CategoryFilter> {
  String _selected = 'ALL';

  void _select(String value) {
    setState(() => _selected = value);
    widget.onFilterChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    // Mas safe gamitin ang MainAxisSize.min para hindi mag-overflow sa Row
    return Row(
      mainAxisSize: MainAxisSize.min, 
      children: [
        _FilterBtn(
          label: 'DOGS', 
          value: 'DOG', // Dinagdag ang value parameter
          selected: _selected, 
          onTap: () => _select('DOG'),
        ),
        const SizedBox(width: 6),
        _FilterBtn(
          label: 'CATS', 
          value: 'CAT', // Dinagdag ang value parameter
          selected: _selected, 
          onTap: () => _select('CAT'),
        ),
        const SizedBox(width: 6),
        _FilterBtn(
          label: 'SEE ALL', 
          value: 'ALL',  // Dinagdag ang value parameter
          selected: _selected, 
          onTap: () => _select('ALL'),
        ),
      ],
    );
  }
}

class _FilterBtn extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final VoidCallback onTap;

  const _FilterBtn({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  // Ngayon, ico-compare na ang 'selected' state vs 'value' ng button
  bool get _isActive => selected == value;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: _isActive
              ? const Color(0xFFCDB4A7) // Active color
              : const Color(0xFF4A5568), // Inactive color
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: _isActive ? const Color(0xFF4A3728) : Colors.white,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}