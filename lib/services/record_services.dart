import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/record_model.dart';
import '../models/pet_model.dart';
import 'notification_services.dart';

class RecordServices {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser?.uid ?? '';

  // ─── Path helpers ─────────────────────────────────────────────────────────
  CollectionReference get _petsCollection {
    if (uid.isEmpty) throw Exception("User not authenticated");
    return _db.collection('users').doc(uid).collection('pets');
  }

  CollectionReference _collection(String petId, String collectionName) {
    if (uid.isEmpty) throw Exception("User not authenticated");
    return _petsCollection.doc(petId).collection(collectionName);
  }

  // ─── Pet management ───────────────────────────────────────────────────────
  Future<void> addPet(Pet pet) async {
    await _petsCollection.add(pet.toMap());
    // Birthday notification is now handled in PetController.saveNewPet
    // via NotificationService.scheduleBirthday(pet)
  }

  Future<void> deletePet(String petId) async {
    await NotificationService.cancel(petId.hashCode.abs());
    await _petsCollection.doc(petId).delete();
  }

  // ─── Record management ────────────────────────────────────────────────────
  Future<void> addPetRecord(PetRecord record) async {
    final docRef = await _collection(record.petID, record.collection).add({
      ...record.extra,
      'petID': record.petID,
      'petName': record.petName,
      'petType': record.petType,
      'category': record.category,
      'status': record.status,
      'date_string': record.dateString,
      'date_timestamp': record.dateTimestamp != null
          ? Timestamp.fromDate(record.dateTimestamp!)
          : FieldValue.serverTimestamp(),
    });

    final savedDoc = await docRef.get();
    final finalRecord = PetRecord.fromDoc(savedDoc, record.collection);

    // Schedule via the new service — handles all categories + medication end date
    if (finalRecord.status == 'Upcoming' || finalRecord.status == 'Ongoing') {
      await NotificationService.scheduleForRecord(finalRecord);
    }
  }

  Future<void> updateRecordStatus(PetRecord record, String newStatus) async {
    await _collection(record.petID, record.collection)
        .doc(record.id)
        .update({'status': newStatus});

    if (newStatus == 'Done' || newStatus == 'Overdue') {
      await NotificationService.cancelForRecord(record);
    } else if (newStatus == 'Upcoming' || newStatus == 'Ongoing') {
      await NotificationService.scheduleForRecord(record);
    }
  }

  Future<void> deleteRecord(
      String petId, String collection, String recordId) async {
    // Cancel both the reminder and potential medication end notification
    await NotificationService.cancel(recordId.hashCode.abs());
    await NotificationService.cancel(recordId.hashCode.abs() + 1);
    await _collection(petId, collection).doc(recordId).delete();
  }

  Future<void> archiveRecord(
      String petId, String collection, String recordId) async {
    await _collection(petId, collection).doc(recordId).update({
      'is_archived': true,
      'archived_at': FieldValue.serverTimestamp(),
    });
  }

  // ─── Streams ──────────────────────────────────────────────────────────────
  Stream<List<PetRecord>> streamPetRecords(
      String petId, String collectionName) {
    return _collection(petId, collectionName)
        .orderBy('date_timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((doc) => PetRecord.fromDoc(doc, collectionName))
            .toList());
  }

  Stream<List<Pet>> streamPets() {
    return _petsCollection.snapshots().map((s) => s.docs
        .map((doc) =>
            Pet.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // ─── Weight logic ─────────────────────────────────────────────────────────
  Future<void> addWeightEntry(String petId, double weight, String unit,
      String dateString, String notes) async {
    final recordedDate =
        DateTime.tryParse(dateString.split('.').reversed.join('-')) ??
            DateTime.now();
    final petRef =
        _db.collection('users').doc(uid).collection('pets').doc(petId);

    await petRef.collection('weight_history').add({
      'petID': petId,
      'weight': weight,
      'unit': unit,
      'recordedDate': recordedDate,
      'date_string': dateString,
      'notes': notes,
      'date_timestamp': FieldValue.serverTimestamp(),
      'category': 'Weight',
    });

    await petRef.update({
      'weight': weight,
      'weightUnit': unit,
      'lastWeighedDate': dateString,
    });
  }

  Future<void> deleteWeightEntry(String petId, String recordId) async {
    final petRef =
        _db.collection('users').doc(uid).collection('pets').doc(petId);
    await petRef.collection('weight_history').doc(recordId).delete();

    final remaining = await petRef
        .collection('weight_history')
        .orderBy('recordedDate', descending: true)
        .limit(1)
        .get();

    if (remaining.docs.isNotEmpty) {
      final latest = remaining.docs.first.data();
      await petRef.update({
        'weight': latest['weight'],
        'weightUnit': latest['unit'] ?? 'kg',
        'lastWeighedDate': latest['date_string'] ?? '',
      });
    }
  }

  Future<void> editWeightEntry({
    required String petId,
    required String recordId,
    required double weight,
    required String unit,
    required String dateString,
    required String notes,
  }) async {
    final recordedDate =
        DateTime.tryParse(dateString.split('.').reversed.join('-')) ??
            DateTime.now();
    final petRef =
        _db.collection('users').doc(uid).collection('pets').doc(petId);

    await petRef.collection('weight_history').doc(recordId).update({
      'weight': weight,
      'unit': unit,
      'recordedDate': recordedDate,
      'date_string': dateString,
      'notes': notes,
    });

    final latest = await petRef
        .collection('weight_history')
        .orderBy('recordedDate', descending: true)
        .limit(1)
        .get();

    if (latest.docs.isNotEmpty && latest.docs.first.id == recordId) {
      await petRef.update({
        'weight': weight,
        'weightUnit': unit,
        'lastWeighedDate': dateString,
      });
    }
  }
}