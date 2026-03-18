import 'package:cloud_firestore/cloud_firestore.dart';

class VaccinationRecord {
  String vaccinationID; 
  String petID;
  String type; // This maps to vaccineName/type
  String veterinarian; // Changed from vetName to match UI naming
  String dateString; // For display (dd.MM.yyyy)
  String timeString; // Added to match UI
  DateTime? givenDate; // Actual timestamp for sorting/logic
  DateTime? dueDate;
  String status;

  VaccinationRecord({
    required this.vaccinationID,
    required this.petID,
    required this.type,
    required this.veterinarian,
    required this.dateString,
    required this.timeString,
    this.givenDate,
    this.dueDate,
    required this.status,
  });

  factory VaccinationRecord.fromMap(Map<String, dynamic> data, String id) {
    return VaccinationRecord(
      vaccinationID: id,
      petID: data['petID'] ?? '',
      type: data['name'] ?? data['vaccine_name'] ?? data['type'] ?? '',
      veterinarian: data['veterinarian'] ?? data['provider'] ?? 'Unknown',
      dateString: data['date_string'] ?? '',
      timeString: data['time_string'] ?? '',
      // Safe conversion for timestamps
      givenDate: data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : null,
      dueDate: data['due_date'] != null ? (data['due_date'] as Timestamp).toDate() : null,
      status: data['status'] ?? 'UPCOMING',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'petID': petID,
      'name': type,
      'veterinarian': veterinarian,
      'date_string': dateString,
      'time_string': timeString,
      'timestamp': givenDate ?? FieldValue.serverTimestamp(),
      'due_date': dueDate,
      'status': status,
      'category': 'Vaccination', // Useful for global filtering
    };
  }
}