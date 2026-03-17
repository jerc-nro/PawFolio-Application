// lib/features/pets/widgets/my_pets_card.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/pet_model.dart';

const _kNavy  = Color(0xFF45617D);
const _kBrown = Color(0xFFBA7F57);
const _kCream = Color(0xFFDCCDC3);

class MyPetsCard extends ConsumerWidget {
  final Pet pet;
  final VoidCallback onTap;
  final Function(Pet) onArchive;

  const MyPetsCard({
    super.key,
    required this.pet,
    required this.onTap,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kNavy,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _kNavy.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _PetAvatar(pet: pet, onArchive: onArchive),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: _PetInfo(pet: pet, onTap: onTap),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────
class _PetAvatar extends StatelessWidget {
  final Pet pet;
  final Function(Pet) onArchive;

  const _PetAvatar({required this.pet, required this.onArchive});

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        pet.profileBase64 != null && pet.profileBase64!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.all(8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kCream.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo or placeholder
          hasPhoto
              ? Image.memory(
                  base64Decode(pet.profileBase64!),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => _Placeholder(pet.type),
                )
              : _Placeholder(pet.type),

          // Subtle gradient overlay at bottom for legibility
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.30),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Archive button
          Positioned(
            top: 6, right: 6,
            child: GestureDetector(
              onTap: () => onArchive(pet),
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.archive_outlined,
                  color: Colors.white70,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String type;
  const _Placeholder(this.type);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        type.toLowerCase() == 'dog'
            ? Icons.pets
            : Icons.animation_outlined,
        size: 38,
        color: Colors.white.withOpacity(0.35),
      ),
    );
  }
}

// ── Info section ──────────────────────────────────────────────────────────────
class _PetInfo extends StatelessWidget {
  final Pet pet;
  final VoidCallback onTap;

  const _PetInfo({required this.pet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pet.name.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${pet.type}  ·  ${pet.breed}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.60),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 28,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBrown.withOpacity(0.75),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              'VIEW',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}