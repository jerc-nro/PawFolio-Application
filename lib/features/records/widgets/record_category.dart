import 'package:flutter/material.dart';

/// Represents a single health-record category shown on the Records screen.
class RecordCategory {
  final String label;
  final String subtitle;
  final String filterKey;
  final IconData icon;
  final Color cardColor;
  final Color iconBg;

  const RecordCategory({
    required this.label,
    required this.subtitle,
    required this.filterKey,
    required this.icon,
    required this.cardColor,
    required this.iconBg,
  });
}

/// The full catalogue of record categories used across the Records feature.
const List<RecordCategory> kRecordCategories = [
  RecordCategory(
    label:     'Medication',
    subtitle:  'Doses & schedules',
    filterKey: 'Medication',
    icon:      Icons.medication_liquid_outlined,
    cardColor: Color(0xFFF0EBE1),
    iconBg:    Color(0xFFDDD0BA),
  ),
  RecordCategory(
    label:     'Preventatives',
    subtitle:  'Flea, tick & more',
    filterKey: 'Preventatives',
    icon:      Icons.shield_outlined,
    cardColor: Color(0xFFE5EDE7),
    iconBg:    Color(0xFFC0D4C6),
  ),
  RecordCategory(
    label:     'Vaccination',
    subtitle:  'Shot history',
    filterKey: 'Vaccination',
    icon:      Icons.vaccines_outlined,
    cardColor: Color(0xFFEBE8F0),
    iconBg:    Color(0xFFCFC9E0),
  ),
  RecordCategory(
    label:     'Vet Visit',
    subtitle:  'Clinic check-ins',
    filterKey: 'Vet Visit',
    icon:      Icons.local_hospital_outlined,
    cardColor: Color(0xFFF0E8E5),
    iconBg:    Color(0xFFDEC4BC),
  ),
  RecordCategory(
    label:     'Grooming',
    subtitle:  'Baths & trims',
    filterKey: 'Grooming',
    icon:      Icons.content_cut_outlined,
    cardColor: Color(0xFFE8EDF0),
    iconBg:    Color(0xFFBDD0DA),
  ),
  RecordCategory(
    label:     'Weight',
    subtitle:  'Growth tracking',
    filterKey: 'Weight',
    icon:      Icons.monitor_weight_outlined,
    cardColor: Color(0xFFF0EDE5),
    iconBg:    Color(0xFFDDD5BC),
  ),
];