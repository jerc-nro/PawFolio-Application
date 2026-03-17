import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../pets/providers/pet_filter_provider.dart'; // Reuse the breed lists if possible

class RecordsFilterModal extends ConsumerWidget {
  const RecordsFilterModal({super.key});

  static const dogBreeds = [
    'Golden Retriever',
    'Bulldog',
    'Poodle',
    'Shih Tzu',
    'Beagle',
    'Labrador',
    'Pug'
  ];

  static const catBreeds = [
    'Persian',
    'Maine Coon',
    'Siamese',
    'Bengal',
    'Sphynx',
    'Ragdoll'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(recordsTypeFilterProvider);
    final breed = ref.watch(recordsBreedFilterProvider);
    final sex = ref.watch(recordsSexFilterProvider);
    final sterilized = ref.watch(recordsSterilizedFilterProvider);

    List<String> currentBreeds = type.toUpperCase() == 'DOG' ? dogBreeds : (type.toUpperCase() == 'CAT' ? catBreeds : []);

    return Padding(
      padding: EdgeInsets.only(
        left: 25, right: 25, top: 25,
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _modalHeader(ref),
          const Divider(),
          _filterLabel("ANIMAL TYPE"),
          Row(
            children: ["ALL", "DOG", "CAT"].map((t) => _choiceChip(
              label: t,
              selected: type.toUpperCase() == t,
              onSelected: (_) {
                ref.read(recordsTypeFilterProvider.notifier).state = t;
                ref.read(recordsBreedFilterProvider.notifier).state = 'ALL';
              },
            )).toList(),
          ),
          if (currentBreeds.isNotEmpty) ...[
            const SizedBox(height: 20),
            _filterLabel("SELECT BREED"),
            SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _choiceChip(label: "ALL", selected: breed == 'ALL', 
                    onSelected: (_) => ref.read(recordsBreedFilterProvider.notifier).state = 'ALL'),
                  ...currentBreeds.map((b) => _choiceChip(label: b, selected: breed == b, 
                    onSelected: (_) => ref.read(recordsBreedFilterProvider.notifier).state = b)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          _filterLabel("SEX"),
          Row(
            children: ["ALL", "MALE", "FEMALE"].map((s) => _choiceChip(
              label: s, selected: sex == s, 
              onSelected: (_) => ref.read(recordsSexFilterProvider.notifier).state = s
            )).toList(),
          ),
          const SizedBox(height: 20),
          _filterLabel("STERILIZATION"),
          Wrap(
            spacing: 8,
            children: [
              _choiceChip(label: "Any", selected: sterilized == null, onSelected: (_) => ref.read(recordsSterilizedFilterProvider.notifier).state = null),
              _choiceChip(label: "Yes", selected: sterilized == true, onSelected: (_) => ref.read(recordsSterilizedFilterProvider.notifier).state = true),
              _choiceChip(label: "No", selected: sterilized == false, onSelected: (_) => ref.read(recordsSterilizedFilterProvider.notifier).state = false),
            ],
          ),
          const SizedBox(height: 30),
          _applyButton(context),
        ],
      ),
    );
  }

  // --- Helper Widgets (Keep private to this file for now) ---
  Widget _modalHeader(WidgetRef ref) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text("Filter Options", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      TextButton(
        onPressed: () {
          ref.read(recordsTypeFilterProvider.notifier).state = 'ALL';
          ref.read(recordsBreedFilterProvider.notifier).state = 'ALL';
          ref.read(recordsSexFilterProvider.notifier).state = 'ALL';
          ref.read(recordsSterilizedFilterProvider.notifier).state = null;
        }, 
        child: const Text("Clear All", style: TextStyle(color: Colors.redAccent))
      ),
    ],
  );

  Widget _filterLabel(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8), 
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey, letterSpacing: 1))
  );

  Widget _choiceChip({required String label, required bool selected, required Function(bool) onSelected}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: const Color(0xFF4A6580),
        labelStyle: TextStyle(color: selected ? Colors.white : Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
        onSelected: onSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _applyButton(BuildContext context) => SizedBox(
    width: double.infinity, height: 50, 
    child: ElevatedButton(
      onPressed: () => Navigator.pop(context), 
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A6580), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), 
      child: const Text("APPLY FILTERS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
    )
  );
}