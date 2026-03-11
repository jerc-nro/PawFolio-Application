import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/pet_model.dart'; 

class PetProfilePage extends StatefulWidget {
  final Pet pet;
  const PetProfilePage({super.key, required this.pet});

  @override
  State<PetProfilePage> createState() => _PetProfilePageState();
}

class _PetProfilePageState extends State<PetProfilePage> {
  final Color kBg = const Color(0xFFF5F2EE);
  final Color kHeader = const Color(0xFF4A6580);
  final Color kCard = const Color(0xFF7A8C6A);
  final Color kRed = const Color(0xFF8B1A1A);

  final TextEditingController _vacNameController = TextEditingController();
  final TextEditingController _vacDateController = TextEditingController();

  late bool _sterilization;
  late bool _vaccinated;
  List<String> _vaccineList = [];

  @override
  void initState() {
    super.initState();
    _sterilization = widget.pet.sterilization;
    _vaccinated = widget.pet.vaccinated;
    
    if (widget.pet.vaccineDetails.isNotEmpty) {
      _vaccineList = widget.pet.vaccineDetails.split('\n').where((s) => s.trim().isNotEmpty).toList();
    }
  }

  // --- CONFIRMATION DIALOG LOGIC ---
  void _toggleSterilization(bool newValue) async {
    // If it's already true, we don't allow changing it back based on your request
    if (widget.pet.sterilization) return;

    if (newValue == true) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Confirm Sterilization"),
          content: const Text("Are you sure you want to mark this pet as Sterilized/Neutered? This action is usually permanent."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: kCard),
              child: const Text("I'M SURE", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() => _sterilization = true);
      }
    } else {
      setState(() => _sterilization = false);
    }
  }

  void _addNewVaccine() {
    if (_vacNameController.text.isEmpty || _vacDateController.text.isEmpty) return;
    setState(() {
      _vaccineList.add("[Name: ${_vacNameController.text} | Date: ${_vacDateController.text}]");
      _vaccinated = true; 
      _vacNameController.clear();
      _vacDateController.clear();
    });
  }

  Future<void> _handleSave() async {
    try {
      await FirebaseFirestore.instance.collection('pets').doc(widget.pet.petID).update({
        'sterilization': _sterilization,
        'vaccinated': _vaccinated,
        'vaccineDetails': _vaccineList.join('\n'),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated!")));
        Navigator.pop(context, true); 
      }
    } catch (e) {
      debugPrint("Save error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kHeader,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Pet Records", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(onPressed: _handleSave, child: const Text("SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          _buildLockedGreenBox(),
          const SizedBox(height: 16),
          _buildMedicalCard(),
        ]),
      ),
    );
  }

  Widget _buildLockedGreenBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        _lockedRow("NAME", widget.pet.name),
        _lockedRow("TYPE", widget.pet.type),
        _lockedRow("BREED", widget.pet.breed),
        _lockedRow("SEX", widget.pet.sex),
        _lockedRow("BIRTH DATE", widget.pet.birthDate),
        _lockedRow("COLOR", widget.pet.color),
        _lockedRow("WEIGHT", "${widget.pet.weight} ${widget.pet.weightUnit}"),
        const Divider(color: Colors.white24, height: 25),
        _lockedRow("NEUTERED", _sterilization ? "YES" : "NO", isStatus: true),
        _lockedRow("VACCINATED", _vaccinated ? "YES" : "NO", isStatus: true),
      ]),
    );
  }

  Widget _buildMedicalCard() {
    // Check if it's already true in the Database object
    bool isPermanentlyNeutered = widget.pet.sterilization;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("UPDATE STATUS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 10),
        
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          // Sterilization Chip
          FilterChip(
            label: Text("Sterilized: ${_sterilization ? 'YES' : 'NO'}"),
            selected: _sterilization,
            // Disable if already true in DB
            onSelected: isPermanentlyNeutered ? null : (v) => _toggleSterilization(v),
            selectedColor: kCard.withOpacity(0.3),
            disabledColor: Colors.grey.shade100,
          ),
          // Vaccination Chip
          FilterChip(
            label: Text("Vaccinated: ${_vaccinated ? 'YES' : 'NO'}"),
            selected: _vaccinated,
            onSelected: (v) => setState(() => _vaccinated = v),
            selectedColor: kCard.withOpacity(0.3),
          ),
        ]),

        if (_vaccinated) ...[
          const Divider(height: 30),
          const Text("VACCINE LIST", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ..._vaccineList.map((v) => Container(
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              IconButton(onPressed: () => setState(() => _vaccineList.remove(v)), icon: const Icon(Icons.close, size: 16, color: Colors.red))
            ]),
          )),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: _miniEntry(_vacNameController, "Name")),
            const SizedBox(width: 5),
            Expanded(child: _miniEntry(_vacDateController, "Date", isDate: true)),
            IconButton(onPressed: _addNewVaccine, icon: Icon(Icons.add_box, color: kHeader, size: 30))
          ]),
        ]
      ]),
    );
  }

  Widget _lockedRow(String label, String value, {bool isStatus = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 10))),
      Text(value.toUpperCase(), style: TextStyle(color: isStatus ? (value == "YES" ? Colors.greenAccent : Colors.orangeAccent) : Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
    ]),
  );

  Widget _miniEntry(TextEditingController ctrl, String hint, {bool isDate = false}) {
    return TextFormField(
      controller: ctrl,
      readOnly: isDate,
      onTap: isDate ? () async {
        DateTime? d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
        if (d != null) ctrl.text = DateFormat('MM/dd/yyyy').format(d);
      } : null,
      decoration: InputDecoration(hintText: hint, filled: true, fillColor: kBg, isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
    );
  }
}