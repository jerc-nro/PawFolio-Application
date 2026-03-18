import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/pet_services.dart'; // Import the service from its own file
import '../../../models/pet_model.dart';

// --- RIVERPOD PROVIDERS ONLY ---

// This gets the engine from the OTHER file
final petServiceProvider = Provider((ref) => PetServices());

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user?.uid,
    loading: () => null,
    error: (_, _) => null,
  );
});

// individual
final activePetProvider = StateProvider<Pet?>((ref) => null);


// plural
final activePetsProvider = StreamProvider<List<Pet>>((ref) {
  final service = ref.watch(petServiceProvider);
  final uid = ref.watch(userIdProvider);
  
  if (uid == null) return Stream.value([]);
  return service.streamActivePets(uid);
});

final archivedPetsProvider = StreamProvider<List<Pet>>((ref) {
  final service = ref.watch(petServiceProvider);
  final uid = ref.watch(userIdProvider);
  
  if (uid == null) return Stream.value([]);
  return service.streamArchivedPets(uid);
});

// DELETE the "class PetServices" section from this file! 
// It belongs in lib/services/pet_services.dart