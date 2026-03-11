class VetVisitRecord {
  String visitID;
  String petID;
  String clinicName;
  String date; // Keeping as String per your original model
  String status;
  String description;

  VetVisitRecord({
    required this.visitID,
    required this.petID,
    required this.clinicName,
    required this.date,
    required this.status,
    required this.description,
  });

  factory VetVisitRecord.fromMap(Map<String, dynamic> data, String id) {
    return VetVisitRecord(
      visitID: id,
      petID: data['petID'] ?? '',
      clinicName: data['clinicName'] ?? '',
      date: data['date'] ?? '',
      status: data['status'] ?? 'Scheduled',
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'petID': petID,
      'clinicName': clinicName,
      'date': date,
      'status': status,
      'description': description,
    };
  }
}