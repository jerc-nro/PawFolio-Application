import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/category_filter.dart';
import '../providers/pet_controller.dart';
import '../providers/pet_filter_provider.dart';
import '../widgets/my_pets_card.dart';
import '../widgets/pet_filter_modal.dart';
import '../widgets/pet_search_bar.dart';
import '../../records/theme/records_theme.dart';
import '../../records/screen/records_navigator.dart';
import 'pet_profile_page.dart';

class MyPetsScreen extends ConsumerWidget {
  const MyPetsScreen({super.key});

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
    final activeFilters     = _activeFilterCount(ref);
    final hasFilters        = activeFilters > 0;

    return Scaffold(
      backgroundColor: RecordsPalette.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // ── Title ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 20, height: 3,
                      decoration: BoxDecoration(
                        color: RecordsPalette.terra,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('MY PETS',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: RecordsPalette.terra,
                            letterSpacing: 2.0)),
                  ]),
                  const SizedBox(height: 6),
                  const Text('Pets',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: RecordsPalette.ink,
                          letterSpacing: -0.5)),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── Search + Filter ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                const Expanded(child: PetSearchBar()),
                const SizedBox(width: 10),

                // Filter button — same height and border style as search bar
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
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: hasFilters
                              ? RecordsPalette.steel
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: hasFilters
                                ? RecordsPalette.steel
                                : RecordsPalette.linenDeep,
                          ),
                          boxShadow: hasFilters
                              ? [BoxShadow(
                                  color: RecordsPalette.steel
                                      .withOpacity(0.22),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))]
                              : [BoxShadow(
                                  color: RecordsPalette.ink
                                      .withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))],
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: hasFilters
                              ? Colors.white
                              : RecordsPalette.muted,
                          size: 20,
                        ),
                      ),

                      // Active filter count badge
                      if (hasFilters)
                        Positioned(
                          top: -4, right: -4,
                          child: Container(
                            width: 17, height: 17,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: RecordsPalette.terra,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: RecordsPalette.bg, width: 1.5),
                            ),
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

            // ── Type filter row ─────────────────────────────
            CategoryFilter(
              selectedCategory: ref.watch(petTypeFilterProvider),
              onFilterChanged: (val) {
                ref.read(petTypeFilterProvider.notifier).state = val;
                ref.read(petBreedFilterProvider.notifier).state = 'ALL';
              },
            ),

            const SizedBox(height: 10),

            // ── Pet grid ────────────────────────────────────
            Expanded(
              child: filteredPetsAsync.when(
                data: (pets) {
                  if (pets.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pets,
                              size: 44,
                              color: RecordsPalette.muted
                                  .withOpacity(0.3)),
                          const SizedBox(height: 12),
                          const Text('No pets found.',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: RecordsPalette.muted)),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: pets.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (_, i) {
                      final pet = pets[i];
                      return MyPetsCard(
                        pet: pet,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  PetProfilePage(pet: pet)),
                        ),
                        onArchive: (p) =>
                            _handleArchive(context, ref, p),
                      );
                    },
                  );
                },
                loading: () => Center(
                    child: CircularProgressIndicator(
                        color: RecordsPalette.steel)),
                error: (_, _) => const Center(
                    child: Text('Something went wrong',
                        style:
                            TextStyle(color: RecordsPalette.muted))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleArchive(
      BuildContext context, WidgetRef ref, dynamic pet) async {
    await ref.read(petControllerProvider).archivePet(pet.petID);
    if (!context.mounted) return;
    showRecordToast(context, '${pet.name} archived',
        icon: Icons.inventory_2_outlined);
    // Undo via a second toast isn't possible — keep a standard SnackBar for undo
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${pet.name} archived'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: RecordsPalette.steel,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      action: SnackBarAction(
        label: 'UNDO',
        textColor: RecordsPalette.linen,
        onPressed: () =>
            ref.read(petControllerProvider).restorePet(pet.petID),
      ),
    ));
  }
}