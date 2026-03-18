import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/record_model.dart';
import '../../pets/providers/pet_provider.dart';

const _kCollections = [
  'vet_visits', 'medications', 'vaccinations', 'preventatives', 'groom_visits',
];

final calendarRecordsProvider =
    StreamProvider.autoDispose<Map<String, List<PetRecord>>>((ref) {
  final uid = ref.watch(userIdProvider);
  if (uid == null) return Stream.value({});

  final pets = ref.watch(activePetsProvider).valueOrNull ?? [];
  if (pets.isEmpty) return Stream.value({});

  final db = FirebaseFirestore.instance;
  final controller = StreamController<Map<String, List<PetRecord>>>();
  final Map<String, List<PetRecord>> cache = {};
  final List<StreamSubscription> subs = [];

  void emit() {
    if (controller.isClosed) return;
    final Map<String, List<PetRecord>> byDate = {};

    for (final records in cache.values) {
      for (final r in records) {
        // Primary date
        final key = _normaliseDate(r.dateString);
        if (key != null) (byDate[key] ??= []).add(r);

        // For medications: fill every day in the range with the same record
        // so the calendar shows a span instead of a single dot.
        if (r.category == 'Medication' &&
            r.dateTimestamp != null &&
            r.medicationEndDate != null) {
          final start = r.dateTimestamp!;
          final end   = r.medicationEndDate!;
          DateTime cursor = start.add(const Duration(days: 1));
          while (!cursor.isAfter(end)) {
            final spanKey = DateFormat('yyyy-MM-dd').format(cursor);
            // Only add if not already keyed to avoid duplicate primary entry
            final list = byDate[spanKey] ??= [];
            if (!list.contains(r)) list.add(r);
            cursor = cursor.add(const Duration(days: 1));
          }
        }
      }
    }
    controller.add(byDate);
  }

  for (final pet in pets) {
    for (final col in _kCollections) {
      final key = '${pet.petID}_$col';
      cache[key] = [];
      final sub = db
          .collection('users')
          .doc(uid)
          .collection('pets')
          .doc(pet.petID)
          .collection(col)
          .snapshots()
          .listen((snap) {
        cache[key] =
            snap.docs.map((d) => PetRecord.fromDoc(d, col)).toList();
        emit();
      });
      subs.add(sub);
    }
  }

  controller.onCancel = () {
    for (final s in subs) s.cancel();
    controller.close();
  };

  return controller.stream;
});

String? _normaliseDate(String raw) {
  try {
    return DateFormat('yyyy-MM-dd')
        .format(DateFormat('dd.MM.yyyy').parse(raw));
  } catch (_) {
    return null;
  }
}