import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/category_filter.dart';
import '../providers/pet_controller.dart';
import '../providers/pet_filter_provider.dart';
import '../widgets/my_pets_card.dart';
import '../widgets/pet_filter_modal.dart';
import '../widgets/pet_search_bar.dart';
import 'pet_profile_page.dart';

class MyPetsScreen extends ConsumerWidget {
  const MyPetsScreen({super.key});

  // Count active non-type filters so badge stays accurate
  int _activeFilterCount(WidgetRef ref) {
    int c = 0;
    if (ref.watch(petBreedFilterProvider) != 'ALL') c++;
    if (ref.watch(petSexFilterProvider) != 'ALL') c++;
    if (ref.watch(petSterilizedFilterProvider) != null) c++;
    return c;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredPetsAsync = ref.watch(filteredActivePetsProvider);
    final activeFilters = _activeFilterCount(ref);

    return Scaffold(
      backgroundColor: const Color(0xFFD7CCC8),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ── Title ──────────────────────────────────────
            const Text('MY PETS', style: TextStyle(
                fontSize: 25, fontWeight: FontWeight.bold,
                color: Color(0xFF4A6572), letterSpacing: 1.2)),

            const SizedBox(height: 20),

            // ── Search + Filter button row ──────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                const Expanded(child: PetSearchBar()),
                const SizedBox(width: 10),
                // Filter button with active badge
                GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => const PetFilterModal(),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: activeFilters > 0
                              ? const Color(0xFF2D3A4A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: activeFilters > 0
                              ? Colors.transparent : Colors.black12),
                        ),
                        child: Icon(Icons.tune_rounded,
                            color: activeFilters > 0
                                ? Colors.white : const Color(0xFF4A6572),
                            size: 20),
                      ),
                      if (activeFilters > 0)
                        Positioned(
                          top: -4, right: -4,
                          child: Container(
                            width: 16, height: 16,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                                color: Color(0xFFCF6679),
                                shape: BoxShape.circle),
                            child: Text('$activeFilters',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                    ],
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 12),

            // ── Category filter (owns type) ─────────────────
            CategoryFilter(
              selectedCategory: ref.watch(petTypeFilterProvider),
              onFilterChanged: (val) {
                ref.read(petTypeFilterProvider.notifier).state = val;
                // Reset breed when type changes — keeps both in sync
                ref.read(petBreedFilterProvider.notifier).state = 'ALL';
              },
            ),

            const SizedBox(height: 10),

            // ── Pet grid ────────────────────────────────────
            Expanded(
              child: filteredPetsAsync.when(
                data: (pets) {
                  if (pets.isEmpty) return const Center(
                      child: Text('No results found.',
                          style: TextStyle(color: Colors.black45)));
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: pets.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 15,
                      mainAxisSpacing: 15, childAspectRatio: 0.72,
                    ),
                    itemBuilder: (_, i) {
                      final pet = pets[i];
                      return MyPetsCard(
                        pet: pet,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => PetProfilePage(pet: pet))),
                        onArchive: (p) => _handleArchive(context, ref, p),
                      );
                    },
                  );
                },
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF4A6580))),
                error: (_, __) => const Center(
                    child: Text('Something went wrong')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleArchive(BuildContext context, WidgetRef ref, dynamic pet) async {
    await ref.read(petControllerProvider).archivePet(pet.petID);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${pet.name} archived'),
      action: SnackBarAction(
          label: 'UNDO',
          onPressed: () =>
              ref.read(petControllerProvider).restorePet(pet.petID)),
    ));
  }
}