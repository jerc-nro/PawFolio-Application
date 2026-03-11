import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationRecord {
  String medicationID;
  String petID;
  String name;
  double dosage;
  DateTime startDate;
  DateTime endDate;
  bool status;

  MedicationRecord({
    required this.medicationID,
    required this.petID,
    required this.name,
    required this.dosage,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory MedicationRecord.fromMap(Map<String, dynamic> data, String id) {
    return MedicationRecord(
      medicationID: id,
      petID: data['petID'] ?? '',
      name: data['name'] ?? '',
      dosage: (data['dosage'] ?? 0.0).toDouble(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      status: data['status'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'petID': petID,
      'name': name,
      'dosage': dosage,
      'startDate': startDate,
      'endDate': endDate,
      'status': status,
    };
  }
}