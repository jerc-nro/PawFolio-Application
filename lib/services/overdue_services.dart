import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'notification_services.dart';

const _overdueCollections = [
  'vet_visits',
  'medications',
  'vaccinations',
  'preventatives',
  'groom_visits',
];

class OverdueService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> markOverdueRecords(String uid) async {
    try {
      final today    = DateTime.now();
      final todayDay = DateTime(today.year, today.month, today.day);

      final petsSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('pets')
          .where('isArchived', isEqualTo: false)
          .where('isAlive', isEqualTo: true)
          .get();

      final batch = _db.batch();
      bool hasBatchWrites = false;
      int overdueCount = 0;
      final List<String> petNames = [];

      for (final pet in petsSnap.docs) {
        final petData = pet.data();
        final petName = petData['name'] as String? ?? '';

        for (final col in _overdueCollections) {
          final snap = await _db
              .collection('users')
              .doc(uid)
              .collection('pets')
              .doc(pet.id)
              .collection(col)
              .where('status', isEqualTo: 'Upcoming')
              .get();

          for (final doc in snap.docs) {
            final ts = doc.data()['date_timestamp'];
            if (ts is! Timestamp) continue;

            final recordDay = DateTime(
              ts.toDate().year,
              ts.toDate().month,
              ts.toDate().day,
            );

            if (recordDay.isBefore(todayDay)) {
              batch.update(doc.reference, {'status': 'Overdue'});
              hasBatchWrites = true;
              overdueCount++;
              petNames.add(petName);
            }
          }
        }
      }

      if (hasBatchWrites) {
        await batch.commit();

        // Fire overdue notification if allowed
        final allowed = await NotificationService.isAllowed();
        if (allowed) {
          await NotificationService.showOverdueAlert(
            overdueCount: overdueCount,
            petNames: petNames,
          );
        }
      }
    } catch (e) {
      debugPrint('OverdueService error: $e');
    }
  }
}