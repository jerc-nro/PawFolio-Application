import 'package:flutter/material.dart';
import '_pet_profile_shared.dart';

class PetInfoCard extends StatefulWidget {
  final String name, breed, color, sex, birthDate;
  final double weight;
  final String weightUnit;
  final bool editMode;
  final void Function(Map<String, dynamic>) onChanged;

  const PetInfoCard({
    super.key,
    required this.name, required this.breed, required this.color,
    required this.sex, required this.birthDate,
    required this.weight, required this.weightUnit,
    required this.editMode, required this.onChanged,
  });

  @override
  State<PetInfoCard> createState() => _PetInfoCardState();
}

class _PetInfoCardState extends State<PetInfoCard> {
  late TextEditingController _nameCtrl, _breedCtrl, _colorCtrl, _weightCtrl;
  late String _sex, _weightUnit, _birthDate;

  @override
  void initState() {
    super.initState();
    _nameCtrl   = TextEditingController(text: widget.name);
    _breedCtrl  = TextEditingController(text: widget.breed);
    _colorCtrl  = TextEditingController(text: widget.color);
    _weightCtrl = TextEditingController(text: widget.weight.toString());
    _sex        = widget.sex;
    _weightUnit = widget.weightUnit;
    _birthDate  = widget.birthDate;
  }

  @override
  void didUpdateWidget(PetInfoCard old) {
    super.didUpdateWidget(old);
    if (!widget.editMode && old.editMode) {
      _nameCtrl.text   = widget.name;
      _breedCtrl.text  = widget.breed;
      _colorCtrl.text  = widget.color;
      _weightCtrl.text = widget.weight.toString();
      _sex        = widget.sex;
      _weightUnit = widget.weightUnit;
      _birthDate  = widget.birthDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _breedCtrl.dispose();
    _colorCtrl.dispose(); _weightCtrl.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged({
    'name'      : _nameCtrl.text.trim(),
    'breed'     : _breedCtrl.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final e = widget.editMode;
    return ProfileCard(
      icon: Icons.info_outline,
      title: 'Basic Info',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LabeledField(label: 'Name',
          child: e ? ProfileTextField(ctrl: _nameCtrl, onChanged: (_) => _emit())
                   : ValueText(widget.name)),
        LabeledField(label: 'Breed',
          child: e ? ProfileTextField(ctrl: _breedCtrl, onChanged: (_) => _emit())
                   : ValueText(widget.breed)),
        LabeledField(label: 'Color',
          child: e ? ProfileTextField(ctrl: _colorCtrl, onChanged: (_) => _emit())
                   : ValueText(widget.color)),
        LabeledField(label: 'Sex',
          child: e
            ? ToggleRow(
                options: const ['Male', 'Female'], selected: _sex,
                onChanged: (v) { setState(() => _sex = v); _emit(); })
            : ValueText(widget.sex)),
        LabeledField(label: 'Date of Birth',
          child: e
            ? GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5EFEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kDivider)),
                  child: Row(children: [
                    Expanded(child: ValueText(_birthDate)),
                    const Icon(Icons.calendar_month_outlined, size: 16, color: kLabel),
                  ]),
                ))
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ValueText(widget.birthDate),
              ])),
        LabeledField(label: 'Weight',
          child: e
            ? Row(children: [
                Expanded(child: ProfileTextField(
                  ctrl: _weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _emit())),
                const SizedBox(width: 8),
                ToggleRow(
                  options: const ['KG', 'LBS'], selected: _weightUnit,
                  compact: true,
                  onChanged: (v) { setState(() => _weightUnit = v); _emit(); }),
              ])
            : ValueText('${widget.weight} ${widget.weightUnit}')),
      ]),
    );
  }
}