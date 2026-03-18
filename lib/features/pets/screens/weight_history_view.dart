import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../../records/providers/record_provider.dart';
import '../../records/widgets/add_weight_dialog.dart';
import '../widgets/edit_weight_dialog.dart';
import '../../../models/pet_model.dart';
// Archive page + config — adjust import path to match your project structure
import '../../records/screen/archived_records_page.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

DateTime _parseDateForSort(QueryDocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  if (data['recordedDate'] is Timestamp) {
    return (data['recordedDate'] as Timestamp).toDate();
  }
  final s = data['date_string'] as String? ?? '';
  final parts = s.split('.');
  if (parts.length == 3) {
    return DateTime(
      int.tryParse(parts[2]) ?? 0,
      int.tryParse(parts[1]) ?? 0,
      int.tryParse(parts[0]) ?? 0,
    );
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

bool _isToday(QueryDocumentSnapshot doc) {
  final date = _parseDateForSort(doc);
  final now  = DateTime.now();
  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}


// ─── Trend Helper ────────────────────────────────────────────────────────────

class _TrendInfo {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _TrendInfo({required this.label, required this.icon, required this.color, required this.bgColor});
}

_TrendInfo _getTrend(double current, double? previous) {
  if (previous == null) {
    return const _TrendInfo(
      label: 'First entry',
      icon: Icons.fiber_new_outlined,
      color: Color(0xFF607D8B),
      bgColor: Color(0xFFECEFF1),
    );
  }
  final diff = current - previous;
  if (diff.abs() < 0.05) {
    return const _TrendInfo(
      label: 'No change',
      icon: Icons.remove,
      color: Color(0xFF607D8B),
      bgColor: Color(0xFFECEFF1),
    );
  } else if (diff > 0) {
    final label = '+${diff.toStringAsFixed(1)} kg';
    return _TrendInfo(
      label: label,
      icon: Icons.trending_up,
      color: const Color(0xFFC0392B),
      bgColor: const Color(0xFFFDEDEB),
    );
  } else {
    final label = '${diff.toStringAsFixed(1)} kg';
    return _TrendInfo(
      label: label,
      icon: Icons.trending_down,
      color: const Color(0xFF27AE60),
      bgColor: const Color(0xFFE9F7EF),
    );
  }
}

// ─── Main Widget ──────────────────────────────────────────────────────────────

class WeightHistoryView extends ConsumerWidget {
  final Pet pet;
  const WeightHistoryView({super.key, required this.pet});

  static const _slate       = Color(0xFF455A64);
  static const _beige       = Color(0xFFD7CCC8);
  static const _listBg      = Color(0xFFF5F0EE);
  static const _todayAccent = Color(0xFF37474F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authProvider).user?.userID;

    return Scaffold(
      backgroundColor: _beige,
      body: Column(
        children: [
          _header(context, ref, uid),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _listBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: _buildStream(context, ref, uid),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stream ────────────────────────────────────────────────────────────────

  Widget _buildStream(BuildContext ctx, WidgetRef ref, String? uid) {
    if (uid == null) return const Center(child: Text('Login Required'));

    // Fetch all entries ordered by date — filter archived client-side.
    // This supports legacy documents that predate the is_archived field
    // (Firestore only matches .where('is_archived', isEqualTo: false) when
    // the field actually exists with that value).
    final stream = FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('pets').doc(pet.petID)
        .collection('weight_history')
        .orderBy('recordedDate', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData) return _emptyState(ctx);

        // Exclude archived entries client-side.
        // Docs without the field (legacy) are treated as active.
        final docs = snap.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['is_archived'] != true;
        }).toList();

        if (docs.isEmpty) return _emptyState(ctx);

        // Determine the single "current" entry.
        // Primary:    highest recordedDate (calendar date the user selected).
        // Tiebreaker: highest createdAt timestamp (server write time), so when
        //             two entries share the same date the latest-added wins.
        //             Falls back to doc.id comparison for legacy docs without createdAt.
        QueryDocumentSnapshot? currentDoc;
        DateTime? maxDate;
        DateTime? maxCreatedAt;

        DateTime _getCreatedAt(QueryDocumentSnapshot d) {
          final raw = (d.data() as Map<String, dynamic>)['createdAt'];
          if (raw is Timestamp) return raw.toDate();
          return DateTime.fromMillisecondsSinceEpoch(0);
        }

        for (final doc in docs) {
          final date      = _parseDateForSort(doc);
          final createdAt = _getCreatedAt(doc);

          if (currentDoc == null) {
            currentDoc  = doc;
            maxDate     = date;
            maxCreatedAt = createdAt;
            continue;
          }

          final isLater      = date.isAfter(maxDate!);
          final isSameDate   = date.isAtSameMomentAs(maxDate);
          final isNewerWrite = isSameDate && createdAt.isAfter(maxCreatedAt!);
          final isNewerDocId = isSameDate &&
              createdAt.isAtSameMomentAs(maxCreatedAt!) &&
              doc.id.compareTo(currentDoc.id) > 0;

          if (isLater || isNewerWrite || isNewerDocId) {
            currentDoc   = doc;
            maxDate      = date;
            maxCreatedAt = createdAt;
          }
        }
        final currentDocId = currentDoc?.id;

        // Sort: current entry always first, rest descending by recordedDate + createdAt
        final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
        sortedDocs.sort((a, b) {
          if (a.id == currentDocId) return -1;
          if (b.id == currentDocId) return 1;
          final dateA = _parseDateForSort(a);
          final dateB = _parseDateForSort(b);
          final dateCmp = dateB.compareTo(dateA);
          if (dateCmp != 0) return dateCmp;
          // Same date: sort by createdAt descending
          final caA = (a.data() as Map)['createdAt'];
          final caB = (b.data() as Map)['createdAt'];
          final tsA = caA is Timestamp ? caA.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
          final tsB = caB is Timestamp ? caB.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
          return tsB.compareTo(tsA);
        });

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            if (sortedDocs.length >= 2) ...[
              _buildChart(sortedDocs),
              const SizedBox(height: 24),
            ],
            _actionRow(ctx),
            const SizedBox(height: 16),
            ...sortedDocs.asMap().entries.map((e) {
              final index = e.key;
              final doc   = e.value;
              // Previous entry in the sorted list (lower = older in display order)
              // For the current entry (index 0), compare against index 1
              // For others, compare against the entry above them
              double? prevWeight;
              if (sortedDocs.length > 1) {
                final prevIndex = index + 1 < sortedDocs.length ? index + 1 : null;
                if (prevIndex != null) {
                  final prevData = sortedDocs[prevIndex].data() as Map<String, dynamic>;
                  prevWeight = (prevData['weight'] as num?)?.toDouble();
                }
              }
              return _entryCard(
                ctx, ref, doc,
                uid: uid,
                isCurrent: doc.id == currentDocId,
                prevWeight: prevWeight,
              );
            }),
          ],
        );
      },
    );
  }

  // ── Entry Card ────────────────────────────────────────────────────────────

  Widget _entryCard(BuildContext ctx, WidgetRef ref, QueryDocumentSnapshot doc,
      {required String uid, required bool isCurrent, double? prevWeight}) {
    final data       = doc.data() as Map<String, dynamic>;
    final weight     = (data['weight'] as num?)?.toDouble() ?? 0.0;
    final dateString = data['date_string'] ?? '';
    final unit       = data['unit'] ?? 'kg';
    final isToday    = _isToday(doc);

    // Trend vs previous entry
    final _TrendInfo trend = _getTrend(weight, prevWeight);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrent
            ? Border.all(color: _todayAccent, width: 2)
            : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isCurrent ? _slate : _slate.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.monitor_weight_outlined,
                color: isCurrent ? Colors.white : _slate,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            // Weight + date + trend
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isCurrent)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _todayAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isToday ? 'CURRENT · TODAY' : 'CURRENT',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  Text(
                    '$weight $unit',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? _todayAccent : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        dateString,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                      if (prevWeight != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: trend.bgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(trend.icon, size: 10, color: trend.color),
                              const SizedBox(width: 3),
                              Text(
                                trend.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: trend.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // CURRENT → fully locked (no edit, no archive, no delete)
            // PAST    → archive button only (no delete)
            if (isCurrent)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.lock_outline,
                    color: Colors.grey.shade400, size: 20),
              )
            else
              IconButton(
                tooltip: 'Archive',
                icon: Icon(Icons.inventory_2_outlined,
                    color: _slate.withOpacity(0.6), size: 20),
                onPressed: () => _confirmArchive(ctx, ref, doc),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmArchive(BuildContext ctx, WidgetRef ref,
      QueryDocumentSnapshot doc) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Archive Entry?'),
        content: const Text(
            'This entry will be moved to the archive. You can restore or permanently delete it from there.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Archive',
                style: TextStyle(color: Colors.blueGrey)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(recordControllerProvider.notifier)
          .archiveWeightRecord(petId: pet.petID, recordId: doc.id);
    }
  }

  // ── Chart ─────────────────────────────────────────────────────────────────

  Widget _buildChart(List<QueryDocumentSnapshot> docs) {
    final docsAsc = List<QueryDocumentSnapshot>.from(docs)
      ..sort((a, b) =>
          _parseDateForSort(a).compareTo(_parseDateForSort(b)));

    final spots       = <FlSpot>[];
    final dateLabels  = <int, String>{};

    for (int i = 0; i < docsAsc.length; i++) {
      final data   = docsAsc[i].data() as Map<String, dynamic>;
      final weight = (data['weight'] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), weight));
      dateLabels[i] =
          DateFormat('MMM d').format(_parseDateForSort(docsAsc[i]));
    }

    final weights   = spots.map((s) => s.y).toList();
    final minY      =
        (weights.reduce((a, b) => a < b ? a : b) - 1).clamp(0.0, double.infinity);
    final maxY      = weights.reduce((a, b) => a > b ? a : b) + 1;
    final showEvery = (spots.length / 4).ceil().clamp(1, spots.length);

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 3,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.withOpacity(0.12),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (val, _) => Text(
                  val.toStringAsFixed(1),
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade500),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: showEvery.toDouble(),
                getTitlesWidget: (val, _) {
                  final idx = val.toInt();
                  if (!dateLabels.containsKey(idx)) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      dateLabels[idx]!,
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: _slate,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, idx) {
                  final isLatest = idx == spots.length - 1;
                  return FlDotCirclePainter(
                    radius: isLatest ? 6 : 4,
                    color: isLatest ? _todayAccent : _slate,
                    strokeWidth: isLatest ? 2 : 1,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _slate.withOpacity(0.18),
                    _slate.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Static helpers ────────────────────────────────────────────────────────

  Widget _emptyState(BuildContext ctx) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monitor_weight_outlined,
              size: 64, color: _slate.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No weight records yet',
            style: TextStyle(
                fontSize: 16,
                color: _slate.withOpacity(0.5),
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => showAddWeightDialog(ctx, pet.petID),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('LOG FIRST WEIGHT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _slate,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext ctx, WidgetRef ref, String? uid) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(ctx),
              ),
              const Expanded(
                child: Text(
                  'WEIGHT HISTORY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _slate,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              // Archive shortcut — navigate directly to weight archive page
              IconButton(
                tooltip: 'View archived',
                icon: Icon(Icons.inventory_2_outlined,
                    size: 20, color: _slate.withOpacity(0.7)),
                onPressed: uid == null
                    ? null
                    : () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => ArchivedRecordsPage(
                              pet: pet,
                              uid: uid,
                              config: weightArchiveConfig,
                            ),
                          ),
                        ),
              ),
            ],
          ),
        ),
      );

  Widget _actionRow(BuildContext ctx) => Row(
        children: [
          Expanded(
            child: Text(
              'All Records',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _slate.withOpacity(0.8),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => showAddWeightDialog(ctx, pet.petID),
            icon: const Icon(Icons.add, size: 16),
            label: const Text(
              'LOG WEIGHT',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _slate,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
            ),
          ),
        ],
      );
}