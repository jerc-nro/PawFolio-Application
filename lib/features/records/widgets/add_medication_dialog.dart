import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/record_provider.dart';
import '../../../models/record_model.dart';
import '_status_date_logic.dart';

// ── Shared palette ────────────────────────────────────────────
const _ink   = Color(0xFF455A64);
const _blue  = Color(0xFF0277BD);
const _green = Color(0xFF388E3C);
const _red   = Colors.red;

// ── Helpers ───────────────────────────────────────────────────
Widget _label(String t, {bool required = false}) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(t, style: const TextStyle(color: _ink, fontWeight: FontWeight.bold, fontSize: 13)),
);

InputDecoration _deco({String? hint, bool err = false, Widget? suffix, int? maxLen}) =>
    InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      suffixIcon: suffix,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: err ? _red : _blue, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: err ? _red : _blue, width: 2)),
    );

Widget _errText(String t) => Padding(
  padding: const EdgeInsets.only(top: 3),
  child: Text(t, style: const TextStyle(color: Colors.red, fontSize: 11)),
);

Widget _togglePills(List<String> opts, String cur, void Function(String) fn) =>
    Row(mainAxisSize: MainAxisSize.min, children: opts.map((o) {
      final sel = cur == o;
      return GestureDetector(
        onTap: () => fn(o),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: sel ? _blue : Colors.transparent,
            border: Border.all(color: _blue, width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(o, style: TextStyle(
              color: sel ? Colors.white : _blue,
              fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      );
    }).toList());

Future<DateTime?> _pickDate(BuildContext ctx,
    {bool pastOnly = false, bool futureAllowed = true}) =>
    showDatePicker(
      context: ctx,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: pastOnly ? DateTime.now() : DateTime(2101),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _ink)),
        child: child!,
      ),
    );

// ══════════════════════════════════════════════════════════════
//  MEDICATION
// ══════════════════════════════════════════════════════════════
void showAddMedicationDialog(BuildContext context, String petId, String petName, String petType) {
  showDialog(context: context, builder: (_) => Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      width: MediaQuery.of(context).size.width > 500 ? 420 : MediaQuery.of(context).size.width * 0.9,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: _MedContent(petId: petId, petName: petName, petType: petType),
    ),
  ));
}

class _MedContent extends ConsumerStatefulWidget {
  final String petId;
  final String petName;
  final String petType;
  const _MedContent({required this.petId, required this.petName, required this.petType});
  @override ConsumerState<_MedContent> createState() => _MedState();
}

class _MedState extends ConsumerState<_MedContent> {
  final _name   = TextEditingController();
  final _date   = TextEditingController();
  final _clinic = TextEditingController();
  final _vet    = TextEditingController();
  final _dosage = TextEditingController();
  final _wgt    = TextEditingController();

  int    _intake  = 1;
  String _period  = 'week';
  String _unit    = 'MG';
  String _status  = 'UPCOMING';
  bool   _saving  = false;

  String? _nameErr, _dateErr, _dosageErr, _wgtErr;

  @override
  void dispose() {
    for (final c in [_name,_date,_clinic,_vet,_dosage,_wgt]) c.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String s) {
    try {
      final p = s.split('.');
      return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
    } catch (_) { return null; }
  }

  String? _validateName(String v) {
    if (v.trim().isEmpty) return 'Medication name is required';
    if (v.trim().length > 100) return 'Max 100 characters';
    return null;
  }

  String? _validateDate(String v) {
    if (v.trim().isEmpty) return 'Start date is required';
    if (_parseDate(v) == null) return 'Invalid date format';
    return null;
  }

  String? _validateDosage(String v) {
    if (v.trim().isEmpty) return 'Dosage is required';
    if (double.tryParse(v.trim()) == null) return 'Must be a number';
    if (double.parse(v.trim()) <= 0) return 'Must be greater than 0';
    return null;
  }

  String? _validateWeight(String v) {
    if (v.trim().isEmpty) return null;
    final d = double.tryParse(v.trim());
    if (d == null) return 'Must be a number';
    if (d <= 0) return 'Must be > 0';
    if (d > 100) return 'Max 100 kg';
    return null;
  }

  Future<void> _save() async {
    setState(() {
      _nameErr   = _validateName(_name.text);
      _dateErr   = _validateDate(_date.text);
      _dosageErr = _validateDosage(_dosage.text);
      _wgtErr    = _validateWeight(_wgt.text);
    });
    if ([_nameErr, _dateErr, _dosageErr, _wgtErr].any((e) => e != null) || _saving) return;

    setState(() => _saving = true);
    final msg = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      final record = PetRecord(
        id: '',
        petID: widget.petId,
        petName: widget.petName,
        petType: widget.petType,
        category: 'Medication',
        collection: 'medications',
        status: _status,
        dateString: _date.text.trim(),
        dateTimestamp: _parseDate(_date.text.trim()),
        extra: {
          'medication_name': _name.text.trim(),
          'clinic_name': _clinic.text.trim(),
          'veterinarian': _vet.text.trim(),
          'pet_weight': double.tryParse(_wgt.text.trim()) ?? 0.0,
          'dosage': '${_dosage.text.trim()} $_unit',
          'intake_count': _intake,
          'period': _period,
        },
      );

      await ref.read(recordControllerProvider.notifier).addPetRecord(record);
      
      if (mounted) {
        nav.pop();
        msg.showSnackBar(const SnackBar(content: Text('Medication saved!'), backgroundColor: _green));
      }
    } catch (e) {
      if (mounted) msg.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final _dateRelation = dateRelation(parseDMY(_date.text));
    return SingleChildScrollView(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      const Row(children: [
        Icon(Icons.medication_liquid_outlined, color: _ink, size: 20),
        SizedBox(width: 8),
        Text('Add Medication', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _ink)),
      ]),
      const SizedBox(height: 16),

      _label('Medication Name'),
      TextField(controller: _name, maxLength: 100, onChanged: (_) => setState(() => _nameErr = null),
        decoration: _deco(hint: 'e.g. Antibiotics', err: _nameErr != null)),
      if (_nameErr != null) _errText(_nameErr!),
      const SizedBox(height: 14),

      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('Start Date'),
          GestureDetector(
            onTap: () async {
              final d = await _pickDate(ctx, pastOnly: false, futureAllowed: true);
              if (d != null) {
              final formatted = DateFormat('dd.MM.yyyy').format(d);
              final rel = dateRelation(parseDMY(formatted));
              final corrected = autoCorrectStatus(_status, rel);
              final changed = corrected != _status;
              setState(() {
                _date.text = formatted;
                _status = corrected;
                _dateErr = null;
              });
              if (changed && context.mounted) {
                final nice = corrected[0] + corrected.substring(1).toLowerCase();
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: Text("Status updated to '$nice' for this date.",
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    backgroundColor: const Color(0xFF455A64),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    duration: const Duration(seconds: 3),
                  ));
              }
            }
            },
            child: AbsorbPointer(child: TextField(controller: _date,
              decoration: _deco(hint: 'DD.MM.YYYY', err: _dateErr != null,
                suffix: const Icon(Icons.calendar_month, size: 18)))),
          ),
          if (_dateErr != null) _errText(_dateErr!),
        ])),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('Pet Weight (kg)'),
          TextField(controller: _wgt, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() => _wgtErr = null),
            decoration: _deco(hint: 'e.g. 4.5', err: _wgtErr != null)),
          if (_wgtErr != null) _errText(_wgtErr!),
        ])),
      ]),
      const SizedBox(height: 14),

      _label('Clinic Name'),
      TextField(controller: _clinic, maxLength: 100, decoration: _deco(hint: 'Clinic Name')),
      const SizedBox(height: 14),

      _label('Veterinarian'),
      TextField(controller: _vet, maxLength: 100, decoration: _deco(hint: 'Dr. Smith')),
      const SizedBox(height: 14),

      _label('Dosage'),
      Row(children: [
        Expanded(child: TextField(controller: _dosage,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() => _dosageErr = null),
          decoration: _deco(hint: 'Amount', err: _dosageErr != null))),
        const SizedBox(width: 10),
        _togglePills(['MG','ML'], _unit, (v) => setState(() => _unit = v)),
      ]),
      if (_dosageErr != null) _errText(_dosageErr!),
      const SizedBox(height: 14),

      _label('Frequency'),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(border: Border.all(color: _blue.withOpacity(0.5)), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          const Text('Intake', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _intake, underline: const SizedBox(),
            items: List.generate(20, (i) => i+1).map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
            onChanged: (v) => setState(() => _intake = v!),
          ),
          const Text(' times a ', style: TextStyle(fontSize: 12, color: Colors.grey)),
          DropdownButton<String>(
            value: _period, underline: const SizedBox(),
            items: ['day','week','month'].map((v) => DropdownMenuItem(value: v,
              child: Text(v, style: const TextStyle(fontWeight: FontWeight.bold, color: _blue)))).toList(),
            onChanged: (v) => setState(() => _period = v!),
          ),
        ]),
      ),
      const SizedBox(height: 14),

      _label('Status'),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        smartStatusBtn(label: 'Upcoming',  color: const Color(0xFFFFB300), current: _status, rel: _dateRelation, onSelect: (v) => setState(() { _status = v; _dateErr = null; }), context: context),
        smartStatusBtn(label: 'Ongoing',   color: const Color(0xFFD32F2F), current: _status, rel: _dateRelation, onSelect: (v) => setState(() { _status = v; _dateErr = null; }), context: context),
        smartStatusBtn(label: 'Completed', color: const Color(0xFF388E3C), current: _status, rel: _dateRelation, onSelect: (v) => setState(() { _status = v; _dateErr = null; }), context: context),
      ]),
      const SizedBox(height: 24),

      SizedBox(width: double.infinity, height: 48,
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: _saving ? const SizedBox(width:20,height:20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('SAVE MEDICATION', style: TextStyle(fontWeight: FontWeight.bold)),
        )),
    ]),
  );
  }
}