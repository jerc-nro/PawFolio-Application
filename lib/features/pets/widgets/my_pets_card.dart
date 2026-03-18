import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/pet_model.dart';
import '../../records/theme/records_theme.dart';

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
    final hasPhoto =
        pet.profileBase64 != null && pet.profileBase64!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: RecordsPalette.steel.withOpacity(0.22),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: RecordsPalette.ink.withOpacity(0.10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Photo ───────────────────────────────────────────────────────
            Expanded(
              flex: 13,
              child: Stack(
                fit: StackFit.expand,
                children: [

                  // Photo / placeholder
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22)),
                    child: hasPhoto
                        ? Image.memory(
                            base64Decode(pet.profileBase64!),
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            errorBuilder: (_, __, ___) =>
                                _Placeholder(pet.type),
                          )
                        : _Placeholder(pet.type),
                  ),

                  // Thin gradient: just enough to read text, no heavy darkening
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22)),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.55, 1.0],
                          colors: [
                            Colors.black.withOpacity(0.08),
                            Colors.transparent,
                            Colors.black.withOpacity(0.52),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Type badge — top left
                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: RecordsPalette.terra.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pet.type.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2),
                      ),
                    ),
                  ),

                  // Status dot — top right
                  Positioned(
                    top: 10, right: 10,
                    child: _StatusDot(isAlive: pet.isAlive),
                  ),

                  // Name + age — bottom of photo
                  Positioned(
                    bottom: 10, left: 10, right: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          pet.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.1,
                              shadows: [
                                Shadow(
                                    color: Colors.black45,
                                    blurRadius: 6,
                                    offset: Offset(0, 1))
                              ]),
                        ),
                        const SizedBox(height: 3),
                        Row(children: [
                          Icon(Icons.cake_outlined,
                              size: 10,
                              color: Colors.white.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text(
                            pet.formattedAge,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 10,
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          if (pet.breed.isNotEmpty)
                            Flexible(
                              child: Text(
                                pet.breed,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.55),
                                    fontSize: 10),
                              ),
                            ),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Action row ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Row(children: [

                // View Profile
                Expanded(
                  child: GestureDetector(
                    onTap: onTap,
                    child: Container(
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF4E6E8A),
                            RecordsPalette.steel,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: RecordsPalette.steel.withOpacity(0.30),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.pets_outlined,
                              size: 12, color: Colors.white),
                          SizedBox(width: 5),
                          Text('Profile',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2)),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 7),

                // Archive
                GestureDetector(
                  onTap: () => _confirmArchive(context),
                  child: Container(
                    height: 36,
                    width: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: RecordsPalette.terraLite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: RecordsPalette.terra.withOpacity(0.3)),
                    ),
                    child: Icon(Icons.archive_outlined,
                        size: 16, color: RecordsPalette.terra),
                  ),
                ),

              ]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmArchive(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RecordsPalette.bg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: RecordsPalette.terraLite,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.archive_outlined,
                  color: RecordsPalette.terra, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              'Archive ${pet.name}?',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: RecordsPalette.ink),
            ),
            const SizedBox(height: 8),
            Text(
              '${pet.name} will be moved to your archived pets '
              'and removed from the active list.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  color: RecordsPalette.muted,
                  height: 1.5),
            ),
          ],
        ),
        actions: [
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx, false),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: RecordsPalette.steelLite.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(
                          color: RecordsPalette.muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx, true),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: RecordsPalette.terra,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Archive',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ),
            ),
          ]),
        ],
      ),
    );

    if (confirmed == true) onArchive(pet);
  }
}

// ─── Status Dot ───────────────────────────────────────────────────────────────
class _StatusDot extends StatelessWidget {
  final bool isAlive;
  const _StatusDot({required this.isAlive});

  @override
  Widget build(BuildContext context) {
    final bgColor    = isAlive ? const Color(0xFF4CAF50) : RecordsPalette.terra;
    final label      = isAlive ? 'Active' : 'Deceased';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.40),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 5, height: 5,
          decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4)),
      ]),
    );
  }
}

// ─── Placeholder ──────────────────────────────────────────────────────────────
class _Placeholder extends StatelessWidget {
  final String type;
  const _Placeholder(this.type);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            RecordsPalette.steelLite,
            RecordsPalette.sageLite,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type.toLowerCase() == 'dog'
                  ? Icons.pets
                  : Icons.animation_outlined,
              size: 38,
              color: RecordsPalette.steel.withOpacity(0.35),
            ),
            const SizedBox(height: 6),
            Text(
              'No photo',
              style: TextStyle(
                  fontSize: 9,
                  color: RecordsPalette.muted.withOpacity(0.5),
                  letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}