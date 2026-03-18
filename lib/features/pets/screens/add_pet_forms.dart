import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pawfolio/utils/constants/pet_constants.dart';

// ─── Palette (matches app theme) ─────────────────────────────────────────────
const _kNavy    = Color(0xFF45617D);
const _kBrown   = Color(0xFFBA7F57);
const _kCream   = Color(0xFFDCCDC3);
const _kLabel   = Color(0xFF8A7060);
const _kDivider = Color(0xFFE8DDD6);
const _kBg      = Color(0xFFF5F2EE);
const _kGreen   = Color(0xFF7A8C6A);

// ─── Shared input decoration ──────────────────────────────────────────────────
InputDecoration _input(String hint, {IconData? icon}) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: _kLabel, fontSize: 13),
  prefixIcon: icon != null ? Icon(icon, size: 18, color: _kLabel) : null,
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kDivider)),
  focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kNavy, width: 1.5)),
  errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 1.2)),
  focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 1.5)),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
);

// ─── Section label ────────────────────────────────────────────────────────────
Widget _sectionLabel(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(t,
    style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: _kLabel,
        letterSpacing: 1.1)),
);

// ─── Toggle row ───────────────────────────────────────────────────────────────
Widget _toggleRow(List<String> opts, String? sel, ValueChanged<String> fn) {
  return Row(
    children: opts.map((o) {
      final isSel = sel == o;
      return Expanded(
        child: GestureDetector(
          onTap: () => fn(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: EdgeInsets.only(right: o == opts.last ? 0 : 8),
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: isSel ? _kNavy : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSel ? _kNavy : _kDivider),
              boxShadow: isSel
                  ? [BoxShadow(
                      color: _kNavy.withOpacity(0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3))]
                  : [],
            ),
            child: Center(
              child: Text(o,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSel ? Colors.white : _kLabel)),
            ),
          ),
        ),
      );
    }).toList(),
  );
}

// ─── Field card wrapper ───────────────────────────────────────────────────────
Widget _fieldCard({required Widget child}) => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: _kDivider),
    boxShadow: [
      BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 2))
    ],
  ),
  child: child,
);

// ─── Shared date formatter ────────────────────────────────────────────────────
String formatDob(DateTime? dob) {
  if (dob == null) return '—';
  return '${dob.month.toString().padLeft(2, '0')} / '
      '${dob.day.toString().padLeft(2, '0')} / '
      '${dob.year}';
}

// ─── Resolve breeds before saving to Firebase ────────────────────────────────
/// Replaces the literal "Other" entry with the user-typed value.
/// Call this before writing to Firestore — never save raw "Other".
List<String> resolveBreeds(List<String> breeds, String otherValue) {
  return breeds.map((b) {
    if (b == 'Other') {
      return otherValue.trim().isNotEmpty ? otherValue.trim() : 'Other';
    }
    return b;
  }).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 0 — Basic Info
// ─────────────────────────────────────────────────────────────────────────────
class StepBasicInfo extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController otherBreedCtrl;
  final String? petType;
  final List<String> selectedBreeds;
  final void Function(String) onTypeChanged;
  final void Function(List<String>) onBreedsChanged;

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
  // FIXED: was 'Others' — must match the exact string in PetConstants.breeds
  static const _othersKey = 'Other';

  bool get _showOtherField => widget.selectedBreeds.contains(_othersKey);

  void _toggleBreed(String breed) {
    final list = List<String>.from(widget.selectedBreeds);
    if (list.contains(breed)) {
      list.remove(breed);
      if (breed == _othersKey) widget.otherBreedCtrl.clear();
    } else {
      list.add(breed);
    }
    widget.onBreedsChanged(list);
  }

  @override
  Widget build(BuildContext context) {
    final breeds = PetConstants.breeds[widget.petType] ?? [];

    return Form(
      key: widget.formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Name ────────────────────────────────────────────────────
        _fieldCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('PET NAME'),
            TextFormField(
              controller: widget.nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _input('e.g. Luna', icon: Icons.pets_outlined),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required';
                if (v.trim().length < 2) return 'Name must be at least 2 characters';
                return null;
              },
            ),
          ],
        )),

        const SizedBox(height: 14),

        // ── Type ────────────────────────────────────────────────────
        _fieldCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('PET TYPE'),
            _toggleRow(['CAT', 'DOG'], widget.petType, widget.onTypeChanged),
          ],
        )),

        const SizedBox(height: 14),

        // ── Breed ───────────────────────────────────────────────────
        _fieldCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('BREED'),
            if (widget.petType == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kDivider),
                ),
                child: Row(children: const [
                  Icon(Icons.info_outline, size: 15, color: _kLabel),
                  SizedBox(width: 8),
                  Text('Select a pet type first',
                      style: TextStyle(color: _kLabel, fontSize: 13)),
                ]),
              )
            else
              Wrap(
                spacing: 8, runSpacing: 8,
                children: breeds.map((b) {
                  final isSel = widget.selectedBreeds.contains(b);
                  return GestureDetector(
                    onTap: () => setState(() => _toggleBreed(b)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? _kNavy : _kCream.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSel ? _kNavy : _kDivider),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (isSel) ...[
                          const Icon(Icons.check, color: Colors.white, size: 11),
                          const SizedBox(width: 4),
                        ],
                        Text(b,
                          style: TextStyle(
                              fontSize: 12,
                              color: isSel ? Colors.white : _kLabel,
                              fontWeight:
                                  isSel ? FontWeight.w600 : FontWeight.w500)),
                      ]),
                    ),
                  );
                }).toList(),
              ),

            // Selected count
            if (widget.selectedBreeds.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(color: _kDivider, height: 1),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.check_circle_outline, size: 13, color: _kGreen),
                const SizedBox(width: 5),
                Text(
                  '${widget.selectedBreeds.length} breed'
                  '${widget.selectedBreeds.length == 1 ? '' : 's'} selected',
                  style: const TextStyle(
                      fontSize: 11,
                      color: _kGreen,
                      fontWeight: FontWeight.w600)),
              ]),
            ],
          ],
        )),

        // ── Other breed text field — shown when 'Other' chip is selected ────
        if (_showOtherField) ...[
          const SizedBox(height: 14),
          _fieldCard(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('SPECIFY OTHER BREED'),
              TextFormField(
                controller: widget.otherBreedCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _input('Enter breed name', icon: Icons.edit_outlined),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\-']")),
                ],
                validator: (v) {
                  if (!_showOtherField) return null;
                  if (v == null || v.trim().isEmpty) {
                    return 'Please specify the breed';
                  }
                  return null;
                },
              ),
            ],
          )),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1 — Physical Details
// ─────────────────────────────────────────────────────────────────────────────
class StepPhysicalDetails extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String? sex;
  final TextEditingController wgtCtrl;
  final TextEditingController colorCtrl;
  final String wgtUnit;
  final DateTime? dob;
  // FIXED: callback now receives the picked DateTime instead of being a plain VoidCallback
  final void Function(DateTime) onPickDate;
  final void Function(String) onSexChanged;
  final void Function(String) onUnitChanged;

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

        // ── Sex ─────────────────────────────────────────────────────
        _fieldCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('SEX'),
            _toggleRow(['Male', 'Female'], sex, onSexChanged),
          ],
        )),

        const SizedBox(height: 14),

        // ── Weight ──────────────────────────────────────────────────
        _fieldCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('WEIGHT'),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: wgtCtrl,
                  decoration: _input('e.g. 4.5',
                      icon: Icons.monitor_weight_outlined),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Weight is required';
                    final parsed = double.tryParse(v.trim());
                    if (parsed == null) return 'Enter a valid number';
                    if (parsed <= 0) return 'Weight must be greater than 0';
                    if (parsed > 200) return 'Weight seems too high';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kDivider),
                ),
                child: Row(
                  children: ['KG', 'LBS'].map((u) {
                    final isSel = wgtUnit == u;
                    return GestureDetector(
                      onTap: () => onUnitChanged(u),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: isSel ? _kNavy : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(u,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSel ? Colors.white : _kLabel)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ]),
          ],
        )),

        const SizedBox(height: 14),

        // ── Color ───────────────────────────────────────────────────
        _fieldCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('COLOR / COAT'),
            TextFormField(
              controller: colorCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: _input('e.g. Tabby brown, white paws',
                  icon: Icons.palette_outlined),
              // FIXED: letters, spaces, commas, slashes, hyphens, apostrophes only
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s,/\-']")),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Color is required';
                if (v.trim().length < 2) return 'Too short';
                return null;
              },
            ),
          ],
        )),

        const SizedBox(height: 14),

        // ── Date of Birth ────────────────────────────────────────────
        _fieldCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('DATE OF BIRTH'),
            GestureDetector(
              onTap: () async {
                // FIXED: constrained to past dates only; result passed back via onPickDate(DateTime)
                final picked = await showDatePicker(
                  context: context,
                  initialDate: dob ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) onPickDate(picked);
              },
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: dob != null ? _kNavy : _kDivider,
                    width: dob != null ? 1.5 : 1,
                  ),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_month_outlined,
                      size: 18, color: dob != null ? _kNavy : _kLabel),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      dob != null ? formatDob(dob) : 'MM / DD / YYYY',
                      style: TextStyle(
                          fontSize: 14,
                          color: dob != null
                              ? const Color(0xFF2C2C2C)
                              : _kLabel),
                    ),
                  ),
                  if (dob != null)
                    const Icon(Icons.check_circle_outline,
                        size: 16, color: _kGreen),
                ]),
              ),
            ),
            if (dob == null)
              const Padding(
                padding: EdgeInsets.only(top: 6, left: 2),
                child: Text('Tap to select a date',
                    style: TextStyle(fontSize: 11, color: _kLabel)),
              ),
          ],
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2 — Health
// ─────────────────────────────────────────────────────────────────────────────
class StepHealth extends StatelessWidget {
  final bool isSpayed;
  final void Function(bool) onSpayedChanged;

  const StepHealth({
    super.key,
    required this.isSpayed,
    required this.onSpayedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _fieldCard(
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: isSpayed
                ? _kNavy.withOpacity(0.1)
                : _kCream.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.health_and_safety_outlined,
              color: isSpayed ? _kNavy : _kLabel, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SPAYED / NEUTERED',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _kLabel,
                    letterSpacing: 0.5)),
              const SizedBox(height: 3),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  key: ValueKey(isSpayed),
                  isSpayed
                      ? 'Yes — has been sterilized'
                      : 'No — not sterilized',
                  style: TextStyle(
                      fontSize: 13,
                      color: isSpayed ? _kNavy : const Color(0xFF2C2C2C),
                      fontWeight:
                          isSpayed ? FontWeight.w600 : FontWeight.normal),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: isSpayed,
          onChanged: onSpayedChanged,
          activeThumbColor: _kNavy,
          activeTrackColor: _kNavy.withOpacity(0.25),
          inactiveThumbColor: Colors.grey.shade400,
          inactiveTrackColor: Colors.grey.shade200,
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 3 — Review
// ─────────────────────────────────────────────────────────────────────────────
class StepReview extends StatelessWidget {
  final String name;
  final String weight;
  final String unit;
  final String? type;
  final String? sex;
  final List<String> breeds;
  final String otherBreed;
  final String color;
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
    required this.otherBreed,
    required this.color,
    this.dob,
    required this.isSpayed,
  });

  String get _breedDisplay {
    if (breeds.isEmpty) return '—';
    // FIXED: 'Other' (no s) to match PetConstants
    final resolved = breeds.map((b) {
      if (b == 'Other') {
        return otherBreed.trim().isNotEmpty ? otherBreed.trim() : 'Other';
      }
      return b;
    }).toList();
    return resolved.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _ReviewRow(Icons.pets_outlined,              'PET NAME',         name.trim().isEmpty ? '—' : name.trim()),
      _ReviewRow(Icons.category_outlined,          'TYPE',             type ?? '—'),
      _ReviewRow(Icons.emoji_nature_outlined,      'BREED',            _breedDisplay),
      _ReviewRow(Icons.wc_outlined,               'SEX',              sex ?? '—'),
      _ReviewRow(Icons.monitor_weight_outlined,    'WEIGHT',
          weight.trim().isEmpty ? '—' : '${double.tryParse(weight.trim())?.toStringAsFixed(1) ?? weight.trim()} $unit'),
      _ReviewRow(Icons.palette_outlined,           'COLOR / COAT',     color.trim().isEmpty ? '—' : color.trim()),
      _ReviewRow(Icons.cake_outlined,              'DATE OF BIRTH',    formatDob(dob)),
      _ReviewRow(Icons.health_and_safety_outlined, 'SPAYED/NEUTERED',  isSpayed ? 'Yes' : 'No'),
    ];

    return Column(
      children: items.map((item) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kDivider),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 1))
          ],
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: _kCream, borderRadius: BorderRadius.circular(10)),
            child: Icon(item.icon, color: _kBrown, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _kLabel,
                        letterSpacing: 0.5)),
                const SizedBox(height: 3),
                Text(item.value,
                    style: TextStyle(
                        fontSize: 13,
                        color: item.value == '—'
                            ? _kLabel
                            : const Color(0xFF2C2C2C),
                        fontWeight: item.value == '—'
                            ? FontWeight.normal
                            : FontWeight.w500)),
              ],
            ),
          ),
          if (item.value == '—')
            const Icon(Icons.warning_amber_rounded,
                size: 16, color: Colors.orange),
        ]),
      )).toList(),
    );
  }
}

class _ReviewRow {
  final IconData icon;
  final String label, value;
  const _ReviewRow(this.icon, this.label, this.value);
}