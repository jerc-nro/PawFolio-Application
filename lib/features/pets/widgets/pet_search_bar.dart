import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pet_filter_provider.dart';
import 'pet_filter_modal.dart';

class PetSearchBar extends ConsumerWidget {
  const PetSearchBar({
    super.key,
    this.onChanged, // Optional callback for custom logic
  });

  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      // Adjusted padding to match your Dialog's 20px standard
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: TextField(
                onChanged: (val) {
                  // If a custom callback is provided (like in SelectPetDialog), use it.
                  // Otherwise, fall back to the default provider.
                  if (onChanged != null) {
                    onChanged!(val);
                  } else {
                    ref.read(petSearchQueryProvider.notifier).state = val;
                  }
                },
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}