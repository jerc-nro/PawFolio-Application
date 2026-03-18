import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/pet_model.dart';
import '../../records/providers/record_provider.dart';
import '../../records/widgets/edit_records_dialog.dart';

// ─── ARCHIVE FIELD CONFIG ─────────────────────────────────────────────────────

class ArchiveFieldConfig {
  final String label;
  final String firestoreKey;
  final IconData icon;
  final String fallback;
  final String? prefix;
  final String? suffix;

  const ArchiveFieldConfig({
    required this.label,
    required this.firestoreKey,
    required this.icon,
    this.fallback = 'N/A',
    this.prefix,
    this.suffix,
  });
}

class ArchivePageConfig {
  final String pageTitle;
  final String collection;
  final String primaryKey;
  final String primaryFallback;
  final String? subtitleKey;
  final String? statusKey;
  final List<ArchiveFieldConfig> fields;
  final EditDialogConfig? editConfig; // nullable — weight uses inline edit

  const ArchivePageConfig({
    required this.pageTitle,
    required this.collection,
    required this.primaryKey,
    this.primaryFallback = 'Record',
    this.subtitleKey,
    this.statusKey,
    required this.fields,
    this.editConfig,
  });
}

// ─── PRESET CONFIGS ───────────────────────────────────────────────────────────

const medicationArchiveConfig = ArchivePageConfig(
  pageTitle: 'MEDICATIONS',
  collection: 'medications',
  primaryKey: 'medication_name',
  primaryFallback: 'Generic Medication',
  subtitleKey: 'type',
  statusKey: 'status',
  editConfig: medicationEditConfig,
  fields: [
    ArchiveFieldConfig(label: 'START DATE',   firestoreKey: 'start_date',   icon: Icons.calendar_today,          fallback: 'N/A'),
    ArchiveFieldConfig(label: 'DOSAGE',       firestoreKey: 'dosage',       icon: Icons.medication_outlined,     fallback: 'N/A'),
    ArchiveFieldConfig(label: 'PET WEIGHT',   firestoreKey: 'pet_weight',   icon: Icons.monitor_weight_outlined, fallback: 'N/A', suffix: 'kg'),
    ArchiveFieldConfig(label: 'CLINIC',       firestoreKey: 'clinic_name',  icon: Icons.local_hospital_outlined, fallback: 'Not specified'),
    ArchiveFieldConfig(label: 'VETERINARIAN', firestoreKey: 'veterinarian', icon: Icons.person_outline,          fallback: '', prefix: 'Dr.'),
  ],
);

const vetVisitArchiveConfig = ArchivePageConfig(
  pageTitle: 'VET VISITS',
  collection: 'vet_visits',
  primaryKey: 'reason',
  primaryFallback: 'Vet Visit',
  statusKey: 'status',
  editConfig: vetVisitEditConfig,
  fields: [
    ArchiveFieldConfig(label: 'DATE',         firestoreKey: 'date_string',  icon: Icons.calendar_today,          fallback: 'N/A'),
    ArchiveFieldConfig(label: 'TIME',         firestoreKey: 'time',         icon: Icons.access_time,             fallback: 'N/A'),
    ArchiveFieldConfig(label: 'CLINIC',       firestoreKey: 'clinic_name',  icon: Icons.local_hospital_outlined, fallback: 'Not specified'),
    ArchiveFieldConfig(label: 'VETERINARIAN', firestoreKey: 'veterinarian', icon: Icons.person_outline,          fallback: 'N/A', prefix: 'Dr.'),
    ArchiveFieldConfig(label: 'NOTES',        firestoreKey: 'description',  icon: Icons.notes_outlined,          fallback: 'None'),
  ],
);

const groomingArchiveConfig = ArchivePageConfig(
  pageTitle: 'GROOMING',
  collection: 'groom_visits',
  primaryKey: 'type',
  primaryFallback: 'Grooming Session',
  statusKey: 'status',
  editConfig: groomingEditConfig,
  fields: [
    ArchiveFieldConfig(label: 'DATE',     firestoreKey: 'date_string', icon: Icons.calendar_today, fallback: 'N/A'),
    ArchiveFieldConfig(label: 'PROVIDER', firestoreKey: 'provider',   icon: Icons.store_outlined,  fallback: 'Not specified'),
  ],
);

const vaccinationArchiveConfig = ArchivePageConfig(
  pageTitle: 'VACCINATIONS',
  collection: 'vaccinations',
  primaryKey: 'vaccine_name',
  primaryFallback: 'Vaccination',
  subtitleKey: 'vaccine_type',
  statusKey: 'status',
  editConfig: vaccinationEditConfig,
  fields: [
    ArchiveFieldConfig(label: 'DATE GIVEN',   firestoreKey: 'date_string',  icon: Icons.calendar_today,          fallback: 'N/A'),
    ArchiveFieldConfig(label: 'TIME',         firestoreKey: 'time_string',  icon: Icons.access_time,             fallback: 'N/A'),
    ArchiveFieldConfig(label: 'CLINIC',       firestoreKey: 'clinic_name',  icon: Icons.local_hospital_outlined, fallback: 'Not specified'),
    ArchiveFieldConfig(label: 'VETERINARIAN', firestoreKey: 'veterinarian', icon: Icons.person_outline,          fallback: 'N/A', prefix: 'Dr.'),
  ],
);

const preventativeArchiveConfig = ArchivePageConfig(
  pageTitle: 'PREVENTATIVES',
  collection: 'preventatives',
  primaryKey: 'brand_name',
  primaryFallback: 'Generic Preventative',
  subtitleKey: 'type',
  statusKey: 'status',
  editConfig: preventativeEditConfig,
  fields: [
    ArchiveFieldConfig(label: 'SCHEDULED DATE', firestoreKey: 'date_string',  icon: Icons.calendar_today,          fallback: 'N/A'),
    ArchiveFieldConfig(label: 'INTAKE TIME',     firestoreKey: 'intake_time',  icon: Icons.access_time,             fallback: 'N/A'),
    ArchiveFieldConfig(label: 'DOSAGE',          firestoreKey: 'dosage',       icon: Icons.medication_outlined,     fallback: 'N/A'),
    ArchiveFieldConfig(label: 'CLINIC',          firestoreKey: 'clinic_name',  icon: Icons.local_hospital_outlined, fallback: 'Not specified'),
    ArchiveFieldConfig(label: 'VETERINARIAN',    firestoreKey: 'veterinarian', icon: Icons.person_outline,          fallback: '', prefix: 'Dr.'),
  ],
);

/// Weight archive — no editConfig needed (weight uses its own edit dialog).
const weightArchiveConfig = ArchivePageConfig(
  pageTitle: 'WEIGHT',
  collection: 'weight_history',
  primaryKey: 'weight',
  primaryFallback: 'Weight Entry',
  // No statusKey — weight entries have no status
  fields: [
    ArchiveFieldConfig(
      label: 'DATE',
      firestoreKey: 'date_string',
      icon: Icons.calendar_today,
      fallback: 'N/A',
    ),
    ArchiveFieldConfig(
      label: 'WEIGHT',
      firestoreKey: 'weight',
      icon: Icons.monitor_weight_outlined,
      fallback: 'N/A',
      suffix: 'kg',
    ),
    ArchiveFieldConfig(
      label: 'UNIT',
      firestoreKey: 'unit',
      icon: Icons.straighten_outlined,
      fallback: 'kg',
    ),
    ArchiveFieldConfig(
      label: 'NOTES',
      firestoreKey: 'notes',
      icon: Icons.notes_outlined,
      fallback: 'None',
    ),
  ],
);

// ─── PAGE ─────────────────────────────────────────────────────────────────────

class ArchivedRecordsPage extends ConsumerWidget {
  final Pet pet;
  final String uid;
  final ArchivePageConfig config;

  const ArchivedRecordsPage({
    super.key,
    required this.pet,
    required this.uid,
    required this.config,
  });

  static const Color navBlue        = Color(0xFF455A64);
  static const Color accentBeige    = Color(0xFFD7CCC8);
  static const Color containerBeige = Color(0xFFEFEBE9);
  static const Color archivedGrey   = Color(0xFF90A4AE);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: accentBeige,
      body: Column(
        children: [
          SafeArea(child: _buildHeader(context)),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: containerBeige,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(children: [
                const SizedBox(height: 20),
                _buildSubtitle(),
                const SizedBox(height: 10),
                Expanded(child: _buildStream(context, ref)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── LOGIC ──────────────────────────────────────────────────────────────────

  void _handleEdit(BuildContext context, Map<String, dynamic> data, String docId) {
    // Weight entries use their own edit dialog; other categories use editConfig
    if (config.collection == 'weight_history') {
      // Weight archive entries are read-only in the archive
      // (editing is done from WeightHistoryView before archiving)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restore the entry to edit it.')),
      );
      return;
    }
    if (config.editConfig == null) return;
    showEditRecordDialog(
      context,
      uid: uid,
      petId: pet.petID,
      docId: docId,
      config: config.editConfig!,
      existingData: data,
    );
  }

  Future<void> _handleRestore(
      BuildContext context, WidgetRef ref, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Restore Record',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Move this record back to the active list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('RESTORE',
                style: TextStyle(
                    color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('pets').doc(pet.petID)
          .collection(config.collection).doc(docId)
          .update({'is_archived': false});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record restored to active list')),
        );
      }
    }
  }

  Future<void> _handleDelete(
      BuildContext context, WidgetRef ref, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Permanently Delete',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'This will permanently delete the record and cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE FOREVER',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      if (config.collection == 'weight_history') {
        // Use weight-specific delete so the pet doc weight is restored
        await ref.read(recordControllerProvider.notifier).deleteWeightRecord(
          petId: pet.petID,
          recordId: docId,
        );
      } else {
        await ref.read(recordControllerProvider.notifier).deleteRecord(
          petId: pet.petID,
          collection: config.collection,
          recordId: docId,
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record permanently deleted')),
        );
      }
    }
  }

  // ── STREAM ─────────────────────────────────────────────────────────────────

  Widget _buildStream(BuildContext context, WidgetRef ref) {
    final query = FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('pets').doc(pet.petID)
        .collection(config.collection)
        .where('is_archived', isEqualTo: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading archived records.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState();

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 30),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data  = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            return _buildCard(context, ref, data, docId);
          },
        );
      },
    );
  }

  // ── CARD ───────────────────────────────────────────────────────────────────

  Widget _buildCard(
    BuildContext context, WidgetRef ref,
    Map<String, dynamic> data, String docId,
  ) {
    final extra  = data['extra'] as Map<String, dynamic>? ?? {};
    final merged = {...data, ...extra};

    // Weight: show "X kg" as the title
    final String title;
    if (config.collection == 'weight_history') {
      final w = (merged['weight'] as num?)?.toDouble();
      final u = merged['unit'] ?? 'kg';
      title = w != null ? '$w $u' : config.primaryFallback;
    } else {
      title = (merged[config.primaryKey] ?? config.primaryFallback).toString();
    }

    final subtitle = config.subtitleKey != null
        ? (merged[config.subtitleKey!] ?? '').toString().toUpperCase()
        : '';
    final status = config.statusKey != null
        ? (merged[config.statusKey!] ?? '').toString().toUpperCase()
        : '';

    String resolveValue(ArchiveFieldConfig f) {
      final raw = merged[f.firestoreKey];
      if (raw == null || raw.toString().isEmpty) return f.fallback;
      final val        = raw.toString();
      final withPrefix = f.prefix != null ? '${f.prefix} $val' : val;
      return f.suffix != null ? '$withPrefix ${f.suffix}' : withPrefix;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: archivedGrey.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blueGrey[400])),
                    if (subtitle.isNotEmpty)
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.blueGrey[300],
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5)),
                  ],
                ),
              ),
              Row(
                children: [
                  _archivedBadge(),
                  const SizedBox(width: 2),
                  // Edit — disabled for weight (restore first)
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    tooltip: config.collection == 'weight_history'
                        ? 'Restore to edit'
                        : 'Edit',
                    icon: Icon(
                      Icons.edit_outlined,
                      color: config.collection == 'weight_history'
                          ? Colors.grey.shade400
                          : navBlue,
                      size: 20,
                    ),
                    onPressed: () => _handleEdit(context, data, docId),
                  ),
                  // Restore
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    tooltip: 'Restore to active',
                    icon: const Icon(Icons.unarchive_outlined,
                        color: Color(0xFF2E7D32), size: 20),
                    onPressed: () => _handleRestore(context, ref, docId),
                  ),
                  // Permanent delete
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    tooltip: 'Delete permanently',
                    icon: const Icon(Icons.delete_forever_outlined,
                        color: Colors.redAccent, size: 20),
                    onPressed: () => _handleDelete(context, ref, docId),
                  ),
                ],
              ),
            ],
          ),

          const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, thickness: 0.5)),

          // ── Dynamic fields in rows of 2 ───────────────────────────────
          ...List.generate((config.fields.length / 2).ceil(), (rowIndex) {
            final left  = config.fields[rowIndex * 2];
            final right = (rowIndex * 2 + 1 < config.fields.length)
                ? config.fields[rowIndex * 2 + 1]
                : null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Expanded(
                    child: _infoTile(left.label, resolveValue(left),
                        icon: left.icon)),
                if (right != null)
                  Expanded(
                      child: _infoTile(right.label, resolveValue(right),
                          icon: right.icon)),
              ]),
            );
          }),

          // ── Previous status note ──────────────────────────────────────
          if (status.isNotEmpty)
            Row(children: [
              Icon(Icons.info_outline, size: 13, color: Colors.blueGrey[300]),
              const SizedBox(width: 6),
              Text('Was $status before archiving',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.blueGrey[300],
                      fontStyle: FontStyle.italic)),
            ]),
        ],
      ),
    );
  }

  // ── UI HELPERS ─────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ARCHIVED',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: navBlue,
                    letterSpacing: 1.0)),
            Text(config.pageTitle,
                style: TextStyle(
                    fontSize: 12,
                    color: navBlue.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
          ]),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const CircleAvatar(
                backgroundColor: navBlue,
                child: Icon(Icons.arrow_back, color: Colors.white, size: 20)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: [
        Icon(Icons.info_outline, size: 14, color: archivedGrey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Edit, restore, or permanently delete archived records.',
            style: TextStyle(
                fontSize: 11,
                color: archivedGrey,
                fontWeight: FontWeight.w500),
          ),
        ),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inventory_2_outlined, size: 56, color: Colors.blueGrey[200]),
        const SizedBox(height: 12),
        Text('No archived ${config.pageTitle.toLowerCase()}',
            style: TextStyle(
                color: Colors.blueGrey[300],
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        const SizedBox(height: 4),
        Text('Records you archive will appear here.',
            style: TextStyle(color: Colors.blueGrey[200], fontSize: 12)),
      ]),
    );
  }

  Widget _archivedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: archivedGrey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: archivedGrey, width: 1)),
      child: const Text('ARCHIVED',
          style: TextStyle(
              color: archivedGrey,
              fontSize: 9,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _infoTile(String label, String value, {IconData? icon}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null)
          Icon(icon, size: 15, color: const Color(0xFF0277BD).withOpacity(0.5)),
        const SizedBox(width: 8),
        Flexible(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 9,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
            Text(value,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey[300],
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      ],
    );
  }
}