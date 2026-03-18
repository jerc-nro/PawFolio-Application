import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet_model.dart';

class PetServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _petRef(String ownerID) {
    return _firestore.collection('users').doc(ownerID).collection('pets');
  }

  // --- CREATE / SAVE ---

  Future<void> savePet(Pet pet) async {
    await _petRef(pet.ownerID).doc(pet.petID).set(pet.toMap());
  }

  // --- UPDATES ---

  Future<void> updatePetImage(
      String ownerID, String petID, String base64Image) async {
    await _petRef(ownerID).doc(petID).update({'profileBase64': base64Image});
  }

  Future<void> updateLivingStatus(
      String ownerID, String petID, bool isAlive) async {
    await _petRef(ownerID).doc(petID).update({'isAlive': isAlive});
  }

  Future<void> archivePet(String ownerID, String petID,
      {bool undo = false}) async {
    await _petRef(ownerID).doc(petID).update({'isArchived': !undo});
  }

  /// Marks a pet as deceased.
  /// Sets isAlive = false AND isArchived = true in one atomic write.
  /// This ensures the pet moves to the archived list and cannot be restored.
  Future<void> markDeceased(String ownerID, String petID) async {
    await _petRef(ownerID).doc(petID).update({
      'isAlive': false,
      'isArchived': true,
    });
  }

  // --- REAL-TIME STREAMS ---

  Stream<List<Pet>> streamActivePets(String ownerID) {
    return _petRef(ownerID)
        .where('isArchived', isEqualTo: false)
        .where('isAlive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Pet.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<Pet>> streamArchivedPets(String ownerID) {
    return _petRef(ownerID)
        .where('isArchived', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Pet.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // --- DELETE ---

  Future<void> deletePet(String ownerID, String petID) async {
    await _petRef(ownerID).doc(petID).delete();
  }
}