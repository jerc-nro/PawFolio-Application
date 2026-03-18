import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/category_filter.dart';
import '../../pets/widgets/record_pets_card.dart';
import '../screen/records_navigator.dart';
import '../../../features/pets/widgets/pet_search_bar.dart';
import '../../pets/providers/pet_filter_provider.dart';
import '../widgets/record_category.dart';
import '../theme/records_theme.dart';

class SelectPetDialog extends ConsumerStatefulWidget {
  const SelectPetDialog({
    super.key,
    required this.category,
    this.isAddMode = false,
    // When opened from quick add (home), pop all the way back after save
    this.popToHomeOnSave = false,
  });

  final RecordCategory category;
  final bool isAddMode;
  final bool popToHomeOnSave;

  @override
  ConsumerState<SelectPetDialog> createState() => _SelectPetDialogState();
}

class _SelectPetDialogState extends ConsumerState<SelectPetDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(petTypeFilterProvider.notifier).set('ALL');
      ref.read(petSearchQueryProvider.notifier).set('');
      ref.read(petBreedFilterProvider.notifier).set('ALL');
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredPetsAsync = ref.watch(filteredActivePetsProvider);
    final selectedType      = ref.watch(petTypeFilterProvider);

    return Dialog.fullscreen(
      backgroundColor: RecordsPalette.bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DialogHeader(
              category:   widget.category,
              isAddMode:  widget.isAddMode,
            ),
            const SizedBox(height: 20),

            PetSearchBar(
              onChanged: (val) =>
                  ref.read(petSearchQueryProvider.notifier).set(val),
            ),
            const SizedBox(height: 15),

            CategoryFilter(
              selectedCategory: selectedType,
              onFilterChanged: (val) {
                ref.read(petTypeFilterProvider.notifier).set(val);
                ref.read(petBreedFilterProvider.notifier).set('ALL');
              },
            ),
            const SizedBox(height: 16),

            const _SectionLabel(text: 'YOUR PETS'),
            const SizedBox(height: 12),

            Expanded(
              child: filteredPetsAsync.when(
                data: (pets) {
                  if (pets.isEmpty) return const _EmptyPets();
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                    itemCount: pets.length,
                    itemBuilder: (context, index) {
                      final pet = pets[index];
                      return PetCard(
                        pet: pet,
                        onTap: () {
                          RecordNavigationHelper.navigateToHistory(
                            context:          context,
                            ref:              ref,
                            category:         widget.category,
                            pet:              pet,
                            isAdd:            widget.isAddMode,
                            // Pass through: true only when coming from quick add
                            popToHomeOnSave:  widget.popToHomeOnSave,
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: RecordsPalette.steel)),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.category, required this.isAddMode});
  final RecordCategory category;
  final bool isAddMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RecordsPalette.steel,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: RecordsPalette.steel.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withOpacity(0.25)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(category.icon,
                  color: Colors.white.withOpacity(0.9), size: 13),
              const SizedBox(width: 6),
              Text(
                category.label.toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 1.4),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Text(
            isAddMode ? 'Add Record for...' : 'Select a Pet',
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.2,
                height: 1.1),
          ),
          const SizedBox(height: 4),
          Text(
            isAddMode
                ? 'Select which pet to add this record to'
                : 'Choose which pet to view records for',
            style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.62)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Container(
          width: 5, height: 5,
          decoration: const BoxDecoration(
              color: RecordsPalette.terra, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: RecordsPalette.muted,
                letterSpacing: 1.6)),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
              height: 1,
              color: RecordsPalette.muted.withOpacity(0.2)),
        ),
      ]),
    );
  }
}

class _EmptyPets extends StatelessWidget {
  const _EmptyPets();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.pets,
            size: 48,
            color: RecordsPalette.muted.withOpacity(0.35)),
        const SizedBox(height: 12),
        const Text('No pets found.',
            style: TextStyle(
                color: RecordsPalette.muted, fontSize: 15)),
      ]),
    );
  }
}