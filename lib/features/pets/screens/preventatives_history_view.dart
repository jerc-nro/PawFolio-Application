import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawfolio/features/auth/providers/auth_provider.dart';

import '../../../models/pet_model.dart';
import '../../records/providers/record_provider.dart';
import '../../records/widgets/add_preventative_dialog.dart';
import '../../records/widgets/status_filter_row.dart';
import '../../records/widgets/edit_records_dialog.dart';
import '../../records/screen/archived_records_page.dart';

final preventativeFilterProvider =
    StateProvider.autoDispose<String>((ref) => "ALL");

class PreventativesHistoryView extends ConsumerWidget {
  final Pet pet;
  const PreventativesHistoryView({super.key, required this.pet});

  static const Color navBlue            = Color(0xFF455A64);
  static const Color accentBeige        = Color(0xFFD7CCC8);
  static const Color listContainerBeige = Color(0xFFEFEBE9);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(preventativeFilterProvider);
    final screenWidth   = MediaQuery.of(context).size.width;
    final uid           = ref.watch(authProvider).user?.userID;

    return Scaffold(
      backgroundColor: accentBeige,
      body: Column(
        children: [
          SafeArea(child: Column(children: [
            const SizedBox(height: 10),
            _buildHeader(context),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.06, vertical: 15),
              child: _petProfileCard(),
            ),
          ])),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: listContainerBeige,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: [
                  const SizedBox(height: 20),
                  StatusFilterRow(
                    selectedStatus: currentFilter,
                    onStatusSelected: (s) => ref
                        .read(preventativeFilterProvider.notifier)
                        .state = s,
                  ),
                  const SizedBox(height: 10),
                  _buildActionRow(context, ref, uid),
                  const SizedBox(height: 15),
                  Expanded(
                      child: _buildStream(
                          context, ref, uid, currentFilter)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleEdit(BuildContext context, String uid, String docId,
      Map<String, dynamic> data) {
    showEditRecordDialog(context,
        uid: uid,
        petId: pet.petID,
        docId: docId,
        config: preventativeEditConfig,
        existingData: data);
  }

  void _handleArchive(
      BuildContext context, WidgetRef ref, String docId) async {
    if (pet.isArchived) return;
    final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text("Archive Record",
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text(
                "This record will be moved to the archive. You can restore or permanently delete it from there."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("CANCEL",
                      style: TextStyle(color: Colors.grey))),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("ARCHIVE",
                      style: TextStyle(
                          color: navBlue,
                          fontWeight: FontWeight.bold))),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await ref.read(recordControllerProvider.notifier).archiveRecord(
          petId: pet.petID,
          collection: 'preventatives',
          recordId: docId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Preventative record archived"),
            duration: Duration(seconds: 3)));
      }
    }
  }

  Widget _buildActionRow(
      BuildContext context, WidgetRef ref, String? uid) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: uid == null
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ArchivedRecordsPage(
                          pet: pet,
                          uid: uid,
                          config: preventativeArchiveConfig))),
          child: _viewArchiveButton(),
        ),
        if (pet.isArchived)
          const Text("READ ONLY (ARCHIVED)",
              style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 10))
        else
          ElevatedButton.icon(
            onPressed: () => showAddPreventativeDialog(
                context, pet.petID, pet.name, pet.type),
            icon: const Icon(Icons.shield, size: 18),
            label: const Text("ADD PREVENTATIVE"),
            style: ElevatedButton.styleFrom(
              backgroundColor: navBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
      ],
    );
  }

  Widget _buildStream(BuildContext context, WidgetRef ref,
      String? uid, String currentFilter) {
    if (uid == null) return const Center(child: Text("Please log in."));

    // INDEX: date_timestamp DESC, status ASC  → used when filter = ALL
    // INDEX: is_archived ASC, status ASC, date_timestamp DESC → used when filtered
    Query query = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('pets')
        .doc(pet.petID)
        .collection('preventatives')
        .orderBy('date_timestamp', descending: true);

    if (currentFilter != "ALL") {
      query = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('pets')
          .doc(pet.petID)
          .collection('preventatives')
          .where('is_archived', isEqualTo: false)
          .where('status', isEqualTo: currentFilter)
          .orderBy('date_timestamp', descending: true);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Preventatives error: ${snapshot.error}');
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs ?? [];
        final docs = currentFilter == "ALL"
            ? allDocs
                .where((d) =>
                    (d.data() as Map<String, dynamic>)['is_archived'] !=
                    true)
                .toList()
            : allDocs;

        if (docs.isEmpty) {
          return const Center(
              child: Text("No records found.",
                  style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data  = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            final extra =
                data['extra'] as Map<String, dynamic>? ?? {};
            return _preventativeItem(context, ref,
              uid: uid, docId: docId, data: data,
              brand: extra['brand_name'] ??
                  data['brand_name'] ?? 'Generic',
              type: extra['type'] ?? data['type'] ?? 'Preventative',
              status: (data['status'] ?? 'UPCOMING')
                  .toString().toUpperCase(),
              date: data['date_string'] ?? 'N/A',
              time: extra['time'] ?? data['intake_time'] ?? 'N/A',
              dosage: extra['dosage'] ?? data['dosage'] ?? 'N/A',
              clinic: extra['clinic_name'] ??
                  data['clinic_name'] ?? 'Not specified',
              vet: extra['veterinarian'] ?? data['veterinarian'] ?? '',
            );
          },
        );
      },
    );
  }

  Widget _preventativeItem(BuildContext context, WidgetRef ref, {
    required String uid, required String docId,
    required Map<String, dynamic> data,
    required String brand, required String type,
    required String status, required String date,
    required String time, required String dosage,
    required String clinic, required String vet,
  }) {
    Color statusColor;
    switch (status) {
      case 'UPCOMING':  statusColor = const Color(0xFFFFB300); break;
      case 'ONGOING':   statusColor = const Color(0xFFD32F2F); break;
      case 'COMPLETED': statusColor = const Color(0xFF008000); break;
      default:          statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(brand, style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 17,
                color: Color(0xFF263238))),
            Text(type.toUpperCase(), style: TextStyle(
                fontSize: 10, color: Colors.blueGrey[400],
                fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ])),
          Row(children: [
            _statusBadge(status, statusColor),
            if (!pet.isArchived) ...[
              const SizedBox(width: 4),
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero, tooltip: "Edit",
                icon: const Icon(Icons.edit_outlined,
                    color: navBlue, size: 20),
                onPressed: () =>
                    _handleEdit(context, uid, docId, data),
              ),
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero, tooltip: "Archive",
                icon: const Icon(Icons.inventory_2_outlined,
                    color: Color(0xFF78909C), size: 20),
                onPressed: () =>
                    _handleArchive(context, ref, docId),
              ),
            ],
          ]),
        ]),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, thickness: 0.5)),
        Row(children: [
          Expanded(child: _infoTile("SCHEDULED DATE", date,
              icon: Icons.calendar_today)),
          Expanded(child: _infoTile("INTAKE TIME", time,
              icon: Icons.access_time)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _infoTile("DOSAGE", dosage,
              icon: Icons.medication_outlined)),
          Expanded(child: _infoTile("CLINIC", clinic,
              icon: Icons.local_hospital_outlined)),
        ]),
        if (vet.isNotEmpty) ...[
          const SizedBox(height: 12),
          _infoTile("VETERINARIAN",
              vet.startsWith('Dr.') ? vet : "Dr. $vet",
              icon: Icons.person_outline),
        ],
      ]),
    );
  }

  Widget _buildHeader(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const CircleAvatar(
                  backgroundColor: navBlue, radius: 18,
                  child: Icon(Icons.arrow_back,
                      color: Colors.white, size: 18)),
            ),
            const Expanded(
              child: Text("PREVENTATIVES",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: navBlue,
                      letterSpacing: 1.0)),
            ),
            IconButton(
              onPressed: () => Navigator.of(context)
                  .popUntil((route) => route.isFirst),
              icon: const CircleAvatar(
                  backgroundColor: navBlue, radius: 18,
                  child: Icon(Icons.home_outlined,
                      color: Colors.white, size: 18)),
            ),
          ],
        ),
      );

  Widget _petProfileCard() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFF546E7A),
            borderRadius: BorderRadius.circular(25)),
        child: Row(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
                color: const Color(0xFF8D8D76),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white, width: 2)),
            child: const Icon(Icons.pets,
                color: Colors.white, size: 25)),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(pet.name, style: const TextStyle(
                color: Colors.white, fontSize: 16,
                fontWeight: FontWeight.bold)),
            Text(pet.breed, style: const TextStyle(
                color: Colors.white70, fontSize: 12)),
          ]),
        ]),
      );

  Widget _viewArchiveButton() => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: navBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: navBlue.withValues(alpha: 0.25), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.inventory_2_outlined,
              size: 14, color: navBlue.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Text("VIEW ARCHIVE",
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold,
                  color: navBlue.withValues(alpha: 0.7),
                  letterSpacing: 0.5)),
        ]),
      );

  Widget _infoTile(String label, String value,
          {IconData? icon}) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Icon(icon,
                size: 15,
                color: const Color(0xFF0277BD)
                    .withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 9,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
              Text(value.isEmpty ? "Not specified" : value,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF455A64),
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
            ]),
          ),
        ],
      );

  Widget _statusBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 1)),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold)),
      );
}