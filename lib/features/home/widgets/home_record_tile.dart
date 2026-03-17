import 'package:flutter/material.dart';
import '../../../models/record_model.dart';

class HomeRecordTile extends StatelessWidget {
  final PetRecord record;
  const HomeRecordTile({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _iconBg(record.category),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon(record.category),
                color: _iconColor(record.category), size: 20),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.title,
                    style: const TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 14, color: Color(0xFF2D3A4A))),
                const SizedBox(height: 2),
                Text('${record.petName} · ${record.dateString}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
              ],
            ),
          ),
          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusBg(record.status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(record.status,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: _statusColor(record.status))),
          ),
        ],
      ),
    );
  }

  IconData _icon(String cat) => switch (cat) {
    'Vaccination'  => Icons.verified_outlined,
    'Medication'   => Icons.science_outlined,
    'Vet Visit'    => Icons.local_hospital_outlined,
    'Grooming'     => Icons.content_cut_outlined,
    'Preventative' => Icons.shield_outlined,
    _              => Icons.medical_services_outlined,
  };

  Color _iconBg(String cat) => switch (cat) {
    'Vaccination'  => const Color(0xFFE8F5E9),
    'Medication'   => const Color(0xFFFFF3E0),
    'Vet Visit'    => const Color(0xFFE3F2FD),
    'Grooming'     => const Color(0xFFF3E5F5),
    'Preventative' => const Color(0xFFE8EAF6),
    _              => const Color(0xFFF5F5F5),
  };

  Color _iconColor(String cat) => switch (cat) {
    'Vaccination'  => const Color(0xFF4CAF50),
    'Medication'   => const Color(0xFFFF9800),
    'Vet Visit'    => const Color(0xFF2196F3),
    'Grooming'     => const Color(0xFF9C27B0),
    'Preventative' => const Color(0xFF3F51B5),
    _              => const Color(0xFF8B947E),
  };

  Color _statusBg(String s) => switch (s) {
    'Done'     => const Color(0xFFE8F5E9),
    'Ongoing'  => const Color(0xFFFFF8E1),
    'Upcoming' => const Color(0xFFE3F2FD),
    'Overdue'  => const Color(0xFFFFEBEE),
    _          => const Color(0xFFF5F5F5),
  };

  Color _statusColor(String s) => switch (s) {
    'Done'     => const Color(0xFF4CAF50),
    'Ongoing'  => const Color(0xFFFF9800),
    'Upcoming' => const Color(0xFF2196F3),
    'Overdue'  => const Color(0xFFE53935),
    _          => const Color(0xFF9E9E9E),
  };
}