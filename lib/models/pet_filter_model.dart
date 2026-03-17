class PetFilter {
  String type;          // 'ALL', 'DOG', 'CAT'
  String sex;           // 'ALL', 'MALE', 'FEMALE'
  String sterilization;  // 'Any', 'Yes', 'No'

  PetFilter({
    this.type = 'ALL',
    this.sex = 'ALL',
    this.sterilization = 'Any',
  });

  // Logic to check if a pet survives ALL active filters
  bool matches(dynamic pet) {
    final bool matchesType = type == 'ALL' || pet.type.toUpperCase() == type;
    final bool matchesSex = sex == 'ALL' || pet.sex.toUpperCase() == sex;
    
    bool matchesSteril = true;
    if (sterilization != 'Any') {
      matchesSteril = pet.isSpayed == (sterilization == 'Yes');
    }

    return matchesType && matchesSex && matchesSteril;
  }

  // Create a copy to allow "Cancel" without saving changes in the UI
  PetFilter copy() => PetFilter(
    type: type,
    sex: sex,
    sterilization: sterilization,
  );
}