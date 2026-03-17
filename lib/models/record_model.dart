import 'package:cloud_firestore/cloud_firestore.dart';

class PetRecord {
  final String id;
  final String petID;
  final String petName;
  final String petType;
  final String category;   // 'Vet Visit', 'Medication', etc.
  final String collection; // Firestore subcollection name
  final String status;     // 'Done', 'Ongoing', 'Upcoming', 'Overdue'
  final String dateString;
  final DateTime? dateTimestamp;
  final Map<String, dynamic> extra;

  const PetRecord({
    required this.id,
    required this.petID,
    required this.petName,
    required this.petType,
    required this.category,
    required this.collection,
    required this.status,
    required this.dateString,
    this.dateTimestamp,
    this.extra = const {},
  });

  // --- NOTIFICATION HELPERS ---

  /// Converts Firestore String ID to an Integer for Android
  int get notificationId => id.hashCode.abs();

  /// Calculates when the user should be notified
  DateTime? get reminderDate {
    if (dateTimestamp == null) return null;
    
    if (category == 'Medication') {
      // Notify at 9:00 AM on the day of the record
      return DateTime(dateTimestamp!.year, dateTimestamp!.month, dateTimestamp!.day, 9, 0);
    } else {
      // For Vet, Grooming, Vaccines: Notify 24 hours before
      return dateTimestamp!.subtract(const Duration(days: 1));
    }
  }

  /// Specifically for Medications: Calculates the end of the course
  DateTime? get medicationEndDate {
    if (category != 'Medication' || dateTimestamp == null) return null;
    
    int count = int.tryParse(extra['intake_count']?.toString() ?? '1') ?? 1;
    String period = (extra['period'] ?? 'days').toString().toLowerCase();
    
    if (period.contains('day')) return dateTimestamp!.add(Duration(days: count));
    if (period.contains('week')) return dateTimestamp!.add(Duration(days: count * 7));
    return null;
  }

  // --- FACTORY & MAPPING ---

  factory PetRecord.fromDoc(DocumentSnapshot doc, String collectionName) {
    final d = doc.data() as Map<String, dynamic>;
    final ts = d['date_timestamp'];

    final known = {
      'petID', 'userId', 'petName', 'petType', 'category',
      'status', 'date_string', 'date_timestamp',
    };
    final extraFields = {
      for (final e in d.entries)
        if (!known.contains(e.key)) e.key: e.value,
    };

    return PetRecord(
      id: doc.id,
      petID: d['petID'] ?? '',
      petName: d['petName'] ?? '',
      petType: d['petType'] ?? '',
      category: d['category'] ?? _collectionToCategory(collectionName),
      collection: collectionName,
      status: d['status'] ?? '',
      dateString: d['date_string'] ?? '',
      dateTimestamp: ts is Timestamp ? ts.toDate() : null,
      extra: extraFields,
    );
  }

  String get title {
    switch (category) {
      case 'Medication':   return extra['medication_name'] ?? 'Medication';
      case 'Vaccination':  return extra['vaccine_name'] ?? 'Vaccination';
      case 'Preventative': return extra['brand_name'] ?? 'Preventative';
      case 'Vet Visit':    return extra['reason'] ?? 'Vet Visit';
      case 'Grooming':     return extra['type'] ?? 'Grooming';
      default:             return category;
    }
  }

  static String _collectionToCategory(String col) => switch (col) {
    'vet_visits'    => 'Vet Visit',
    'medications'   => 'Medication',
    'vaccinations'  => 'Vaccination',
    'preventatives' => 'Preventative',
    'groom_visits'  => 'Grooming',
    _               => col,
  };
}