class Pet {
  String petID;
  String ownerID;
  String type;
  String breed;
  String name;
  String sex;
  String birthDate;
  bool sterilization;
  double weight;
  String weightUnit;
  String color;
  bool vaccinated;
  String vaccineDetails;

  Pet({
    required this.petID,
    required this.ownerID,
    required this.type,
    required this.name,
    required this.breed,
    required this.sex,
    required this.birthDate,
    required this.sterilization,
    required this.weight,
    required this.weightUnit,
    required this.color,
    required this.vaccinated,
    required this.vaccineDetails,
  });

  // --- ADD THIS FACTORY CONSTRUCTOR ---
  factory Pet.fromFirestore(Map<String, dynamic> data) {
    return Pet(
      petID: data['petID'] ?? '',
      ownerID: data['ownerID'] ?? '',
      type: data['type'] ?? 'Unknown',
      name: data['name'] ?? 'Unknown',
      breed: data['breed'] ?? 'unknown',
      sex: data['sex'] ?? '',
      birthDate: data['birthDate'] ?? 'Unknown',
      sterilization: data['sterilization'] ?? false,
      weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
      weightUnit: data['weightUnit'] ?? 'kg',
      color: data['color'] ?? '',
      vaccinated: data['vaccinated'] ?? false,
      vaccineDetails: data['vaccineDetails'] ?? '',
    );
  }

  factory Pet.fromMap(Map<String, dynamic> data) {
    return Pet(
      petID: data['petID'] ?? '',
      ownerID: data['ownerID'] ?? '',
      type: data['type'] ?? '',
      name: data['name'] ?? '',
      breed: data['breed'] ?? '',
      sex: data['sex'] ?? '',
      birthDate: data['birthDate'] ?? '',
      sterilization: data['sterilization'] ?? false,
      weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
      weightUnit: data['weightUnit'] ?? 'kg',
      color: data['color'] ?? '',
      vaccinated: data['vaccinated'] ?? false,
      vaccineDetails: data['vaccineDetails'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'petID': petID,
      'ownerID': ownerID,
      'type': type,
      'name': name,
      'breed': breed,
      'sex': sex,
      'birthDate': birthDate,
      'sterilization': sterilization,
      'weight': weight,
      'weightUnit': weightUnit,
      'color': color,
      'vaccinated': vaccinated,
      'vaccineDetails': vaccineDetails,
    };
  }
}