import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/record_provider.dart';
import '../../../models/record_model.dart';
import '../screen/records_navigator.dart';
import '../theme/records_theme.dart';
import '_status_date_logic.dart';

void showAddMedicationDialog(
  BuildContext context,
  String petId,
  String petName,
  String petType, {
  void Function(String label)? onSaved,
}) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width > 500
            ? 420
            : MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(25)),
        child: _MedContent(
            petId: petId, petName: petName, petType: petType, onSaved: onSaved),
      ),
    ),
  );
}

class _MedContent extends ConsumerStatefulWidget {
  final String petId, petName, petType;
  final void Function(String)? onSaved;
  const _MedContent(
      {required this.petId,
      required this.petName,
      required this.petType,
      this.onSaved});
  @override
  ConsumerState<_MedContent> createState() => _MedState();
}

class _MedState extends ConsumerState<_MedContent> {
  final _name   = TextEditingController();
  final _date   = TextEditingController();
  final _clinic = TextEditingController();
  final _vet    = TextEditingController();
  final _dosage = TextEditingController();
  final _wgt    = TextEditingController();

  int    _intake = 1;
  String _period = 'week';
  String _unit   = 'MG';
  String _status = 'UPCOMING';
  bool   _saving = false;

  String? _nameErr, _dateErr, _dosageErr, _wgtErr;

  @override
  void dispose() {
    for (final c in [_name, _date, _clinic, _vet, _dosage, _wgt]) c.dispose();
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
          'clinic_name':     _clinic.text.trim(),
          'veterinarian':    _vet.text.trim(),
          'pet_weight':      double.tryParse(_wgt.text.trim()) ?? 0.0,
          'dosage':          '${_dosage.text.trim()} $_unit',
          'intake_count':    _intake,
          'period':          _period,
        },
      );

      await ref.read(recordControllerProvider.notifier).addPetRecord(record);

      if (mounted) {
        nav.pop();
        widget.onSaved?.call('Medication');
      }
    } catch (e) {
      if (mounted) showRecordToast(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _lbl(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: const TextStyle(
                color: RecordsPalette.ink,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      );

  InputDecoration _deco({String? hint, bool err = false, Widget? suffix}) =>
      InputDecoration(
        isDense: true,
        hintText: hint,
        counterText: '',
        hintStyle:
            TextStyle(color: RecordsPalette.muted.withOpacity(0.7), fontSize: 12),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: err ? Colors.red : RecordsPalette.linenDeep,
                width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: err ? Colors.red : RecordsPalette.steel, width: 2)),
      );

  Widget _errText(String t) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(t, style: const TextStyle(color: Colors.red, fontSize: 11)),
      );

  Widget _pill(String o, String cur, void Function(String) fn) {
    final sel = cur == o;
    return GestureDetector(
      onTap: () => fn(o),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? RecordsPalette.steel : Colors.transparent,
          border: Border.all(color: RecordsPalette.steel, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(o,
            style: TextStyle(
                color: sel ? Colors.white : RecordsPalette.steel,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final daterltn = dateRelation(parseDMY(_date.text));
    return SingleChildScrollView(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E8),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.science_outlined,
                    color: Color(0xFFBA7F57), size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Add Medication',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: RecordsPalette.ink)),
            ]),
            const SizedBox(height: 16),

            _lbl('Medication Name'),
            TextField(
                controller: _name,
                maxLength: 100,
                onChanged: (_) => setState(() => _nameErr = null),
                decoration: _deco(
                    hint: 'e.g. Antibiotics', err: _nameErr != null)),
            if (_nameErr != null) _errText(_nameErr!),
            const SizedBox(height: 14),

            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _lbl('Start Date'),
                      GestureDetector(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                            builder: (c, child) => Theme(
                                data: Theme.of(c).copyWith(
                                    colorScheme: const ColorScheme.light(
                                        primary: RecordsPalette.steel)),
                                child: child!),
                          );
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
                              showRecordToast(context, "Status updated to '$nice'",
                                  icon: Icons.info_outline_rounded);
                            }
                          }
                        },
                        child: AbsorbPointer(
                            child: TextField(
                                controller: _date,
                                decoration: _deco(
                                    hint: 'DD.MM.YYYY',
                                    err: _dateErr != null,
                                    suffix: Icon(Icons.calendar_month,
                                        size: 18,
                                        color: RecordsPalette.muted)))),
                      ),
                      if (_dateErr != null) _errText(_dateErr!),
                    ]),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _lbl('Pet Weight (kg)'),
                      TextField(
                          controller: _wgt,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) =>
                              setState(() => _wgtErr = null),
                          decoration: _deco(
                              hint: 'e.g. 4.5', err: _wgtErr != null)),
                      if (_wgtErr != null) _errText(_wgtErr!),
                    ]),
              ),
            ]),
            const SizedBox(height: 14),

            _lbl('Clinic Name'),
            TextField(
                controller: _clinic,
                maxLength: 100,
                decoration: _deco(hint: 'Clinic Name')),
            const SizedBox(height: 14),

            _lbl('Veterinarian'),
            TextField(
                controller: _vet,
                maxLength: 100,
                decoration: _deco(hint: 'Dr. Smith')),
            const SizedBox(height: 14),

            _lbl('Dosage'),
            Row(children: [
              Expanded(
                child: TextField(
                    controller: _dosage,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    onChanged: (_) => setState(() => _dosageErr = null),
                    decoration:
                        _deco(hint: 'Amount', err: _dosageErr != null)),
              ),
              const SizedBox(width: 10),
              Row(mainAxisSize: MainAxisSize.min, children: [
                _pill('MG', _unit, (v) => setState(() => _unit = v)),
                _pill('ML', _unit, (v) => setState(() => _unit = v)),
              ]),
            ]),
            if (_dosageErr != null) _errText(_dosageErr!),
            const SizedBox(height: 14),

            _lbl('Frequency'),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  border: Border.all(
                      color: RecordsPalette.linenDeep),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Text('Intake',
                    style: TextStyle(
                        fontSize: 12,
                        color: RecordsPalette.muted)),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _intake,
                  underline: const SizedBox(),
                  items: List.generate(20, (i) => i + 1)
                      .map((v) => DropdownMenuItem(
                          value: v, child: Text('$v')))
                      .toList(),
                  onChanged: (v) => setState(() => _intake = v!),
                ),
                Text(' times a ',
                    style: TextStyle(
                        fontSize: 12, color: RecordsPalette.muted)),
                DropdownButton<String>(
                  value: _period,
                  underline: const SizedBox(),
                  items: ['day', 'week', 'month']
                      .map((v) => DropdownMenuItem(
                          value: v,
                          child: Text(v,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: RecordsPalette.steel))))
                      .toList(),
                  onChanged: (v) => setState(() => _period = v!),
                ),
              ]),
            ),
            const SizedBox(height: 14),

            _lbl('Status'),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  smartStatusBtn(
                      label: 'Upcoming',
                      color: const Color(0xFFBA7F57),
                      current: _status,
                      rel: daterltn,
                      onSelect: (v) =>
                          setState(() { _status = v; _dateErr = null; }),
                      context: context),
                  smartStatusBtn(
                      label: 'Ongoing',
                      color: RecordsPalette.steel,
                      current: _status,
                      rel: daterltn,
                      onSelect: (v) =>
                          setState(() { _status = v; _dateErr = null; }),
                      context: context),
                  smartStatusBtn(
                      label: 'Completed',
                      color: const Color(0xFF5A9E62),
                      current: _status,
                      rel: daterltn,
                      onSelect: (v) =>
                          setState(() { _status = v; _dateErr = null; }),
                      context: context),
                ]),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: RecordsPalette.steel,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('SAVE MEDICATION',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
    );
  }
}