import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_services.dart';
import 'record_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser?.uid ?? '';

  // --- MASTER ADD RECORD FUNCTION ---
  Future<void> addPetRecord(PetRecord record) async {
    if (uid.isEmpty) return;

    // 1. Save to Firestore
    DocumentReference docRef = await _db
        .collection('users').doc(uid)
        .collection('pets').doc(record.petID)
        .collection(record.collection)
        .add({
          ...record.extra,
          'petID': record.petID,
          'petName': record.petName,
          'category': record.category,
          'status': record.status,
          'date_string': record.dateString,
          'date_timestamp': record.dateTimestamp != null 
              ? Timestamp.fromDate(record.dateTimestamp!) 
              : FieldValue.serverTimestamp(),
        });

    // 2. Create a local instance with the generated ID for notifications
    final finalRecord = PetRecord.fromDoc(await docRef.get(), record.collection);

    // 3. Logic: Schedule Upcoming Reminder
    if (finalRecord.status.toLowerCase() == 'upcoming' && finalRecord.reminderDate != null) {
      await NotificationService.schedule(
        id: finalRecord.notificationId,
        title: "Upcoming ${finalRecord.category}",
        body: "${finalRecord.petName} has ${finalRecord.title} scheduled.",
        scheduledDate: finalRecord.reminderDate!,
      );
    }

    // 4. Logic: Schedule Medication End Date Reminder
    if (finalRecord.category == 'Medication' && finalRecord.medicationEndDate != null) {
      await NotificationService.schedule(
        id: finalRecord.notificationId + 1, // Offset ID
        title: "Course Completed",
        body: "${finalRecord.petName} finished their ${finalRecord.title}!",
        scheduledDate: finalRecord.medicationEndDate!,
      );
    }
  }

  // --- MASTER DELETE RECORD FUNCTION ---
  Future<void> deleteRecord(String petId, String collection, String recordId) async {
    // Cancel any scheduled notifications
    int notifyId = recordId.hashCode.abs();
    await NotificationService.cancel(notifyId);
    await NotificationService.cancel(notifyId + 1);

    // Delete from Firestore
    await _db
        .collection('users').doc(uid)
        .collection('pets').doc(petId)
        .collection(collection)
        .doc(recordId)
        .delete();
  }
}