import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pet_filter_provider.dart';

class PetFilterModal extends ConsumerWidget {
  const PetFilterModal({super.key});

  static const _dogBreeds = ['Golden Retriever','Bulldog','Poodle','Shih Tzu','Beagle','Labrador','Pug'];
  static const _catBreeds = ['Persian','Maine Coon','Siamese','Bengal','Sphynx','Ragdoll'];
  static const _dark = Color(0xFF2D3A4A);
  static const _sage = Color(0xFF8B947E);
  static const _bg   = Color(0xFFF5F2EE);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type       = ref.watch(petTypeFilterProvider);
    final breed      = ref.watch(petBreedFilterProvider);
    final sex        = ref.watch(petSexFilterProvider);
    final sterilized = ref.watch(petSterilizedFilterProvider);

    // Breeds scoped to selected type
    final breeds = type == 'DOG' ? _dogBreeds
        : type == 'CAT' ? _catBreeds
        : [..._dogBreeds, ..._catBreeds];

    // Count active filters for clear button label
    int active = 0;
    if (type != 'ALL') active++;
    if (breed != 'ALL') active++;
    if (sex != 'ALL') active++;
    if (sterilized != null) active++;

    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(child: Container(width: 38, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.black12,
                  borderRadius: BorderRadius.circular(2)))),

          // Header
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Filter Pets', style: TextStyle(fontSize: 17,
                fontWeight: FontWeight.w800, color: _dark)),
            if (active > 0)
              TextButton(
                onPressed: () {
                  ref.read(petTypeFilterProvider.notifier).state = 'ALL';
                  ref.read(petBreedFilterProvider.notifier).state = 'ALL';
                  ref.read(petSexFilterProvider.notifier).state = 'ALL';
                  ref.read(petSterilizedFilterProvider.notifier).state = null;
                },
                child: Text('Clear all ($active)',
                    style: const TextStyle(color: Color(0xFFCF6679),
                        fontWeight: FontWeight.w700)),
              )
            else
              const SizedBox(height: 36),
          ]),
          const SizedBox(height: 4),

          // ── Step 1: Pet Type ───────────────────────────
          _Step(
            number: '1', label: 'PET TYPE',
            isActive: true,
            child: _ChipRow(
              items: const ['ALL', 'DOG', 'CAT'],
              selected: type,
              onTap: (v) {
                ref.read(petTypeFilterProvider.notifier).state = v;
                // Reset downstream
                ref.read(petBreedFilterProvider.notifier).state = 'ALL';
                ref.read(petSexFilterProvider.notifier).state = 'ALL';
                ref.read(petSterilizedFilterProvider.notifier).state = null;
              },
            ),
          ),

          const _StepDivider(),

          // ── Step 2: Breed ──────────────────────────────
          _Step(
            number: '2', label: 'BREED',
            isActive: true,
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _Chip(label: 'All', selected: breed == 'ALL',
                      onTap: () => ref.read(petBreedFilterProvider.notifier).state = 'ALL'),
                  ...breeds.map((b) => _Chip(label: b, selected: breed == b,
                      onTap: () => ref.read(petBreedFilterProvider.notifier).state = b)),
                ],
              ),
            ),
          ),

          const _StepDivider(),

          // ── Step 3: Sex ────────────────────────────────
          _Step(
            number: '3', label: 'SEX',
            isActive: true,
            child: _ChipRow(
              items: const ['ALL', 'MALE', 'FEMALE'],
              selected: sex,
              onTap: (v) => ref.read(petSexFilterProvider.notifier).state = v,
            ),
          ),

          const _StepDivider(),

          // ── Step 4: Sterilization ──────────────────────
          _Step(
            number: '4', label: 'STERILIZATION',
            isActive: true,
            child: Row(children: [
              _Chip(label: 'Any',  selected: sterilized == null,
                  onTap: () => ref.read(petSterilizedFilterProvider.notifier).state = null),
              _Chip(label: 'Yes',  selected: sterilized == true,
                  onTap: () => ref.read(petSterilizedFilterProvider.notifier).state = true),
              _Chip(label: 'No',   selected: sterilized == false,
                  onTap: () => ref.read(petSterilizedFilterProvider.notifier).state = false),
            ]),
          ),

          const SizedBox(height: 24),

          // Apply
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _dark, elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                active > 0 ? 'Apply Filters ($active active)' : 'Apply Filters',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step container ────────────────────────────────────────────────────────────
class _Step extends StatelessWidget {
  final String number, label;
  final bool isActive;
  final Widget child;
  const _Step({required this.number, required this.label,
      required this.isActive, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step number bubble
        Container(
          width: 22, height: 22,
          alignment: Alignment.center,
          margin: const EdgeInsets.only(top: 2, right: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2D3A4A) : Colors.black12,
            shape: BoxShape.circle,
          ),
          child: Text(number, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800,
              color: isActive ? Colors.white : Colors.black38)),
        ),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10,
                fontWeight: FontWeight.w700, color: Color(0xFF8B947E),
                letterSpacing: 1.1)),
            const SizedBox(height: 8),
            child,
          ],
        )),
      ],
    ),
  );
}

class _StepDivider extends StatelessWidget {
  const _StepDivider();
  @override
  Widget build(BuildContext context) => Row(children: [
    const SizedBox(width: 11),
    Container(width: 1, height: 12, color: Colors.black12),
  ]);
}

// ── Chip row helper ───────────────────────────────────────────────────────────
class _ChipRow extends StatelessWidget {
  final List<String> items;
  final String selected;
  final ValueChanged<String> onTap;
  const _ChipRow({required this.items, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8, runSpacing: 6,
    children: items.map((i) => _Chip(
      label: i, selected: selected == i, onTap: () => onTap(i))).toList(),
  );
}

// ── Single chip ───────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF2D3A4A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? Colors.transparent : Colors.black12),
        boxShadow: selected ? [BoxShadow(
            color: const Color(0xFF2D3A4A).withOpacity(0.2),
            blurRadius: 6, offset: const Offset(0, 2))] : [],
      ),
      child: Text(label, style: TextStyle(fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : Colors.black54)),
    ),
  );
}