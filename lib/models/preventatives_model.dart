import 'package:cloud_firestore/cloud_firestore.dart';

class PreventativeRecord {
  final String id;
  final String type; // e.g., "Heartworm", "Flea & Tick"
  final String brand; // e.g., "NexGard"
  final DateTime appliedDate;
  final DateTime? nextDueDate;
  final String notes;

  PreventativeRecord({
    required this.id,
    required this.type,
    required this.brand,
    required this.appliedDate,
    this.nextDueDate,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'brand': brand,
      'appliedDate': appliedDate,
      'nextDueDate': nextDueDate,
      'notes': notes,
    };
  }

  factory PreventativeRecord.fromMap(Map<String, dynamic> map, String id) {
    return PreventativeRecord(
      id: id,
      type: map['type'] ?? '',
      brand: map['brand'] ?? '',
      appliedDate: (map['appliedDate'] as Timestamp).toDate(),
      nextDueDate: map['nextDueDate'] != null 
          ? (map['nextDueDate'] as Timestamp).toDate() 
          : null,
      notes: map['notes'] ?? '',
    );
  }
}