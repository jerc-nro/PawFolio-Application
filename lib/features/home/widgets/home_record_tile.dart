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
        border: Border.all(color: const Color(0xFFE8DDD6)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: _iconBg(record.category),
              borderRadius: BorderRadius.circular(12),
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
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF2D3A4A))),
                const SizedBox(height: 3),
                Text('${record.petName} · ${record.dateString}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF8A7060))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _statusBg(record.status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(record.status,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

  // Icon backgrounds tinted to match the warm/neutral theme
  Color _iconBg(String cat) => switch (cat) {
    'Vaccination'  => const Color(0xFFEDF4EB),
    'Medication'   => const Color(0xFFFFF4E8),
    'Vet Visit'    => const Color(0xFFEAF2FB),
    'Grooming'     => const Color(0xFFF5EEF8),
    'Preventative' => const Color(0xFFEDF0FA),
    _              => const Color(0xFFF5F2EE),
  };

  Color _iconColor(String cat) => switch (cat) {
    'Vaccination'  => const Color(0xFF5A9E62),
    'Medication'   => const Color(0xFFBA7F57),
    'Vet Visit'    => const Color(0xFF45617D),
    'Grooming'     => const Color(0xFF8B6FAB),
    'Preventative' => const Color(0xFF5C6BAD),
    _              => const Color(0xFF8A7060),
  };

  Color _statusBg(String s) => switch (s) {
    'Done'     => const Color(0xFFEDF4EB),
    'Ongoing'  => const Color(0xFFFFF4E8),
    'Upcoming' => const Color(0xFFEAF2FB),
    'Overdue'  => const Color(0xFFFAECEC),
    _          => const Color(0xFFF5F2EE),
  };

  Color _statusColor(String s) => switch (s) {
    'Done'     => const Color(0xFF5A9E62),
    'Ongoing'  => const Color(0xFFBA7F57),
    'Upcoming' => const Color(0xFF45617D),
    'Overdue'  => const Color(0xFFCF6679),
    _          => const Color(0xFF8A7060),
  };
}