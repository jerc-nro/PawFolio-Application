import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/record_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pets/providers/pet_provider.dart';

const _collections = [
  'vet_visits',
  'medications',
  'vaccinations',
  'preventatives',
  'groom_visits',
];

/// Streams the [limit] most recent records across all active pets & subcollections.
final recentRecordsProvider =
    StreamProvider.autoDispose.family<List<PetRecord>, int>((ref, limit) {
  final uid = ref.watch(userIdProvider);
  if (uid == null) return Stream.value([]);

  final pets = ref.watch(activePetsProvider).valueOrNull ?? [];
  if (pets.isEmpty) return Stream.value([]);

  final db = FirebaseFirestore.instance;
  final controller = StreamController<List<PetRecord>>();
  final Map<String, List<PetRecord>> cache = {};
  final List<StreamSubscription> subs = [];

  void emit() {
    final all = cache.values.expand((r) => r).toList()
      ..sort((a, b) {
        final at = a.dateTimestamp;
        final bt = b.dateTimestamp;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
    if (!controller.isClosed) controller.add(all.take(limit).toList());
  }

  for (final pet in pets) {
    for (final col in _collections) {
      final key = '${pet.petID}_$col';
      cache[key] = [];

      final sub = db
          .collection('users')
          .doc(uid)
          .collection('pets')
          .doc(pet.petID)
          .collection(col)
          .orderBy('date_timestamp', descending: true)
          .limit(limit)
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