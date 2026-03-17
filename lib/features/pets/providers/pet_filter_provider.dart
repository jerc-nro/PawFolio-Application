import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/pet_model.dart';
import 'pet_provider.dart'; // activePetsProvider

// ===============================
// PET FILTERING PROVIDERS & LOGIC
// ===============================

// Generic Notifier for String filters
class FilterNotifier extends Notifier<String> {
  @override
  String build() => "ALL";
  void set(String val) => state = val;
}

// Specific Notifier for Nullable Boolean (Sterilization)
class SterilizedNotifier extends Notifier<bool?> {
  @override
  bool? build() => null;
  void set(bool? val) => state = val;
}

class SearchNotifier extends Notifier<String> {
  @override
  String build() => "";
  void set(String val) => state = val;
}

// PET FILTER PROVIDERS
final petSearchQueryProvider = NotifierProvider<SearchNotifier, String>(SearchNotifier.new);
final petTypeFilterProvider = NotifierProvider<FilterNotifier, String>(FilterNotifier.new);
final petBreedFilterProvider = NotifierProvider<FilterNotifier, String>(FilterNotifier.new);
final petSexFilterProvider = NotifierProvider<FilterNotifier, String>(FilterNotifier.new);
// CHANGED: Now uses bool? to match UI logic
final petSterilizedFilterProvider = NotifierProvider<SterilizedNotifier, bool?>(SterilizedNotifier.new);

// FILTERED ACTIVE PETS
final filteredActivePetsProvider = Provider<AsyncValue<List<Pet>>>((ref) {
  final petsAsync = ref.watch(activePetsProvider);
  final query = ref.watch(petSearchQueryProvider).toLowerCase().trim();
  final type = ref.watch(petTypeFilterProvider);
  final breed = ref.watch(petBreedFilterProvider);
  final sex = ref.watch(petSexFilterProvider);
  final sterilized = ref.watch(petSterilizedFilterProvider);

  return petsAsync.whenData((pets) {
    return pets.where((pet) {
      // Search filter
      if (query.isNotEmpty &&
          !pet.name.toLowerCase().contains(query) &&
          !pet.breed.toLowerCase().contains(query)) {
        return false;
      }

      // Type filter
      if (type != 'ALL' && pet.type.toUpperCase() != type.toUpperCase()) {
        return false;
      }

      // Breed filter
      if (breed != 'ALL' && pet.breed.toUpperCase() != breed.toUpperCase()) {
        return false;
      }

      // Sex filter
      if (sex != 'ALL' && pet.sex.toUpperCase() != sex.toUpperCase()) {
        return false;
      }

      // Sterilization filter
      if (sterilized != null && pet.sterilization != sterilized) {
        return false;
      }

      return true;
    }).toList();
  });
});

// ===============================
// RECORDS FILTERING PROVIDERS & LOGIC
// ===============================
// Ensure this is in your providers file
final filteredRecordsProvider = Provider<AsyncValue<List<Pet>>>((ref) {
  final petsAsync = ref.watch(activePetsProvider);
  final search = ref.watch(recordsSearchQueryProvider).toLowerCase().trim();
  final type = ref.watch(recordsTypeFilterProvider); // <--- Crucial

  return petsAsync.whenData((pets) {
    return pets.where((pet) {
      if (search.isNotEmpty && !pet.name.toLowerCase().contains(search)) return false;
      if (type != 'ALL' && pet.type.toUpperCase() != type.toUpperCase()) return false;
      return true;
    }).toList();
  });
});

final recordsSearchQueryProvider = StateProvider<String>((ref) => '');
final recordsTypeFilterProvider = StateProvider<String>((ref) => 'ALL');
final recordsBreedFilterProvider = StateProvider<String>((ref) => 'ALL');
final recordsSexFilterProvider = StateProvider<String>((ref) => 'ALL');
final recordsSterilizedFilterProvider = StateProvider<bool?>((ref) => null);
