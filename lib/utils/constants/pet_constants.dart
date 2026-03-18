
class PetConstants {
  static const Map<String, List<String>> breeds = {
    'DOG': ['Labrador Retriever', 'German Shepherd', 'Golden Retriever', 'Bulldog', 'Poodle', 'Shih Tzu', 'Beagle', 'Dachshund', 'Other'],
    'CAT': ['Persian', 'Maine Coon', 'Siamese', 'British Shorthair', 'Ragdoll', 'Bengal', 'Sphynx', 'Scottish Fold', 'Other'],
  };

  // Move your regex-heavy validators here to keep the UI file clean
  static String? validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Name is required.';
    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(v.trim())) return 'Letters and spaces only.';
    return null;
  }
}