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
      try {
        petImage = MemoryImage(base64Decode(pet.profileBase64!));
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => PetProfilePage(pet: pet))),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showArchiveDialog(context, ref);
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8DDD6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Photo ────────────────────────────────────────
              SizedBox(
                height: 110,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    petImage != null
                        ? Image(image: petImage, fit: BoxFit.cover)
                        : Container(
                            color: const Color(0xFFF0EBE6),
                            child: const Center(
                              child: Icon(Icons.pets,
                                  color: Color(0xFFBA7F57), size: 34),
                            ),
                          ),
                    // Type badge
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(pet.type,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3)),
                      ),
                    ),
                    // Hold-to-archive hint
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.black.withOpacity(0.30),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.touch_app_outlined,
                                color: Colors.white70, size: 10),
                            SizedBox(width: 3),
                            Text('Hold to archive',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Info ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(pet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF2D3A4A),
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(pet.breed,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF9A8F88),
                            fontSize: 10,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    // Age chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EBE6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cake_outlined,
                              size: 11, color: Color(0xFFBA7F57)),
                          const SizedBox(width: 4),
                          Text(pet.formattedAge,
                              style: const TextStyle(
                                  color: Color(0xFFBA7F57),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
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
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Archive ${pet.name}? You can restore them anytime.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 13, height: 1.5)),
          ],
        ),
        actions: [
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 42, alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.white10,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white70,
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(petControllerProvider).archivePet(pet.petID);
                },
                child: Container(
                  height: 42, alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFFCF6679),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Text('Archive',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}