import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import 'profile_avatar.dart';

class ProfileCard extends ConsumerWidget {
  final VoidCallback onResendVerification;
  const ProfileCard({super.key, required this.onResendVerification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final bool isVerified = user?.emailVerified ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF8B947E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          const ProfileAvatar(),
          const SizedBox(height: 14),
          Text(user?.username ?? "User",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(user?.email ?? "",
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 6),
              Icon(
                isVerified ? Icons.verified_rounded : Icons.warning_amber_rounded,
                size: 15,
                color: isVerified ? Colors.lightBlueAccent : Colors.orangeAccent,
              ),
            ],
          ),
          if (!isVerified) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onResendVerification,
              child: const Text("Resend verification email",
                  style: TextStyle(
                      color: Colors.white60, fontSize: 11, decoration: TextDecoration.underline)),
            ),
          ],
        ],
      ),
    );
  }
}