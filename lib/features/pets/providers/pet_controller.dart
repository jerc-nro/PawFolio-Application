import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/pet_model.dart';
import '../../../services/notification_services.dart';
import 'pet_provider.dart';

// ── Loading state ─────────────────────────────────────────────────────────────
final petLoadingProvider =
    NotifierProvider.autoDispose<PetLoadingNotifier, bool>(
  () => PetLoadingNotifier(),
);

class PetLoadingNotifier extends AutoDisposeNotifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

// ── Pet Controller ────────────────────────────────────────────────────────────
final petControllerProvider =
    Provider.autoDispose((ref) => PetController(ref));

class PetController {
  final Ref ref;
  PetController(this.ref);

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    return user.uid;
  }

  // ── Save new pet ────────────────────────────────────────────────────────────
  Future<void> saveNewPet({
    required String type,
    required List<String> selectedBreeds,
    required String otherBreed,
    required String name,
    required String sex,
    required DateTime dob,
    required bool isSpayed,
    required double weight,
    required String unit,
    required String color,
    required String description,
    XFile? photo,
  }) async {
    ref.read(petLoadingProvider.notifier).set(true);
    try {
      final uid = _uid;
      String? base64;
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        base64 = base64Encode(bytes);
      }
      final breeds = [...selectedBreeds];
      if (otherBreed.isNotEmpty) breeds.add(otherBreed);

      final pet = Pet(
        petID: DateTime.now().millisecondsSinceEpoch.toString(),
        ownerID: uid,
        type: type,
        breed: breeds.join(', '),
        name: name,
        sex: sex,
        birthDate: dob.toIso8601String().split('T')[0],
        sterilization: isSpayed,
        weight: weight,
        weightUnit: unit,
        color: color,
        description: description,
        vaccinated: false,
        vaccineDetails: '',
        isArchived: false,
        isAlive: true,
        profileBase64: base64,
      );

      await ref.read(petServiceProvider).savePet(pet);

      // Schedule annual birthday notification for this pet
      await NotificationService.scheduleBirthday(pet);
    } finally {
      ref.read(petLoadingProvider.notifier).set(false);
    }
  }

  // ── Delete ──────────────────────────────────────────────────────────────────
  Future<void> deletePet(String petID) async {
    ref.read(petLoadingProvider.notifier).set(true);
    try {
      await ref.read(petServiceProvider).deletePet(_uid, petID);

      // Cancel birthday notification when pet is deleted
      final pet = Pet(
        petID: petID,
        ownerID: _uid,
        type: '', breed: '', name: '', sex: '',
        birthDate: '', sterilization: false,
        weight: 0, weightUnit: '', color: '',
        description: '', vaccinated: false,
        vaccineDetails: '', isArchived: false, isAlive: false,
      );
      await NotificationService.cancel(pet.birthdayNotifyId);

      ref.invalidate(activePetsProvider);
    } catch (e) {
      rethrow;
    } finally {
      ref.read(petLoadingProvider.notifier).set(false);
    }
  }

  // ── Archive / Restore ───────────────────────────────────────────────────────
  Future<void> setArchiveStatus(String petID, {required bool archive}) async {
    ref.read(petLoadingProvider.notifier).set(true);
    try {
      await ref.read(petServiceProvider).archivePet(
            _uid, petID,
            undo: !archive,
          );
      ref.invalidate(activePetsProvider);
    } finally {
      ref.read(petLoadingProvider.notifier).set(false);
    }
  }

  Future<void> archivePet(String petID) =>
      setArchiveStatus(petID, archive: true);

  Future<void> restorePet(String petID) =>
      setArchiveStatus(petID, archive: false);

  // ── Mark as Deceased ────────────────────────────────────────────────────────
  Future<void> markDeceased(String petID) async {
    ref.read(petLoadingProvider.notifier).set(true);
    try {
      await ref.read(petServiceProvider).markDeceased(_uid, petID);

      // Cancel birthday notification — no longer needed
      final pet = Pet(
        petID: petID,
        ownerID: _uid,
        type: '', breed: '', name: '', sex: '',
        birthDate: '', sterilization: false,
        weight: 0, weightUnit: '', color: '',
        description: '', vaccinated: false,
        vaccineDetails: '', isArchived: false, isAlive: false,
      );
      await NotificationService.cancel(pet.birthdayNotifyId);

      ref.invalidate(activePetsProvider);
    } finally {
      ref.read(petLoadingProvider.notifier).set(false);
    }
  }
}