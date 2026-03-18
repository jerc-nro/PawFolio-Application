import 'package:flutter/material.dart';
import 'package:pawfolio/features/records/widgets/select_pet_dialog.dart';
import 'package:pawfolio/features/records/widgets/record_category.dart';
import '../../features/pets/screens/add_pet_page.dart';

class QuickAddModal {
  static const _kNavy   = Color(0xFF45617D);
  static const _kBrown  = Color(0xFFBA7F57);
  static const _kCream  = Color(0xFFDCCDC3);
  static const _kBg     = Color(0xFFF5F2EE);
  static const _kLabel  = Color(0xFF8A7060);
  static const _kDivider= Color(0xFFE8DDD6);
  static const _kGreen  = Color(0xFF7A8C6A);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _QuickAddContent(),
    );
  }
}

class _QuickAddContent extends StatelessWidget {
  const _QuickAddContent();

  static const _options = [
    _Option('Medication',    Icons.science_outlined,           Color(0xFFFFF4E8), Color(0xFFBA7F57)),
    _Option('Vaccination',   Icons.verified_outlined,          Color(0xFFEDF4EB), Color(0xFF5A9E62)),
    _Option('Preventatives', Icons.shield_outlined,            Color(0xFFEDF0FA), Color(0xFF5C6BAD)),
    _Option('Vet Visit',     Icons.local_hospital_outlined,    Color(0xFFEAF2FB), Color(0xFF45617D)),
    _Option('Grooming',      Icons.content_cut_outlined,       Color(0xFFF5EEF8), Color(0xFF8B6FAB)),
    _Option('Weight',        Icons.monitor_weight_outlined,    Color(0xFFF0F4F0), Color(0xFF7A8C6A)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: QuickAddModal._kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──────────────────────────────────────────
          Container(
            width: 38, height: 4,
            decoration: BoxDecoration(
              color: QuickAddModal._kDivider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // ── Title row ────────────────────────────────────────
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: QuickAddModal._kNavy.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_circle_outline_rounded,
                  color: QuickAddModal._kNavy, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick Add',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2D3A4A),
                  )),
                Text('Choose a record type',
                  style: TextStyle(
                    fontSize: 12,
                    color: QuickAddModal._kLabel,
                  )),
              ],
            ),
          ]),

          const SizedBox(height: 18),

          // ── Options grid ─────────────────────────────────────
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
            children: _options
                .map((o) => _GridTile(option: o))
                .toList(),
          ),

          const SizedBox(height: 14),
          const Divider(color: QuickAddModal._kDivider, height: 1),
          const SizedBox(height: 14),

          // ── Add new pet button ────────────────────────────────
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddPetPage()));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: QuickAddModal._kDivider),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: QuickAddModal._kGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.pets,
                        color: QuickAddModal._kGreen, size: 15),
                  ),
                  const SizedBox(width: 10),
                  const Text('Add New Pet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: QuickAddModal._kGreen,
                    )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grid tile ─────────────────────────────────────────────────────────────────
class _GridTile extends StatelessWidget {
  final _Option option;
  const _GridTile({required this.option});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final fullCategory = kRecordCategories.firstWhere(
          (cat) => cat.label.toLowerCase() == option.label.toLowerCase(),
          orElse: () => RecordCategory(
            label: option.label,
            subtitle: 'Add new ${option.label} entry',
            filterKey: option.label.toLowerCase().replaceAll(' ', '_'),
            icon: option.icon,
            cardColor: option.iconBg,
            iconBg: option.iconBg,
          ),
        );
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => SelectPetDialog(
            category: fullCategory,
            isAddMode: true,
          ),
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8DDD6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: option.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(option.icon, color: option.iconColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(option.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3A4A),
              )),
          ],
        ),
      ),
    );
  }
}

// ── Option model ──────────────────────────────────────────────────────────────
class _Option {
  final String label;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  const _Option(this.label, this.icon, this.iconBg, this.iconColor);
}