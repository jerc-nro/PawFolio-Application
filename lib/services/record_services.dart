import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Added for birthday repeat logic
import '../models/record_model.dart';
import '../models/pet_model.dart'; // Ensure your Pet model is imported
import '../services/notification_services.dart';

class RecordServices {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper to get current User ID safely
  String get uid => _auth.currentUser?.uid ?? '';

  // --- PATH HELPERS ---
  
  // users/{uid}/pets/
  CollectionReference get _petsCollection {
    if (uid.isEmpty) throw Exception("User not authenticated");
    return _db.collection('users').doc(uid).collection('pets');
  }

  // users/{uid}/pets/{petId}/{collectionName}
  CollectionReference _collection(String petId, String collectionName) {
    if (uid.isEmpty) throw Exception("User not authenticated");
    return _petsCollection.doc(petId).collection(collectionName);
  }

  // --- 1. PET MANAGEMENT (With Yearly Birthdays) ---

  Future<void> addPet(Pet pet) async {
    // 1. Save to Firestore
    DocumentReference docRef = await _petsCollection.add(pet.toMap());

    // 2. Schedule Yearly Birthday Notification
    final dob = DateTime.tryParse(pet.birthDate);
    if (dob != null) {
      // Set to 9:00 AM on the day of the birthday
      final scheduledDate = DateTime(dob.year, dob.month, dob.day, 9, 0);
      
      await NotificationService.schedule(
        id: docRef.id.hashCode.abs(),
        title: "Happy Birthday, ${pet.name}! 🎂",
        body: "Wish your ${pet.breed} a very special day!",
        scheduledDate: scheduledDate,
        // This ensures the notification repeats every year
        matchComponents: DateTimeComponents.dateAndTime, 
      );
    }
  }

  Future<void> deletePet(String petId) async {
    // 1. Cancel Birthday Notification
    await NotificationService.cancel(petId.hashCode.abs());

    // 2. Delete the pet document
    await _petsCollection.doc(petId).delete();
  }

  // --- 2. RECORD MANAGEMENT (With Auto-Notifications) ---

  Future<void> addPetRecord(PetRecord record) async {
    // 1. Save to Firestore
    DocumentReference docRef = await _collection(record.petID, record.collection).add({
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

    // 2. Fetch the saved data to create final record with real ID
    final savedDoc = await docRef.get();
    final finalRecord = PetRecord.fromDoc(savedDoc, record.collection);

    // 3. Schedule "Upcoming" Notification (e.g., 24 hours before)
    if (finalRecord.status.toLowerCase() == 'upcoming' && finalRecord.reminderDate != null) {
      await NotificationService.schedule(
        id: finalRecord.notificationId,
        title: "Upcoming ${finalRecord.category}",
        body: "${finalRecord.petName} has ${finalRecord.title} tomorrow.",
        scheduledDate: finalRecord.reminderDate!,
      );
    }

    // 4. Schedule "Medication End" Notification
    if (finalRecord.category == 'Medication' && finalRecord.medicationEndDate != null) {
      await NotificationService.schedule(
        id: finalRecord.notificationId + 1,
        title: "Medication Course Finished",
        body: "${finalRecord.petName} completed their ${finalRecord.title}!",
        scheduledDate: finalRecord.medicationEndDate!,
      );
    }
  }

  Future<void> updateRecordStatus(PetRecord record, String newStatus) async {
    await _collection(record.petID, record.collection).doc(record.id).update({
      'status': newStatus,
    });

    if (newStatus.toLowerCase() != 'upcoming') {
      await NotificationService.cancel(record.notificationId);
      if (record.category == 'Medication') {
        await NotificationService.cancel(record.notificationId + 1);
      }
    }
  }

  Future<void> deleteRecord(String petId, String collection, String recordId) async {
    int notifyId = recordId.hashCode.abs();
    await NotificationService.cancel(notifyId);
    await NotificationService.cancel(notifyId + 1);

    await _collection(petId, collection).doc(recordId).delete();
  }

  // --- 3. STREAMS ---

  Stream<List<PetRecord>> streamPetRecords(String petId, String collectionName) {
    return _collection(petId, collectionName)
        .orderBy('date_timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PetRecord.fromDoc(doc, collectionName))
            .toList());
  }

  Future<void> archiveRecord(String petId, String collection, String recordId) async {
  await _collection(petId, collection).doc(recordId).update({'status': 'ARCHIVED'});
}

  Stream<List<Pet>> streamPets() {
    return _petsCollection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Pet.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // ─── WEIGHT LOGIC ───

  Future<void> addWeightEntry(String petId, double weight, String unit, String dateString, String notes) async {
    DateTime recordedDate = DateTime.tryParse(dateString.split('.').reversed.join('-')) ?? DateTime.now();
    
    final petRef = _db.collection('users').doc(uid).collection('pets').doc(petId);

    // 1. Historical log
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

    // 2. Update Pet Document
    await petRef.update({
      'weight': weight,
      'weightUnit': unit,
      'lastWeighedDate': dateString,
    });
  }

  Future<void> deleteWeightEntry(String petId, String recordId) async {
    final petRef = _db.collection('users').doc(uid).collection('pets').doc(petId);

    // 1. Delete the entry
    await petRef.collection('weight_history').doc(recordId).delete();

    // 2. Smart Restore Logic
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
    DateTime recordedDate = DateTime.tryParse(dateString.split('.').reversed.join('-')) ?? DateTime.now();
    
    final petRef = _db.collection('users').doc(uid).collection('pets').doc(petId);

    // 1. Update the history entry
    await petRef.collection('weight_history').doc(recordId).update({
      'weight': weight,
      'unit': unit,
      'recordedDate': recordedDate,
      'date_string': dateString,
      'notes': notes,
    });

    // 2. Check if this is the latest entry; if so, update pet doc
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