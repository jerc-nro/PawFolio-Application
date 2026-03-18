import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_services.dart';
import 'record_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser?.uid ?? '';

  // ─── Add record ───────────────────────────────────────────────────────────
  Future<void> addPetRecord(PetRecord record) async {
    if (uid.isEmpty) return;

    final docRef = await _db
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

    final finalRecord =
        PetRecord.fromDoc(await docRef.get(), record.collection);

    // Schedule via the new service — handles all categories + medication end date
    if (finalRecord.status == 'Upcoming' || finalRecord.status == 'Ongoing') {
      await NotificationService.scheduleForRecord(finalRecord);
    }
  }

  // ─── Delete record ────────────────────────────────────────────────────────
  Future<void> deleteRecord(
      String petId, String collection, String recordId) async {
    await NotificationService.cancel(recordId.hashCode.abs());
    await NotificationService.cancel(recordId.hashCode.abs() + 1);

    await _db
        .collection('users').doc(uid)
        .collection('pets').doc(petId)
        .collection(collection)
        .doc(recordId)
        .delete();
  }
}