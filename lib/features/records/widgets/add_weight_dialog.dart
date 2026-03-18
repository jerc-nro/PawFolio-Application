import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/record_provider.dart';
import '../screen/records_navigator.dart';
import '../theme/records_theme.dart';

void showAddWeightDialog(
  BuildContext context,
  String petId, {
  VoidCallback? onSaved,
}) {
  showDialog(
    context: context,
    builder: (_) => _AddWeightDialog(petId: petId, onSaved: onSaved),
  );
}

class _AddWeightDialog extends ConsumerStatefulWidget {
  final String petId;
  final VoidCallback? onSaved;
  const _AddWeightDialog({required this.petId, this.onSaved});

  @override
  ConsumerState<_AddWeightDialog> createState() => _AddWeightDialogState();
}

class _AddWeightDialogState extends ConsumerState<_AddWeightDialog> {
  final _weightCtrl = TextEditingController();
  late DateTime _selectedDate;
  late String _dateString;
  bool _saving = false;

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

  Future<void> _save() async {
    final val = double.tryParse(_weightCtrl.text.trim());
    if (val == null || val <= 0) return;

    setState(() => _saving = true);
    try {
      await ref.read(recordControllerProvider.notifier).addWeightRecord(
            petId: widget.petId,
            weight: val,
            unit: 'kg',
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
            // Header
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
              const Text('Log Weight',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: RecordsPalette.ink)),
            ]),
            const SizedBox(height: 20),

            // Weight input
            TextField(
              controller: _weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Weight',
                suffixText: 'kg',
                labelStyle: const TextStyle(color: RecordsPalette.muted),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: RecordsPalette.linenDeep, width: 1.5)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: RecordsPalette.steel, width: 2)),
              ),
            ),
            const SizedBox(height: 16),

            // Date picker
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

            // Actions
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap:
                      _saving ? null : () => Navigator.pop(context),
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