import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '_pet_profile_shared.dart';

class PetHealthCard extends StatefulWidget {
  final bool sterilization, vaccinated;
  final String vaccineDetails, description;
  final bool editMode;
  final String ownerID, petID;
  final void Function(Map<String, dynamic>) onChanged;

  const PetHealthCard({
    super.key,
    required this.sterilization, required this.vaccinated,
    required this.vaccineDetails, required this.description,
    required this.editMode,
    required this.ownerID, required this.petID,
    required this.onChanged,
  });

  @override
  State<PetHealthCard> createState() => _PetHealthCardState();
}

class _PetHealthCardState extends State<PetHealthCard> {
  late TextEditingController _descCtrl;
  late bool _sterilization;

  @override
  void initState() {
    super.initState();
    _descCtrl      = TextEditingController(text: widget.description);
    _sterilization = widget.sterilization;
  }

  @override
  void didUpdateWidget(PetHealthCard old) {
    super.didUpdateWidget(old);
    if (!widget.editMode && old.editMode) {
      _descCtrl.text = widget.description;
      _sterilization = widget.sterilization;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  void _emit({required bool vaccinated}) => widget.onChanged({
    'sterilization' : _sterilization,
    'vaccinated'    : vaccinated,
    'vaccineDetails': widget.vaccineDetails, // preserved as-is
    'description'   : _descCtrl.text.trim(),
  });

  /// Streams vaccine names, returns (names list, hasRecords bool)
  Stream<List<String>> get _vaccineNamesStream => FirebaseFirestore.instance
      .collection('users').doc(widget.ownerID)
      .collection('pets').doc(widget.petID)
      .collection('vaccinations')
      .orderBy('date_timestamp', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => (d.data())['vaccine_name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList());

  @override
  Widget build(BuildContext context) {
    final e = widget.editMode;

    return StreamBuilder<List<String>>(
      stream: _vaccineNamesStream,
      builder: (context, snap) {
        final vaccineNames  = snap.data ?? [];
        final hasVaxRecords = vaccineNames.isNotEmpty;

        // If there are vaccine records, vaccinated = true always.
        // Emit this upstream so Firestore stays in sync when saving.
        final effectiveVaccinated = hasVaxRecords || widget.vaccinated;

        return Column(children: [
          ProfileCard(
            icon: Icons.health_and_safety_outlined,
            title: 'Health',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Spayed / Neutered
                LabeledField(
                  label: 'Spayed / Neutered',
                  child: e
                    ? ToggleRow(
                        options: const ['Yes', 'No'],
                        selected: _sterilization ? 'Yes' : 'No',
                        onChanged: (v) {
                          setState(() => _sterilization = v == 'Yes');
                          _emit(vaccinated: effectiveVaccinated);
                        })
                    : StatusBadge(
                        label: widget.sterilization ? 'Yes' : 'No',
                        positive: widget.sterilization)),

                // Vaccinated — driven by records, not editable
                LabeledField(
                  label: 'Vaccinated',
                  child: StatusBadge(
                    label: effectiveVaccinated ? 'Yes' : 'No',
                    positive: effectiveVaccinated,
                  ),
                ),

                // Vaccines — always read-only, shown only if records exist
                if (effectiveVaccinated)
                  LabeledField(
                    label: 'Vaccines',
                    child: snap.connectionState == ConnectionState.waiting
                      ? const SizedBox(
                          height: 16,
                          child: LinearProgressIndicator(color: kNavy))
                      : hasVaxRecords
                        // Show comma-separated names from records
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              vaccineNames.join(', '),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF2C2C2C),
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          )
                        // Fallback to stored text if no records but vaccinated=true
                        : ValueText(widget.vaccineDetails.isEmpty
                            ? '—' : widget.vaccineDetails),
                  ),
              ],
            ),
          ),

          // Notes card
          if (widget.description.isNotEmpty || e) ...[
            const SizedBox(height: 14),
            ProfileCard(
              icon: Icons.notes_outlined,
              title: 'Notes',
              child: e
                ? ProfileTextField(
                    ctrl: _descCtrl, maxLines: 4,
                    hint: 'Add notes about your pet...',
                    onChanged: (_) => _emit(vaccinated: effectiveVaccinated))
                : Text(widget.description,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4A4A4A),
                        height: 1.5)),
            ),
          ],
        ]);
      },
    );
  }
}