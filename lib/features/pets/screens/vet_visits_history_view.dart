import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawfolio/features/auth/providers/auth_provider.dart';

import '../../../models/pet_model.dart';
import '../../records/providers/record_provider.dart';
import '../../records/widgets/add_vet_visit_dialog.dart';
import '../../records/widgets/status_filter_row.dart';
import '../../records/widgets/edit_records_dialog.dart';
import '../../records/screen/archived_records_page.dart';

final vetVisitFilterProvider = StateProvider.autoDispose<String>((ref) => "ALL");

class VetVisitsHistoryView extends ConsumerWidget {
  final Pet pet;
  const VetVisitsHistoryView({super.key, required this.pet});

  static const Color navBlue            = Color(0xFF455A64);
  static const Color accentBeige        = Color(0xFFD7CCC8);
  static const Color listContainerBeige = Color(0xFFEFEBE9);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(vetVisitFilterProvider);
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
                    topLeft: Radius.circular(40), topRight: Radius.circular(40)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: [
                  const SizedBox(height: 20),
                  StatusFilterRow(
                    selectedStatus: currentFilter,
                    onStatusSelected: (s) =>
                        ref.read(vetVisitFilterProvider.notifier).state = s,
                  ),
                  const SizedBox(height: 10),
                  _buildActionRow(context, ref, uid),
                  const SizedBox(height: 15),
                  Expanded(child: _buildStream(context, ref, uid, currentFilter)),
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
        uid: uid, petId: pet.petID, docId: docId,
        config: vetVisitEditConfig, existingData: data);
  }

  void _handleArchive(BuildContext context, WidgetRef ref, String docId) async {
    if (pet.isArchived) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Archive Record",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            "This record will be moved to the archive. You can restore or permanently delete it from there."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text("ARCHIVE",
                  style: TextStyle(color: navBlue, fontWeight: FontWeight.bold))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await ref.read(recordControllerProvider.notifier).archiveRecord(
          petId: pet.petID, collection: 'vet_visits', recordId: docId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vet visit record archived")));
      }
    }
  }

  Widget _buildActionRow(BuildContext context, WidgetRef ref, String? uid) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: uid == null ? null : () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ArchivedRecordsPage(
                  pet: pet, uid: uid, config: vetVisitArchiveConfig))),
          child: _viewArchiveButton(),
        ),
        if (pet.isArchived)
          const Text("READ ONLY (ARCHIVED)",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10))
        else
          ElevatedButton.icon(
            onPressed: () =>
                showAddVetVisitDialog(context, pet.petID, pet.name, pet.type),
            icon: const Icon(Icons.local_hospital_outlined, size: 18),
            label: const Text("ADD VET VISIT"),
            style: ElevatedButton.styleFrom(
              backgroundColor: navBlue, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
      ],
    );
  }

  Widget _buildStream(BuildContext context, WidgetRef ref, String? uid,
      String currentFilter) {
    if (uid == null) return const Center(child: Text("Please log in."));

    Query query = FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('pets').doc(pet.petID)
        .collection('vet_visits')
        .where('is_archived', isEqualTo: false);

    if (currentFilter != "ALL") {
      query = query.where('status', isEqualTo: currentFilter);
    } else {
      query = query.orderBy('date_timestamp', descending: true);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty)
          return const Center(child: Text("No records found.",
              style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data  = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            final extra = data['extra'] as Map<String, dynamic>? ?? {};

            return _visitItem(context, ref,
              uid: uid, docId: docId, data: data,
              reason: extra['reason'] ?? data['reason'] ?? 'Routine Checkup',
              clinic: extra['clinic_name'] ?? data['clinic_name'] ?? 'Not specified',
              vet: extra['veterinarian'] ?? data['veterinarian'] ?? '',
              date: data['date_string'] ?? 'N/A',
              time: extra['time'] ?? data['time'] ?? 'N/A',
              desc: extra['description'] ?? data['description'] ?? 'No notes provided.',
              status: (data['status'] ?? 'UPCOMING').toString().toUpperCase(),
            );
          },
        );
      },
    );
  }

  Widget _visitItem(BuildContext context, WidgetRef ref, {
    required String uid, required String docId, required Map<String, dynamic> data,
    required String reason, required String clinic, required String vet,
    required String date, required String time, required String desc, required String status,
  }) {
    Color statusColor;
    switch (status) {
      case 'COMPLETED': statusColor = const Color(0xFF008000); break;
      case 'ONGOING':   statusColor = Colors.redAccent; break;
      default:          statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(reason, style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF263238))),
            Text("MEDICAL VISIT", style: TextStyle(
                fontSize: 10, color: Colors.blueGrey[400],
                fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ])),
          Row(children: [
            _statusBadge(status, statusColor),
            if (!pet.isArchived) ...[
              const SizedBox(width: 4),
              IconButton(
                constraints: const BoxConstraints(), padding: EdgeInsets.zero,
                tooltip: "Edit",
                icon: const Icon(Icons.edit_outlined, color: navBlue, size: 20),
                onPressed: () => _handleEdit(context, uid, docId, data),
              ),
              IconButton(
                constraints: const BoxConstraints(), padding: EdgeInsets.zero,
                tooltip: "Archive",
                icon: const Icon(Icons.inventory_2_outlined,
                    color: Color(0xFF78909C), size: 20),
                onPressed: () => _handleArchive(context, ref, docId),
              ),
            ],
          ]),
        ]),
        const Padding(padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, thickness: 0.5)),
        Row(children: [
          Expanded(child: _infoTile("VISIT DATE", date, icon: Icons.calendar_today)),
          Expanded(child: _infoTile("VISIT TIME", time, icon: Icons.access_time)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _infoTile("CLINIC", clinic, icon: Icons.local_hospital_outlined)),
          if (vet.isNotEmpty)
            Expanded(child: _infoTile("VETERINARIAN",
                vet.startsWith('Dr.') ? vet : "Dr. $vet", icon: Icons.person_outline)),
        ]),
        const SizedBox(height: 12),
        _infoTile("NOTES", desc, icon: Icons.notes_outlined),
      ]),
    );
  }

  Widget _viewArchiveButton() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: navBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: navBlue.withOpacity(0.25), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.inventory_2_outlined, size: 14, color: navBlue.withOpacity(0.7)),
          const SizedBox(width: 6),
          Text("VIEW ARCHIVE", style: TextStyle(fontSize: 11,
              fontWeight: FontWeight.bold, color: navBlue.withOpacity(0.7),
              letterSpacing: 0.5)),
        ]),
      );

  Widget _infoTile(String label, String value, {IconData? icon}) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) Icon(icon, size: 15, color: navBlue.withOpacity(0.6)),
          const SizedBox(width: 8),
          Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey,
                fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            Text(value.isEmpty ? "Not specified" : value,
                style: const TextStyle(fontSize: 12, color: navBlue,
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.visible),
          ])),
        ],
      );

  Widget _buildHeader(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("VET VISITS", style: TextStyle(fontSize: 20,
              fontWeight: FontWeight.w900, color: navBlue, letterSpacing: 1.0)),
          IconButton(onPressed: () => Navigator.pop(context),
              icon: const CircleAvatar(backgroundColor: navBlue,
                  child: Icon(Icons.arrow_back, color: Colors.white, size: 20))),
        ]),
      );

  Widget _petProfileCard() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF546E7A),
            borderRadius: BorderRadius.circular(25)),
        child: Row(children: [
          Container(width: 50, height: 50,
              decoration: BoxDecoration(color: const Color(0xFF8D8D76),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white, width: 2)),
              child: const Icon(Icons.pets, color: Colors.white, size: 25)),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pet.name, style: const TextStyle(color: Colors.white,
                fontSize: 16, fontWeight: FontWeight.bold)),
            Text(pet.breed,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ]),
      );

  Widget _statusBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 1)),
        child: Text(label, style: TextStyle(
            color: color, fontSize: 9, fontWeight: FontWeight.bold)),
      );
}