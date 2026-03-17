import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/pet_model.dart';
import '../providers/pet_provider.dart';
import '../providers/pet_controller.dart';
import '../providers/pet_filter_provider.dart';
import 'pet_profile_page.dart';

class ArchivedPetsPage extends ConsumerWidget {
  const ArchivedPetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const Color kHeader = Color(0xFF4A6580);
    
    // Watch the stream and the filter
    final archivedPetsAsync = ref.watch(archivedPetsProvider);
    final selectedFilter = ref.watch(petTypeFilterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EE),
      appBar: AppBar(
        backgroundColor: kHeader,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Archived Pets", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            initialValue: selectedFilter,
            icon: const Icon(Icons.filter_list),
            onSelected: (val) => ref.read(petTypeFilterProvider.notifier).state = val,
            itemBuilder: (context) => [
              const PopupMenuItem(value: "ALL", child: Text("All Species")),
              const PopupMenuItem(value: "CAT", child: Text("Cats")),
              const PopupMenuItem(value: "DOG", child: Text("Dogs")),
            ],
          ),
        ],
      ),
      body: archivedPetsAsync.when(
        data: (pets) => pets.isEmpty 
            ? _buildEmptyState() 
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pets.length,
                itemBuilder: (context, index) => _PetItem(pet: pets[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(child: Text("Error loading pets")),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.archive_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("No archived pets found.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _PetItem extends ConsumerWidget {
  final Pet pet;
  const _PetItem({required this.pet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if the pet is deceased to restrict dismiss directions
    final bool isDeceased = pet.isAlive == false;

    return Dismissible(
      key: Key(pet.petID),
      // If deceased, only allow swiping to delete (Right to Left)
      direction: isDeceased ? DismissDirection.endToStart : DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Restore action
          return !isDeceased;
        } else {
          // Permanent delete action
          return await _showDeleteDialog(context, pet.name, () {
            ref.read(petControllerProvider).deletePet(pet.petID);
          });
        }
      },
      onDismissed: (direction) {
  final controller = ref.read(petControllerProvider);
        if (direction == DismissDirection.startToEnd) {
          // Swipe left-to-right → Restore pet
          controller.restorePet(pet.petID);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${pet.name} restored to active list.")),
          );
        }
      },
      background: _buildActionBackground(Icons.unarchive, const Color(0xFF7A8C6A), Alignment.centerLeft),
      secondaryBackground: _buildActionBackground(Icons.delete_forever, Colors.redAccent, Alignment.centerRight),
      child: _buildPetCard(context, pet, isDeceased),
    );
  }

  Future<bool> _showDeleteDialog(BuildContext context, String name, VoidCallback onDelete) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Permanently?"),
        content: Text("Are you sure you want to delete $name? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey))
          ),
          TextButton(
            onPressed: () {
              onDelete();
              Navigator.pop(context, true);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildActionBackground(IconData icon, Color color, Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
      child: Icon(icon, color: Colors.white),
    );
  }

  Widget _buildPetCard(BuildContext context, Pet pet, bool isDeceased) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade300, width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: isDeceased ? Colors.blueGrey : const Color(0xFF7A8C6A),
          child: Icon(
            isDeceased ? Icons.cloud_outlined : Icons.pets, 
            color: Colors.white, 
            size: 20
          ),
        ),
        title: Text(
          pet.name, 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        subtitle: Text("${pet.type} • ${pet.breed}"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => PetProfilePage(pet: pet))
        ),
      ),
    );
  }
}