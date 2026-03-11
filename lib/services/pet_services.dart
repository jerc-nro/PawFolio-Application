import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet_model.dart';

class PetServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Pet> savePet({
    required String petID,
    required String ownerID,
    required String type,
    required String breed,
    required String name,
    required String sex,
    required String birthDate,
    required bool sterilization,
    required double weight,
    required String weightUnit,
    required String color,
    required bool vaccinated,
    required String vaccineDetails,
  }) async {
    final pet = Pet(
      petID: petID,
      ownerID: ownerID,
      type: type,
      name: name,
      breed: breed,
      sex: sex,
      birthDate: birthDate,
      sterilization: sterilization,
      weight: weight,
      weightUnit: weightUnit,
      color: color,
      vaccinated: vaccinated,
      vaccineDetails: vaccineDetails,
    );

    await _firestore.collection('pets').doc(petID).set(pet.toMap());
    return pet;
  }

  Future<List<Pet>> loadPets(String ownerID) async {
    final querySnapshot = await _firestore
        .collection('pets')
        .where('ownerID', isEqualTo: ownerID)
        .get();

    return querySnapshot.docs
        .map((doc) => Pet.fromMap(doc.data()))
        .toList();
  }

  Stream<List<Pet>> streamPets(String ownerID) {
    return _firestore
        .collection('pets')
        .where('ownerID', isEqualTo: ownerID)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Pet.fromMap(doc.data()))
            .toList());
  }

  Future<void> removePet(String petID) async {
    await _firestore.collection('pets').doc(petID).delete();
  }
}