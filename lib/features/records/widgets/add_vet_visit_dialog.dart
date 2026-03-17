import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/record_model.dart';
import '../providers/record_provider.dart';
import '_status_date_logic.dart';

const _ink   = Color(0xFF455A64);
const _blue  = Color(0xFF0277BD);
const _green = Color(0xFF388E3C);

// ── UI Helpers ────────────────────────────────────────────────

Widget _lbl(String t, {bool req = false}) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(t, style: const TextStyle(color: _ink, fontWeight: FontWeight.bold, fontSize: 13)),
);

InputDecoration _deco({String? hint, bool err = false, Widget? suffix, int? maxLines}) =>
  InputDecoration(
    isDense: true, hintText: hint, counterText: '',
    hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
    suffixIcon: suffix,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: err ? Colors.red : _blue, width: 1.5)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: err ? Colors.red : _blue, width: 2)),
  );

Widget _err(String t) => Padding(
  padding: const EdgeInsets.only(top: 3),
  child: Text(t, style: const TextStyle(color: Colors.red, fontSize: 11)),
);

// ── Vet Visit Dialog Entry ────────────────────────────────────

void showAddVetVisitDialog(BuildContext context, String petId, String petName, String petType) {
  final sw = MediaQuery.of(context).size.width;
  showDialog(context: context, builder: (_) => Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      width: sw > 500 ? 420 : sw * 0.88,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: _VetContent(petId: petId, petName: petName, petType: petType),
    ),
  ));
}

class _VetContent extends ConsumerStatefulWidget {
  final String petId;
  final String petName;
  final String petType;
  const _VetContent({required this.petId, required this.petName, required this.petType});
  @override ConsumerState<_VetContent> createState() => _VetState();
}

class _VetState extends ConsumerState<_VetContent> {
  final _reason = TextEditingController();
  final _date   = TextEditingController();
  final _time   = TextEditingController();
  final _clinic = TextEditingController();
  final _vet    = TextEditingController();
  final _notes  = TextEditingController();

  String _status = 'UPCOMING';
  TimeOfDay _tod = TimeOfDay.now();
  bool _saving   = false;

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
    if (v.trim().length > 100) return 'Max 100 characters';
    return null;
  }

  String? _validateDate(String v) {
    if (v.trim().isEmpty) return 'Date is required';
    final d = _parseDateStr(v);
    if (d == null) return 'Invalid date';
    if (_status == 'COMPLETED' && d.isAfter(DateTime.now())) return 'Past/present date required for Completed';
    return null;
  }

  void _showTimePicker() async {
    TimeOfDay picked = _tod;
    await showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 260, color: Colors.white,
        child: Column(children: [
          Container(color: const Color(0xFFF5F5F5),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              CupertinoButton(child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.pop(context)),
              CupertinoButton(child: const Text('Done', style: TextStyle(color: _blue, fontWeight: FontWeight.bold)),
                onPressed: () {
                  setState(() { _tod = picked; _time.text = _tod.format(context); });
                  Navigator.pop(context);
                }),
            ])),
          Expanded(child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            initialDateTime: DateTime(2024, 1, 1, _tod.hour, _tod.minute),
            onDateTimeChanged: (dt) => picked = TimeOfDay.fromDateTime(dt),
          )),
        ]),
      ),
    );
  }

  Future<void> _save() async {
    if (_notes.text.length > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notes must be under 1000 characters'), backgroundColor: Colors.red));
      return;
    }
    setState(() {
      _reasonErr = _validateReason(_reason.text);
      _dateErr   = _validateDate(_date.text);
    });
    if ([_reasonErr, _dateErr].any((e) => e != null) || _saving) return;

    setState(() => _saving = true);
    final msg = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      final record = PetRecord(
        id: '',
        petID: widget.petId,
        petName: widget.petName,
        petType: widget.petType,
        category: 'Vet Visit',
        collection: 'vet_visits',
        status: _status,
        dateString: _date.text.trim(),
        dateTimestamp: _parseDateStr(_date.text.trim()),
        extra: {
          'reason': _reason.text.trim(),
          'time': _time.text.trim(),
          'clinic_name': _clinic.text.trim(),
          'veterinarian': _vet.text.trim(),
          'description': _notes.text.trim(),
        },
      );

      await ref.read(recordControllerProvider.notifier).addPetRecord(record);

      if (mounted) {
        nav.pop();
        msg.showSnackBar(const SnackBar(content: Text('Vet visit saved!'), backgroundColor: _green));
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
          Icon(Icons.local_hospital_outlined, color: _ink, size: 20),
          SizedBox(width: 8),
          Text('Add Vet Visit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _ink)),
        ]),
        const SizedBox(height: 16),

        _lbl('Reason for Visit'),
        TextField(controller: _reason, maxLength: 100, onChanged: (_) => setState(() => _reasonErr = null),
          decoration: _deco(hint: 'e.g. Annual Checkup', err: _reasonErr != null)),
        if (_reasonErr != null) _err(_reasonErr!),
        const SizedBox(height: 14),

        _lbl('Date of Visit'),
        GestureDetector(
          onTap: () async {
            final pastOnly = _status == 'COMPLETED';
            final d = await showDatePicker(
              context: ctx,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: pastOnly ? DateTime.now() : DateTime(2101),
              builder: (c, child) => Theme(data: Theme.of(c).copyWith(
                colorScheme: const ColorScheme.light(primary: _ink)), child: child!),
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
        if (_dateErr != null) _err(_dateErr!),
        const SizedBox(height: 14),

        _lbl('Visit Time (optional)'),
        GestureDetector(
          onTap: _showTimePicker,
          child: AbsorbPointer(child: TextField(controller: _time,
            decoration: _deco(hint: 'Tap to select',
              suffix: const Icon(Icons.access_time, color: _ink)))),
        ),
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

        _lbl('Notes / Findings (optional)'),
        TextField(controller: _notes, maxLines: 3, maxLength: 1000,
          decoration: _deco(hint: 'Enter findings or instructions...')),
        const SizedBox(height: 14),

        _lbl('Status'),
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
            child: _saving
              ? const SizedBox(width:20,height:20,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2))
              : const Text('SAVE VET VISIT', style: TextStyle(fontWeight: FontWeight.bold)),
          )),
      ]),
    );
  }
}