class ActivityRecord {
  int activityID;
  int petID;
  String type;
  DateTime date;
  String description;

  ActivityRecord ({
    required this.activityID,
    required this.petID,
    required this.type, 
    required this.date, 
    required this.description
  });

  factory ActivityRecord.fromMap(Map<String, dynamic> data) {
  return ActivityRecord(
      activityID: data['aID'],
      petID: data['petID'],
      type: data['type'],
      date: data['date'],
      description: data['description']

    );
  }

  Map<String, dynamic> toMap() {
    return {
      'aID': activityID,
      'petID': petID,
      'type': type,
      'date': date,
      'description': description
    };
  }
}