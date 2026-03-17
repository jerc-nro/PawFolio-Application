import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/pets/providers/pet_filter_provider.dart';
import '../widgets/record_category.dart';
import '../theme/records_theme.dart';
import '../widgets/record_category_card.dart';
import '../widgets/select_pet_dialog.dart';

/// Displays the health-journal landing page: a 2-column grid of record
/// categories. Tapping a card opens [SelectPetDialog] filtered to that category.
class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  void _openSelectPet(
    BuildContext context,
    WidgetRef ref,
    RecordCategory cat,
  ) {
    ref.read(recordsTypeFilterProvider.notifier).state  = cat.filterKey;
    ref.read(recordsBreedFilterProvider.notifier).state = 'ALL';

    showDialog(
      context:    context,
      useSafeArea: false,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child:  SelectPetDialog(category: cat),
      ),
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

            // ── Page header ──────────────────────────────────────────────────
            const SliverToBoxAdapter(child: _RecordsHeader()),

            // ── 2-column category grid ───────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid.count(
                crossAxisCount:  2,
                mainAxisSpacing:  14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.93,
                children: kRecordCategories
                    .map((cat) => CategoryCard(
                          category: cat,
                          onTap:    () => _openSelectPet(context, ref, cat),
                        ))
                    .toList(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }
}

// ─── Header widget ─────────────────────────────────────────────────────────────

class _RecordsHeader extends StatelessWidget {
  const _RecordsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow
          Row(
            children: [
              Container(
                width: 24, height: 3,
                decoration: BoxDecoration(
                  color:        RecordsPalette.terra,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'HEALTH JOURNAL',
                style: TextStyle(
                  fontSize:     11,
                  fontWeight:   FontWeight.w700,
                  color:        RecordsPalette.terra,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title
          const Text(
            'Records',
            style: TextStyle(
              fontSize:     36,
              fontWeight:   FontWeight.w800,
              color:        RecordsPalette.ink,
              letterSpacing: -0.8,
              height:       1.1,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          const Text(
            'Tap a category to browse your pet\'s history',
            style: TextStyle(
              fontSize: 14,
              color:    RecordsPalette.muted,
              height:   1.4,
            ),
          ),
          const SizedBox(height: 28),

          // Decorative paw-print divider
          Row(
            children: [
              Expanded(child: _FadeRule()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.pets, size: 13,
                    color: RecordsPalette.muted.withOpacity(0.35)),
              ),
              Expanded(child: _FadeRule()),
            ],
          ),
        ],
      ),
    );
  }
}

class _FadeRule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          RecordsPalette.muted.withOpacity(0.0),
          RecordsPalette.muted.withOpacity(0.22),
          RecordsPalette.muted.withOpacity(0.0),
        ]),
      ),
    );
  }
}