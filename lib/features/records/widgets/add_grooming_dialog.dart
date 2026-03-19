import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/record_provider.dart';
import '../../../models/record_model.dart';
import '../screen/records_navigator.dart';
import '_status_date_logic.dart';
import '../theme/records_theme.dart';
import 'location_selector_widget.dart';

void showAddGroomingDialog(
  BuildContext context,
  String petId,
  String petName,
  String petType, {
  void Function(String label)? onSaved,
  VoidCallback? onCancel,
}) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width > 500
            ? 420
            : MediaQuery.of(context).size.width * 0.88,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(25)),
        child: _GroomContent(
          petId: petId,
          petName: petName,
          petType: petType,
          onSaved: onSaved,
          onCancel: onCancel,
        ),
      ),
    ),
  );
}

class _GroomContent extends ConsumerStatefulWidget {
  final String petId, petName, petType;
  final void Function(String)? onSaved;
  final VoidCallback? onCancel;
  const _GroomContent({
    required this.petId,
    required this.petName,
    required this.petType,
    this.onSaved,
    this.onCancel,
  });
  @override
  ConsumerState<_GroomContent> createState() => _GS();
}

class _GS extends ConsumerState<_GroomContent> {
  final _clinic = TextEditingController();
  final _date   = TextEditingController();

  static const _groomTypes = ['NAIL TRIM', 'FULL GROOM', 'BATH', 'EYE/EAR CLEAN'];
  String _type   = 'NAIL TRIM';
  String _status = 'UPCOMING';
  bool   _saving = false;
  ClinicLocation? _location;
  String? _clinicErr, _dateErr;

  @override
  void dispose() {
    _clinic.dispose();
    _date.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String s) {
    try {
      final p = s.split('.');
      return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
    } catch (_) { return null; }
  }

  String? _validateClinic(String v) {
    if (v.trim().isEmpty) return 'Clinic name is required';
    if (v.trim().length < 2) return 'Minimum 2 characters';
    if (v.trim().length > 100) return 'Max 100 characters';
    return null;
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

  void _handleCancel() {
    Navigator.of(context).pop();
    widget.onCancel?.call();
  }

  Future<void> _save() async {
    setState(() {
      _clinicErr = _validateClinic(_clinic.text);
      _dateErr   = _validateDate(_date.text);
    });
    if ([_clinicErr, _dateErr].any((e) => e != null) || _saving) return;

    setState(() => _saving = true);
    final nav = Navigator.of(context);
    try {
      final record = PetRecord(
        id: '',
        petID: widget.petId,
        petName: widget.petName,
        petType: widget.petType,
        category: 'Grooming',
        collection: 'groom_visits',
        status: _status,
        dateString: _date.text.trim(),
        dateTimestamp: _parseDate(_date.text.trim()),
        extra: {
          'provider': _clinic.text.trim(),
          'type': _type,
          if (_location != null) 'clinic_location': _location!.display,
        },
      );
      await ref.read(recordControllerProvider.notifier).addPetRecord(record);
      if (mounted) {
        nav.pop();
        widget.onSaved?.call('Grooming');
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
        hintStyle: TextStyle(
            color: RecordsPalette.muted.withOpacity(0.7), fontSize: 12),
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

  @override
  Widget build(BuildContext ctx) {
    final daterltn = dateRelation(parseDMY(_date.text));
    return SingleChildScrollView(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EEF8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.content_cut_outlined,
                    color: Color(0xFF8B6FAB), size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Add Grooming',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: RecordsPalette.ink)),
              ),
              if (widget.onCancel != null)
                GestureDetector(
                  onTap: _handleCancel,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: RecordsPalette.ink),
                  ),
                ),
            ]),
            const SizedBox(height: 12),
            _PetNameBanner(petName: widget.petName),
            const SizedBox(height: 16),

            _lbl('Clinic / Salon Name'),
            TextField(
                controller: _clinic,
                maxLength: 100,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                ],
                onChanged: (_) => setState(() => _clinicErr = null),
                decoration:
                    _deco(hint: 'e.g. Paws & Claws', err: _clinicErr != null)),
            if (_clinicErr != null)
              Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(_clinicErr!,
                      style: const TextStyle(color: Colors.red, fontSize: 11))),
            const SizedBox(height: 14),

            _lbl('Date of Service'),
            GestureDetector(
              onTap: () async {
                final pastOnly = _status == 'COMPLETED';
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: pastOnly ? DateTime.now() : DateTime(2101),
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
                    final nice =
                        corrected[0] + corrected.substring(1).toLowerCase();
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
                              size: 18, color: RecordsPalette.muted)))),
            ),
            if (_dateErr != null)
              Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(_dateErr!,
                      style: const TextStyle(color: Colors.red, fontSize: 11))),
            const SizedBox(height: 14),

            _lbl('Type of Grooming'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: RecordsPalette.linenDeep, width: 1.5)),
              child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                value: _type,
                isExpanded: true,
                items: _groomTypes
                    .map((v) => DropdownMenuItem(
                        value: v,
                        child: Text(v,
                            style: const TextStyle(
                                color: RecordsPalette.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.bold))))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              )),
            ),
            const SizedBox(height: 14),

            _lbl('Clinic Location'),
            LocationSelectorField(
              value: _location,
              onChanged: (loc) => setState(() => _location = loc),
              decoration: _deco(hint: 'Tap to select location'),
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

            // ── Actions ───────────────────────────────────
            Row(children: [
              if (widget.onCancel != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _handleCancel,
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(color: RecordsPalette.linenDeep),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: RecordsPalette.muted,
                            fontWeight: FontWeight.w600)),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('SAVE GROOMING',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ]),
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
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ]),
    );
  }
}