import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '_pet_profile_shared.dart';

// ── Breed data ────────────────────────────────────────────────────────────────
const _dogBreeds = [
  'Aspin (Asong Pinoy)', 'Labrador Retriever', 'German Shepherd',
  'Golden Retriever', 'French Bulldog', 'Bulldog', 'Poodle', 'Beagle',
  'Rottweiler', 'Dachshund', 'Shih Tzu', 'Siberian Husky', 'Dobermann',
  'Chihuahua', 'Great Dane', 'Pomeranian', 'Maltese', 'Boxer', 'Border Collie',
  'Cocker Spaniel', 'Chow Chow', 'Dalmatian', 'Pug', 'Samoyed',
  'Australian Shepherd', 'Schnauzer', 'Bichon Frise', 'Shiba Inu',
  'Jack Russell Terrier', 'Yorkshire Terrier',
];

const _catBreeds = [
  'Puspin (Pusang Pinoy)', 'Persian', 'Maine Coon', 'Siamese', 'Ragdoll',
  'Bengal', 'Sphynx', 'British Shorthair', 'Abyssinian', 'Scottish Fold',
  'Russian Blue', 'Norwegian Forest Cat', 'Birman', 'American Shorthair',
  'Devon Rex', 'Burmese', 'Tonkinese', 'Himalayan', 'Turkish Angora',
  'Exotic Shorthair',
];

List<String> _breedsFor(String petType) =>
    petType.toLowerCase() == 'cat' ? _catBreeds : _dogBreeds;

// ── Input formatters ──────────────────────────────────────────────────────────

/// Allows letters (including accented), spaces, hyphens, and apostrophes.
/// Used for Name and Color fields.
class _LettersOnlyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue value) {
    final filtered = value.text.replaceAll(RegExp(r"[^a-zA-ZÀ-ÿ\s'\-]"), '');
    if (filtered == value.text) return value;
    return value.copyWith(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}

/// Allows digits and at most one decimal point.
class _DecimalFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue value) {
    final text = value.text;
    if (text.isEmpty) return value;
    // Allow only digits and one dot
    final filtered = text.replaceAll(RegExp(r'[^0-9.]'), '');
    // Remove extra dots
    final parts = filtered.split('.');
    final cleaned = parts.length > 2
        ? '${parts[0]}.${parts.sublist(1).join('')}'
        : filtered;
    if (cleaned == value.text) return value;
    return value.copyWith(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  }
}

// ── Main card ─────────────────────────────────────────────────────────────────
class PetInfoCard extends StatefulWidget {
  final String name, breed, color, sex, birthDate, petType;
  final double weight;
  final String weightUnit;
  final bool editMode;
  final void Function(Map<String, dynamic>) onChanged;

  const PetInfoCard({
    super.key,
    required this.name,
    required this.breed,
    required this.color,
    required this.sex,
    required this.birthDate,
    required this.weight,
    required this.weightUnit,
    required this.editMode,
    required this.onChanged,
    this.petType = 'Dog', // default; pass the real value from PetProfilePage
  });

  @override
  State<PetInfoCard> createState() => _PetInfoCardState();
}

class _PetInfoCardState extends State<PetInfoCard> {
  late TextEditingController _nameCtrl, _colorCtrl, _weightCtrl;
  late TextEditingController _breedOtherCtrl;
  late String _sex, _weightUnit, _birthDate;
  late String _breed; // selected breed (may be 'Other')
  bool _showLbs = false;

  static const _otherLabel = 'Other (specify)';

  @override
  void initState() {
    super.initState();
    _nameCtrl       = TextEditingController(text: widget.name);
    _colorCtrl      = TextEditingController(text: widget.color);
    _weightCtrl     = TextEditingController(text: widget.weight.toString());
    _sex            = widget.sex;
    _weightUnit     = widget.weightUnit;
    _birthDate      = widget.birthDate;
    _initBreed(widget.breed);
  }

  void _initBreed(String raw) {
    final list = _breedsFor(widget.petType);
    if (list.contains(raw)) {
      _breed = raw;
      _breedOtherCtrl = TextEditingController();
    } else {
      _breed = _otherLabel;
      _breedOtherCtrl = TextEditingController(text: raw);
    }
  }

  String get _effectiveBreed =>
      _breed == _otherLabel ? _breedOtherCtrl.text.trim() : _breed;

  @override
  void didUpdateWidget(PetInfoCard old) {
    super.didUpdateWidget(old);
    if (!widget.editMode && old.editMode) {
      _nameCtrl.text   = widget.name;
      _colorCtrl.text  = widget.color;
      _weightCtrl.text = widget.weight.toString();
      _sex        = widget.sex;
      _weightUnit = widget.weightUnit;
      _birthDate  = widget.birthDate;
      _initBreed(widget.breed);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _colorCtrl.dispose();
    _weightCtrl.dispose();
    _breedOtherCtrl.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged({
    'name'      : _nameCtrl.text.trim(),
    'breed'     : _effectiveBreed,
    'color'     : _colorCtrl.text.trim(),
    'weight'    : double.tryParse(_weightCtrl.text.trim()) ?? widget.weight,
    'weightUnit': _weightUnit,
    'sex'       : _sex,
    'birthDate' : _birthDate,
  });

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_birthDate) ?? DateTime.now();
    final picked  = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: kNavy)),
        child: child!),
    );
    if (picked != null) {
      setState(() {
        _birthDate =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        _emit();
      });
    }
  }

  Future<void> _pickBreed() async {
    final breeds = [..._breedsFor(widget.petType), _otherLabel];
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BreedPickerSheet(
        breeds: breeds,
        selected: _breed,
        petType: widget.petType,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _breed = picked);
    _emit();
  }

  // ── Weight display helpers ────────────────────────────────────────────────
  double get _displayWeight {
    final storedKg = widget.weightUnit.toLowerCase() == 'lbs'
        ? widget.weight / 2.20462
        : widget.weight;
    return _showLbs ? storedKg * 2.20462 : storedKg;
  }

  String get _displayUnit => _showLbs ? 'lbs' : 'kg';

  @override
  Widget build(BuildContext context) {
    final e = widget.editMode;
    return ProfileCard(
      icon: Icons.info_outline,
      title: 'Basic Info',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Name ───────────────────────────────────────────────
        LabeledField(
          label: 'Name',
          child: e
              ? ProfileTextField(
                  ctrl: _nameCtrl,
                  hint: 'Pet name',
                  inputFormatters: [_LettersOnlyFormatter()],
                  onChanged: (_) => _emit(),
                )
              : ValueText(widget.name),
        ),

        // ── Breed ──────────────────────────────────────────────
        LabeledField(
          label: 'Breed',
          child: e
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tappable breed selector row
                    GestureDetector(
                      onTap: _pickBreed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5EFEB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kDivider),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Text(
                              _breed.isEmpty ? 'Select breed' : _breed,
                              style: TextStyle(
                                fontSize: 13,
                                color: _breed.isEmpty ? kLabel : kNavy,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 18, color: kLabel),
                        ]),
                      ),
                    ),
                    // "Other" free-text field
                    if (_breed == _otherLabel) ...[
                      const SizedBox(height: 8),
                      ProfileTextField(
                        ctrl: _breedOtherCtrl,
                        hint: 'Enter breed name',
                        onChanged: (_) => _emit(),
                      ),
                    ],
                  ],
                )
              : ValueText(widget.breed),
        ),

        // ── Color ──────────────────────────────────────────────
        LabeledField(
          label: 'Color',
          child: e
              ? ProfileTextField(
                  ctrl: _colorCtrl,
                  hint: 'e.g. Golden, Black & White',
                  inputFormatters: [_LettersOnlyFormatter()],
                  onChanged: (_) => _emit(),
                )
              : ValueText(widget.color),
        ),

        // ── Sex ────────────────────────────────────────────────
        LabeledField(
          label: 'Sex',
          child: e
              ? ToggleRow(
                  options: const ['Male', 'Female'],
                  selected: _sex,
                  onChanged: (v) { setState(() => _sex = v); _emit(); },
                )
              : ValueText(widget.sex),
        ),

        // ── Date of Birth ──────────────────────────────────────
        LabeledField(
          label: 'Date of Birth',
          child: e
              ? GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EFEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kDivider),
                    ),
                    child: Row(children: [
                      Expanded(child: ValueText(_birthDate)),
                      const Icon(Icons.calendar_month_outlined,
                          size: 16, color: kLabel),
                    ]),
                  ),
                )
              : ValueText(widget.birthDate),
        ),

        // ── Weight ─────────────────────────────────────────────
        LabeledField(
          label: 'Weight',
          child: e
              ? Row(children: [
                  Expanded(
                    child: ProfileTextField(
                      ctrl: _weightCtrl,
                      hint: '0.0',
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [_DecimalFormatter()],
                      onChanged: (_) => _emit(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ToggleRow(
                    options: const ['KG', 'LBS'],
                    selected: _weightUnit,
                    compact: true,
                    onChanged: (v) {
                      setState(() => _weightUnit = v);
                      _emit();
                    },
                  ),
                ])
              : Row(children: [
                  Expanded(
                    child: ValueText(
                        '${_displayWeight.toStringAsFixed(1)} $_displayUnit'),
                  ),
                  _ViewUnitToggle(
                    showLbs: _showLbs,
                    onToggle: (v) => setState(() => _showLbs = v),
                  ),
                ]),
        ),

      ]),
    );
  }
}

// ── Breed picker bottom sheet ─────────────────────────────────────────────────
class _BreedPickerSheet extends StatefulWidget {
  final List<String> breeds;
  final String selected;
  final String petType;
  const _BreedPickerSheet({
    required this.breeds,
    required this.selected,
    required this.petType,
  });

  @override
  State<_BreedPickerSheet> createState() => _BreedPickerSheetState();
}

class _BreedPickerSheetState extends State<_BreedPickerSheet> {
  late List<String> _filtered;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.breeds;
    _search.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.breeds
          : widget.breeds
              .where((b) => b.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  void dispose() {
    _search.removeListener(_onSearch);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      minChildSize: 0.50,
      maxChildSize: 0.92,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F2EE),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 38, height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: kNavy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pets_rounded, color: kNavy, size: 17),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Select Breed',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: kNavy)),
                Text('${widget.petType} breeds',
                    style: const TextStyle(
                        fontSize: 11, color: kLabel)),
              ]),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: kNavy),
                ),
              ),
            ]),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kDivider),
              ),
              child: Row(children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.search_rounded, size: 18, color: kLabel),
                ),
                Expanded(
                  child: TextField(
                    controller: _search,
                    style: const TextStyle(fontSize: 13, color: kNavy),
                    decoration: const InputDecoration(
                      hintText: 'Search breed...',
                      hintStyle: TextStyle(fontSize: 13, color: kLabel),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                if (_search.text.isNotEmpty)
                  GestureDetector(
                    onTap: () { _search.clear(); },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.close_rounded,
                          size: 16, color: kLabel),
                    ),
                  ),
              ]),
            ),
          ),

          const Divider(height: 1, color: kDivider),

          // Breed list
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off_rounded,
                            size: 32, color: kLabel),
                        const SizedBox(height: 8),
                        Text('No breeds match "${_search.text}"',
                            style: const TextStyle(
                                fontSize: 13, color: kLabel)),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: sc,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16, color: kDivider),
                    itemBuilder: (_, i) {
                      final breed = _filtered[i];
                      final isOther = breed == 'Other (specify)';
                      final isSelected = breed == widget.selected;
                      return InkWell(
                        onTap: () => Navigator.pop(context, breed),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 13),
                          child: Row(children: [
                            if (isOther)
                              const Icon(Icons.edit_outlined,
                                  size: 16, color: kLabel)
                            else
                              const Icon(Icons.pets_rounded,
                                  size: 14, color: kBrown),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                breed,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isOther ? kLabel : kNavy,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_rounded,
                                  size: 16, color: kNavy),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}

// ── Compact view-mode KG / LBS toggle ────────────────────────────────────────
class _ViewUnitToggle extends StatelessWidget {
  final bool showLbs;
  final ValueChanged<bool> onToggle;
  const _ViewUnitToggle({required this.showLbs, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _btn('KG',  !showLbs),
        _btn('LBS', showLbs),
      ]),
    );
  }

  Widget _btn(String label, bool selected) => GestureDetector(
        onTap: () => onToggle(label == 'LBS'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? kNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : kLabel)),
        ),
      );
}