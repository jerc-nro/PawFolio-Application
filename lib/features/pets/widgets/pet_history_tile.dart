import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '_pet_profile_shared.dart';

class PetHistoryTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String ownerID, petID, collection, nameField;
  final VoidCallback onViewAll;

  const PetHistoryTile({
    super.key,
    required this.title, required this.icon,
    required this.ownerID, required this.petID,
    required this.collection, required this.nameField,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kDivider),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: const Color(0xFFF5EFEB),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: kBrown, size: 18)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        children: [_HistoryStream(
          ownerID: ownerID, petID: petID,
          collection: collection, nameField: nameField,
          onViewAll: onViewAll,
        )],
      ),
    );
  }
}

class _HistoryStream extends StatelessWidget {
  final String ownerID, petID, collection, nameField;
  final VoidCallback onViewAll;

  const _HistoryStream({
    required this.ownerID, required this.petID,
    required this.collection, required this.nameField,
    required this.onViewAll,
  });

  Color _statusColor(String s) => switch (s.toLowerCase()) {
    'done' || 'completed' => kGreen,
    'ongoing'   => const Color(0xFFE09B3D),
    'overdue'   => kRed,
    _           => kLabel,
  };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users').doc(ownerID)
          .collection('pets').doc(petID)
          .collection(collection)
          .orderBy('date_timestamp', descending: true)
          .limit(3)
          .snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
              padding: EdgeInsets.all(12),
              child: LinearProgressIndicator(color: kNavy));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text('No records yet.',
                style: TextStyle(color: kLabel, fontSize: 13)));
        }
        return Column(children: [
          ...docs.map((doc) {
            final d      = doc.data() as Map<String, dynamic>;
            final name   = d[nameField]?.toString() ?? 'Record';
            final date   = d['date_string']?.toString() ?? '';
            final status = d['status']?.toString() ?? '';
            return ListTile(
              dense: true,
              title: Text(name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              subtitle: Text(date,
                  style: const TextStyle(fontSize: 11, color: kLabel)),
              trailing: status.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _statusColor(status).withOpacity(0.3)),
                      ),
                      child: Text(status,
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700,
                              color: _statusColor(status))),
                    )
                  : const Icon(Icons.chevron_right, size: 16, color: kLabel),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextButton(
              onPressed: onViewAll,
              child: const Text('VIEW ALL',
                  style: TextStyle(color: kNavy,
                      fontWeight: FontWeight.bold,
                      fontSize: 12, letterSpacing: 0.5))),
          ),
        ]);
      },
    );
  }
}