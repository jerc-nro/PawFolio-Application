import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GlobalPreviewSection extends StatelessWidget {
  final String title;
  final String collectionId;
  final IconData icon;
  final String? uid;
  final String currentFilter;

  const GlobalPreviewSection({
    super.key,
    required this.title,
    required this.collectionId,
    required this.icon,
    this.uid,
    required this.currentFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFC7C1BA),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Urgent $title",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black12, offset: Offset(0, 2), blurRadius: 4)
                  ],
                ),
              ),
              _buildSmallFilterUI(),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: uid == null ? null : _getFilteredStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: LinearProgressIndicator(
                    color: Colors.white54,
                    backgroundColor: Colors.transparent,
                  ),
                );
              }

              if (snapshot.hasError) {
                return const Text(
                  "Error loading records",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              
              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "No upcoming $title found.",
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  return _buildRecordListItem(doc.data() as Map<String, dynamic>);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredStream() {
    final now = DateTime.now();
    // Normalizing to start of today to include all today's events
    final startOfToday = DateTime(now.year, now.month, now.day);

    Query query = FirebaseFirestore.instance
        .collectionGroup(collectionId)
        .where('userID', isEqualTo: uid) // Ensure this matches your Firestore field key
        .where('date_timestamp', isGreaterThanOrEqualTo: startOfToday);

    if (currentFilter != 'ALL') {
      query = query.where('petType', isEqualTo: currentFilter.toUpperCase());
    }

    return query.orderBy('date_timestamp', descending: false).limit(3).snapshots();
  }

  Widget _buildRecordListItem(Map<String, dynamic> data) {
    final DateTime? recordDate = (data['date_timestamp'] as Timestamp?)?.toDate();
    final now = DateTime.now();
    
    final bool isToday = recordDate != null &&
        recordDate.day == now.day &&
        recordDate.month == now.month &&
        recordDate.year == now.year;

    // Dynamically choose label based on what data exists in the doc
    String primaryInfo = data['vaccine_name'] ?? 
                         data['reason'] ?? 
                         data['medication_name'] ?? 
                         data['service_type'] ?? "Record";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: (isToday ? Colors.orange : const Color(0xFF8A9A7B)).withOpacity(0.15),
            child: Icon(icon, size: 20, color: isToday ? Colors.orange : const Color(0xFF8A9A7B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      data['petName']?.toString().toUpperCase() ?? "PET",
                      style: const TextStyle(
                        fontSize: 10, 
                        color: Colors.grey, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(isToday),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  primaryInfo,
                  style: const TextStyle(
                    fontSize: 15, 
                    fontWeight: FontWeight.bold, 
                    color: Color(0xFF4A5568)
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data['date_string'] ?? 'N/A',
                style: const TextStyle(
                  color: Color(0xFF8A9A7B), 
                  fontWeight: FontWeight.bold, 
                  fontSize: 11
                ),
              ),
              const Text(
                "DUE DATE",
                style: TextStyle(fontSize: 7, color: Colors.black26, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isToday) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isToday ? Colors.orange : Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isToday ? "TODAY" : "UPCOMING",
        style: TextStyle(
          fontSize: 8, 
          fontWeight: FontWeight.w900, 
          color: isToday ? Colors.orange : Colors.blue
        ),
      ),
    );
  }

  Widget _buildSmallFilterUI() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4A6572),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        currentFilter,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}