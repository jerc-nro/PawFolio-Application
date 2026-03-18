import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/record_model.dart';
import '../providers/record_provider.dart';
import '../screen/records_navigator.dart';
import '../theme/records_theme.dart';
import '_status_date_logic.dart';
import 'location_selector_widget.dart';
import 'pet_weight_field.dart';

void showAddVetVisitDialog(
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
        child: _VetContent(
            petId: petId, petName: petName, petType: petType,
            onSaved: onSaved, onCancel: onCancel),
      ),
    ),
  );
}

class _VetContent extends ConsumerStatefulWidget {
  final String petId, petName, petType;
  final void Function(String)? onSaved;
  final VoidCallback? onCancel;
  const _VetContent({
    required this.petId, required this.petName, required this.petType,
    this.onSaved, this.onCancel,
  });
  @override
  ConsumerState<_VetContent> createState() => _VetState();
}

class _VetState extends ConsumerState<_VetContent> {
  final _reason = TextEditingController();
  final _date   = TextEditingController();
  final _time   = TextEditingController();
  final _clinic = TextEditingController();
  final _vet    = TextEditingController();
  final _notes  = TextEditingController();

  String    _status = 'UPCOMING';
  TimeOfDay _tod    = TimeOfDay.now();
  bool      _saving = false;
  ClinicLocation? _location;
  double?   _petWeightKg;
  bool      _isCurrentWeight = false;

  String? _reasonErr, _dateErr;

  @override
  void dispose() {
    for (final c in [_reason, _date, _time, _clinic, _vet, _notes]) c.dispose();
    super.dispose();
  }

  DateTime? _parseDateStr(String s) {
    try {
      final p = s.split('.');
      return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
    } catch (_) { return null; }
  }

  String? _validateReason(String v) {
    if (v.trim().isEmpty) return 'Reason is required';
    if (v.trim().length < 3) return 'Minimum 3 characters';
    if (v.trim().length > 200) return 'Max 200 characters';
    return null;
  }

  String? _validateDate(String v) {
    if (v.trim().isEmpty) return 'Date is required';
    final d = _parseDateStr(v);
    if (d == null) return 'Invalid date format';
    if (_status == 'UPCOMING' &&
        d.isBefore(DateTime.now().subtract(const Duration(days: 1))))
      return 'Future date required for Upcoming';
    if (_status == 'COMPLETED' && d.isAfter(DateTime.now()))
      return 'Past/present date required for Completed';
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
                    setState(() { _tod = picked; _time.text = _tod.format(context); });
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
    if (_notes.text.length > 1000) {
      showRecordToast(context, 'Notes must be under 1000 characters', isError: true);
      return;
    }
    setState(() {
      _reasonErr = _validateReason(_reason.text);
      _dateErr   = _validateDate(_date.text);
    });
    if ([_reasonErr, _dateErr].any((e) => e != null) || _saving) return;
    setState(() => _saving = true);
    final nav = Navigator.of(context);
    try {
      await ref.read(recordControllerProvider.notifier).addPetRecord(PetRecord(
        id: '', petID: widget.petId, petName: widget.petName,
        petType: widget.petType, category: 'Vet Visit',
        collection: 'vet_visits', status: _status,
        dateString: _date.text.trim(),
        dateTimestamp: _parseDateStr(_date.text.trim()),
        extra: {
          'reason': _reason.text.trim(), 'time': _time.text.trim(),
          'clinic_name': _clinic.text.trim(), 'veterinarian': _vet.text.trim(),
          'description': _notes.text.trim(),
          if (_petWeightKg != null) 'pet_weight': _petWeightKg,
          if (_location != null) 'clinic_location': _location!.display,
        },
      ));
      if (_petWeightKg != null && _isCurrentWeight) {
        await ref.read(recordControllerProvider.notifier).updatePetWeight(
          petId: widget.petId, weightKg: _petWeightKg!,
          dateString: DateFormat('dd.MM.yyyy').format(DateTime.now()),
        );
      }
      if (mounted) { nav.pop(); widget.onSaved?.call('Vet Visit'); }
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

  @override
  Widget build(BuildContext ctx) {
    final rel = dateRelation(parseDMY(_date.text));
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFEAF2FB), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.local_hospital_outlined, color: Color(0xFF45617D), size: 18)),
          const SizedBox(width: 10),
          const Expanded(child: Text('Add Vet Visit', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: RecordsPalette.ink))),
          if (widget.onCancel != null)
            GestureDetector(onTap: _handleCancel,
              child: Container(padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.close_rounded, size: 16, color: RecordsPalette.ink))),
        ]),
        const SizedBox(height: 16),

        _lbl('Reason for Visit'),
        TextField(controller: _reason, maxLength: 200,
            onChanged: (_) => setState(() => _reasonErr = null),
            decoration: _deco(hint: 'e.g. Annual Checkup', err: _reasonErr != null)),
        if (_reasonErr != null) _errText(_reasonErr!),
        const SizedBox(height: 14),

        _lbl('Date of Visit'),
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(
              context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2000),
              lastDate: _status == 'COMPLETED' ? DateTime.now() : DateTime(2101),
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

        _lbl('Visit Time'),
        GestureDetector(onTap: _showTimePicker,
          child: AbsorbPointer(child: TextField(controller: _time,
              decoration: _deco(hint: 'Tap to select',
                  suffix: const Icon(Icons.access_time, color: RecordsPalette.steel))))),
        const SizedBox(height: 14),

        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _lbl('Clinic'),
            TextField(controller: _clinic, maxLength: 100, decoration: _deco(hint: 'Clinic Name')),
          ])),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _lbl('Veterinarian'),
            TextField(controller: _vet, maxLength: 100, decoration: _deco(hint: 'Dr. Name')),
          ])),
        ]),
        const SizedBox(height: 14),

        _lbl('Clinic Location'),
        LocationSelectorField(value: _location,
            onChanged: (loc) => setState(() => _location = loc),
            decoration: _deco(hint: 'Tap to select location')),
        const SizedBox(height: 14),

        _lbl('Notes / Findings'),
        TextField(controller: _notes, maxLines: 3, maxLength: 1000,
            decoration: _deco(hint: 'Enter findings or instructions...')),
        const SizedBox(height: 14),

        _lbl('Pet Weight'),
        PetWeightField(onChanged: (kg, isCurrent) => setState(() {
          _petWeightKg = kg; _isCurrentWeight = isCurrent;
        })),
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
            Expanded(child: GestureDetector(onTap: _saving ? null : _handleCancel,
              child: Container(height: 48, alignment: Alignment.center,
                decoration: BoxDecoration(color: RecordsPalette.sageLite,
                    borderRadius: BorderRadius.circular(12)),
                child: const Text('Cancel', style: TextStyle(
                    color: RecordsPalette.muted, fontWeight: FontWeight.w600))))),
            const SizedBox(width: 10),
          ],
          Expanded(child: SizedBox(height: 48,
            child: ElevatedButton(onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: RecordsPalette.steel,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('SAVE VET VISIT', style: TextStyle(fontWeight: FontWeight.bold))))),
        ]),
      ]),
    );
  }
}