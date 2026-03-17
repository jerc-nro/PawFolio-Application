import 'package:cloud_firestore/cloud_firestore.dart';

class VetVisitRecord {
  String visitID;
  String petID;
  String clinicName;
  String veterinarian; // Added
  String date;         // Used for date_string (dd.MM.yyyy)
  String time;         // Added
  String status;
  String description;

  VetVisitRecord({
    required this.visitID,
    required this.petID,
    required this.clinicName,
    required this.veterinarian,
    required this.date,
    required this.time,
    required this.status,
    required this.description,
  });

  factory VetVisitRecord.fromMap(Map<String, dynamic> data, String id) {
    return VetVisitRecord(
      visitID: id,
      petID: data['petID'] ?? '',
      clinicName: data['clinic_name'] ?? data['clinicName'] ?? '',
      veterinarian: data['veterinarian'] ?? '',
      date: data['date_string'] ?? data['date'] ?? '',
      time: data['time_string'] ?? '',
      status: data['status'] ?? 'UPCOMING',
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'petID': petID,
      'clinic_name': clinicName,
      'veterinarian': veterinarian,
      'date_string': date,
      'time_string': time,
      'status': status,
      'description': description,
      'category': 'Vet Visit',
      'date_timestamp': FieldValue.serverTimestamp(), // For sorting in Streams
    };
  }
}