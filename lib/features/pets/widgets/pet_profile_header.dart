// lib/features/pets/widgets/pet_profile_header.dart

import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../models/pet_model.dart';

const _kNavy  = Color(0xFF45617D);
const _kBrown = Color(0xFFBA7F57);
const _kRed   = Color(0xFFBD4B4B);

class PetProfileHeader extends StatelessWidget {
  final Pet pet;
  final bool editMode;
  final bool saving;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onPickPhoto;

  const PetProfileHeader({
    super.key,
    required this.pet,
    required this.editMode,
    required this.saving,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
    required this.onPickPhoto,
  });

  int? _daysUntilBirthday() {
    final dob = DateTime.tryParse(pet.birthDate);
    if (dob == null) return null;
    final now  = DateTime.now();
    var next   = DateTime(now.year, dob.month, dob.day);
    if (next.isBefore(DateTime(now.year, now.month, now.day))) {
      next = DateTime(now.year + 1, dob.month, dob.day);
    }
    return next.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final isDeceased = !pet.isAlive;
    // Lock edit for both archived AND deceased pets
    final isLocked   = pet.isArchived || isDeceased;
    final days       = _daysUntilBirthday();

    return SliverAppBar(
      expandedHeight: 270,
      pinned: true,
      backgroundColor: _kNavy,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        if (!editMode)
          isLocked
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      // Different icon per state
                      isDeceased
                          ? Icons.heart_broken_outlined
                          : Icons.lock_outline,
                      color: Colors.white.withOpacity(0.4),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      // "Deceased" for dead pets, "Archived" for archived
                      isDeceased ? 'Deceased' : 'Archived',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 13),
                    ),
                  ]),
                )
              : TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined,
                      color: Colors.white, size: 16),
                  label: const Text('Edit',
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                )
        else ...[
          TextButton(
            onPressed: saving ? null : onCancel,
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          TextButton(
            onPressed: saving ? null : onSave,
            child: saving
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Save',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
          ),
        ],
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(fit: StackFit.expand, children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3D5570), _kNavy],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05)),
            ),
          ),
          Positioned(
            bottom: 24, left: 0, right: 0,
            child: Column(children: [
              _PetAvatar(
                base64: pet.profileBase64,
                editMode: editMode,
                onTap: onPickPhoto,
              ),
              const SizedBox(height: 10),
              Text(pet.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _Chip(pet.type),
                const SizedBox(width: 6),
                _Chip(pet.formattedAge),
                if (isDeceased) ...[
                  const SizedBox(width: 6),
                  _Chip('DECEASED', color: _kRed),
                ],
              ]),
              // Birthday chip — hide for deceased pets
              if (!isDeceased && days != null) ...[
                const SizedBox(height: 6),
                _Chip(
                  days == 0
                      ? '🎂 Birthday today!'
                      : '🎁 Birthday in $days day${days == 1 ? '' : 's'}',
                  color: days == 0 ? _kBrown : null,
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class _PetAvatar extends StatelessWidget {
  final String? base64;
  final bool editMode;
  final VoidCallback onTap;

  const _PetAvatar({
    required this.base64,
    required this.editMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = base64 != null && base64!.isNotEmpty;
    return GestureDetector(
      onTap: editMode ? onTap : null,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 86, height: 86,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            color: const Color(0xFFDCCDC3),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: hasPhoto
              ? Image.memory(base64Decode(base64!), fit: BoxFit.cover)
              : const Icon(Icons.pets, color: _kNavy, size: 34),
        ),
        if (editMode)
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                  color: _kBrown,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2)),
              child: const Icon(Icons.camera_alt,
                  color: Colors.white, size: 13),
            ),
          ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color? color;
  const _Chip(this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withOpacity(color != null ? 0.85 : 0.15),
        borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: color != null
                  ? Colors.white
                  : Colors.white.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4)),
    );
  }
}