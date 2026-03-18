import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pet_filter_provider.dart';
import '../../records/theme/records_theme.dart';

class PetSearchBar extends ConsumerWidget {
  const PetSearchBar({super.key, this.onChanged});

  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: RecordsPalette.linenDeep),
          boxShadow: [
            BoxShadow(
              color: RecordsPalette.ink.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onChanged: (val) {
            if (onChanged != null) {
              onChanged!(val);
            } else {
              ref.read(petSearchQueryProvider.notifier).state = val;
            }
          },
          style: const TextStyle(
            fontSize: 14,
            color: RecordsPalette.ink,
          ),
          decoration: InputDecoration(
            hintText: 'Search pets...',
            hintStyle: TextStyle(
              fontSize: 14,
              color: RecordsPalette.muted.withOpacity(0.7),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: RecordsPalette.muted,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                vertical: 14, horizontal: 4),
          ),
        ),
      ),
    );
  }
}