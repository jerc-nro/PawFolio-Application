import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void showAddGroomingDialog(BuildContext context, String petId) {
  final screenWidth = MediaQuery.of(context).size.width;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: screenWidth > 500 ? 400 : screenWidth * 0.85,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: AddGroomingContent(petId: petId),
        ),
      );
    },
  );
}

class AddGroomingContent extends StatefulWidget {
  final String petId;
  const AddGroomingContent({super.key, required this.petId});

  @override
  State<AddGroomingContent> createState() => _AddGroomingContentState();
}

class _AddGroomingContentState extends State<AddGroomingContent> {
  // 1. Controllers and Variables for your 4 required fields
  final TextEditingController _clinicController = TextEditingController(); // clinicName
  final TextEditingController _dateController = TextEditingController();   // date
  String _selectedGroomType = "NAIL TRIM";                                 // type
  String _selectedStatus = "UPCOMING";                                     // status

  bool _clinicError = false;
  bool _dateError = false;

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd.MM.yyyy').format(picked);
        _dateError = false;
      });
    }
  }

  void _onSavePressed() {
    setState(() {
      _clinicError = _clinicController.text.trim().isEmpty;
      _dateError = _dateController.text.trim().isEmpty;
    });

    if (_clinicError || _dateError) return;

    _showConfirmationDialog();
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Confirm Submission"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Are you sure you want to save this record?"),
              const SizedBox(height: 10),
              Text("Clinic: ${_clinicController.text}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text("Type: $_selectedGroomType", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text("Status: $_selectedStatus", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // SAVING ALL 4 FIELDS TO FIREBASE
                  await FirebaseFirestore.instance
                      .collection('pets')
                      .doc(widget.petId)
                      .collection('groom_visits')
                      .add({
                    'provider': _clinicController.text.trim(), // clinicName
                    'date_string': _dateController.text.trim(), // date
                    'type': _selectedGroomType,                 // type
                    'status': _selectedStatus,                  // status
                    'date_timestamp': FieldValue.serverTimestamp(),
                  });

                  if (mounted) {
                    Navigator.pop(context); // Close Confirmation
                    Navigator.pop(this.context); // Close Main Dialog
                  }
                } catch (e) {
                  debugPrint("Error saving grooming: $e");
                }
              },
              child: const Text("Yes, Submit", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color textBlue = Color(0xFF455A64);
    const Color borderBlue = Color(0xFF0277BD);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIELD 1: CLINIC NAME
          _dialogTextField("Clinic / Salon Name", textBlue, borderBlue, _clinicController, showError: _clinicError),
          
          const SizedBox(height: 15),
          
          // FIELD 2: DATE
          _dialogFieldLabel("Date of Service", textBlue),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: AbsorbPointer(
              child: _customTextField(
                _dateController, 
                _dateError ? Colors.red : borderBlue, 
                suffixIcon: Icon(Icons.calendar_month, color: _dateError ? Colors.red : Colors.black)
              ),
            ),
          ),
          if (_dateError)
            const Padding(
              padding: EdgeInsets.only(top: 4, left: 4),
              child: Text("Please select a date", style: TextStyle(color: Colors.red, fontSize: 11)),
            ),
          
          const SizedBox(height: 15),
          
          // FIELD 3: GROOMING TYPE
          _dialogFieldLabel("Type of Groom", textBlue),
          _groomTypeDropdown(borderBlue),
          
          const SizedBox(height: 20),
          
          // FIELD 4: STATUS
          const Text("Grooming Status",
              style: TextStyle(color: textBlue, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _statusButton("Upcoming", const Color(0xFFFFB300)),
              _statusButton("Ongoing", const Color(0xFFD32F2F)),
              _statusButton("Completed", const Color(0xFF008000)),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // FINAL SAVE ACTION
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _onSavePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: textBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: const Text("SAVE RECORD", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Helpers ---

  Widget _statusButton(String label, Color color) {
    bool isSelected = _selectedStatus == label.toUpperCase();
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = label.toUpperCase()),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color, 
            fontSize: 11, 
            fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }

  Widget _dialogFieldLabel(String label, Color color) {
    return Padding(padding: const EdgeInsets.only(bottom: 5), child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)));
  }

  Widget _dialogTextField(String label, Color textColor, Color borderColor, TextEditingController controller, {bool showError = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(height: 5),
      _customTextField(controller, showError ? Colors.red : borderColor),
      if (showError) const Padding(padding: EdgeInsets.only(top: 4, left: 4), child: Text("This field is required", style: TextStyle(color: Colors.red, fontSize: 11))),
    ]);
  }

  Widget _customTextField(TextEditingController controller, Color borderColor, {Widget? suffixIcon}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(isDense: true, suffixIcon: suffixIcon, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor, width: 1.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor, width: 2))),
    );
  }

  Widget _groomTypeDropdown(Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor, width: 1.5)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGroomType,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0277BD), size: 30),
          items: ["NAIL TRIM", "FULL GROOM", "BATH"].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Row(children: [const Icon(Icons.cut, color: Color(0xFF0277BD), size: 20), const SizedBox(width: 10), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0277BD)))]));
          }).toList(),
          onChanged: (newValue) => setState(() => _selectedGroomType = newValue!),
        ),
      ),
    );
  }
}