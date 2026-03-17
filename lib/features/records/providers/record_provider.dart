import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/record_model.dart';
import '../../../services/record_services.dart';

final recordControllerProvider = AsyncNotifierProvider.autoDispose<RecordController, void>(() {
  return RecordController();
});

class RecordController extends AutoDisposeAsyncNotifier<void> {
  late final RecordServices _service;

  @override
  Future<void> build() async {
    _service = RecordServices();
  }

  Future<void> addPetRecord(PetRecord record) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.addPetRecord(record));
  }

  Future<void> archiveRecord({
    required String petId,
    required String collection,
    required String recordId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.archiveRecord(petId, collection, recordId));
  }

  Future<void> updateRecordStatus(PetRecord record, String newStatus) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.updateRecordStatus(record, newStatus));
  }

  Future<void> deleteRecord({
    required String petId,
    required String collection,
    required String recordId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.deleteRecord(petId, collection, recordId));
  }

  Future<void> addWeightRecord({
    required String petId,
    required double weight,
    required String unit,
    required String dateString,
    required String notes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.addWeightEntry(petId, weight, unit, dateString, notes));
  }

  Future<void> editWeightRecord({
    required String petId,
    required String recordId,
    required double weight,
    required String unit,
    required String dateString,
    required String notes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.editWeightEntry(
        petId: petId,
        recordId: recordId,
        weight: weight,
        unit: unit,
        dateString: dateString,
        notes: notes,
      ));
  }

  Future<void> deleteWeightRecord({
    required String petId,
    required String recordId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.deleteWeightEntry(petId, recordId));
  }
}