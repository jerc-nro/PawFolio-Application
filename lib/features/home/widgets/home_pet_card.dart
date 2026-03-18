import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/pet_model.dart';
import '../../pets/providers/pet_controller.dart';
import '../../pets/screens/pet_profile_page.dart';

class HomePetCard extends ConsumerWidget {
  final Pet pet;
  const HomePetCard({super.key, required this.pet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ImageProvider? petImage;
    if (pet.profileBase64 != null && pet.profileBase64!.isNotEmpty) {
      try { petImage = MemoryImage(base64Decode(pet.profileBase64!)); } catch (_) {}
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PetProfilePage(pet: pet)),
      ),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showArchiveDialog(context, ref);
      },
      child: Container(
        width: 112,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF45617D),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF45617D).withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Image ──────────────────────────────────────
              AspectRatio(
                aspectRatio: 1,
                child: petImage != null
                    ? Image(image: petImage, fit: BoxFit.cover)
                    : Container(
                        color: const Color(0xFF3A5068),
                        child: const Center(
                          child: Icon(Icons.pets,
                              color: Color(0xFF6B8CA4), size: 30)),
                      ),
              ),
              // ── Info ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(pet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.1)),
                    const SizedBox(height: 2),
                    Text('${pet.type} · ${pet.breed}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.w400)),
                    const SizedBox(height: 8),
                    Container(
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBA7F57),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('View Info',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showArchiveDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D3A4A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                  color: const Color(0xFFCF6679).withOpacity(0.15),
                  shape: BoxShape.circle),
              child: const Icon(Icons.archive_outlined,
                  color: Color(0xFFCF6679), size: 26),
            ),
            const SizedBox(height: 14),
            const Text('Archive Pet?',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'Archive ${pet.name}? You can restore them anytime.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 42, alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Text('Cancel',
                      style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  await ref
                      .read(petControllerProvider)
                      .archivePet(pet.petID);
                },
                child: Container(
                  height: 42, alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: const Color(0xFFCF6679),
                      borderRadius: BorderRadius.circular(10)),
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
  }
}