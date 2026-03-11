import 'package:flutter/material.dart';
import '../models/pet_model.dart';
import '../services/pet_services.dart';

class PetProvider extends ChangeNotifier {
  final PetServices _petServices = PetServices();

  List<Pet> _pets = [];
  bool _isLoading = false;

  List<Pet> get pets => _pets;
  bool get isLoading => _isLoading;

  /// NEW: Optimized Save Wrapper
  /// Moves formatting logic out of the UI to save memory and clean up AddPetPage.
  Future<void> saveNewPet({
    required String uid,
    required String type,
    required String breed,
    required String name,
    required String sex,
    required DateTime dob,
    required bool isSpayed,
    required double weight,
    required String unit,
    required String color,
    String description = '',
  }) async {
    // 1. Format date once here instead of inside the UI state
    final dateStr = "${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}";
    
    // 2. Pass to existing addPet logic
    await addPet(
      petID: DateTime.now().millisecondsSinceEpoch.toString(),
      ownerID: uid,
      type: type,
      breed: breed,
      name: name,
      sex: sex,
      birthDate: dateStr,
      sterilization: isSpayed,
      weight: weight,
      weightUnit: unit,
      color: color,
      vaccinated: false, // Default for new profile
      vaccineDetails: description, // Re-using this for description/details
    );
  }

  // --- EXISTING LOGIC ---

  Future<void> fetchPets(String ownerID) async {
    _isLoading = true;
    notifyListeners();
    try {
      _pets = await _petServices.loadPets(ownerID);
    } catch (e) {
      debugPrint("fetchPets error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPet({
    required String petID, required String ownerID, required String type,
    required String breed, required String name, required String sex,
    required String birthDate, required bool sterilization, required double weight,
    required String weightUnit, required String color, required bool vaccinated,
    required String vaccineDetails,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _petServices.savePet(
        petID: petID, ownerID: ownerID, type: type, breed: breed,
        name: name, sex: sex, birthDate: birthDate,
        sterilization: sterilization, weight: weight,
        weightUnit: weightUnit, color: color,
        vaccinated: vaccinated, vaccineDetails: vaccineDetails,
      );
      await fetchPets(ownerID);
    } catch (e) {
      debugPrint("addPet error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePet(String petID, String ownerID) async {
    try {
      await _petServices.removePet(petID);
      _pets.removeWhere((pet) => pet.petID == petID);
      notifyListeners();
    } catch (e) {
      debugPrint("deletePet error: $e");
      rethrow;
    }
  }

  List<Pet> getFilteredPets(String query, String category) {
    return _pets.where((p) {
      final matchesCategory = category == 'ALL' || p.type.toUpperCase() == category;
      final matchesSearch = p.name.toLowerCase().contains(query.toLowerCase()) || 
                            p.type.toLowerCase().contains(query.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }
}