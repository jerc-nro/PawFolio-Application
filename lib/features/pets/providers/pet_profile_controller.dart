// lib/features/pets/providers/pet_profile_controller.dart

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/pet_model.dart';
import '../../../services/pet_services.dart';

// ── State ────────────────────────────────────────────────────────────────────
class PetProfileState {
  final Pet pet;
  final bool editMode;
  final bool saving;

  const PetProfileState({
    required this.pet,
    this.editMode = false,
    this.saving   = false,
  });

  PetProfileState copyWith({Pet? pet, bool? editMode, bool? saving}) =>
      PetProfileState(
        pet:      pet      ?? this.pet,
        editMode: editMode ?? this.editMode,
        saving:   saving   ?? this.saving,
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────────
class PetProfileNotifier extends StateNotifier<PetProfileState> {
  PetProfileNotifier(Pet pet) : super(PetProfileState(pet: pet));

  void enterEditMode()  => state = state.copyWith(editMode: true);
  void cancelEditMode() => state = state.copyWith(editMode: false);

  Future<void> saveFields(Map<String, dynamic> fields) async {
    state = state.copyWith(saving: true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(state.pet.ownerID)
          .collection('pets')
          .doc(state.pet.petID)
          .update(fields);

      state = state.copyWith(
        editMode: false,
        saving: false,
        pet: state.pet.copyWith(
          name          : fields['name']           as String?,
          breed         : fields['breed']          as String?,
          color         : fields['color']          as String?,
          weight        : fields['weight']         as double?,
          weightUnit    : fields['weightUnit']     as String?,
          description   : fields['description']   as String?,
          sex           : fields['sex']            as String?,
          sterilization : fields['sterilization'] as bool?,
          vaccinated    : fields['vaccinated']    as bool?,
          vaccineDetails: fields['vaccineDetails'] as String?,
          birthDate     : fields['birthDate']      as String?,
        ),
      );
    } catch (_) {
      state = state.copyWith(saving: false);
      rethrow;
    }
  }

  Future<void> pickAndSavePhoto() async {
    final file = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;
    final base64 = base64Encode(await file.readAsBytes());
    await PetServices()
        .updatePetImage(state.pet.ownerID, state.pet.petID, base64);
    state = state.copyWith(
        pet: state.pet.copyWith(profileBase64: () => base64));
  }
}

// ── Provider factory ─────────────────────────────────────────────────────────
final petProfileProvider = StateNotifierProvider.family
    .autoDispose<PetProfileNotifier, PetProfileState, Pet>(
  (ref, pet) => PetProfileNotifier(pet),
);