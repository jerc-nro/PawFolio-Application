import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/record_provider.dart';
import '../../../models/record_model.dart';
import '_status_date_logic.dart';

const _ink = Color(0xFF455A64);
const _blue = Color(0xFF0277BD);
const _green = Color(0xFF388E3C);

// Added petName and petType here to populate the record correctly
void showAddGroomingDialog(BuildContext context, String petId, String petName, String petType) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width > 500 ? 420 : MediaQuery.of(context).size.width * 0.88,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
        child: _GroomContent(petId: petId, petName: petName, petType: petType),
      ),
    ),
  );
}

class _GroomContent extends ConsumerStatefulWidget {
  final String petId;
  final String petName;
  final String petType;
  const _GroomContent({required this.petId, required this.petName, required this.petType});
  @override
  ConsumerState<_GroomContent> createState() => _GS();
}

class _GS extends ConsumerState<_GroomContent> {
  final _clinic = TextEditingController();
  final _date = TextEditingController();

  static const _groomTypes = ['NAIL TRIM', 'FULL GROOM', 'BATH', 'EYE/EAR CLEAN'];
  String _type = 'NAIL TRIM';
  String _status = 'UPCOMING';
  bool _saving = false;

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
    } catch (_) {
      return null;
    }
  }

  String? _validateDate(String v) {
    if (v.trim().isEmpty) return 'Date is required';
    final d = _parseDate(v);
    if (d == null) return 'Invalid date';
    if (_status == 'COMPLETED' && d.isAfter(DateTime.now())) return 'Past/present date required for Completed';
    return null;
  }

  Future<void> _save() async {
    setState(() {
      _clinicErr = _clinic.text.trim().isEmpty
          ? 'Clinic name is required'
          : _clinic.text.trim().length > 100
              ? 'Max 100 characters'
              : null;
      _dateErr = _validateDate(_date.text);
    });
    if ([_clinicErr, _dateErr].any((e) => e != null) || _saving) return;

    setState(() => _saving = true);
    final msg = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      // 1. Create the Universal Record model
      final record = PetRecord(
        id: '', // Firestore auto-generates this
        petID: widget.petId,
        petName: widget.petName,
        petType: widget.petType,
        category: 'Grooming',
        collection: 'groom_visits', // Matches your sub-collection name
        status: _status,
        dateString: _date.text.trim(),
        dateTimestamp: _parseDate(_date.text.trim()),
        extra: {
          'provider': _clinic.text.trim(),
          'type': _type,
        },
      );

      // 2. Call the refactored controller
      await ref.read(recordControllerProvider.notifier).addPetRecord(record);

      if (mounted) {
        nav.pop();
        msg.showSnackBar(const SnackBar(
          content: Text('Grooming record saved!'),
          backgroundColor: _green,
        ));
      }
    } catch (e) {
      if (mounted) msg.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _lbl(String t, {bool req = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(color: _ink, fontWeight: FontWeight.bold, fontSize: 13)),
      );

  InputDecoration _deco({String? hint, bool err = false, Widget? suffix}) => InputDecoration(
        isDense: true,
        hintText: hint,
        counterText: '',
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: err ? Colors.red : _blue, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: err ? Colors.red : _blue, width: 2)),
      );

  @override
  Widget build(BuildContext ctx) {
    final _dateRelation = dateRelation(parseDMY(_date.text));
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        const Row(children: [
          Icon(Icons.content_cut_outlined, color: _ink, size: 20),
          SizedBox(width: 8),
          Text('Add Grooming', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _ink)),
        ]),
        const SizedBox(height: 16),

        // Clinic
        _lbl('Clinic / Salon Name'),
        TextField(
            controller: _clinic,
            maxLength: 100,
            onChanged: (_) => setState(() => _clinicErr = null),
            decoration: _deco(hint: 'e.g. Paws & Claws', err: _clinicErr != null)),
        if (_clinicErr != null)
          Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(_clinicErr!, style: const TextStyle(color: Colors.red, fontSize: 11))),
        const SizedBox(height: 14),

        // Date
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
                  data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: _ink)), child: child!),
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
          child: AbsorbPointer(
              child: TextField(
                  controller: _date,
                  decoration:
                      _deco(hint: 'DD.MM.YYYY', err: _dateErr != null, suffix: const Icon(Icons.calendar_month, size: 18)))),
        ),
        if (_dateErr != null)
          Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(_dateErr!, style: const TextStyle(color: Colors.red, fontSize: 11))),
        const SizedBox(height: 14),

        // Type
        _lbl('Type of Grooming'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: _blue, width: 1.5)),
          child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
            value: _type,
            isExpanded: true,
            items: _groomTypes
                .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text(v, style: const TextStyle(color: _blue, fontSize: 13, fontWeight: FontWeight.bold))))
                .toList(),
            onChanged: (v) => setState(() => _type = v!),
          )),
        ),
        const SizedBox(height: 14),

        // Status
        _lbl('Status'),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          smartStatusBtn(
              label: 'Upcoming',
              color: const Color(0xFFFFB300),
              current: _status,
              rel: _dateRelation,
              onSelect: (v) => setState(() {
                    _status = v;
                    _dateErr = null;
                  }),
              context: context),
          smartStatusBtn(
              label: 'Ongoing',
              color: const Color(0xFFD32F2F),
              current: _status,
              rel: _dateRelation,
              onSelect: (v) => setState(() {
                    _status = v;
                    _dateErr = null;
                  }),
              context: context),
          smartStatusBtn(
              label: 'Completed',
              color: const Color(0xFF388E3C),
              current: _status,
              rel: _dateRelation,
              onSelect: (v) => setState(() {
                    _status = v;
                    _dateErr = null;
                  }),
              context: context),
        ]),
        const SizedBox(height: 24),

        SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('SAVE GROOMING', style: TextStyle(fontWeight: FontWeight.bold)),
            )),
      ]),
    );
  }
}