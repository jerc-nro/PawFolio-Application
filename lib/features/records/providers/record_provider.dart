import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/record_model.dart';
import '../../../services/notification_services.dart';
import '../../../services/record_services.dart';
import '../../auth/providers/auth_provider.dart';

final recordControllerProvider =
    AsyncNotifierProvider.autoDispose<RecordController, void>(
  () => RecordController(),
);

class RecordController extends AutoDisposeAsyncNotifier<void> {
  late final RecordServices _service;

  @override
  Future<void> build() async {
    _service = RecordServices();
  }

  // ── Add record + schedule notification ────────────────────────────────────
  Future<void> addPetRecord(PetRecord record) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _service.addPetRecord(record);
      // Schedule reminder only for upcoming/active records
      if (record.status == 'Upcoming' || record.status == 'Ongoing') {
        await NotificationService.scheduleForRecord(record);
      }
    });
  }

  // ── Archive record + cancel notification ──────────────────────────────────
  Future<void> archiveRecord({
    required String petId,
    required String collection,
    required String recordId,
    PetRecord? record,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _service.archiveRecord(petId, collection, recordId);
      if (record != null) await NotificationService.cancelForRecord(record);
    });
  }

  // ── Update status + reschedule or cancel notification ─────────────────────
  Future<void> updateRecordStatus(PetRecord record, String newStatus) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _service.updateRecordStatus(record, newStatus);

      if (newStatus == 'Done' || newStatus == 'Overdue') {
        // No longer needs a reminder
        await NotificationService.cancelForRecord(record);
      } else if (newStatus == 'Upcoming' || newStatus == 'Ongoing') {
        // Reschedule in case it was previously cancelled
        await NotificationService.scheduleForRecord(record);
      }
    });
  }

  // ── Delete record + cancel notification ───────────────────────────────────
  Future<void> deleteRecord({
    required String petId,
    required String collection,
    required String recordId,
    PetRecord? record,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _service.deleteRecord(petId, collection, recordId);
      if (record != null) await NotificationService.cancelForRecord(record);
    });
  }

  // ── Weight records (no notifications needed) ──────────────────────────────

  Future<void> addWeightRecord({
    required String petId,
    required double weight,
    required String unit,
    required String dateString,
    required DateTime recordedDate,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uid = ref.read(authProvider).user?.userID;
      if (uid == null) throw Exception('User not authenticated');

      final petRef = FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('pets').doc(petId);

      final historyRef = petRef.collection('weight_history').doc();
      final batch = FirebaseFirestore.instance.batch();

      final normalizedDate = DateTime(
        recordedDate.year, recordedDate.month, recordedDate.day,
      );

      batch.set(historyRef, {
        'weight': weight,
        'unit': unit,
        'date_string': dateString,
        'recordedDate': Timestamp.fromDate(normalizedDate),
        'createdAt': FieldValue.serverTimestamp(),
        'is_archived': false,
      });

      final now = DateTime.now();
      final isToday = normalizedDate.year == now.year &&
          normalizedDate.month == now.month &&
          normalizedDate.day == now.day;

      if (isToday) {
        batch.update(petRef, {
          'weight': weight,
          'weightUnit': unit,
          'lastWeighedDate': dateString,
        });
      }

      await batch.commit();
    });
  }

  Future<void> archiveWeightRecord({
    required String petId,
    required String recordId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uid = ref.read(authProvider).user?.userID;
      if (uid == null) throw Exception('User not authenticated');

      await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('pets').doc(petId)
          .collection('weight_history').doc(recordId)
          .update({'is_archived': true});
    });
  }

  Future<void> deleteWeightRecord({
    required String petId,
    required String recordId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uid = ref.read(authProvider).user?.userID;
      if (uid == null) throw Exception('User not authenticated');

      final petRef = FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('pets').doc(petId);

      await petRef.collection('weight_history').doc(recordId).delete();

      final latest = await petRef
          .collection('weight_history')
          .where('is_archived', isEqualTo: false)
          .orderBy('recordedDate', descending: true)
          .limit(1)
          .get();

      if (latest.docs.isNotEmpty) {
        final d = latest.docs.first.data();
        await petRef.update({
          'weight': d['weight'] ?? 0.0,
          'weightUnit': d['unit'] ?? 'kg',
          'lastWeighedDate': d['date_string'] ?? '',
        });
      } else {
        await petRef.update({'weight': 0.0});
      }
    });
  }
}