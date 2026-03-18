import 'package:flutter/foundation.dart';

@immutable
class Pet {
  final String petID;
  final String ownerID;
  final String type;
  final String breed;
  final String name;
  final String sex;
  final String birthDate;
  final bool sterilization;
  final double weight;
  final String weightUnit;
  final String color;
  final String description; // Added this field
  final bool vaccinated;
  final String vaccineDetails;
  final bool isArchived;
  final bool isAlive;
  final String? profileBase64;

  const Pet({
    required this.petID,
    required this.ownerID,
    required this.type,
    required this.breed,
    required this.name,
    required this.sex,
    required this.birthDate,
    required this.sterilization,
    required this.weight,
    required this.weightUnit,
    required this.color,
    required this.description, // Added to constructor
    required this.vaccinated,
    required this.vaccineDetails,
    required this.isArchived,
    required this.isAlive,
    this.profileBase64,
  });

  // CRITICAL for Riverpod state updates
  Pet copyWith({
    String? petID,
    String? ownerID,
    String? type,
    String? breed,
    String? name,
    String? sex,
    String? birthDate,
    bool? sterilization,
    double? weight,
    String? weightUnit,
    String? color,
    String? description, // Added to copyWith
    bool? vaccinated,
    String? vaccineDetails,
    bool? isArchived,
    bool? isAlive,
    ValueGetter<String?>? profileBase64, 
  }) {
    return Pet(
      petID: petID ?? this.petID,
      ownerID: ownerID ?? this.ownerID,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      name: name ?? this.name,
      sex: sex ?? this.sex,
      birthDate: birthDate ?? this.birthDate,
      sterilization: sterilization ?? this.sterilization,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      color: color ?? this.color,
      description: description ?? this.description,
      vaccinated: vaccinated ?? this.vaccinated,
      vaccineDetails: vaccineDetails ?? this.vaccineDetails,
      isArchived: isArchived ?? this.isArchived,
      isAlive: isAlive ?? this.isAlive,
      profileBase64: profileBase64 != null ? profileBase64() : this.profileBase64,
    );
  }

  factory Pet.fromMap(Map<String, dynamic> data, String id) {
    return Pet(
      petID: id,
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
      description: data['description'] ?? '', // Added to fromMap
      vaccinated: data['vaccinated'] ?? false,
      vaccineDetails: data['vaccineDetails'] ?? '',
      isArchived: data['isArchived'] ?? false,
      isAlive: data['isAlive'] ?? true,
      profileBase64: data['profileBase64'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
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
    'description': description, // Added to toMap
    'vaccinated': vaccinated,
    'vaccineDetails': vaccineDetails,
    'isArchived': isArchived,
    'isAlive': isAlive,
    'profileBase64': profileBase64,
  };

  String get formattedAge {
    final dob = DateTime.tryParse(birthDate);
    if (dob == null) return "-";

    final now = DateTime.now();
    int years = now.year - dob.year;
    int months = now.month - dob.month;
    int days = now.day - dob.day;

    if (days < 0) {
      months -= 1;
      days += DateTime(now.year, now.month, 0).day;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }

    if (years > 0) return "$years year${years > 1 ? 's' : ''}";
    if (months > 0) return "$months month${months > 1 ? 's' : ''}";
    return "$days day${days > 1 ? 's' : ''}";
  }

  // Inside your Pet class

  /// Converts the String birthDate to a DateTime for notification scheduling
  DateTime? get birthDateTime => DateTime.tryParse(birthDate);

  /// Unique notification ID for the pet's birthday
  int get birthdayNotifyId => ('$petID birthday').hashCode.abs();
    
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pet &&
          runtimeType == other.runtimeType &&
          petID == other.petID &&
          name == other.name &&
          isArchived == other.isArchived &&
          weight == other.weight &&
          profileBase64 == other.profileBase64;

  @override
  int get hashCode => petID.hashCode ^ name.hashCode ^ isArchived.hashCode;
}