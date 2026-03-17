import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/pet_model.dart';
import '../providers/pet_controller.dart';
import '../providers/pet_profile_controller.dart';
import '../widgets/pet_profile_header.dart';
import '../widgets/pet_info_card.dart';
import '../widgets/pet_health_card.dart';
import '../widgets/pet_history_tile.dart';
import '../widgets/_pet_profile_shared.dart';
import 'grooming_history_view.dart';
import 'medication_history_view.dart';
import 'vaccination_history_view.dart';
import 'vet_visits_history_view.dart';
import 'preventatives_history_view.dart';

class PetProfilePage extends ConsumerStatefulWidget {
  final Pet pet;
  const PetProfilePage({super.key, required this.pet});

  @override
  ConsumerState<PetProfilePage> createState() => _PetProfilePageState();
}

class _PetProfilePageState extends ConsumerState<PetProfilePage> {
  final Map<String, dynamic> _pendingFields = {};

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(petProfileProvider(widget.pet));
    final notifier = ref.read(petProfileProvider(widget.pet).notifier);
    final pet      = state.pet;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EE),
      body: CustomScrollView(slivers: [

        // ── Header (unchanged) ────────────────────────────
        PetProfileHeader(
          pet: pet,
          editMode: state.editMode, saving: state.saving,
          onEdit:      notifier.enterEditMode,
          onCancel:    () { _pendingFields.clear(); notifier.cancelEditMode(); },
          onSave:      () => _save(notifier),
          onPickPhoto: notifier.pickAndSavePhoto,
        ),

        // ── Body ──────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          sliver: SliverList(delegate: SliverChildListDelegate([

            PetInfoCard(
              name: pet.name, breed: pet.breed, color: pet.color,
              sex: pet.sex, birthDate: pet.birthDate,
              weight: pet.weight, weightUnit: pet.weightUnit,
              editMode: state.editMode,
              onChanged: (f) => _pendingFields.addAll(f),
            ),

            const SizedBox(height: 14),

            PetHealthCard(
              sterilization: pet.sterilization,
              vaccinated: pet.vaccinated,
              vaccineDetails: pet.vaccineDetails,
              description: pet.description,
              editMode: state.editMode,
              ownerID: pet.ownerID,   // ← for live vaccine stream
              petID: pet.petID,
              onChanged: (f) => _pendingFields.addAll(f),
            ),

            const SizedBox(height: 14),

            // ── Status + Archive ──────────────────────────
            _PetStatusCard(pet: pet),

            const SizedBox(height: 20),

            // ── History ───────────────────────────────────
            const _SectionLabel('HISTORY'),
            const SizedBox(height: 10),

            PetHistoryTile(
              title: 'Vaccinations',
              icon: Icons.verified_outlined,
              ownerID: pet.ownerID, petID: pet.petID,
              collection: 'vaccinations', nameField: 'vaccine_name',
              onViewAll: () => _push(context, VaccinationHistoryView(pet: pet)),
            ),
            const SizedBox(height: 10),
            PetHistoryTile(
              title: 'Vet Visits',
              icon: Icons.local_hospital_outlined,
              ownerID: pet.ownerID, petID: pet.petID,
              collection: 'vet_visits', nameField: 'reason',
              onViewAll: () => _push(context, VetVisitsHistoryView(pet: pet)),
            ),
            const SizedBox(height: 10),
            PetHistoryTile(
              title: 'Medications',
              icon: Icons.medication_outlined,
              ownerID: pet.ownerID, petID: pet.petID,
              collection: 'medications', nameField: 'medication_name',
              onViewAll: () => _push(context, MedicationHistoryView(pet: pet)),
            ),
            const SizedBox(height: 10),
            PetHistoryTile(
              title: 'Preventatives',
              icon: Icons.shield_outlined,
              ownerID: pet.ownerID, petID: pet.petID,
              collection: 'preventatives', nameField: 'brand_name',
              onViewAll: () => _push(context, PreventativesHistoryView(pet: pet)),
            ),
            const SizedBox(height: 10),
            PetHistoryTile(
              title: 'Grooming',
              icon: Icons.content_cut_outlined,
              ownerID: pet.ownerID, petID: pet.petID,
              collection: 'groom_visits', nameField: 'type',
              onViewAll: () => _push(context, GroomingHistoryView(pet: pet)),
            ),

          ])),
        ),
      ]),
    );
  }

  void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Future<void> _save(PetProfileNotifier notifier) async {
    if (_pendingFields.isEmpty) { notifier.cancelEditMode(); return; }
    try {
      await notifier.saveFields(Map.from(_pendingFields));
      _pendingFields.clear();
      if (mounted) _snack('Changes saved ✓', kGreen);
    } catch (e) {
      if (mounted) _snack('Save failed: $e', kRed);
    }
  }

  void _snack(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
}

// ── Pet Status Card ───────────────────────────────────────────────────────────
class _PetStatusCard extends ConsumerWidget {
  final Pet pet;
  const _PetStatusCard({required this.pet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAlive = pet.isAlive;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kDivider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Status row
        Row(children: [
          const Icon(Icons.favorite_rounded, color: kRed, size: 16),
          const SizedBox(width: 7),
          const Text('Status', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: kNavy, letterSpacing: 0.3)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isAlive
                  ? kGreen.withOpacity(0.1)
                  : kRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isAlive
                  ? kGreen.withOpacity(0.3) : kRed.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                    color: isAlive ? kGreen : kRed,
                    shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(isAlive ? 'Active' : 'Deceased',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: isAlive ? kGreen : kRed)),
            ]),
          ),
        ]),

        // Mark as deceased button — only if alive
        if (isAlive) ...[
          const SizedBox(height: 12),
          const Divider(color: kDivider, height: 1),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _handleMarkDeceased(context, ref),
            child: Row(children: [
              const Icon(Icons.heart_broken_outlined, color: kRed, size: 16),
              const SizedBox(width: 8),
              const Text('Mark as Deceased',
                  style: TextStyle(
                      color: kRed, fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              const Icon(Icons.chevron_right, color: kRed, size: 16),
            ]),
          ),
        ],
      ]),
    );
  }

  Future<void> _handleMarkDeceased(BuildContext context, WidgetRef ref) async {
    // ── Step 1: Initial confirmation ────────────────────
    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF5F2EE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: const [
          Icon(Icons.heart_broken_outlined, color: kRed, size: 20),
          SizedBox(width: 8),
          Text('Mark as Deceased',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        content: Text(
          'Are you sure you want to mark ${pet.name} as deceased?\n\n'
          'This action cannot be undone.',
          style: const TextStyle(fontSize: 13, color: kLabel, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: kLabel))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: kRed, elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Continue',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (step1 != true || !context.mounted) return;

    // ── Step 2: Final warning — no restore ──────────────
    final step2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF5F2EE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: const [
          Icon(Icons.warning_amber_rounded, color: kRed, size: 20),
          SizedBox(width: 8),
          Text('Are you absolutely sure?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kRed.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kRed.withOpacity(0.2)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Icon(Icons.info_outline, color: kRed, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  '${pet.name} will be permanently marked as deceased '
                  'and cannot be restored.',
                  style: const TextStyle(
                      fontSize: 12, color: kRed, height: 1.5))),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Go back', style: TextStyle(color: kLabel))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: kRed, elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Yes, mark as deceased',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (step2 != true || !context.mounted) return;

    // ── Execute ──────────────────────────────────────────
    try {
      await ref.read(petControllerProvider).archivePet(pet.petID);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${pet.name} has been marked as deceased.'),
        backgroundColor: kRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 5, height: 5,
        decoration: const BoxDecoration(color: kBrown, shape: BoxShape.circle)),
    const SizedBox(width: 8),
    Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
        color: kLabel, letterSpacing: 1.5)),
    const SizedBox(width: 10),
    Expanded(child: Container(height: 1, color: kDivider)),
  ]);
}