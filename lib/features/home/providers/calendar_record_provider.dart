import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/record_model.dart';
import '../../pets/providers/pet_provider.dart';

const _kCollections = [
  'vet_visits', 'medications', 'vaccinations', 'preventatives', 'groom_visits',
];

/// Streams ALL records for the current user, keyed by normalised date (yyyy-MM-dd).
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
    // Merge all cache entries into date-keyed map
    final Map<String, List<PetRecord>> byDate = {};
    for (final records in cache.values) {
      for (final r in records) {
        final key = _normaliseDate(r.dateString);
        if (key != null) (byDate[key] ??= []).add(r);
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
        cache[key] = snap.docs.map((d) => PetRecord.fromDoc(d, col)).toList();
        emit();
      });
      subs.add(sub);
    }
  }

  controller.onCancel = () {
    for (final s in subs) {
      s.cancel();
    }
    controller.close();
  };

  return controller.stream;
});

/// Converts dd.MM.yyyy → yyyy-MM-dd. Returns null on parse failure.
String? _normaliseDate(String raw) {
  try {
    return DateFormat('yyyy-MM-dd').format(DateFormat('dd.MM.yyyy').parse(raw));
  } catch (_) {
    return null;
  }
}