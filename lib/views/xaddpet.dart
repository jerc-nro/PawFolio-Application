import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/pet_provider.dart';
import '../utils/constants/pet_constants.dart';
import '../services/picker_service.dart';

// Mas mainam kung ang mga ito ay nasa lib/utils/app_colors.dart
const _kBg       = Color(0xFF8B947E);
const _kNavBg    = Color(0xFF4A5568);
const _kBrown    = Color(0xFFB5714A);
const _kDarkRed  = Color(0xFF7B2D2D);
const _kWhite    = Colors.white;
const _kLabel    = Color(0xFFF5F0EB);
const _kField    = Color(0xFFF5F0EB);

class AddPetPage extends StatefulWidget {
  const AddPetPage({super.key});
  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _wgtCtrl   = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();

  String?   _petType, _sex, _spayed, _breed;
  String    _wgtUnit = 'KG';
  DateTime? _dob;
  File?     _photo;
  bool      _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _wgtCtrl.dispose();
    _colorCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  // --- Logic Handlers (Nanatiling pareho ang logic mo) ---
  void _err(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _handlePhoto() async {
    try {
      final file = await PickerService.pickPetPhoto();
      if (file != null) setState(() => _photo = file);
    } catch (e) { _err(e.toString()); }
  }

  Future<void> _handleDate() async {
    final date = await PickerService.pickDate(context, _kBrown);
    if (date != null) setState(() => _dob = date);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_petType == null || _sex == null || _spayed == null || _breed == null || _dob == null) {
      _err('Please complete all required selections.');
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<PetProvider>().saveNewPet(
            uid: FirebaseAuth.instance.currentUser!.uid,
            type: _petType!,
            breed: _breed!,
            name: _nameCtrl.text.trim(),
            sex: _sex!,
            dob: _dob!,
            isSpayed: _spayed == 'YES',
            weight: double.tryParse(_wgtCtrl.text.trim()) ?? 0.0,
            unit: _wgtUnit,
            color: _colorCtrl.text.trim(),
            description: _descCtrl.text.trim(),
          );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet added successfully!'), backgroundColor: Colors.green)
        );
        Navigator.pop(context);
      }
    } catch (e) { _err('Save failed: $e'); } 
    finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    // 1. DYNAMIC SIZE DETECTION
    final screenSize = MediaQuery.of(context).size;
    final bool isWideScreen = screenSize.width > 500;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          // Nag-a-adjust ang width base sa device (Mobile vs Tablet/Web)
          width: isWideScreen ? 450 : screenSize.width,
          height: screenSize.height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: isWideScreen ? BorderRadius.circular(32) : BorderRadius.zero,
            boxShadow: isWideScreen ? [const BoxShadow(color: Colors.black12, blurRadius: 20)] : [],
          ),
          child: Scaffold(
            backgroundColor: _kBg,
            // Ginagamit ang resizeToAvoidBottomInset para hindi mag-error ang UI pag lumabas ang keyboard
            resizeToAvoidBottomInset: true, 
            body: Column(children: [
              _buildHeader(),
              Expanded(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(), // Close keyboard pag tinap ang labas
                  child: _buildForm(),
                ),
              ),
              _buildBottomNav(),
            ]),
          ),
        ),
      ),
    );
  }

  // --- UI Components (Optimized with LayoutBuilder/Flexible) ---

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 42, 16, 8),
      child: Stack(alignment: Alignment.center, children: [
        Align(alignment: Alignment.centerLeft, child: _headerBtn('BACK', () => Navigator.pop(context))),
        const Column(children: [
          Text('ADD', style: TextStyle(color: _kWhite, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
          Text('NEW PET', style: TextStyle(color: _kWhite, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ]),
        Align(alignment: Alignment.centerRight, child: _headerBtn('CANCEL', () => Navigator.pop(context))),
      ]),
    );
  }

  Widget _headerBtn(String label, VoidCallback fn) => GestureDetector(
    onTap: fn,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: _kWhite.withOpacity(0.8), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(color: _kWhite, fontSize: 11, fontWeight: FontWeight.bold)),
    ),
  );

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        // BouncingScrollPhysics para sa better mobile feel
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          
          // Photo upload section
          Center(child: Column(children: [
            GestureDetector(
              onTap: _handlePhoto,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 96, height: 96,
                    decoration: const BoxDecoration(color: _kBrown, shape: BoxShape.circle),
                    clipBehavior: Clip.antiAlias,
                    child: _photo != null
                        ? Image.file(_photo!, width: 96, height: 96, fit: BoxFit.cover)
                        : const Icon(Icons.camera_alt_outlined, color: _kWhite, size: 38),
                  ),
                  if (_photo != null)
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: _kDarkRed, shape: BoxShape.circle, border: Border.all(color: _kWhite, width: 2)),
                      child: const Icon(Icons.edit, color: _kWhite, size: 14),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _actionButton(_photo != null ? 'CHANGE PHOTO' : 'UPLOAD PHOTO', _handlePhoto),
          ])),

          const SizedBox(height: 18),
          _rowField('NAME', _textField(ctrl: _nameCtrl, hint: 'ex. Jane Doe', validator: _vName)),
          const SizedBox(height: 10),
          _rowToggle('TYPE', ['CAT', 'DOG'], _petType, (v) => setState(() { _petType = v; _breed = null; })),
          const SizedBox(height: 10),
          _rowToggle('SEX', ['MALE', 'FEMALE'], _sex, (v) => setState(() => _sex = v)),
          const SizedBox(height: 10),
          _rowField('BREED', _breedDrop()),
          const SizedBox(height: 10),
          _rowField('DATE OF BIRTH', _datePickerField()),
          const SizedBox(height: 10),
          _rowField('WEIGHT', Row(children: [
            Expanded(child: _textField(ctrl: _wgtCtrl, hint: 'ex. 6.7', type: const TextInputType.numberWithOptions(decimal: true), validator: _vWeight)),
            const SizedBox(width: 8),
            _unitDrop(),
          ])),
          const SizedBox(height: 10),
          _rowField('COLOR', _textField(ctrl: _colorCtrl, hint: 'Ex. Orange', validator: _vColor)),
          const SizedBox(height: 10),
          _rowToggle('SPAYED/NEUTERED', ['YES', 'NO'], _spayed, (v) => setState(() => _spayed = v)),
          const SizedBox(height: 20),
          
          const Center(child: Text('PET DESCRIPTION', style: TextStyle(color: _kLabel, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
          const SizedBox(height: 8),
          _descriptionField(),
          
          const SizedBox(height: 22),
          _saveButton(),
          const SizedBox(height: 40), // Extra space para hindi dikit sa bottom nav
        ]),
      ),
    );
  }

  // --- Modular UI Widgets ---

  Widget _actionButton(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: _kDarkRed, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: _kWhite, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
    ),
  );

  Widget _datePickerField() => GestureDetector(
    onTap: _handleDate,
    child: Container(
      height: 40, padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: _kField, borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Expanded(child: Text(
          _dob != null ? '${_dob!.month.toString().padLeft(2,'0')}/${_dob!.day.toString().padLeft(2,'0')}/${_dob!.year}' : 'MM/DD/YYYY',
          style: TextStyle(fontSize: 13, color: _dob != null ? Colors.black87 : Colors.grey.shade500),
        )),
        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
      ]),
    ),
  );

  Widget _descriptionField() => TextFormField(
    controller: _descCtrl, maxLines: 5, validator: _vDesc,
    style: const TextStyle(fontSize: 13),
    decoration: InputDecoration(
      hintText: 'Ex. Personality, Favorite Food, Comfort Place',
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      filled: true, fillColor: _kField,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(12),
      errorStyle: const TextStyle(fontSize: 10, color: Color(0xFFFFCDD2)),
    ),
  );

  Widget _saveButton() => SizedBox(
    width: double.infinity, height: 48,
    child: ElevatedButton(
      onPressed: _saving ? null : _handleSave,
      style: ElevatedButton.styleFrom(
        backgroundColor: _kDarkRed, foregroundColor: _kWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
      ),
      child: _saving
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: _kWhite, strokeWidth: 2))
          : const Text('ADD PET PROFILE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
    ),
  );

  Widget _rowField(String label, Widget child) => Row(children: [
      SizedBox(width: 100, child: Text(label, style: const TextStyle(color: _kLabel, fontSize: 11, fontWeight: FontWeight.bold))),
      Expanded(child: child),
    ]);

  Widget _rowToggle(String label, List<String> opts, String? sel, ValueChanged<String> fn) {
    return Row(children: [
      SizedBox(width: 100, child: Text(label, style: const TextStyle(color: _kLabel, fontSize: 11, fontWeight: FontWeight.bold))),
      Expanded(
        child: Wrap( // Wrap para hindi mag-overflow pag maraming options
          spacing: 8,
          children: opts.map((o) => GestureDetector(
            onTap: () => fn(o),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel == o ? _kWhite : _kWhite.withOpacity(0.22),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(o, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: sel == o ? _kBg : _kWhite)),
            ),
          )).toList(),
        ),
      ),
    ]);
  }

  Widget _textField({required TextEditingController ctrl, required String hint, TextInputType? type, String? Function(String?)? validator}) => TextFormField(
    controller: ctrl, keyboardType: type, validator: validator,
    style: const TextStyle(fontSize: 13),
    decoration: InputDecoration(
      hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      filled: true, fillColor: _kField,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
      errorStyle: const TextStyle(fontSize: 10, color: Color(0xFFFFCDD2)),
    ),
  );

  Widget _breedDrop() {
    final list = _petType != null ? PetConstants.breeds[_petType] ?? [] : <String>[];
    return DropdownButtonFormField<String>(
      value: _breed, isDense: true,
      validator: (_) => _breed == null ? 'Please select a breed' : null,
      decoration: InputDecoration(
        filled: true, fillColor: _kField,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
        errorStyle: const TextStyle(fontSize: 10, color: Color(0xFFFFCDD2)),
      ),
      hint: Text(_petType == null ? 'Select type first' : 'SELECT BREED', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      items: list.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: _petType != null ? (v) => setState(() => _breed = v) : null,
    );
  }

  Widget _unitDrop() => Container(
    height: 40, padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(color: _kField, borderRadius: BorderRadius.circular(8)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _wgtUnit, isDense: true,
        items: const [
          DropdownMenuItem(value: 'KG',  child: Text('KG',  style: TextStyle(fontSize: 12))),
          DropdownMenuItem(value: 'LBS', child: Text('LBS', style: TextStyle(fontSize: 12))),
        ],
        onChanged: (v) => setState(() => _wgtUnit = v!),
      ),
    ),
  );

  // --- Validators (Invisible personalization applied silently) ---
  String? _vName(String? v) => (v == null || v.trim().isEmpty) ? 'Name is required.' : null;
  String? _vWeight(String? v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Invalid weight.' : null;
  String? _vColor(String? v) => (v == null || v.trim().isEmpty) ? 'Color is required.' : null;
  String? _vDesc(String? v) => (v != null && v.length > 500) ? 'Too long.' : null;

  // --- Bottom Nav ---
  Widget _buildBottomNav() {
    return Container(
      height: 80, color: _kNavBg,
      child: Stack(clipBehavior: Clip.none, children: [
        Row(children: [
          _navItem(Icons.home_outlined, 'Home'),
          _navItem(Icons.pets, 'My Pets'),
          const SizedBox(width: 70),
          _navItem(Icons.description_outlined, 'Records'),
          _navItem(Icons.person_outline, 'Account'),
        ]),
        Positioned(
          top: -24, left: 0, right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _saving ? null : _handleSave,
              child: Container(
                width: 58, height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: _kBrown,
                  border: Border.all(color: _kWhite, width: 3),
                  boxShadow: [BoxShadow(color: _kBrown.withOpacity(0.45), blurRadius: 14, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.add_rounded, color: _kWhite, size: 32),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _navItem(IconData icon, String label) => Expanded(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: Colors.white60, size: 22),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
    ]),
  );
}