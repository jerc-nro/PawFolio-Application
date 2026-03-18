import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/pet_model.dart';
import '../../records/theme/records_theme.dart';

class MyPetsCard extends ConsumerStatefulWidget {
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
  ConsumerState<MyPetsCard> createState() => _MyPetsCardState();
}

class _MyPetsCardState extends ConsumerState<MyPetsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    _isFlipped ? _flipCtrl.reverse() : _flipCtrl.forward();
    setState(() => _isFlipped = !_isFlipped);
  }

  void _cancelFlip() {
    _flipCtrl.reverse();
    setState(() => _isFlipped = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isFlipped ? null : widget.onTap,
      onLongPress: _flip,
      child: AnimatedBuilder(
        animation: _flipAnim,
        builder: (context, _) {
          final angle    = _flipAnim.value * math.pi;
          final showBack = _flipAnim.value > 0.5;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _CardBack(
                      pet: widget.pet,
                      onArchive: () {
                        _cancelFlip();
                        widget.onArchive(widget.pet);
                      },
                      onCancel: _cancelFlip,
                    ),
                  )
                : _CardFront(
                    pet: widget.pet,
                    onTap: widget.onTap,
                    onLongPress: _flip,
                  ),
          );
        },
      ),
    );
  }
}

// ─── Front Face ───────────────────────────────────────────────────────────────
class _CardFront extends StatelessWidget {
  final Pet pet;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _CardFront({
    required this.pet,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        pet.profileBase64 != null && pet.profileBase64!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: RecordsPalette.steel,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: RecordsPalette.steel.withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Photo ──────────────────────────────────────
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.all(7),
              width: double.infinity,
              decoration: BoxDecoration(
                color: RecordsPalette.steelLite.withOpacity(0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(fit: StackFit.expand, children: [

                hasPhoto
                    ? Image.memory(
                        base64Decode(pet.profileBase64!),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) => _Placeholder(pet.type),
                      )
                    : _Placeholder(pet.type),

                // Bottom scrim
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          RecordsPalette.ink.withOpacity(0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Active pill — top left
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: RecordsPalette.sage.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 5, height: 5,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      const Text('Active',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4)),
                    ]),
                  ),
                ),

                // Hold hint — top right
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.touch_app_outlined,
                        color: Colors.white60, size: 13),
                  ),
                ),

                // Pet type badge — bottom left over scrim
                Positioned(
                  bottom: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25)),
                    ),
                    child: Text(
                      pet.type.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8),
                    ),
                  ),
                ),
              ]),
            ),
          ),

          // ── Info ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 6, 11, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1),
                ),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.cake_outlined,
                      size: 10,
                      color: Colors.white.withOpacity(0.45)),
                  const SizedBox(width: 4),
                  Text(
                    pet.formattedAge,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10),
                  ),
                ]),
                const SizedBox(height: 9),

                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    width: double.infinity,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: RecordsPalette.terra,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'View Profile',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Back Face ────────────────────────────────────────────────────────────────
class _CardBack extends StatelessWidget {
  final Pet pet;
  final VoidCallback onArchive;
  final VoidCallback onCancel;

  const _CardBack({
    required this.pet,
    required this.onArchive,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2E4558),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: RecordsPalette.steel.withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // Icon ring
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: RecordsPalette.linen.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: RecordsPalette.linen.withOpacity(0.18),
                    width: 1.5),
              ),
              child: Icon(Icons.inventory_2_outlined,
                  color: RecordsPalette.linen.withOpacity(0.75), size: 22),
            ),
            const SizedBox(height: 12),

            Text(pet.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1)),
            const SizedBox(height: 5),

            Text(
              'Long-pressed by mistake?\nTap Cancel below.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: RecordsPalette.linen.withOpacity(0.4),
                  fontSize: 10,
                  height: 1.5),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                  height: 1, color: Colors.white.withOpacity(0.08)),
            ),

            Text(
              'Archive ${pet.name}?',
              style: TextStyle(
                  color: RecordsPalette.linen.withOpacity(0.65),
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            // Archive button
            GestureDetector(
              onTap: onArchive,
              child: Container(
                width: double.infinity,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: RecordsPalette.terra.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.archive_outlined,
                          size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text('Archive',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ]),
              ),
            ),

            const SizedBox(height: 7),

            // Cancel button
            GestureDetector(
              onTap: onCancel,
              child: Container(
                width: double.infinity,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.12)),
                ),
                child: Text('Cancel',
                    style: TextStyle(
                        color: RecordsPalette.linen.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Placeholder ──────────────────────────────────────────────────────────────
class _Placeholder extends StatelessWidget {
  final String type;
  const _Placeholder(this.type);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            type.toLowerCase() == 'dog'
                ? Icons.pets
                : Icons.animation_outlined,
            size: 34,
            color: RecordsPalette.steelLite.withOpacity(0.5),
          ),
          const SizedBox(height: 6),
          Text(
            'No photo',
            style: TextStyle(
                fontSize: 9,
                color: RecordsPalette.steelLite.withOpacity(0.4),
                letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}