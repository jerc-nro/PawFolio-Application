import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/account_controller.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final String? b64 = authState.localBase64 ?? user?.profileBase64;

    ImageProvider? profileImage;

    if (b64 != null && b64.isNotEmpty) {
      try {
        profileImage = MemoryImage(base64Decode(b64));
      } catch (_) {}
    } else if (user?.photoUrl != null &&
        user!.photoUrl!.isNotEmpty &&
        !user.photoUrl!.contains('profile/picture/0')) {
      // ✅ NetworkImage works for Google photos — add size param for better resolution
      final url = user.photoUrl!.contains('=s')
          ? user.photoUrl!.replaceAll(RegExp(r'=s\d+'), '=s200')
          : '${user.photoUrl}=s200';
      profileImage = NetworkImage(url);
    }

    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: CircleAvatar(
              radius: 52,
              backgroundColor: Colors.white10,
              foregroundImage: profileImage,
              onForegroundImageError: profileImage != null
                  ? (_, _) => debugPrint('Image load failed')
                  : null,
              child: const Icon(Icons.person_rounded, size: 52, color: Colors.white60),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => ref.read(accountControllerProvider.notifier).updateImage(),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF425C7D),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}