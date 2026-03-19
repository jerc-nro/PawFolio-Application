import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/record_model.dart';
import '../providers/record_provider.dart';
import '../screen/records_navigator.dart';
import '../theme/records_theme.dart';
import '_status_date_logic.dart';
import 'location_selector_widget.dart';

void showAddVaccinationDialog(
  BuildContext context,
  String petId,
  String petName,
  String petType, {
  void Function(String label)? onSaved,
  VoidCallback? onCancel,
}) {
  final sw = MediaQuery.of(context).size.width;
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: sw > 500 ? 420 : sw * 0.88,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(25)),
        child: _VaccineContent(
            petId: petId, petName: petName, petType: petType,
            onSaved: onSaved, onCancel: onCancel),
      ),
    ),
  );
}

class _VaccineContent extends ConsumerStatefulWidget {
  final String petId, petName, petType;
  final void Function(String)? onSaved;
  final VoidCallback? onCancel;
  const _VaccineContent({
    required this.petId, required this.petName, required this.petType,
    this.onSaved, this.onCancel,
  });
  @override
  ConsumerState<_VaccineContent> createState() => _VS();
}

class _VS extends ConsumerState<_VaccineContent> {
  final _name       = TextEditingController();
  final _date       = TextEditingController();
  final _vet        = TextEditingController();
  final _dosage     = TextEditingController();
  final _time       = TextEditingController();
  final _weightCtrl = TextEditingController();

  String    _type        = 'CORE';
  String    _unit        = 'MG';
  String    _weightUnit  = 'kg';
  String    _status      = 'UPCOMING';
  TimeOfDay _tod         = TimeOfDay.now();
  bool      _saving      = false;
  bool      _isCurrentWeight = false;
  ClinicLocation? _location;

  String? _nameErr, _dateErr, _timeErr;

  double? get _weightInKg {
    final v = double.tryParse(_weightCtrl.text.trim());
    if (v == null || v <= 0) return null;
    return _weightUnit == 'lbs' ? v / 2.20462 : v;
  }

  @override
  void dispose() {
    for (final c in [_name, _date, _vet, _dosage, _time, _weightCtrl]) c.dispose();
    super.dispose();
  }

  DateTime? _parseDateStr(String s) {
    try {
      final p = s.split('.');
      return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
    } catch (_) { return null; }
  }

  String? _validateDate(String v) {
    if (v.trim().isEmpty) return 'Date is required';
    final d = _parseDateStr(v);
    if (d == null) return 'Invalid date format';
    if (_status == 'UPCOMING' &&
        d.isBefore(DateTime.now().subtract(const Duration(days: 1))))
      return 'Future date required for Upcoming';
    if (_status != 'UPCOMING' && d.isAfter(DateTime.now()))
      return 'Past/present date required for this status';
    return null;
  }

  void _handleCancel() {
    Navigator.of(context).pop();
    widget.onCancel?.call();
  }

  void _showTimePicker() async {
    TimeOfDay picked = _tod;
    await showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(height: 260, color: Colors.white,
        child: Column(children: [
          Container(color: const Color(0xFFF5F5F5),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              CupertinoButton(
                  child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                  onPressed: () => Navigator.pop(context)),
              CupertinoButton(
                  child: const Text('Done', style: TextStyle(
                      color: RecordsPalette.steel, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    setState(() { _tod = picked; _time.text = _tod.format(context); _timeErr = null; });
                    Navigator.pop(context);
                  }),
            ])),
          Expanded(child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: DateTime(2024, 1, 1, _tod.hour, _tod.minute),
              onDateTimeChanged: (dt) => picked = TimeOfDay.fromDateTime(dt))),
        ]),
      ),
    );
  }

  Future<void> _save() async {
    final timeRequired = _status == 'COMPLETED' && _time.text.trim().isEmpty;
    setState(() {
      _nameErr = _name.text.trim().isEmpty ? 'Vaccine name is required'
          : _name.text.trim().length < 2 ? 'Minimum 2 characters'
          : _name.text.trim().length > 100 ? 'Max 100 characters' : null;
      _dateErr = _validateDate(_date.text);
      _timeErr = timeRequired ? 'Time required for Completed status' : null;
    });
    if ([_nameErr, _dateErr, _timeErr].any((e) => e != null) || _saving) return;
    setState(() => _saving = true);
    final nav = Navigator.of(context);
    try {
      final weightKg = _weightInKg;

      await ref.read(recordControllerProvider.notifier).addPetRecord(PetRecord(
        id: '', petID: widget.petId, petName: widget.petName,
        petType: widget.petType, category: 'Vaccination',
        collection: 'vaccinations', status: _status,
        dateString: _date.text.trim(),
        dateTimestamp: _parseDateStr(_date.text.trim()),
        extra: {
          'vaccine_name': _name.text.trim(), 'type': _type,
          'veterinarian': _vet.text.trim(),
          'dosage': _dosage.text.trim().isEmpty ? '' : '${_dosage.text.trim()} $_unit',
          'time': _time.text.trim(),
          if (weightKg != null) 'pet_weight': weightKg,
          if (_location != null) 'clinic_location': _location!.display,
        },
      ));

      // Always log to history; mark as current only if toggled
      if (weightKg != null) {
        await ref.read(recordControllerProvider.notifier).addWeightRecord(
          petId: widget.petId,
          weight: weightKg,
          unit: 'kg',
          dateString: DateFormat('dd.MM.yyyy').format(DateTime.now()),
          recordedDate: DateTime.now(),
          forceUpdateCurrent: _isCurrentWeight,
        );
      }

      if (mounted) { nav.pop(); widget.onSaved?.call('Vaccination'); }
    } catch (e) {
      if (mounted) showRecordToast(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _lbl(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(t, style: const TextStyle(
          color: RecordsPalette.ink, fontWeight: FontWeight.bold, fontSize: 13)));

  InputDecoration _deco({String? hint, bool err = false, Widget? suffix}) =>
      InputDecoration(
        isDense: true, hintText: hint, counterText: '',
        hintStyle: TextStyle(color: RecordsPalette.muted.withOpacity(0.7), fontSize: 12),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: err ? Colors.red : RecordsPalette.linenDeep, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: err ? Colors.red : RecordsPalette.steel, width: 2)),
      );

  Widget _errText(String t) => Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(t, style: const TextStyle(color: Colors.red, fontSize: 11)));

  Widget _pill(String o, String cur, void Function(String) fn) {
    final sel = cur == o;
    return GestureDetector(onTap: () => fn(o),
      child: AnimatedContainer(duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? RecordsPalette.steel : Colors.transparent,
          border: Border.all(color: RecordsPalette.steel, width: 1.5),
          borderRadius: BorderRadius.circular(20)),
        child: Text(o, style: TextStyle(
            color: sel ? Colors.white : RecordsPalette.steel,
            fontSize: 11, fontWeight: FontWeight.bold))));
  }

  @override
  Widget build(BuildContext ctx) {
    final rel = dateRelation(parseDMY(_date.text));
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFEDF4EB), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.verified_outlined, color: Color(0xFF5A9E62), size: 18)),
          const SizedBox(width: 10),
          const Expanded(child: Text('Add Vaccination', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: RecordsPalette.ink))),
          if (widget.onCancel != null)
            GestureDetector(onTap: _handleCancel,
              child: Container(padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.close_rounded, size: 16, color: RecordsPalette.ink))),
        ]),
        const SizedBox(height: 12),
        _PetNameBanner(petName: widget.petName),
        const SizedBox(height: 16),

        _lbl('Vaccine Name'),
        TextField(controller: _name, maxLength: 100,
            onChanged: (_) => setState(() => _nameErr = null),
            decoration: _deco(hint: 'e.g. Rabies, DHPP', err: _nameErr != null)),
        if (_nameErr != null) _errText(_nameErr!),
        const SizedBox(height: 14),

        _lbl('Vaccine Type'),
        Row(children: [
          _pill('CORE', _type, (v) => setState(() => _type = v)),
          _pill('NON-CORE', _type, (v) => setState(() => _type = v)),
        ]),
        const SizedBox(height: 14),

        _lbl('Date of Vaccination'),
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(
              context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2000),
              lastDate: _status != 'UPCOMING' ? DateTime.now() : DateTime(2101),
              builder: (c, child) => Theme(data: Theme.of(c).copyWith(
                  colorScheme: const ColorScheme.light(primary: RecordsPalette.steel)), child: child!),
            );
            if (d != null) {
              final fmt = DateFormat('dd.MM.yyyy').format(d);
              final corrected = autoCorrectStatus(_status, dateRelation(parseDMY(fmt)));
              final changed = corrected != _status;
              setState(() { _date.text = fmt; _status = corrected; _dateErr = null; });
              if (changed && context.mounted)
                showRecordToast(context,
                    "Status updated to '${corrected[0]}${corrected.substring(1).toLowerCase()}'",
                    icon: Icons.info_outline_rounded);
            }
          },
          child: AbsorbPointer(child: TextField(controller: _date,
              decoration: _deco(hint: 'DD.MM.YYYY', err: _dateErr != null,
                  suffix: Icon(Icons.calendar_month, size: 18, color: RecordsPalette.muted)))),
        ),
        if (_dateErr != null) _errText(_dateErr!),
        const SizedBox(height: 14),

        _lbl('Veterinarian'),
        TextField(controller: _vet, maxLength: 100,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
            decoration: _deco(hint: 'Dr. Name')),
        const SizedBox(height: 14),

        _lbl('Clinic Location'),
        LocationSelectorField(value: _location,
            onChanged: (loc) => setState(() => _location = loc),
            decoration: _deco(hint: 'Tap to select location')),
        const SizedBox(height: 14),

        _lbl('Dosage'),
        Row(children: [
          Expanded(child: TextField(controller: _dosage,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _deco(hint: 'Amount'))),
          const SizedBox(width: 10),
          Row(mainAxisSize: MainAxisSize.min, children: [
            _pill('MG', _unit, (v) => setState(() => _unit = v)),
            _pill('ML', _unit, (v) => setState(() => _unit = v)),
          ]),
        ]),
        const SizedBox(height: 14),

        _lbl('Administration Time'),
        GestureDetector(onTap: _showTimePicker,
          child: AbsorbPointer(child: TextField(controller: _time,
              decoration: _deco(hint: 'Tap to select',
                  err: _timeErr != null,
                  suffix: const Icon(Icons.access_time, color: RecordsPalette.steel))))),
        if (_timeErr != null) _errText(_timeErr!),
        const SizedBox(height: 14),

        _lbl('Pet Weight'),
        _WeightWithCurrentToggle(
          controller: _weightCtrl,
          unit: _weightUnit,
          isCurrentWeight: _isCurrentWeight,
          onUnitChanged: (u) {
            final cur = double.tryParse(_weightCtrl.text.trim());
            if (cur != null && cur > 0) {
              _weightCtrl.text = (u == 'lbs' ? cur * 2.20462 : cur / 2.20462).toStringAsFixed(1);
            }
            setState(() => _weightUnit = u);
          },
          onCurrentToggled: (v) => setState(() => _isCurrentWeight = v),
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 14),

        _lbl('Status'),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          smartStatusBtn(label: 'Upcoming', color: const Color(0xFFBA7F57),
              current: _status, rel: rel,
              onSelect: (v) => setState(() { _status = v; _dateErr = null; }), context: context),
          smartStatusBtn(label: 'Ongoing', color: RecordsPalette.steel,
              current: _status, rel: rel,
              onSelect: (v) => setState(() { _status = v; _dateErr = null; }), context: context),
          smartStatusBtn(label: 'Completed', color: const Color(0xFF5A9E62),
              current: _status, rel: rel,
              onSelect: (v) => setState(() { _status = v; _dateErr = null; }), context: context),
        ]),
        const SizedBox(height: 24),

        Row(children: [
          if (widget.onCancel != null) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : _handleCancel,
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: RecordsPalette.linenDeep),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Cancel',
                    style: TextStyle(color: RecordsPalette.muted, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: RecordsPalette.steel,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('SAVE VACCINATION', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── Shared weight + current toggle widget ─────────────────────────────────────
class _WeightWithCurrentToggle extends StatelessWidget {
  final TextEditingController controller;
  final String unit;
  final bool isCurrentWeight;
  final ValueChanged<String> onUnitChanged;
  final ValueChanged<bool> onCurrentToggled;
  final VoidCallback onChanged;

  const _WeightWithCurrentToggle({
    required this.controller,
    required this.unit,
    required this.isCurrentWeight,
    required this.onUnitChanged,
    required this.onCurrentToggled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = controller.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              onChanged: (_) => onChanged(),
              style: const TextStyle(fontSize: 13, color: RecordsPalette.ink),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'e.g. 4.5',
                counterText: '',
                suffixText: unit,
                hintStyle: TextStyle(
                    color: RecordsPalette.muted.withOpacity(0.7), fontSize: 12),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: RecordsPalette.linenDeep, width: 1.5)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: RecordsPalette.steel, width: 2)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _unitBtn('kg', unit, onUnitChanged),
              const SizedBox(height: 3),
              _unitBtn('lbs', unit, onUnitChanged),
            ]),
          ),
        ]),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          child: hasValue
              ? GestureDetector(
                  onTap: () => onCurrentToggled(!isCurrentWeight),
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isCurrentWeight
                          ? RecordsPalette.steel.withOpacity(0.08)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCurrentWeight ? RecordsPalette.steel : RecordsPalette.linenDeep,
                        width: isCurrentWeight ? 1.5 : 1,
                      ),
                    ),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 18, height: 18,
                        decoration: BoxDecoration(
                          color: isCurrentWeight ? RecordsPalette.steel : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCurrentWeight ? RecordsPalette.steel : RecordsPalette.linenDeep,
                            width: 1.5,
                          ),
                        ),
                        child: isCurrentWeight
                            ? const Icon(Icons.check, size: 11, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Set as current weight',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: RecordsPalette.ink)),
                      ),
                      if (isCurrentWeight)
                        const Icon(Icons.sync_rounded, size: 14, color: RecordsPalette.steel),
                    ]),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        if (hasValue)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              isCurrentWeight
                  ? 'Will be logged to history and set as current weight.'
                  : 'Will be logged to weight history only.',
              style: TextStyle(fontSize: 10, color: RecordsPalette.muted.withOpacity(0.8)),
            ),
          ),
      ],
    );
  }

  Widget _unitBtn(String label, String current, ValueChanged<String> onChanged) {
    final sel = current == label;
    return GestureDetector(
      onTap: () => onChanged(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? RecordsPalette.steel : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: sel ? Colors.white : RecordsPalette.muted)),
      ),
    );
  }
}

class _PetNameBanner extends StatelessWidget {
  final String petName;
  const _PetNameBanner({required this.petName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF546E7A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.pets, color: Colors.white, size: 15),
        const SizedBox(width: 8),
        Text(petName,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }
}