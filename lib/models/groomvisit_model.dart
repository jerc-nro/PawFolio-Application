class GroomVisitRecord  {
  int groomID;
  int petID;
  String clinicName;
  DateTime date;
  String type;
  String status;

  GroomVisitRecord ({
    required this.groomID,
    required this.petID,
    required this.clinicName,
    required this.date,
    required this.type,
    required this.status,
  });

  factory GroomVisitRecord.fromMap(Map<String, dynamic> data, String id) {
  return GroomVisitRecord(
      groomID: data['gID'],
      petID: data['petID'],
      clinicName: data['clinicName'],
      date: data['date'],
      type: data['type'],
      status: data['status']

    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gID': groomID,
      'petID': petID,
      'clinicName': clinicName,
      'date': date,
      'type': type,
      'status': status
    };
  }
}