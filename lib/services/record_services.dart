import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/groomvisit_model.dart';
import '../models/medication_model.dart';
import '../models/vaccination_model.dart';
import '../models/vetvisit_model.dart';


class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- GENERIC CRUD HELPERS ---
  
  CollectionReference _collection(String petId, String collectionName) {
    return _db.collection('pets').doc(petId).collection(collectionName);
  }

  // --- VACCINATIONS ---
  Stream<List<VaccinationRecord>> streamVaccinations(String petId) {
    return _collection(petId, 'vaccinations')
        .orderBy('givenDate', descending: true) // Added sorting
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => VaccinationRecord.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> addVaccination(String petId, VaccinationRecord record) =>
      _collection(petId, 'vaccinations').add(record.toMap());

  Future<void> deleteVaccination(String petId, String id) =>
      _collection(petId, 'vaccinations').doc(id).delete();

  // --- MEDICATIONS ---
  Stream<List<MedicationRecord>> streamMedications(String petId) {
    return _collection(petId, 'medications')
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MedicationRecord.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> addMedication(String petId, MedicationRecord record) =>
      _collection(petId, 'medications').add(record.toMap());

  Future<void> deleteMedication(String petId, String id) =>
      _collection(petId, 'medications').doc(id).delete();

  // --- VET VISITS ---
  Stream<List<VetVisitRecord>> streamVetVisits(String petId) {
    return _collection(petId, 'vet_visits')
        // Note: If 'date' is a String in your model, sorting might be alphabetical.
        // It is better to use DateTime/Timestamp for proper chronological sorting.
        .snapshots() 
        .map((snap) => snap.docs
            .map((doc) => VetVisitRecord.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> addVetVisit(String petId, VetVisitRecord record) =>
      _collection(petId, 'vet_visits').add(record.toMap());

  Future<void> deleteVetVisit(String petId, String id) =>
      _collection(petId, 'vet_visits').doc(id).delete();

  // --- GROOMING ---
  Stream<List<GroomVisitRecord>> streamGroomVisits(String petId) {
    return _collection(petId, 'groom_visits').snapshots().map((snap) =>
        snap.docs.map((doc) => GroomVisitRecord.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  Future<void> addGroomVisit(String petId, GroomVisitRecord record) =>
      _collection(petId, 'groom_visits').add(record.toMap());

  // FIXED: Changed .add() to .doc(id).delete()
  Future<void> deleteGroomVisit(String petId, String id) =>
      _collection(petId, 'groom_visits').doc(id).delete();
}