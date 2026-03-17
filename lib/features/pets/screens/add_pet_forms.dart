import 'package:flutter/material.dart';
import 'package:pawfolio/utils/constants/pet_constants.dart';

const _kNavy    = Color(0xFF45617D);
const _kBrown   = Color(0xFFBA7F57);
const _kCream   = Color(0xFFDCCDC3);
const _kLabel   = Color(0xFF8A7060);
const _kDivider = Color(0xFFE8DDD6);

InputDecoration _input(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: _kLabel, fontSize: 13),
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kDivider)),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kNavy, width: 1.5)),
  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.2)),
  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
);

Widget _sectionLabel(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(t, style: const TextStyle(
    fontSize: 10, fontWeight: FontWeight.bold,
    color: _kLabel, letterSpacing: 1.1,
  )),
);

Widget _toggleRow(List<String> opts, String? sel, ValueChanged<String> fn) {
  return Row(children: opts.map((o) {
    final isSelected = sel == o;
    return Expanded(
      child: GestureDetector(
        onTap: () => fn(o),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: EdgeInsets.only(right: o == opts.last ? 0 : 8),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: isSelected ? _kNavy : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? _kNavy : _kDivider),
            boxShadow: isSelected ? [
              BoxShadow(color: _kNavy.withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 3))
            ] : [],
          ),
          child: Center(child: Text(o,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : _kLabel,
            ),
          )),
        ),
      ),
    );
  }).toList());
}

// --- Step 0: Basic Info ---
class StepBasicInfo extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl, otherBreedCtrl;
  final String? petType;
  final List<String> selectedBreeds;
  final Function(String) onTypeChanged;
  final Function(List<String>) onBreedsChanged;

  const StepBasicInfo({
    super.key,
    required this.formKey,
    required this.nameCtrl,
    required this.petType,
    required this.selectedBreeds,
    required this.otherBreedCtrl,
    required this.onTypeChanged,
    required this.onBreedsChanged,
  });

  @override
  State<StepBasicInfo> createState() => _StepBasicInfoState();
}

class _StepBasicInfoState extends State<StepBasicInfo> {
  @override
  Widget build(BuildContext context) {
    final breeds = PetConstants.breeds[widget.petType] ?? [];
    final showOther = widget.selectedBreeds.any(
      (b) => b.toUpperCase() == 'OTHERS' || b == 'Other');

    return Form(
      key: widget.formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('NAME'),
        TextFormField(
          controller: widget.nameCtrl,
          decoration: _input('e.g. Luna'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 20),
        _sectionLabel('TYPE'),
        _toggleRow(['CAT', 'DOG'], widget.petType, (v) {
          widget.onTypeChanged(v);
        }),
        const SizedBox(height: 20),
        _sectionLabel('BREED'),
        widget.petType == null
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kDivider),
              ),
              child: const Text('Select type first',
                style: TextStyle(color: _kLabel, fontSize: 13)),
            )
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kDivider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: breeds.map((b) {
                      final isSel = widget.selectedBreeds.contains(b);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            isSel
                              ? widget.selectedBreeds.remove(b)
                              : widget.selectedBreeds.add(b);
                            widget.onBreedsChanged(widget.selectedBreeds);
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSel ? _kNavy : _kCream.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSel ? _kNavy : _kDivider),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            if (isSel) ...[
                              const Icon(Icons.check, color: Colors.white, size: 11),
                              const SizedBox(width: 4),
                            ],
                            Text(b, style: TextStyle(
                              fontSize: 12,
                              color: isSel ? Colors.white : _kLabel,
                              fontWeight: FontWeight.w500,
                            )),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                  if (widget.selectedBreeds.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(color: _kDivider, height: 1),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.selectedBreeds.length} selected',
                      style: const TextStyle(fontSize: 11, color: _kBrown, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
        if (showOther) ...[
          const SizedBox(height: 12),
          _sectionLabel('SPECIFY BREED'),
          TextFormField(
            controller: widget.otherBreedCtrl,
            decoration: _input('Enter breed name'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ],
      ]),
    );
  }
}

// --- Step 1: Physical Details ---
class StepPhysicalDetails extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String? sex;
  final TextEditingController wgtCtrl, colorCtrl;
  final String wgtUnit;
  final DateTime? dob;
  final VoidCallback onPickDate;
  final Function(String) onSexChanged, onUnitChanged;

  const StepPhysicalDetails({
    super.key,
    required this.formKey,
    required this.sex,
    required this.wgtCtrl,
    required this.wgtUnit,
    required this.colorCtrl,
    required this.dob,
    required this.onPickDate,
    required this.onSexChanged,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('SEX'),
        _toggleRow(['Male', 'Female'], sex, onSexChanged),
        const SizedBox(height: 20),
        _sectionLabel('WEIGHT'),
        Row(children: [
          Expanded(child: TextFormField(
            controller: wgtCtrl,
            decoration: _input('e.g. 4.5'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter a valid weight' : null,
          )),
          const SizedBox(width: 10),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kDivider),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: wgtUnit,
                items: const [
                  DropdownMenuItem(value: 'KG', child: Text('KG', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'LBS', child: Text('LBS', style: TextStyle(fontSize: 13))),
                ],
                onChanged: (v) => onUnitChanged(v!),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        _sectionLabel('COLOR'),
        TextFormField(
          controller: colorCtrl,
          decoration: _input('e.g. Tabby brown'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 20),
        _sectionLabel('DATE OF BIRTH'),
        GestureDetector(
          onTap: onPickDate,
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kDivider),
            ),
            child: Row(children: [
              Expanded(child: Text(
                dob != null
                  ? '${dob!.month.toString().padLeft(2,'0')}/${dob!.day.toString().padLeft(2,'0')}/${dob!.year}'
                  : 'MM/DD/YYYY',
                style: TextStyle(
                  fontSize: 14,
                  color: dob != null ? const Color(0xFF2C2C2C) : _kLabel,
                ),
              )),
              const Icon(Icons.calendar_month_outlined, size: 20, color: _kLabel),
            ]),
          ),
        ),
      ]),
    );
  }
}

// --- Step 2: Health ---
class StepHealth extends StatelessWidget {
  final bool isSpayed;
  final Function(bool) onSpayedChanged;

  const StepHealth({
    super.key,
    required this.isSpayed,
    required this.onSpayedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kDivider),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: isSpayed ? _kNavy.withOpacity(0.08) : _kCream.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.health_and_safety_outlined,
            color: isSpayed ? _kNavy : _kLabel, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('SPAYED / NEUTERED',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
              color: _kLabel, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(isSpayed ? 'Yes, has been sterilized' : 'Has been sterilized',
            style: const TextStyle(fontSize: 13, color: Color(0xFF2C2C2C))),
        ])),
        Switch(
          value: isSpayed,
          onChanged: onSpayedChanged,
          activeThumbColor: _kNavy,
        ),
      ]),
    );
  }
}

// --- Step 3: Review ---
class StepReview extends StatelessWidget {
  final String name, weight, unit;
  final String? type, sex;
  final List<String> breeds;
  final DateTime? dob;
  final bool isSpayed;

  const StepReview({
    super.key,
    required this.name,
    required this.weight,
    required this.unit,
    this.type,
    this.sex,
    required this.breeds,
    this.dob,
    required this.isSpayed,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _R(Icons.pets,                   'NAME',            name.isEmpty ? '—' : name),
      _R(Icons.category_outlined,      'TYPE & BREED',    '${type ?? '—'} • ${breeds.isEmpty ? '—' : breeds.join(", ")}'),
      _R(Icons.wc_outlined,            'SEX',             sex ?? '—'),
      _R(Icons.monitor_weight_outlined,'WEIGHT',          weight.isEmpty ? '—' : '$weight $unit'),
      _R(Icons.cake_outlined,          'DATE OF BIRTH',
          dob == null ? '—' : '${dob!.month.toString().padLeft(2,'0')}/${dob!.day.toString().padLeft(2,'0')}/${dob!.year}'),
      _R(Icons.check_circle_outline,   'SPAYED/NEUTERED', isSpayed ? 'Yes' : 'No'),
    ];

    return Column(children: items.map((f) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kDivider),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: _kCream,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(f.icon, color: _kBrown, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(f.label, style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold,
            color: _kLabel, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(f.value, style: const TextStyle(
            fontSize: 13, color: Color(0xFF2C2C2C), fontWeight: FontWeight.w500)),
        ])),
      ]),
    )).toList());
  }
}

class _R {
  final IconData icon;
  final String label, value;
  const _R(this.icon, this.label, this.value);
}