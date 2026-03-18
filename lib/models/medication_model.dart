import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationRecord {
  final String medicationID;
  final String petID;
  final String medicationName;
  final String dateString;
  final String clinicName;
  final String veterinarian;
  final double petWeight;
  final String dosage;
  final int intakeCount;
  final String period; // e.g., "days", "weeks", "months"
  final String status; // ONGOING, UPCOMING, COMPLETED
  final DateTime? dateTimestamp;
  final DateTime? endDate; // NEW: Calculated end date

  MedicationRecord({
    required this.medicationID,
    required this.petID,
    required this.medicationName,
    required this.dateString,
    required this.clinicName,
    required this.veterinarian,
    required this.petWeight,
    required this.dosage,
    required this.intakeCount,
    required this.period,
    required this.status,
    this.dateTimestamp,
    this.endDate,
  });

  /// Helper to convert Firestore String ID to an Integer for Android Notifications
  int get notificationId => medicationID.hashCode.abs();

  factory MedicationRecord.fromMap(Map<String, dynamic> data, String id) {
    // 1. Parse the Start Date
    DateTime? start = data['date_timestamp'] != null
        ? (data['date_timestamp'] as Timestamp).toDate()
        : null;

    // 2. Calculate End Date based on Period and Intake Count
    DateTime? calculatedEnd;
    if (start != null) {
      int count = data['intake_count'] ?? 1;
      String per = (data['period'] ?? 'days').toLowerCase();

      if (per.contains('day')) {
        calculatedEnd = start.add(Duration(days: count));
      } else if (per.contains('week')) {
        calculatedEnd = start.add(Duration(days: count * 7));
      } else if (per.contains('month')) {
        // Approximate month as 30 days for simplicity
        calculatedEnd = start.add(Duration(days: count * 30));
      }
    }

    return MedicationRecord(
      medicationID: id,
      petID: data['petID'] ?? '',
      medicationName: data['medication_name'] ?? '',
      dateString: data['date_string'] ?? '',
      clinicName: data['clinic_name'] ?? '',
      veterinarian: data['veterinarian'] ?? '',
      petWeight: (data['pet_weight'] ?? 0.0).toDouble(),
      dosage: data['dosage'] ?? '',
      intakeCount: data['intake_count'] ?? 1,
      period: data['period'] ?? 'days',
      status: data['status'] ?? 'ONGOING',
      dateTimestamp: start,
      endDate: data['end_date'] != null 
          ? (data['end_date'] as Timestamp).toDate() 
          : calculatedEnd,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'petID': petID,
      'medication_name': medicationName,
      'date_string': dateString,
      'clinic_name': clinicName,
      'veterinarian': veterinarian,
      'pet_weight': petWeight,
      'dosage': dosage,
      'intake_count': intakeCount,
      'period': period,
      'status': status,
      'date_timestamp': dateTimestamp != null
          ? Timestamp.fromDate(dateTimestamp!)
          : FieldValue.serverTimestamp(),
      'end_date': endDate != null ? Timestamp.fromDate(endDate!) : null,
    };
  }
}