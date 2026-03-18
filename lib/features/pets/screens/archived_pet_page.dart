import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/pet_model.dart';
import '../providers/pet_provider.dart';
import '../providers/pet_controller.dart';
import '../providers/pet_filter_provider.dart';
import 'pet_profile_page.dart';

class ArchivedPetsPage extends ConsumerWidget {
  const ArchivedPetsPage({super.key});

  static const _kHeader  = Color(0xFF4A6580);
  static const _kNavy    = Color(0xFF45617D);
  static const _kGreen   = Color(0xFF7A8C6A);
  static const _kRed     = Color(0xFFBD4B4B);
  static const _kBg      = Color(0xFFF5F2EE);
  static const _kDivider = Color(0xFFE0D4CB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedPetsAsync = ref.watch(archivedPetsProvider);
    final selectedFilter    = ref.watch(petTypeFilterProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kHeader,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Archived Pets',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            initialValue: selectedFilter,
            icon: const Icon(Icons.filter_list, color: Colors.white),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            onSelected: (val) =>
                ref.read(petTypeFilterProvider.notifier).state = val,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'ALL', child: Text('All Species')),
              PopupMenuItem(value: 'CAT', child: Text('Cats')),
              PopupMenuItem(value: 'DOG', child: Text('Dogs')),
            ],
          ),
        ],
      ),
      body: archivedPetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => const Center(child: Text('Error loading pets')),
        data: (allPets) {
          // ── Apply filter client-side ──────────────────────────────
          final pets = selectedFilter == 'ALL'
              ? allPets
              : allPets
                  .where((p) =>
                      p.type.toUpperCase() == selectedFilter.toUpperCase())
                  .toList();

          if (pets.isEmpty) return _emptyState(selectedFilter);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: pets.length,
            itemBuilder: (context, i) => _PetItem(pet: pets[i]),
          );
        },
      ),
    );
  }

  Widget _emptyState(String filter) {
    final label = filter == 'ALL' ? 'archived pets' : '${filter.toLowerCase()}s';
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inventory_2_outlined, size: 64,
            color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('No $label found.',
            style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 15,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ── Pet Item ──────────────────────────────────────────────────────────────────

class _PetItem extends ConsumerWidget {
  final Pet pet;
  const _PetItem({required this.pet});

  static const _kGreen = Color(0xFF7A8C6A);
  static const _kRed   = Color(0xFFBD4B4B);
  static const _kNavy  = Color(0xFF45617D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDeceased = !pet.isAlive;

    return Dismissible(
      key: Key(pet.petID),
      // Deceased → delete only (end-to-start)
      // Archived → both directions (restore | delete)
      direction: isDeceased
          ? DismissDirection.endToStart
          : DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Restore — deceased pets can never reach here due to direction above
          return await _confirmRestore(context, ref);
        } else {
          // Delete — two-step confirmation
          return await _confirmDelete(context, ref);
        }
      },
      background: _actionBg(
        Icons.unarchive_outlined, _kGreen, Alignment.centerLeft),
      secondaryBackground: _actionBg(
        Icons.delete_forever_outlined, _kRed, Alignment.centerRight),
      child: _PetCard(pet: pet, isDeceased: isDeceased),
    );
  }

  // ── Step 1 + 2: Delete confirmation ──────────────────────────────────────

  Future<bool> _confirmDelete(BuildContext context, WidgetRef ref) async {
    // Step 1
    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Permanently?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to permanently delete ${pet.name}?\n\n'
          'All records will be lost.',
          style: const TextStyle(fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kRed,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Continue',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700))),
        ],
      ),
    ) ?? false;
    if (!step1 || !context.mounted) return false;

    // Step 2
    final step2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: const [
          Icon(Icons.warning_amber_rounded,
              color: Color(0xFFBD4B4B), size: 20),
          SizedBox(width: 8),
          Text('Are you absolutely sure?',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kRed.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kRed.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: _kRed, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${pet.name} and all their records will be permanently '
                  'deleted and cannot be recovered.',
                  style: const TextStyle(
                      fontSize: 12, color: _kRed, height: 1.5)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Go back',
                style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kRed,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Delete Forever',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700))),
        ],
      ),
    ) ?? false;

    if (step2 && context.mounted) {
      await ref.read(petControllerProvider).deletePet(pet.petID);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${pet.name} permanently deleted.'),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
    return step2;
  }

  // ── Restore confirmation ──────────────────────────────────────────────────

  Future<bool> _confirmRestore(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: const [
          Icon(Icons.unarchive_outlined,
              color: Color(0xFF7A8C6A), size: 20),
          SizedBox(width: 8),
          Text('Restore Pet?',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: Text(
          'Move ${pet.name} back to your active pets list?',
          style: const TextStyle(fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Restore',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700))),
        ],
      ),
    ) ?? false;

    if (confirmed && context.mounted) {
      await ref.read(petControllerProvider).restorePet(pet.petID);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${pet.name} restored to active list.'),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
    return confirmed;
  }

  Widget _actionBg(IconData icon, Color color, Alignment align) {
    return Container(
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(15)),
      child: Icon(icon, color: Colors.white),
    );
  }
}

// ── Pet Card ──────────────────────────────────────────────────────────────────

class _PetCard extends StatelessWidget {
  final Pet pet;
  final bool isDeceased;
  const _PetCard({required this.pet, required this.isDeceased});

  static const _kGreen  = Color(0xFF7A8C6A);
  static const _kRed    = Color(0xFFBD4B4B);
  static const _kNavy   = Color(0xFF45617D);
  static const _kDivider = Color(0xFFE0D4CB);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _kDivider, width: 1),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PetProfilePage(pet: pet)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isDeceased
                      ? _kRed.withOpacity(0.1)
                      : _kGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDeceased ? Icons.heart_broken_outlined : Icons.pets,
                  color: isDeceased ? _kRed : _kGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              // Name + breed + badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pet.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${pet.type} • ${pet.breed}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDeceased
                            ? _kRed.withOpacity(0.08)
                            : _kNavy.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isDeceased ? 'Deceased' : 'Archived',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDeceased ? _kRed : _kNavy,
                            letterSpacing: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              // Mark as Deceased button — only for archived-alive pets
              if (!isDeceased)
                Consumer(builder: (context, ref, _) {
                  return IconButton(
                    tooltip: 'Mark as Deceased',
                    icon: const Icon(Icons.heart_broken_outlined,
                        color: Color(0xFFBD4B4B), size: 20),
                    onPressed: () =>
                        _handleMarkDeceased(context, ref),
                  );
                }),
              const Icon(Icons.arrow_forward_ios,
                  size: 13, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleMarkDeceased(
      BuildContext context, WidgetRef ref) async {
    // Step 1
    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: const [
          Icon(Icons.heart_broken_outlined,
              color: Color(0xFFBD4B4B), size: 20),
          SizedBox(width: 8),
          Text('Mark as Deceased',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        content: Text(
          'Are you sure you want to mark ${pet.name} as deceased?\n\n'
          'This action cannot be undone.',
          style: const TextStyle(fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kRed,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Continue',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700))),
        ],
      ),
    ) ?? false;
    if (!step1 || !context.mounted) return;

    // Step 2
    final step2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: const [
          Icon(Icons.warning_amber_rounded,
              color: Color(0xFFBD4B4B), size: 20),
          SizedBox(width: 8),
          Text('Are you absolutely sure?',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kRed.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kRed.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  color: _kRed, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${pet.name} will be permanently marked as deceased '
                  'and cannot be restored.',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFBD4B4B),
                      height: 1.5)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Go back',
                style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kRed,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Yes, mark as deceased',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700))),
        ],
      ),
    ) ?? false;
    if (!step2 || !context.mounted) return;

    await ref.read(petControllerProvider).markDeceased(pet.petID);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${pet.name} has been marked as deceased.'),
        backgroundColor: _kRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }
}