import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── FIELD TYPES ─────────────────────────────────────────────────────────────

enum EditFieldType { text, number, dropdown, date, time }

/// Defines one editable field in the dialog.
class EditFieldConfig {
  final String label;
  final String firestoreKey;
  final EditFieldType type;
  final List<String> options;   // for dropdown
  final String hint;
  final bool required;
  final TextInputType keyboardType;

  const EditFieldConfig({
    required this.label,
    required this.firestoreKey,
    this.type = EditFieldType.text,
    this.options = const [],
    this.hint = '',
    this.required = false,
    this.keyboardType = TextInputType.text,
  });
}

/// Top-level config for one record type's edit dialog.
class EditDialogConfig {
  final String title;           // e.g. "Edit Medication"
  final String collection;      // Firestore sub-collection
  final List<EditFieldConfig> fields;

  const EditDialogConfig({
    required this.title,
    required this.collection,
    required this.fields,
  });
}

// ─── PRESET EDIT CONFIGS ─────────────────────────────────────────────────────

const medicationEditConfig = EditDialogConfig(
  title: 'Edit Medication',
  collection: 'medications',
  fields: [
    EditFieldConfig(label: 'Medication Name', firestoreKey: 'medication_name', required: true),
    EditFieldConfig(label: 'Type', firestoreKey: 'type',
        type: EditFieldType.dropdown,
        options: ['Treatment', 'Supplement', 'Antibiotic', 'Antiparasitic', 'Other']),
    EditFieldConfig(label: 'Status', firestoreKey: 'status',
        type: EditFieldType.dropdown,
        options: ['ONGOING', 'COMPLETED']),
    EditFieldConfig(label: 'Dosage', firestoreKey: 'dosage'),
    EditFieldConfig(label: 'Start Date', firestoreKey: 'start_date', type: EditFieldType.date),
    EditFieldConfig(label: 'Intake Count', firestoreKey: 'intake_count',
        type: EditFieldType.number, keyboardType: TextInputType.number),
    EditFieldConfig(label: 'Period', firestoreKey: 'period',
        type: EditFieldType.dropdown,
        options: ['day', 'week', 'month']),
    EditFieldConfig(label: 'Pet Weight (kg)', firestoreKey: 'pet_weight',
        type: EditFieldType.number, keyboardType: TextInputType.number),
    EditFieldConfig(label: 'Clinic Name', firestoreKey: 'clinic_name'),
    EditFieldConfig(label: 'Veterinarian', firestoreKey: 'veterinarian'),
  ],
);

const vaccinationEditConfig = EditDialogConfig(
  title: 'Edit Vaccination',
  collection: 'vaccinations',
  fields: [
    EditFieldConfig(label: 'Vaccine Name', firestoreKey: 'vaccine_name', required: true),
    EditFieldConfig(label: 'Vaccine Type', firestoreKey: 'vaccine_type',
        type: EditFieldType.dropdown,
        options: ['Core', 'Non-Core', 'Rabies', 'Booster', 'Other']),
    EditFieldConfig(label: 'Status', firestoreKey: 'status',
        type: EditFieldType.dropdown,
        options: ['UPCOMING', 'COMPLETED', 'ONGOING']),
    EditFieldConfig(label: 'Date Administered', firestoreKey: 'date_string', type: EditFieldType.date),
    EditFieldConfig(label: 'Time', firestoreKey: 'time_string', type: EditFieldType.time),
    EditFieldConfig(label: 'Clinic Name', firestoreKey: 'clinic_name'),
    EditFieldConfig(label: 'Veterinarian', firestoreKey: 'veterinarian'),
  ],
);

const preventativeEditConfig = EditDialogConfig(
  title: 'Edit Preventative',
  collection: 'preventatives',
  fields: [
    EditFieldConfig(label: 'Brand Name', firestoreKey: 'brand_name', required: true),
    EditFieldConfig(label: 'Type', firestoreKey: 'type',
        type: EditFieldType.dropdown,
        options: ['Flea & Tick', 'Dewormer', 'Heartworm', 'Flea', 'Tick', 'Other']),
    EditFieldConfig(label: 'Status', firestoreKey: 'status',
        type: EditFieldType.dropdown,
        options: ['UPCOMING', 'ONGOING', 'COMPLETED']),
    EditFieldConfig(label: 'Scheduled Date', firestoreKey: 'date_string', type: EditFieldType.date),
    EditFieldConfig(label: 'Intake Time', firestoreKey: 'intake_time', type: EditFieldType.time),
    EditFieldConfig(label: 'Dosage', firestoreKey: 'dosage'),
    EditFieldConfig(label: 'Clinic Name', firestoreKey: 'clinic_name'),
    EditFieldConfig(label: 'Veterinarian', firestoreKey: 'veterinarian'),
  ],
);

const vetVisitEditConfig = EditDialogConfig(
  title: 'Edit Vet Visit',
  collection: 'vet_visits',
  fields: [
    EditFieldConfig(label: 'Reason / Complaint', firestoreKey: 'reason', required: true),
    EditFieldConfig(label: 'Status', firestoreKey: 'status',
        type: EditFieldType.dropdown,
        options: ['UPCOMING', 'ONGOING', 'COMPLETED']),
    EditFieldConfig(label: 'Visit Date', firestoreKey: 'date_string', type: EditFieldType.date),
    EditFieldConfig(label: 'Visit Time', firestoreKey: 'time', type: EditFieldType.time),
    EditFieldConfig(label: 'Clinic Name', firestoreKey: 'clinic_name'),
    EditFieldConfig(label: 'Veterinarian', firestoreKey: 'veterinarian'),
    EditFieldConfig(label: 'Notes / Description', firestoreKey: 'description',
        hint: 'Diagnosis, observations, follow-ups...'),
  ],
);

const groomingEditConfig = EditDialogConfig(
  title: 'Edit Grooming',
  collection: 'groom_visits',
  fields: [
    EditFieldConfig(label: 'Grooming Type', firestoreKey: 'type', required: true,
        type: EditFieldType.dropdown,
        options: ['Full Groom', 'Bath & Dry', 'Haircut', 'Nail Trim', 'Ear Cleaning', 'Other']),
    EditFieldConfig(label: 'Status', firestoreKey: 'status',
        type: EditFieldType.dropdown,
        options: ['UPCOMING', 'ONGOING', 'COMPLETED']),
    EditFieldConfig(label: 'Date', firestoreKey: 'date_string', type: EditFieldType.date),
    EditFieldConfig(label: 'Provider / Salon', firestoreKey: 'provider'),
  ],
);

// ─── DIALOG ───────────────────────────────────────────────────────────────────

/// Shows the edit dialog. Call this from any history view or archive page.
///
/// [uid]        – current user's UID
/// [petId]      – the pet document ID
/// [docId]      – the record document ID to update
/// [config]     – which record type to edit
/// [existingData] – current Firestore data map (top-level fields)
Future<void> showEditRecordDialog(
  BuildContext context, {
  required String uid,
  required String petId,
  required String docId,
  required EditDialogConfig config,
  required Map<String, dynamic> existingData,
}) {
  return showDialog(
    context: context,
    builder: (_) => _EditRecordDialog(
      uid: uid,
      petId: petId,
      docId: docId,
      config: config,
      existingData: existingData,
    ),
  );
}

// ─── INTERNAL STATEFUL DIALOG ─────────────────────────────────────────────────

class _EditRecordDialog extends StatefulWidget {
  final String uid;
  final String petId;
  final String docId;
  final EditDialogConfig config;
  final Map<String, dynamic> existingData;

  const _EditRecordDialog({
    required this.uid,
    required this.petId,
    required this.docId,
    required this.config,
    required this.existingData,
  });

  @override
  State<_EditRecordDialog> createState() => _EditRecordDialogState();
}

class _EditRecordDialogState extends State<_EditRecordDialog> {
  static const Color navBlue = Color(0xFF455A64);

  final _formKey   = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, String?> _dropdownValues;
  bool _saving = false;

  // Merges top-level and extra sub-map so both storage patterns are handled
  Map<String, dynamic> get _merged {
    final extra = widget.existingData['extra'] as Map<String, dynamic>? ?? {};
    return {...widget.existingData, ...extra};
  }

  @override
  void initState() {
    super.initState();
    _controllers   = {};
    _dropdownValues = {};

    for (final field in widget.config.fields) {
      final raw = _merged[field.firestoreKey]?.toString() ?? '';
      if (field.type == EditFieldType.dropdown) {
        // Validate the stored value is actually in the options list
        _dropdownValues[field.firestoreKey] =
            field.options.contains(raw) ? raw : null;
      } else {
        _controllers[field.firestoreKey] = TextEditingController(text: raw);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  // ── DATE / TIME PICKERS ────────────────────────────────────────────────────

  Future<void> _pickDate(EditFieldConfig field) async {
    DateTime initial = DateTime.now();
    final existing = _controllers[field.firestoreKey]?.text ?? '';
    if (existing.isNotEmpty) {
      try { initial = DateTime.parse(existing); } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: navBlue),
        ),
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      final formatted =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      _controllers[field.firestoreKey]!.text = formatted;
    }
  }

  Future<void> _pickTime(EditFieldConfig field) async {
    TimeOfDay initial = TimeOfDay.now();
    final existing = _controllers[field.firestoreKey]?.text ?? '';
    if (existing.isNotEmpty) {
      final parts = existing.split(':');
      if (parts.length == 2) {
        initial = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0);
      }
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: navBlue),
        ),
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      _controllers[field.firestoreKey]!.text =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
    }
  }

  // ── SAVE ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    // Build the update map from all fields
    final updates = <String, dynamic>{};
    for (final field in widget.config.fields) {
      if (field.type == EditFieldType.dropdown) {
        final val = _dropdownValues[field.firestoreKey];
        if (val != null) updates[field.firestoreKey] = val;
      } else {
        final val = _controllers[field.firestoreKey]?.text.trim() ?? '';
        if (val.isNotEmpty) {
          updates[field.firestoreKey] =
              field.type == EditFieldType.number ? num.tryParse(val) ?? val : val;
        }
      }
    }

    try {
      await FirebaseFirestore.instance
          .collection('users').doc(widget.uid)
          .collection('pets').doc(widget.petId)
          .collection(widget.config.collection).doc(widget.docId)
          .update(updates);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Record updated successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update: $e")),
        );
      }
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: navBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(widget.config.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                ),
              ],
            ),
          ),

          // ── Scrollable fields ──────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Form(
                key: _formKey,
                child: Column(
                  children: widget.config.fields
                      .map((field) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildField(field),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),

          // ── Actions ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: navBlue),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("CANCEL",
                        style: TextStyle(color: navBlue, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text("SAVE CHANGES",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── FIELD BUILDER ─────────────────────────────────────────────────────────

  Widget _buildField(EditFieldConfig field) {
    switch (field.type) {
      case EditFieldType.dropdown:
        return _buildDropdown(field);
      case EditFieldType.date:
        return _buildDateField(field);
      case EditFieldType.time:
        return _buildTimeField(field);
      default:
        return _buildTextField(field);
    }
  }

  Widget _buildTextField(EditFieldConfig field) {
    return TextFormField(
      controller: _controllers[field.firestoreKey],
      keyboardType: field.keyboardType,
      maxLines: field.firestoreKey == 'description' ? 3 : 1,
      decoration: _inputDecoration(field.label, field.hint),
      validator: field.required
          ? (v) => (v == null || v.trim().isEmpty) ? '${field.label} is required' : null
          : null,
    );
  }

  Widget _buildDropdown(EditFieldConfig field) {
    return DropdownButtonFormField<String>(
      value: _dropdownValues[field.firestoreKey],
      decoration: _inputDecoration(field.label, ''),
      items: field.options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: (v) => setState(() => _dropdownValues[field.firestoreKey] = v),
      validator: field.required
          ? (v) => v == null ? '${field.label} is required' : null
          : null,
    );
  }

  Widget _buildDateField(EditFieldConfig field) {
    return TextFormField(
      controller: _controllers[field.firestoreKey],
      readOnly: true,
      decoration: _inputDecoration(field.label, 'YYYY-MM-DD').copyWith(
        suffixIcon: const Icon(Icons.calendar_today, size: 18, color: navBlue),
      ),
      onTap: () => _pickDate(field),
    );
  }

  Widget _buildTimeField(EditFieldConfig field) {
    return TextFormField(
      controller: _controllers[field.firestoreKey],
      readOnly: true,
      decoration: _inputDecoration(field.label, 'HH:MM').copyWith(
        suffixIcon: const Icon(Icons.access_time, size: 18, color: navBlue),
      ),
      onTap: () => _pickTime(field),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint.isNotEmpty ? hint : null,
      labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF607D8B)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: navBlue, width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFFF9F9F9),
    );
  }
}