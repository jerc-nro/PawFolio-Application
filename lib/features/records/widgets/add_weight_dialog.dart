import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/record_provider.dart';

const _ink   = Color(0xFF455A64);
const _blue  = Color(0xFF0277BD);
const _green = Color(0xFF388E3C);

// Dog/cat weight thresholds for "Are you sure?" confirmation
const _dogWarnKg = 80.0;
const _catWarnKg = 12.0;

void showAddWeightDialog(BuildContext context, String petId, {String? petType}) {
  final sw = MediaQuery.of(context).size.width;
  showDialog(context: context, builder: (_) => Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      width: sw > 500 ? 420 : sw * 0.88,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: _WeightContent(petId: petId, petType: petType ?? ''),
    ),
  ));
}

class _WeightContent extends ConsumerStatefulWidget {
  final String petId;
  final String petType;
  const _WeightContent({required this.petId, required this.petType});
  @override ConsumerState<_WeightContent> createState() => _WS();
}

class _WS extends ConsumerState<_WeightContent> {
  final _wgt   = TextEditingController();
  final _date  = TextEditingController();
  final _notes = TextEditingController();

  String _unit   = 'kg';
  bool _saving   = false;
  String? _wgtErr, _dateErr;

  @override
  void initState() {
    super.initState();
    _date.text = DateFormat('dd.MM.yyyy').format(DateTime.now());
  }

  @override
  void dispose() { _wgt.dispose(); _date.dispose(); _notes.dispose(); super.dispose(); }

  // Auto-convert value when switching units
  void _onUnitChanged(String newUnit) {
    if (newUnit == _unit) return;
    // Clear the weight field when switching units to avoid confusion
    _wgt.clear();
    setState(() { _unit = newUnit; _wgtErr = null; });
  }

  String? _validateWeight(double? v) {
    if (v == null || v <= 0) return 'Enter a valid weight';
    // Convert to kg for threshold check
    final kg = _unit == 'lbs' ? v / 2.20462 : v;
    if (kg > 200) return 'Weight seems too high (max 200 kg equivalent)';
    return null;
  }

  bool _shouldWarn(double v) {
    final kg = _unit == 'lbs' ? v / 2.20462 : v;
    final type = widget.petType.toLowerCase();
    if (type == 'dog' && kg > _dogWarnKg) return true;
    if (type == 'cat' && kg > _catWarnKg) return true;
    return false;
  }

  Future<void> _save() async {
    final w = double.tryParse(_wgt.text.trim());
    setState(() {
      _wgtErr  = _validateWeight(w);
      _dateErr = _date.text.trim().isEmpty ? 'Date is required' : null;
    });
    if (_wgtErr != null || _dateErr != null || _saving) return;

    // "Are you sure?" warning for suspiciously high weight
    if (_shouldWarn(w!)) {
      final type = widget.petType.isEmpty ? 'pet' : widget.petType.toLowerCase();
      final threshold = type == 'cat' ? '${_catWarnKg}kg' : '${_dogWarnKg}kg';
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Unusually High Weight', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            '${_wgt.text} $_unit is above the typical threshold ($threshold) for a $type.\n\nAre you sure this is correct?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('RE-ENTER', style: TextStyle(color: Colors.grey))),
            ElevatedButton(onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: _blue),
              child: const Text('YES, SAVE', style: TextStyle(color: Colors.white))),
          ],
        ),
      ) ?? false;
      if (!confirm) return;
    }

    setState(() => _saving = true);
    final msg = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      await ref.read(recordControllerProvider.notifier).addWeightRecord(
        petId: widget.petId,
        weight: w,
        unit: _unit,
        dateString: _date.text.trim(),
        notes: _notes.text.trim(),
      );
      if (mounted) {
        nav.pop();
        msg.showSnackBar(const SnackBar(content: Text('Weight logged & pet profile updated!'), backgroundColor: _green));
      }
    } catch (e) {
      if (mounted) msg.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _unitPill(String u) {
    final sel = _unit == u;
    return GestureDetector(
      onTap: () => _onUnitChanged(u),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? _blue : Colors.transparent,
          border: Border.all(color: _blue, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(u, style: TextStyle(color: sel ? Colors.white : _blue,
            fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  InputDecoration _deco({String? hint, bool err = false, Widget? suffix}) =>
    InputDecoration(
      isDense: true, hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: err ? Colors.red : _blue, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: err ? Colors.red : _blue, width: 2)),
    );

  @override
  Widget build(BuildContext ctx) => SingleChildScrollView(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      // Header
      Row(children: [
        Container(padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: const Color(0xFFF0EDE5), borderRadius: BorderRadius.circular(13)),
          child: const Icon(Icons.monitor_weight_outlined, color: _ink, size: 22)),
        const SizedBox(width: 12),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Log Weight', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _ink)),
          Text('Track growth over time', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      ]),
      const SizedBox(height: 20),

      // Weight * with auto-convert on unit switch
      Padding(padding: const EdgeInsets.only(bottom: 6),
        child: Text('Weight', style: const TextStyle(color: _ink, fontWeight: FontWeight.bold, fontSize: 13))),
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(child: TextField(
          controller: _wgt,
          // Only allow numbers and one decimal point
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) {
            // Prevent multiple decimal points
            if (v.contains('.')) {
              final parts = v.split('.');
              if (parts.length > 2) {
                _wgt.text = '${parts[0]}.${parts.sublist(1).join('')}';
                _wgt.selection = TextSelection.collapsed(offset: _wgt.text.length);
              }
            }
            setState(() => _wgtErr = null);
          },
          decoration: _deco(hint: 'e.g. 4.5', err: _wgtErr != null),
        )),
        const SizedBox(width: 10),
        Row(mainAxisSize: MainAxisSize.min, children: [
          _unitPill('kg'),
          const SizedBox(width: 6),
          _unitPill('lbs'),
        ]),
      ]),
      if (_wgtErr != null) Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(_wgtErr!, style: const TextStyle(color: Colors.red, fontSize: 11))),
      const SizedBox(height: 14),

      // Date * (past/present only for weight)
      Padding(padding: const EdgeInsets.only(bottom: 6),
        child: Text('Date Recorded', style: const TextStyle(color: _ink, fontWeight: FontWeight.bold, fontSize: 13))),
      GestureDetector(
        onTap: () async {
          final d = await showDatePicker(
            context: ctx,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now(), // Past/present only
            builder: (c, child) => Theme(data: Theme.of(c).copyWith(
              colorScheme: const ColorScheme.light(primary: _ink)), child: child!),
          );
          if (d != null) setState(() { _date.text = DateFormat('dd.MM.yyyy').format(d); _dateErr = null; });
        },
        child: AbsorbPointer(child: TextField(controller: _date,
          decoration: _deco(hint: 'DD.MM.YYYY', err: _dateErr != null,
            suffix: Icon(Icons.calendar_month,
                color: _dateErr != null ? Colors.red : Colors.black54, size: 20)))),
      ),
      if (_dateErr != null) Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(_dateErr!, style: const TextStyle(color: Colors.red, fontSize: 11))),
      const SizedBox(height: 14),

      // Notes (optional)
      const Padding(padding: EdgeInsets.only(bottom: 6),
        child: Text('Notes (optional)', style: TextStyle(color: _ink, fontWeight: FontWeight.bold, fontSize: 13))),
      TextField(controller: _notes, maxLines: 2, maxLength: 500,
        decoration: _deco(hint: 'e.g. After meal, before bath…')),
      const SizedBox(height: 24),

      SizedBox(width: double.infinity, height: 48,
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: _saving
            ? const SizedBox(width:20,height:20,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2))
            : const Text('SAVE WEIGHT', style: TextStyle(fontWeight: FontWeight.bold)),
        )),
    ]),
  );
}
