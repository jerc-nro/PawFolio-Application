import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet_model.dart';

class PetServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper to get the pet collection reference for a specific user
  CollectionReference _petRef(String ownerID) {
    return _firestore.collection('users').doc(ownerID).collection('pets');
  }

  // --- CREATE / SAVE ---
  
  /// Optimized: Accepts a Pet object to keep arguments clean
  Future<void> savePet(Pet pet) async {
    await _petRef(pet.ownerID).doc(pet.petID).set(pet.toMap());
  }

  // --- UPDATES ---

  Future<void> updatePetImage(String ownerID, String petID, String base64Image) async {
    await _petRef(ownerID).doc(petID).update({'profileBase64': base64Image});
  }

  Future<void> updateLivingStatus(String ownerID, String petID, bool isAlive) async {
    await _petRef(ownerID).doc(petID).update({'isAlive': isAlive});
  }

  /// Archive logic: "pet cannot be deleted, they are archived"
  /// Set undo to true to bring a pet back from archives
  Future<void> archivePet(String ownerID, String petID, {bool undo = false}) async {
    await _petRef(ownerID).doc(petID).update({'isArchived': !undo});
  }

  // --- REAL-TIME STREAMS ---
  
  /// Streams pets that are ALIVE and NOT ARCHIVED
  Stream<List<Pet>> streamActivePets(String ownerID) {
    return _petRef(ownerID)
        .where('isArchived', isEqualTo: false)
        .where('isAlive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Pet.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Streams pets that have been moved to the archive
  Stream<List<Pet>> streamArchivedPets(String ownerID) {
    return _petRef(ownerID)
        .where('isArchived', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Pet.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // --- DELETE PET ---

Future<void> deletePet(String ownerID, String petID) async {
  await _petRef(ownerID).doc(petID).delete();
}
}