// lib/features/pets/widgets/record_pets_card.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../models/pet_model.dart';

const _kNavy   = Color(0xFF45617D);
const _kBrown  = Color(0xFFBA7F57);
const _kCream  = Color(0xFFDCCDC3);
const _kLabel  = Color(0xFF8A7060);

class PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback? onTap;
  final Function(Pet)? onArchive;

  const PetCard({
    super.key,
    required this.pet,
    this.onTap,
    this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final bool alive    = pet.isAlive;
    final bool canSwipe = onArchive != null;

    return Dismissible(
      key: Key(pet.petID),
      direction: canSwipe
          ? DismissDirection.endToStart
          : DismissDirection.none,
      onDismissed: (_) => onArchive?.call(pet),
      background: _ArchiveBackground(),
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: alive ? 1.0 : 0.72,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: alive ? _kNavy : const Color(0xFF374A5A),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: (alive ? _kNavy : Colors.black).withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  _PetImage(pet: pet, alive: alive),
                  const SizedBox(width: 16),
                  _PetDetails(pet: pet, alive: alive),
                ]),
              ),
              Positioned(
                top: 12, right: 14,
                child: _StatusBadge(alive: alive),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Pet image ─────────────────────────────────────────────────────────────────
class _PetImage extends StatelessWidget {
  final Pet pet;
  final bool alive;
  const _PetImage({required this.pet, required this.alive});

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        pet.profileBase64 != null && pet.profileBase64!.isNotEmpty;

    Widget image = hasPhoto
        ? Image.memory(
            base64Decode(pet.profileBase64!),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => _placeholder(),
          )
        : _placeholder();

    // Greyscale filter for deceased pets
    if (!alive) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: image,
      );
    }

    return Container(
      width: 88, height: 88,
      decoration: BoxDecoration(
        color: _kCream.withOpacity(0.25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: alive ? Colors.white.withOpacity(0.30) : Colors.white24,
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: image,
    );
  }

  Widget _placeholder() => Center(
    child: Icon(
      Icons.pets,
      size: 36,
      color: Colors.white.withOpacity(0.40),
    ),
  );
}

// ── Pet details ───────────────────────────────────────────────────────────────
class _PetDetails extends StatelessWidget {
  final Pet pet;
  final bool alive;
  const _PetDetails({required this.pet, required this.alive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spacer so text doesn't overlap the status badge
          const SizedBox(height: 20),
          Text(
            pet.name,
            style: TextStyle(
              color: alive ? Colors.white : Colors.white60,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              decoration: alive ? null : TextDecoration.lineThrough,
              decorationColor: Colors.white38,
            ),
          ),
          const SizedBox(height: 4),
          _Row(Icons.category_outlined, '${pet.type}  ·  ${pet.breed}'),
          const SizedBox(height: 3),
          _Row(Icons.cake_outlined, pet.formattedAge),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Row(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 11, color: Colors.white54),
      const SizedBox(width: 5),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ]);
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool alive;
  const _StatusBadge({required this.alive});

  @override
  Widget build(BuildContext context) {
    final color = alive ? const Color(0xFF81C784) : const Color(0xFFE57373);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.50), width: 1),
      ),
      child: Text(
        alive ? 'active' : 'inactive',
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ── Swipe-to-archive background ───────────────────────────────────────────────
class _ArchiveBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: _kBrown,
        borderRadius: BorderRadius.circular(22),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 28),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.archive_outlined, color: Colors.white, size: 24),
          SizedBox(height: 4),
          Text('ARCHIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            )),
        ],
      ),
    );
  }
}