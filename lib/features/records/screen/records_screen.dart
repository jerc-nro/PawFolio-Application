import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/pets/providers/pet_filter_provider.dart';
import '../../../features/pets/providers/pet_provider.dart';
import '../../../models/pet_model.dart' show Pet;
import '../widgets/record_category.dart';
import '../theme/records_theme.dart';
import '../widgets/record_category_card.dart';
import '../widgets/select_pet_dialog.dart';

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
          Row(children: [
            Expanded(child: _FadeRule()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Icon(Icons.pets,
                  size: 12, color: RecordsPalette.linenDeep),
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