import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/record_provider.dart';
import '../screen/records_navigator.dart';
import '../theme/records_theme.dart';

void showAddWeightDialog(
  BuildContext context,
  String petId, {
  VoidCallback? onSaved,
  bool popToHomeOnSave = false,
}) {
  showDialog(
    context: context,
    builder: (_) => _AddWeightDialog(
      petId: petId,
      onSaved: onSaved,
      popToHomeOnSave: popToHomeOnSave,
    ),
  );
}

class _AddWeightDialog extends ConsumerStatefulWidget {
  final String petId;
  final VoidCallback? onSaved;
  final bool popToHomeOnSave;
  const _AddWeightDialog({
    required this.petId,
    this.onSaved,
    this.popToHomeOnSave = false,
  });

  @override
  ConsumerState<_AddWeightDialog> createState() => _AddWeightDialogState();
}

class _AddWeightDialogState extends ConsumerState<_AddWeightDialog> {
  final _weightCtrl = TextEditingController();
  late DateTime _selectedDate;
  late String _dateString;
  String _unit = 'kg';
  bool _saving = false;
  String? _weightErr;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateString = DateFormat('dd.MM.yyyy').format(_selectedDate);
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String? _validateWeight(String v) {
    if (v.trim().isEmpty) return 'Weight is required';
    final d = double.tryParse(v.trim());
    if (d == null) return 'Must be a valid number';
    if (d <= 0) return 'Must be greater than 0';
    if (_unit == 'kg' && d > 200) return 'Weight seems too high (max 200 kg)';
    if (_unit == 'lbs' && d > 440) return 'Weight seems too high (max 440 lbs)';
    return null;
  }

  /// Always stores in kg regardless of display unit.
  double get _weightInKg {
    final val = double.tryParse(_weightCtrl.text.trim()) ?? 0;
    return _unit == 'lbs' ? val / 2.20462 : val;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (c, child) => Theme(
          data: Theme.of(c).copyWith(
              colorScheme:
                  const ColorScheme.light(primary: RecordsPalette.steel)),
          child: child!),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateString = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  void _cancel() {
    if (widget.popToHomeOnSave) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _save() async {
    setState(() => _weightErr = _validateWeight(_weightCtrl.text));
    if (_weightErr != null || _saving) return;

    setState(() => _saving = true);
    try {
      await ref.read(recordControllerProvider.notifier).addWeightRecord(
            petId: widget.petId,
            weight: _weightInKg,
            unit: 'kg', // always stored as kg
            dateString: _dateString,
            recordedDate: _selectedDate,
          );

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) showRecordToast(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(25)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F0),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.monitor_weight_outlined,
                    color: Color(0xFF7A8C6A), size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Log Weight',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: RecordsPalette.ink)),
              ),
              // ── Cancel X (quick-add only) ────────────────
              if (widget.popToHomeOnSave)
                GestureDetector(
                  onTap: _cancel,
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
            const SizedBox(height: 20),

            // ── Weight input + unit toggle ────────────────
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      autofocus: true,
                      onChanged: (_) =>
                          setState(() => _weightErr = null),
                      decoration: InputDecoration(
                        labelText: 'Weight',
                        suffixText: _unit,
                        labelStyle:
                            const TextStyle(color: RecordsPalette.muted),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: _weightErr != null
                                    ? Colors.red
                                    : RecordsPalette.linenDeep,
                                width: 1.5)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: _weightErr != null
                                    ? Colors.red
                                    : RecordsPalette.steel,
                                width: 2)),
                      ),
                    ),
                    if (_weightErr != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(_weightErr!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 11)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // kg / lbs toggle
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _UnitToggle(
                  unit: _unit,
                  onChanged: (u) {
                    // Convert displayed value when switching units
                    final current =
                        double.tryParse(_weightCtrl.text.trim());
                    if (current != null && current > 0) {
                      final converted = u == 'lbs'
                          ? current * 2.20462
                          : current / 2.20462;
                      _weightCtrl.text =
                          converted.toStringAsFixed(1);
                    }
                    setState(() {
                      _unit = u;
                      _weightErr = null;
                    });
                  },
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // ── Date picker ───────────────────────────────
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: RecordsPalette.linenDeep),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 18, color: RecordsPalette.steel),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_dateString,
                        style: const TextStyle(
                            fontSize: 15, color: RecordsPalette.ink)),
                  ),
                  if (_isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: RecordsPalette.steel,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('TODAY',
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                    ),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                _isToday
                    ? 'This will be marked as your current weight.'
                    : "Past dates are logged but won't change the current weight.",
                style: TextStyle(
                    fontSize: 11,
                    color: RecordsPalette.muted.withOpacity(0.8)),
              ),
            ),
            const SizedBox(height: 20),

            // ── Actions ───────────────────────────────────
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: _saving ? null : _cancel,
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: RecordsPalette.sageLite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: RecordsPalette.muted,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _saving ? null : _save,
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: RecordsPalette.steel,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('SAVE',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── kg / lbs toggle ───────────────────────────────────────────────────────────
class _UnitToggle extends StatelessWidget {
  final String unit;
  final ValueChanged<String> onChanged;
  const _UnitToggle({required this.unit, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _btn('kg'),
        const SizedBox(height: 3),
        _btn('lbs'),
      ]),
    );
  }

  Widget _btn(String label) {
    final sel = unit == label;
    return GestureDetector(
      onTap: () => onChanged(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? RecordsPalette.steel : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: sel ? Colors.white : RecordsPalette.muted)),
      ),
    );
  }
}