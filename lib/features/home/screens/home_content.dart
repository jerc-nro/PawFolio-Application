import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/notification_services.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pets/providers/pet_provider.dart';
import '../providers/home_record_provider.dart';
import '../widgets/home_pet_card.dart';
import '../widgets/home_schedule_calendar.dart';
import '../widgets/home_record_tile.dart';
import '../../../../core/main_navigation_screen.dart';

class HomeContent extends ConsumerWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState  = ref.watch(authProvider);
    final user       = authState.user;
    final petsAsync  = ref.watch(activePetsProvider);
    final recAsync   = ref.watch(recentRecordsProvider(5));
    final totalPets  = petsAsync.valueOrNull?.length ?? 0;

    // Profile image
    final String? b64 = authState.localBase64 ?? user?.profileBase64;
    ImageProvider? profileImage;
    if (b64 != null && b64.isNotEmpty) {
      try { profileImage = MemoryImage(base64Decode(b64)); } catch (_) {}
    } else if (user?.photoUrl != null &&
        user!.photoUrl!.isNotEmpty &&
        !user.photoUrl!.contains('profile/picture/0')) {
      final url = user.photoUrl!.contains('=s')
          ? user.photoUrl!.replaceAll(RegExp(r'=s\d+'), '=s200')
          : '${user.photoUrl}=s200';
      profileImage = NetworkImage(url);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EE),
      body: SafeArea(
        child: CustomScrollView(slivers: [

          SliverToBoxAdapter(
            child: ElevatedButton(
              onPressed: () async {
                await NotificationService.showTestNotification();
              },
              child: const Text("Test Notification"),
            ),
          ),
          
          // ── Header ────────────────────────────────────────
          SliverToBoxAdapter(child: _HomeHeader(
            username: user?.username ?? 'User',
            totalPets: totalPets,
            profileImage: profileImage,
          )),

          // ── My Pets ───────────────────────────────────────
          SliverToBoxAdapter(child: _SectionHeader(
            title: 'MY PETS', actionLabel: 'See all',
            onTap: () => ref.read(navigationIndexProvider.notifier).setIndex(1),
          )),
          SliverToBoxAdapter(child: SizedBox(
            height: 210,
            child: petsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (e, _) => Center(child: Text('Error: $e')),
              data:    (pets) => pets.isEmpty
                  ? const Center(child: Text('No pets yet',
                      style: TextStyle(color: Color(0xFF9E9E9E))))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: pets.length,
                      itemBuilder: (_, i) => HomePetCard(pet: pets[i]),
                    ),
            ),
          )),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Calendar ──────────────────────────────────────
          SliverToBoxAdapter(child: _SectionHeader(
            title: 'CALENDAR', actionLabel: '', onTap: () {})),
          const SliverToBoxAdapter(child: HomeScheduleCalendar()),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Recent Records ────────────────────────────────
          SliverToBoxAdapter(child: _SectionHeader(
            title: 'RECENT RECORDS', actionLabel: 'See all',
            onTap: () => _showAllRecords(context, ref),
          )),
          recAsync.when(
            loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverToBoxAdapter(child: Text('Error: $e')),
            data: (records) => records.isEmpty
                ? const SliverToBoxAdapter(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No records yet',
                        style: TextStyle(color: Color(0xFF9E9E9E))))))
                : SliverList(delegate: SliverChildBuilderDelegate(
                    (_, i) => HomeRecordTile(record: records[i]),
                    childCount: records.length.clamp(0, 5),
                  )),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]),
      ),
    );
  }

  void _showAllRecords(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: const _AllRecordsSheet(),
      ),
    );
  }
}

// ── All Records Sheet ─────────────────────────────────────────────────────────
class _AllRecordsSheet extends ConsumerWidget {
  const _AllRecordsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recAsync = ref.watch(recentRecordsProvider(200));
    return DraggableScrollableSheet(
      initialChildSize: 0.75, minChildSize: 0.5, maxChildSize: 0.95,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F2EE),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // handle
          Padding(padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(width: 38, height: 4,
              decoration: BoxDecoration(color: Colors.black12,
                  borderRadius: BorderRadius.circular(2)))),
          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(children: [
                  Icon(Icons.history_rounded, color: Color(0xFF8B947E), size: 20),
                  SizedBox(width: 8),
                  Text('All Records', style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w800, color: Color(0xFF2D3A4A))),
                ]),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: Color(0xFF2D3A4A)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.black12),
          // list
          Expanded(child: recAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:   (e, _) => Center(child: Text('Error: $e')),
            data:    (records) => records.isEmpty
                ? const Center(child: Text('No records yet',
                    style: TextStyle(color: Color(0xFF9E9E9E))))
                : ListView.builder(
                    controller: sc,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: records.length,
                    itemBuilder: (_, i) => HomeRecordTile(record: records[i]),
                  ),
          )),
        ]),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title, actionLabel;
  final VoidCallback onTap;
  const _SectionHeader({required this.title, required this.actionLabel, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(width: 6, height: 6,
              decoration: const BoxDecoration(
                  color: Color(0xFF8B947E), shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontSize: 12,
              fontWeight: FontWeight.w700, color: Color(0xFF4A4A4A),
              letterSpacing: 0.8)),
        ]),
        if (actionLabel.isNotEmpty)
          GestureDetector(onTap: onTap,
            child: Text(actionLabel, style: const TextStyle(fontSize: 12,
                color: Color(0xFF8B947E), fontWeight: FontWeight.w600))),
      ],
    ),
  );
}

// ── Header ────────────────────────────────────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  final String username;
  final int totalPets;
  final ImageProvider? profileImage;
  const _HomeHeader({required this.username, required this.totalPets, this.profileImage});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 24, 22, 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFFDDD5CE),
          foregroundImage: profileImage,
          child: const Icon(Icons.person_rounded, size: 24, color: Color(0xFF8B947E)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hello, $username!', style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800,
                color: Color(0xFF2D3A4A), letterSpacing: -0.3)),
            const SizedBox(height: 2),
            Row(children: [
              Container(width: 6, height: 6,
                  decoration: const BoxDecoration(
                      color: Color(0xFF8B947E), shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text('$totalPets ${totalPets == 1 ? "pet" : "pets"} registered',
                  style: const TextStyle(fontSize: 12,
                      color: Color(0xFF9A8F88), fontWeight: FontWeight.w500)),
            ]),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFF2D3A4A),
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.pets, color: Color(0xFF8B947E), size: 13),
            const SizedBox(width: 5),
            Text('$totalPets', style: const TextStyle(fontSize: 15,
                fontWeight: FontWeight.w800, color: Colors.white)),
          ]),
        ),
      ],
    ),
  );
}