import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '_pet_profile_shared.dart';

class PetHealthCard extends StatefulWidget {
  final bool sterilization, vaccinated;
  final String vaccineDetails, description;
  final bool editMode;
  final String ownerID, petID; // needed to stream vaccine names
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
  late TextEditingController _vaccineDetailsCtrl, _descCtrl;
  late bool _sterilization, _vaccinated;

  @override
  void initState() {
    super.initState();
    _vaccineDetailsCtrl = TextEditingController(text: widget.vaccineDetails);
    _descCtrl           = TextEditingController(text: widget.description);
    _sterilization      = widget.sterilization;
    _vaccinated         = widget.vaccinated;
  }

  @override
  void didUpdateWidget(PetHealthCard old) {
    super.didUpdateWidget(old);
    if (!widget.editMode && old.editMode) {
      _vaccineDetailsCtrl.text = widget.vaccineDetails;
      _descCtrl.text           = widget.description;
      _sterilization           = widget.sterilization;
      _vaccinated              = widget.vaccinated;
    }
  }

  @override
  void dispose() {
    _vaccineDetailsCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged({
    'sterilization' : _sterilization,
    'vaccinated'    : _vaccinated,
    'vaccineDetails': _vaccineDetailsCtrl.text.trim(),
    'description'   : _descCtrl.text.trim(),
  });

  /// Streams vaccine names from Firestore vaccinations subcollection
  Widget _vaccineNamesFromRecords() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users').doc(widget.ownerID)
          .collection('pets').doc(widget.petID)
          .collection('vaccinations')
          .orderBy('date_timestamp', descending: true)
          .snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 16,
            child: LinearProgressIndicator(color: kNavy));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return ValueText(widget.vaccineDetails.isEmpty
              ? '—' : widget.vaccineDetails);
        }
        // Deduplicate vaccine names
        final names = docs
            .map((d) => (d.data() as Map)['vaccine_name']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .toSet()
            .toList();
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 6, runSpacing: 6,
            children: names.map((n) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kGreen.withOpacity(0.3))),
              child: Text(n, style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: kGreen)),
            )).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.editMode;
    return Column(children: [
      ProfileCard(
        icon: Icons.health_and_safety_outlined,
        title: 'Health',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LabeledField(
            label: 'Spayed / Neutered',
            child: e
              ? ToggleRow(
                  options: const ['Yes', 'No'],
                  selected: _sterilization ? 'Yes' : 'No',
                  onChanged: (v) {
                    setState(() => _sterilization = v == 'Yes');
                    _emit();
                  })
              : StatusBadge(
                  label: widget.sterilization ? 'Yes' : 'No',
                  positive: widget.sterilization)),
          LabeledField(
            label: 'Vaccinated',
            child: e
              ? ToggleRow(
                  options: const ['Yes', 'No'],
                  selected: _vaccinated ? 'Yes' : 'No',
                  onChanged: (v) {
                    setState(() => _vaccinated = v == 'Yes');
                    _emit();
                  })
              : StatusBadge(
                  label: widget.vaccinated ? 'Yes' : 'No',
                  positive: widget.vaccinated)),
          // Vaccine details: edit mode = text field, view mode + vaccinated = live record chips
          if (_vaccinated || widget.vaccinated || e)
            LabeledField(
              label: 'Vaccines',
              child: e
                ? ProfileTextField(
                    ctrl: _vaccineDetailsCtrl,
                    hint: 'e.g. Rabies, DHPP',
                    onChanged: (_) => _emit())
                : (widget.vaccinated
                    ? _vaccineNamesFromRecords()
                    : ValueText(widget.vaccineDetails.isEmpty
                        ? '—' : widget.vaccineDetails))),
        ]),
      ),
      if (widget.description.isNotEmpty || e) ...[
        const SizedBox(height: 14),
        ProfileCard(
          icon: Icons.notes_outlined,
          title: 'Notes',
          child: e
            ? ProfileTextField(
                ctrl: _descCtrl, maxLines: 4,
                hint: 'Add notes about your pet...',
                onChanged: (_) => _emit())
            : Text(widget.description,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF4A4A4A), height: 1.5)),
        ),
      ],
    ]);
  }
}