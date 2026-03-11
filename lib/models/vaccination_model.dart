import 'package:cloud_firestore/cloud_firestore.dart';

class VaccinationRecord {
  String vaccinationID; // Changed to String for Firestore Doc ID
  String petID;
  String type;
  DateTime givenDate;
  DateTime dueDate;
  String status;

  VaccinationRecord({
    required this.vaccinationID,
    required this.petID,
    required this.type,
    required this.givenDate,
    required this.dueDate,
    required this.status,
  });

  factory VaccinationRecord.fromMap(Map<String, dynamic> data, String id) {
    return VaccinationRecord(
      vaccinationID: id,
      petID: data['petID'] ?? '',
      type: data['type'] ?? '',
      givenDate: (data['givenDate'] as Timestamp).toDate(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'petID': petID,
      'type': type,
      'givenDate': givenDate, // Firestore converts DateTime to Timestamp automatically
      'dueDate': dueDate,
      'status': status,
    };
  }
}