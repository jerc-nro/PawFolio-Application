import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawfolio/services/picker_services.dart';
import '../providers/pet_controller.dart';
import 'add_pet_forms.dart';

const _kNavy    = Color(0xFF45617D);
const _kCream   = Color(0xFFDCCDC3);
const _kBrown   = Color(0xFFBA7F57);
const _kLabel   = Color(0xFF8A7060);
const _kDivider = Color(0xFFE8DDD6);

class AddPetPage extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;
  /// Set to false when shown inside _NewUserGate (no back destination).
  final bool showCancel;

  const AddPetPage({
    super.key,
    this.onComplete,
    this.showCancel = true,
  });

  @override
  ConsumerState<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends ConsumerState<AddPetPage> {
  int  _step   = 0;
  bool _saving = false;

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  String?   _petType, _sex;
  bool      _spayed  = false;
  String    _wgtUnit = 'KG';
  DateTime? _dob;
  XFile?    _photo;

  final List<String> _selectedBreeds = [];
  List<TextEditingController> _otherBreedCtrls = [TextEditingController()];

  final _nameCtrl        = TextEditingController();
  final _wgtCtrl         = TextEditingController();
  final _colorCtrl       = TextEditingController();
  final _otherBreedCtrl  = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  static const _titles = [
    'Basic Info',
    'Physical Details',
    'Health',
    'Review',
  ];
  static const _subs = [
    'What should we call your pet?',
    'Tell us about their appearance',
    'Health & sterilization status',
    'Review everything before saving',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _wgtCtrl.dispose();
    _colorCtrl.dispose();
    _otherBreedCtrl.dispose();
    _descriptionCtrl.dispose();
    for (final c in _otherBreedCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String msg, {Color color = Colors.red}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ));

  void _next() {
    if (_step == 0) {
      if (!_formKey1.currentState!.validate()) return;
      if (_petType == null) { _snack('Please select a pet type'); return; }
      if (_selectedBreeds.isEmpty) { _snack('Please select at least one breed'); return; }
      if (_selectedBreeds.contains('Other')) {
        final anyEmpty = _otherBreedCtrls.any((c) => c.text.trim().isEmpty);
        if (anyEmpty) {
          _snack('Please fill in all breed name fields');
          return;
        }
      }
    }

    if (_step == 1) {
      if (!_formKey2.currentState!.validate()) return;
      if (_sex == null) { _snack('Please select a sex'); return; }
      if (_dob == null) { _snack('Please pick a date of birth'); return; }
    }

    if (_step < 3) setState(() => _step++);
  }

  List<String> _resolvedBreeds() {
    final result = <String>[];
    for (final b in _selectedBreeds) {
      if (b == 'Other') {
        for (final ctrl in _otherBreedCtrls) {
          final val = ctrl.text.trim();
          if (val.isNotEmpty) result.add(val);
        }
      } else {
        result.add(b);
      }
    }
    return result;
  }

  Future<void> _handleSave() async {
    setState(() => _saving = true);
    try {
      final finalBreeds = _resolvedBreeds();

      await ref.read(petControllerProvider).saveNewPet(
            type:           _petType!,
            selectedBreeds: finalBreeds,
            otherBreed:     '',
            name:           _nameCtrl.text.trim(),
            sex:            _sex!,
            dob:            _dob!,
            isSpayed:       _spayed,
            weight:         double.tryParse(_wgtCtrl.text.trim()) ?? 0.0,
            unit:           _wgtUnit,
            color:          _colorCtrl.text.trim(),
            description:    _descriptionCtrl.text.trim(),
            photo:          _photo,
          );

      if (mounted) {
        if (widget.onComplete != null) {
          widget.onComplete!();
        } else {
          Navigator.pop(context);
        }
        _snack('${_nameCtrl.text.trim()} added! 🐾',
            color: const Color(0xFF7A8C6A));
      }
    } catch (e) {
      _snack('Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await PickerService.pickPetPhoto();
      if (file != null) setState(() => _photo = file);
    } catch (e) {
      _snack('Could not pick photo: $e');
    }
  }

  void _handleBack() {
    if (_step > 0) {
      setState(() => _step--);
    } else if (widget.showCancel) {
      Navigator.pop(context);
    }
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepDots(),
                  const SizedBox(height: 20),
                  _buildStepTitle(),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
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
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    final hasPhoto = _photo != null;

    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background: photo or gradient — entire area is tappable to change photo
          GestureDetector(
            onTap: _pickPhoto,
            child: hasPhoto
                ? ClipRect(
                    child: kIsWeb
                        ? Image.network(_photo!.path,
                            fit: BoxFit.cover, width: double.infinity)
                        : Image.file(File(_photo!.path),
                            fit: BoxFit.cover, width: double.infinity),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3D5570), _kNavy],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
          ),

          // Dark scrim
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(hasPhoto ? 0.45 : 0.0),
                    Colors.black.withOpacity(hasPhoto ? 0.20 : 0.0),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),

          // Back / close button — only shown when showCancel=true OR when step > 0
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: (_step > 0 || widget.showCancel)
                    ? IconButton(
                        icon: const Icon(Icons.chevron_left,
                            color: Colors.white, size: 28),
                        onPressed: _handleBack,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),

          // Title
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Text('Add New Pet',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        shadows: hasPhoto
                            ? [const Shadow(
                                color: Colors.black54, blurRadius: 6)]
                            : null)),
              ),
            ),
          ),

          // Bottom-right camera pill button
          Positioned(
            bottom: 14,
            right: 16,
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    hasPhoto
                        ? Icons.edit_outlined
                        : Icons.camera_alt_outlined,
                    color: _kNavy,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasPhoto ? 'Change Photo' : 'Add Photo',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kNavy),
                  ),
                ]),
              ),
            ),
          ),

          // Centered camera icon when no photo
          if (!hasPhoto)
            IgnorePointer(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_outlined,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 8),
                    Text('Tap to add a photo',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final active = i == _step;
        final done   = i < _step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: active
                ? _kBrown
                : done
                    ? _kBrown.withOpacity(0.45)
                    : _kCream,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
                color: active || done ? _kBrown : Colors.grey.shade400,
                width: 1.5),
          ),
        );
      }),
    );
  }

  Widget _buildStepTitle() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _kNavy.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Step ${_step + 1} of 4',
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _kNavy,
                letterSpacing: 0.5),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      Text(
        _step == 3 ? 'All Done! 🐾' : _titles[_step],
        style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C2C)),
      ),
      const SizedBox(height: 4),
      Text(_subs[_step],
          style: const TextStyle(fontSize: 13, color: _kLabel)),
    ]);
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return StepBasicInfo(
          formKey:         _formKey1,
          nameCtrl:        _nameCtrl,
          petType:         _petType,
          selectedBreeds:  _selectedBreeds,
          otherBreedCtrl:  _otherBreedCtrl,
          otherBreedCtrls: _otherBreedCtrls,
          onTypeChanged: (v) => setState(() {
            _petType = v;
            _selectedBreeds.clear();
            _otherBreedCtrl.clear();
            for (final c in _otherBreedCtrls) {
              c.dispose();
            }
            _otherBreedCtrls = [TextEditingController()];
          }),
          onBreedsChanged: (v) => setState(() {
            _selectedBreeds..clear()..addAll(v);
          }),
          onOtherBreedCtrlsChanged: (v) => setState(() {
            _otherBreedCtrls = v;
          }),
        );
      case 1:
        return StepPhysicalDetails(
          formKey:         _formKey2,
          sex:             _sex,
          wgtCtrl:         _wgtCtrl,
          wgtUnit:         _wgtUnit,
          colorCtrl:       _colorCtrl,
          descriptionCtrl: _descriptionCtrl,
          dob:             _dob,
          onSexChanged:    (v) => setState(() => _sex = v),
          onUnitChanged:   (v) => setState(() => _wgtUnit = v),
          onPickDate:      (picked) => setState(() => _dob = picked),
        );
      case 2:
        return StepHealth(
          isSpayed:        _spayed,
          onSpayedChanged: (v) => setState(() => _spayed = v),
        );
      case 3:
        return StepReview(
          name:            _nameCtrl.text,
          type:            _petType,
          breeds:          _selectedBreeds,
          otherBreed:      _otherBreedCtrl.text,
          otherBreedCtrls: _otherBreedCtrls,
          sex:             _sex,
          weight:          _wgtCtrl.text,
          unit:            _wgtUnit,
          color:           _colorCtrl.text,
          description:     _descriptionCtrl.text,
          dob:             _dob,
          isSpayed:        _spayed,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildNavButtons() {
    final isReview = _step == 3;
    return Row(children: [
      if (_step > 0) ...[
        GestureDetector(
          onTap: () => setState(() => _step--),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kDivider),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: const Icon(Icons.chevron_left, color: _kNavy),
          ),
        ),
        const SizedBox(width: 12),
      ],
      Expanded(
        child: GestureDetector(
          onTap: _saving ? null : (isReview ? _handleSave : _next),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
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
                    color:
                        (isReview ? _kBrown : _kNavy).withOpacity(0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Center(
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      if (isReview)
                        const Icon(Icons.save_outlined,
                            color: Colors.white, size: 18),
                      if (isReview) const SizedBox(width: 6),
                      Text(
                        isReview ? 'Save Profile' : 'Continue',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                      ),
                      if (!isReview) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right,
                            color: Colors.white, size: 20),
                      ],
                    ]),
            ),
          ),
        ),
      ),
    ]);
  }
}