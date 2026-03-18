import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/records_theme.dart';

/// Drop-in widget for any "Add record" dialog.
///
/// Shows:
///   • kg/lbs number input
///   • "Is this the pet's current weight?" toggle (shown only when a value
///     is entered)
///
/// [onChanged] fires on every keystroke/unit-switch with the current kg value
/// (null = empty/invalid) and whether to update the pet.
///
/// Usage:
///   PetWeightField(
///     onChanged: (weightKg, isCurrentWeight) {
///       setState(() {
///         _petWeightKg = weightKg;
///         _isCurrentWeight = isCurrentWeight;
///       });
///     },
///   )
///
/// Then in _save():
///   if (_petWeightKg != null && _isCurrentWeight) {
///     await ref.read(recordControllerProvider.notifier).updatePetWeight(
///       petId: widget.petId,
///       weightKg: _petWeightKg!,
///       dateString: DateFormat('dd.MM.yyyy').format(DateTime.now()),
///     );
///   }

class PetWeightField extends StatefulWidget {
  final void Function(double? weightKg, bool isCurrentWeight) onChanged;
  final String? errorText;

  const PetWeightField({
    super.key,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<PetWeightField> createState() => _PetWeightFieldState();
}

class _PetWeightFieldState extends State<PetWeightField> {
  final _ctrl = TextEditingController();
  String _unit = 'kg';
  bool   _isCurrentWeight = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double? get _valueKg {
    final v = double.tryParse(_ctrl.text.trim());
    if (v == null || v <= 0) return null;
    return _unit == 'lbs' ? v / 2.20462 : v;
  }

  bool get _hasValue => _ctrl.text.trim().isNotEmpty;

  void _emit() =>
      widget.onChanged(_valueKg, _hasValue && _isCurrentWeight);

  void _switchUnit(String unit) {
    if (unit == _unit) return;
    final current = double.tryParse(_ctrl.text.trim());
    if (current != null && current > 0) {
      final converted =
          unit == 'lbs' ? current * 2.20462 : current / 2.20462;
      _ctrl.text = converted.toStringAsFixed(1);
    }
    setState(() => _unit = unit);
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final hasErr = widget.errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Input row ──────────────────────────────────────
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Number field
          Expanded(
            child: TextField(
              controller: _ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              onChanged: (_) {
                // Reset "is current" if field is cleared
                if (!_hasValue && _isCurrentWeight) {
                  setState(() => _isCurrentWeight = false);
                }
                setState(() {}); // rebuild to show/hide toggle
                _emit();
              },
              style: const TextStyle(
                  fontSize: 13, color: RecordsPalette.ink),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'e.g. 4.5',
                counterText: '',
                suffixText: _unit,
                hintStyle: TextStyle(
                    color: RecordsPalette.muted.withOpacity(0.7),
                    fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 11),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: hasErr
                            ? Colors.red
                            : RecordsPalette.linenDeep,
                        width: 1.5)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: hasErr
                            ? Colors.red
                            : RecordsPalette.steel,
                        width: 2)),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // kg / lbs toggle
          _UnitToggle(unit: _unit, onChanged: _switchUnit),
        ]),

        // ── Validation error ───────────────────────────────
        if (hasErr)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(widget.errorText!,
                style:
                    const TextStyle(color: Colors.red, fontSize: 11)),
          ),

        // ── "Is current weight?" toggle ────────────────────
        // Only visible once the user has typed something.
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          child: _hasValue
              ? GestureDetector(
                  onTap: () {
                    setState(
                        () => _isCurrentWeight = !_isCurrentWeight);
                    _emit();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: _isCurrentWeight
                          ? RecordsPalette.steel.withOpacity(0.08)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isCurrentWeight
                            ? RecordsPalette.steel
                            : RecordsPalette.linenDeep,
                        width: _isCurrentWeight ? 1.5 : 1,
                      ),
                    ),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _isCurrentWeight
                              ? RecordsPalette.steel
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isCurrentWeight
                                ? RecordsPalette.steel
                                : RecordsPalette.linenDeep,
                            width: 1.5,
                          ),
                        ),
                        child: _isCurrentWeight
                            ? const Icon(Icons.check,
                                size: 11, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'This is the pet\'s current weight',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: RecordsPalette.ink),
                        ),
                      ),
                      if (_isCurrentWeight)
                        const Icon(Icons.sync_rounded,
                            size: 14,
                            color: RecordsPalette.steel),
                    ]),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ── kg / lbs pill toggle ──────────────────────────────────────────────────────
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
                color:
                    sel ? Colors.white : RecordsPalette.muted)),
      ),
    );
  }
}