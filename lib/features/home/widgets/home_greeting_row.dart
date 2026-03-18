import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

class HomeGreetingRow extends ConsumerWidget {
  const HomeGreetingRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final userName = user?.username ?? 'User';

    return Row(
      children: [
        Text(
          'Hi there $userName,',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A5568),
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFF7B2B2B)),
          onPressed: () => ref.read(authProvider.notifier).signOut(),
        ),
      ],
    );
  }
}