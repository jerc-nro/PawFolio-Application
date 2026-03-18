import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/pets/providers/pet_filter_provider.dart';
import '../../../features/pets/providers/pet_provider.dart';
import '../../../models/pet_model.dart' show Pet;
import '../widgets/record_category.dart';
import '../theme/records_theme.dart';
import '../widgets/record_category_card.dart';
import '../widgets/select_pet_dialog.dart';
import '../screen/archived_records_page.dart';

class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  void _openSelectPet(BuildContext context, WidgetRef ref, RecordCategory cat) {
    ref.read(recordsTypeFilterProvider.notifier).state  = cat.filterKey;
    ref.read(recordsBreedFilterProvider.notifier).state = 'ALL';
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (ctx) => SelectPetDialog(category: cat),
    );
  }

  void _openArchiveForCategory(
      BuildContext context, WidgetRef ref, RecordCategory cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ArchivePetPicker(category: cat),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: RecordsPalette.bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            // ── Header ──────────────────────────────────────────────────────
            const SliverToBoxAdapter(child: _RecordsHeader()),

            // ── 2-column category grid ───────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid.count(
                crossAxisCount:  2,
                mainAxisSpacing:  12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.93,
                children: kRecordCategories
                    .map((cat) => CategoryCard(
                          category: cat,
                          onTap: () => _openSelectPet(context, ref, cat),
                        ))
                    .toList(),
              ),
            ),

            // ── Archive section ──────────────────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            const SliverToBoxAdapter(child: _ArchiveSectionHeader()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final cat = kRecordCategories[index];
                    return _ArchiveCategoryRow(
                      category: cat,
                      onTap: () =>
                          _openArchiveForCategory(context, ref, cat),
                    );
                  },
                  childCount: kRecordCategories.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }
}

// ─── Page Header ──────────────────────────────────────────────────────────────
class _RecordsHeader extends StatelessWidget {
  const _RecordsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow
          Row(children: [
            Container(
              width: 20, height: 3,
              decoration: BoxDecoration(
                color: RecordsPalette.terra,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text('PET INFORMATION',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: RecordsPalette.terra,
                    letterSpacing: 2.0)),
          ]),
          const SizedBox(height: 8),
          const Text('Records',
              style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: RecordsPalette.ink,
                  letterSpacing: -0.8,
                  height: 1.1)),
          const SizedBox(height: 5),
          const Text("Tap a category to browse your pet's history",
              style: TextStyle(
                  fontSize: 13,
                  color: RecordsPalette.muted,
                  height: 1.4)),
          const SizedBox(height: 22),
          // Divider with paw
          Row(children: [
            Expanded(child: _FadeRule()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Icon(Icons.pets,
                  size: 12,
                  color: RecordsPalette.linenDeep),
            ),
            Expanded(child: _FadeRule()),
          ]),
        ],
      ),
    );
  }
}

class _FadeRule extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [
        RecordsPalette.linenDeep.withOpacity(0.0),
        RecordsPalette.linenDeep.withOpacity(0.6),
        RecordsPalette.linenDeep.withOpacity(0.0),
      ]),
    ),
  );
}

// ─── Archive Section Header ───────────────────────────────────────────────────
class _ArchiveSectionHeader extends StatelessWidget {
  const _ArchiveSectionHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Container(
          width: 20, height: 3,
          decoration: BoxDecoration(
            color: RecordsPalette.sage,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        const Text('RECORDS ARCHIVE',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: RecordsPalette.sage,
                letterSpacing: 2.0)),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                RecordsPalette.sage.withOpacity(0.25),
                RecordsPalette.sage.withOpacity(0.0),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Archive Category Row ─────────────────────────────────────────────────────
class _ArchiveCategoryRow extends StatelessWidget {
  final RecordCategory category;
  final VoidCallback onTap;
  const _ArchiveCategoryRow({required this.category, required this.onTap});

  // Per-category accent colors matching the quick-add modal
  static const _iconColors = {
    'Medication':    Color(0xFFBA7F57),
    'Vaccination':   Color(0xFF5A9E62),
    'Preventatives': Color(0xFF5C6BAD),
    'Vet Visit':     Color(0xFF45617D),
    'Grooming':      Color(0xFF8B6FAB),
    'Weight':        Color(0xFF7A8C6A),
  };

  static const _iconBgs = {
    'Medication':    Color(0xFFFFF4E8),
    'Vaccination':   Color(0xFFEDF4EB),
    'Preventatives': Color(0xFFEDF0FA),
    'Vet Visit':     Color(0xFFEAF2FB),
    'Grooming':      Color(0xFFF5EEF8),
    'Weight':        Color(0xFFF0F4F0),
  };

  @override
  Widget build(BuildContext context) {
    final iconColor = _iconColors[category.label] ?? RecordsPalette.steel;
    final iconBg    = _iconBgs[category.label]    ?? RecordsPalette.steelLite;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: RecordsPalette.linenDeep.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(
                color: RecordsPalette.ink.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(children: [
            // Icon
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(category.icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: RecordsPalette.ink)),
                  const SizedBox(height: 2),
                  Text('View archived records',
                      style: TextStyle(
                          fontSize: 11,
                          color: RecordsPalette.muted.withOpacity(0.8))),
                ],
              ),
            ),
            // Archive badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: RecordsPalette.sageLite,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.inventory_2_outlined,
                    size: 12, color: RecordsPalette.sage),
                const SizedBox(width: 4),
                Text('Archive',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: RecordsPalette.sage)),
              ]),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: RecordsPalette.linenDeep),
          ]),
        ),
      ),
    );
  }
}

// ─── Archive Pet Picker Sheet ─────────────────────────────────────────────────
class _ArchivePetPicker extends ConsumerWidget {
  final RecordCategory category;
  const _ArchivePetPicker({required this.category});

  static ArchivePageConfig? _archiveConfig(String label) {
    switch (label.toLowerCase()) {
      case 'medication':    return medicationArchiveConfig;
      case 'vaccination':   return vaccinationArchiveConfig;
      case 'preventatives': return preventativeArchiveConfig;
      case 'vet visit':     return vetVisitArchiveConfig;
      case 'grooming':      return groomingArchiveConfig;
      case 'weight':        return weightArchiveConfig;
      default:              return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config    = _archiveConfig(category.label);
    final petsAsync = ref.watch(activePetsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: RecordsPalette.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(child: Container(
            width: 38, height: 4,
            decoration: BoxDecoration(
              color: RecordsPalette.linenDeep,
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          const SizedBox(height: 20),

          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: category.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(category.icon, size: 18, color: RecordsPalette.steel),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ARCHIVED ${category.label.toUpperCase()}',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: RecordsPalette.terra,
                        letterSpacing: 1.5)),
                const Text('Select a pet to view its archive',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: RecordsPalette.ink)),
              ],
            ),
          ]),

          if (config == null) ...[
            const SizedBox(height: 24),
            Center(child: Text('Archive not available for ${category.label}.',
                style: const TextStyle(color: RecordsPalette.muted))),
          ] else ...[
            const SizedBox(height: 16),
            const Divider(color: RecordsPalette.linenDeep, height: 1),
            const SizedBox(height: 12),
            petsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (pets) {
                if (pets.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No active pets found.',
                        style: TextStyle(color: RecordsPalette.muted)),
                  ));
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final pet = pets[i];
                    return _PetArchiveTile(
                      pet: pet,
                      config: config,
                      onTap: () {
                        Navigator.pop(context);
                        final uid = ref.read(userIdProvider);
                        if (uid == null) return;
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ArchivedRecordsPage(
                            pet: pet, uid: uid, config: config),
                        ));
                      },
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Pet Archive Tile ─────────────────────────────────────────────────────────
class _PetArchiveTile extends StatelessWidget {
  final Pet pet;
  final ArchivePageConfig config;
  final VoidCallback onTap;
  const _PetArchiveTile(
      {required this.pet, required this.config, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: RecordsPalette.linenDeep.withOpacity(0.6)),
          boxShadow: [
            BoxShadow(
              color: RecordsPalette.ink.withOpacity(0.025),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(children: [
          // Avatar
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: RecordsPalette.steelLite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.pets,
                size: 20, color: RecordsPalette.steel),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pet.name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: RecordsPalette.ink)),
              const SizedBox(height: 1),
              Text(pet.breed,
                  style: const TextStyle(
                      fontSize: 11, color: RecordsPalette.muted)),
            ],
          )),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: RecordsPalette.sageLite,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chevron_right_rounded,
                size: 16, color: RecordsPalette.sage),
          ),
        ]),
      ),
    );
  }
}