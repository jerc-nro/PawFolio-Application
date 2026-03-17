import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawfolio/services/picker_services.dart';
import '../providers/pet_controller.dart';
import 'add_pet_forms.dart';

const _kNavy  = Color(0xFF45617D);
const _kCream = Color(0xFFDCCDC3);
const _kBrown = Color(0xFFBA7F57);

class AddPetPage extends ConsumerStatefulWidget {
  const AddPetPage({super.key});

  @override
  ConsumerState<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends ConsumerState<AddPetPage> {
  int _step = 0;
  bool _saving = false;
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  String? _petType, _sex;
  bool _spayed = false;
  String _wgtUnit = 'KG';
  DateTime? _dob;
  XFile? _photo;
  final List<String> _selectedBreeds = [];

  final _nameCtrl       = TextEditingController();
  final _wgtCtrl        = TextEditingController();
  final _colorCtrl      = TextEditingController();
  final _otherBreedCtrl = TextEditingController();

  static const _titles = ['Basic Info', 'Physical Details', 'Health', 'Review'];
  static const _subs   = [
    'What should we call your pet?',
    'Tell us about their appearance',
    'Health & sterilization',
    'Review before saving',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose(); _wgtCtrl.dispose();
    _colorCtrl.dispose(); _otherBreedCtrl.dispose();
    super.dispose();
  }

  void _err(String m) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(m),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );

  void _next() {
    if (_step == 0) {
      if (!_formKey1.currentState!.validate()) return;
      if (_petType == null) { _err('Select a pet type'); return; }
      if (_selectedBreeds.isEmpty) { _err('Select at least one breed'); return; }
    }
    if (_step == 1) {
      if (!_formKey2.currentState!.validate()) return;
      if (_sex == null) { _err('Select sex'); return; }
      if (_dob == null) { _err('Pick a date of birth'); return; }
    }
    if (_step < 3) setState(() => _step++);
  }

  Future<void> _handleSave() async {
    setState(() => _saving = true);
    try {
      await ref.read(petControllerProvider).saveNewPet(
        type: _petType!,
        selectedBreeds: _selectedBreeds,
        otherBreed: _otherBreedCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        sex: _sex!,
        dob: _dob!,
        isSpayed: _spayed,
        weight: double.tryParse(_wgtCtrl.text.trim()) ?? 0.0,
        unit: _wgtUnit,
        color: _colorCtrl.text.trim(),
        description: '',
        photo: _photo,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pet added! 🐾'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) { _err('Save failed: $e'); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCream,
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildStepDots(),
                const SizedBox(height: 20),
                _buildStepTitle(),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.06, 0), end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildCurrentStep(),
                  ),
                ),
                const SizedBox(height: 28),
                _buildNavButtons(),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3D5570), _kNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 160,
          child: Stack(alignment: Alignment.center, children: [
            Positioned(top: 12, left: 12,
              child: IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                onPressed: () => _step > 0 ? setState(() => _step--) : Navigator.pop(context),
              ),
            ),
            const Positioned(
              top: 18,
              child: Text('Pet Profile',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            ),
            Positioned(
              bottom: -40,
              child: GestureDetector(
                onTap: () async {
                  final file = await PickerService.pickPetPhoto();
                  if (file != null) setState(() => _photo = file);
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        color: _kCream, shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _photo != null
                        ? (kIsWeb
                            ? Image.network(_photo!.path, fit: BoxFit.cover)
                            : Image.file(File(_photo!.path), fit: BoxFit.cover))
                        : const Icon(Icons.camera_alt_outlined, color: _kNavy, size: 28),
                    ),
                    if (_photo != null)
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            color: _kBrown, shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 13),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildStepDots() {
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (i) {
          final active = i == _step;
          final done   = i < _step;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 28 : 10, height: 10,
            decoration: BoxDecoration(
              color: active ? _kBrown : done ? _kBrown.withOpacity(0.4) : _kCream,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: active || done ? _kBrown : Colors.grey.shade400, width: 1.5),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepTitle() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        _step == 3 ? 'All Done! 🐾' : _titles[_step],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C)),
      ),
      const SizedBox(height: 4),
      Text(_subs[_step],
        style: const TextStyle(fontSize: 13, color: Color(0xFF8A7060))),
    ]);
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0: return StepBasicInfo(
        formKey: _formKey1,
        nameCtrl: _nameCtrl,
        petType: _petType,
        selectedBreeds: _selectedBreeds,
        otherBreedCtrl: _otherBreedCtrl,
        onTypeChanged: (v) => setState(() { _petType = v; _selectedBreeds.clear(); }),
        onBreedsChanged: (v) => setState(() {}),
      );
      case 1: return StepPhysicalDetails(
        formKey: _formKey2,
        sex: _sex,
        wgtCtrl: _wgtCtrl,
        wgtUnit: _wgtUnit,
        colorCtrl: _colorCtrl,
        dob: _dob,
        onSexChanged: (v) => setState(() => _sex = v),
        onUnitChanged: (v) => setState(() => _wgtUnit = v),
        onPickDate: () async {
          final d = await PickerService.pickDate(context, _kBrown);
          if (d != null) setState(() => _dob = d);
        },
      );
      case 2: return StepHealth(
        isSpayed: _spayed,
        onSpayedChanged: (v) => setState(() => _spayed = v),
      );
      case 3: return StepReview(
        name: _nameCtrl.text,
        type: _petType,
        breeds: _selectedBreeds,
        sex: _sex,
        weight: _wgtCtrl.text,
        unit: _wgtUnit,
        dob: _dob,
        isSpayed: _spayed,
      );
      default: return const SizedBox();
    }
  }

  Widget _buildNavButtons() {
    final isReview = _step == 3;
    return Row(children: [
      if (_step > 0) ...[
        GestureDetector(
          onTap: () => setState(() => _step--),
          child: Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8DDD6)),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: const Icon(Icons.chevron_left, color: _kNavy),
          ),
        ),
        const SizedBox(width: 12),
      ],
      Expanded(
        child: GestureDetector(
          onTap: _saving ? null : (isReview ? _handleSave : _next),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isReview
                    ? [const Color(0xFFC4895E), _kBrown]
                    : [const Color(0xFF4E6E8A), _kNavy],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (isReview ? _kBrown : _kNavy).withOpacity(0.28),
                  blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Center(child: _saving
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  if (isReview) const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                  if (isReview) const SizedBox(width: 6),
                  Text(isReview ? 'Save Profile' : 'Continue',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  if (!isReview) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                  ],
                ]),
            ),
          ),
        ),
      ),
    ]);
  }
}