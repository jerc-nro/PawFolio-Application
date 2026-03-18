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

void showAddPreventativeDialog(
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
        child: _PrevContent(
            petId: petId, petName: petName, petType: petType,
            onSaved: onSaved, onCancel: onCancel),
      ),
    ),
  );
}

class _PrevContent extends ConsumerStatefulWidget {
  final String petId, petName, petType;
  final void Function(String)? onSaved;
  final VoidCallback? onCancel;
  const _PrevContent({
    required this.petId, required this.petName, required this.petType,
    this.onSaved, this.onCancel,
  });
  @override
  ConsumerState<_PrevContent> createState() => _PS();
}

class _PS extends ConsumerState<_PrevContent> {
  final _brand  = TextEditingController();
  final _date   = TextEditingController();
  final _clinic = TextEditingController();
  final _vet    = TextEditingController();
  final _dosage = TextEditingController();
  final _other  = TextEditingController();
  final _time   = TextEditingController();

  static const _types = ['Flea/Tick', 'Heartworm', 'Dewormer', 'Multi-Parasite', 'Other'];
  String    _type   = 'Flea/Tick';
  String    _unit   = 'MG';
  String    _status = 'UPCOMING';
  TimeOfDay _tod    = const TimeOfDay(hour: 8, minute: 0);
  bool      _saving = false;
  ClinicLocation? _location;
  double?   _petWeightKg;
  bool      _isCurrentWeight = false;

  String? _brandErr, _dateErr, _dosageErr;

  @override
  void dispose() {
    for (final c in [_brand, _date, _clinic, _vet, _dosage, _other, _time]) c.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String s) {
    try {
      final p = s.split('.');
      return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
    } catch (_) { return null; }
  }

  String? _validateDate(String v) {
    if (v.trim().isEmpty) return 'Date is required';
    final d = _parseDate(v);
    if (d == null) return 'Invalid date format';
    if (_status == 'COMPLETED' && d.isAfter(DateTime.now()))
      return 'Past/present date required for Completed';
    if (_status == 'UPCOMING' &&
        d.isBefore(DateTime.now().subtract(const Duration(days: 1))))
      return 'Future date required for Upcoming';
    return null;
  }

  String? _validateDosage(String v) {
    if (v.trim().isEmpty) return null;
    final d = double.tryParse(v.trim());
    if (d == null) return 'Must be a valid number';
    if (d <= 0) return 'Must be greater than 0';
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
    if (_type == 'Other' && _other.text.trim().isEmpty) {
      showRecordToast(context, 'Please specify the preventative type', isError: true);
      return;
    }
    setState(() {
      _brandErr = _brand.text.trim().isEmpty ? 'Brand name is required'
          : _brand.text.trim().length < 2 ? 'Minimum 2 characters'
          : _brand.text.trim().length > 100 ? 'Max 100 characters' : null;
      _dateErr   = _validateDate(_date.text);
      _dosageErr = _validateDosage(_dosage.text);
    });
    if ([_brandErr, _dateErr, _dosageErr].any((e) => e != null) || _saving) return;
    setState(() => _saving = true);
    final nav = Navigator.of(context);
    try {
      await ref.read(recordControllerProvider.notifier).addPetRecord(PetRecord(
        id: '', petID: widget.petId, petName: widget.petName,
        petType: widget.petType, category: 'Preventative',
        collection: 'preventatives', status: _status,
        dateString: _date.text.trim(),
        dateTimestamp: _parseDate(_date.text.trim()),
        extra: {
          'brand_name': _brand.text.trim(),
          'type': _type == 'Other' ? _other.text.trim() : _type,
          'clinic_name': _clinic.text.trim(),
          'veterinarian': _vet.text.trim(),
          'dosage': _dosage.text.trim().isEmpty ? '' : '${_dosage.text.trim()} $_unit',
          'intake_time': _time.text.trim(),
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
      if (mounted) { nav.pop(); widget.onSaved?.call('Preventative'); }
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
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            decoration: BoxDecoration(color: const Color(0xFFEDF0FA), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.shield_outlined, color: Color(0xFF5C6BAD), size: 18)),
          const SizedBox(width: 10),
          const Expanded(child: Text('Add Preventative', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: RecordsPalette.ink))),
          if (widget.onCancel != null)
            GestureDetector(onTap: _handleCancel,
              child: Container(padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.close_rounded, size: 16, color: RecordsPalette.ink))),
        ]),
        const SizedBox(height: 16),

        _lbl('Brand Name'),
        TextField(controller: _brand, maxLength: 100,
            onChanged: (_) => setState(() => _brandErr = null),
            decoration: _deco(hint: 'e.g. NexGard', err: _brandErr != null)),
        if (_brandErr != null) _errText(_brandErr!),
        const SizedBox(height: 14),

        _lbl('Preventative Type'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
              border: Border.all(color: RecordsPalette.linenDeep, width: 1.5)),
          child: DropdownButtonHideUnderline(child: DropdownButton<String>(
            value: _type, isExpanded: true,
            items: _types.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => _type = v!),
          )),
        ),
        if (_type == 'Other') ...[
          const SizedBox(height: 8),
          TextField(controller: _other, maxLength: 100,
              decoration: _deco(hint: 'Specify type (e.g. Ear Mites)')),
        ],
        const SizedBox(height: 14),

        _lbl('Date of Administration'),
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

        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _lbl('Clinic'),
            TextField(controller: _clinic, maxLength: 100, decoration: _deco(hint: 'Clinic')),
          ])),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _lbl('Vet'),
            TextField(controller: _vet, maxLength: 100, decoration: _deco(hint: 'Dr. Smith')),
          ])),
        ]),
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
              onChanged: (_) => setState(() => _dosageErr = null),
              decoration: _deco(hint: 'Amount', err: _dosageErr != null))),
          const SizedBox(width: 10),
          Row(mainAxisSize: MainAxisSize.min, children: [
            _pill('MG', _unit, (v) => setState(() => _unit = v)),
            _pill('ML', _unit, (v) => setState(() => _unit = v)),
          ]),
        ]),
        if (_dosageErr != null) _errText(_dosageErr!),
        const SizedBox(height: 14),

        _lbl('Intake Time'),
        GestureDetector(onTap: _showTimePicker,
          child: AbsorbPointer(child: TextField(controller: _time,
              decoration: _deco(hint: 'Tap to select time',
                  suffix: const Icon(Icons.access_time, color: RecordsPalette.steel))))),
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
                  : const Text('SAVE PREVENTATIVE', style: TextStyle(fontWeight: FontWeight.bold))))),
        ]),
      ]),
    );
  }
}