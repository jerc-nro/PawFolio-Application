import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../../records/providers/record_provider.dart';
import '../../../features/records/widgets/add_weight_dialog.dart';
import '../../../models/pet_model.dart';

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

double _toDisplay(double kg, bool showLbs) =>
    showLbs ? kg * 2.20462 : kg;

// ─── Trend ────────────────────────────────────────────────────────────────────

class _TrendInfo {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _TrendInfo({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

_TrendInfo _getTrend(double current, double? previous, bool showLbs) {
  if (previous == null) {
    return const _TrendInfo(
        label: 'First entry',
        icon: Icons.fiber_new_outlined,
        color: Color(0xFF607D8B),
        bgColor: Color(0xFFECEFF1));
  }
  final diff     = current - previous;
  final dispDiff = showLbs ? diff * 2.20462 : diff;
  final unit     = showLbs ? 'lbs' : 'kg';
  if (diff.abs() < 0.05) {
    return const _TrendInfo(
        label: 'No change',
        icon: Icons.remove,
        color: Color(0xFF607D8B),
        bgColor: Color(0xFFECEFF1));
  } else if (diff > 0) {
    return _TrendInfo(
        label: '+${dispDiff.toStringAsFixed(1)} $unit',
        icon: Icons.trending_up,
        color: const Color(0xFFC0392B),
        bgColor: const Color(0xFFFDEDEB));
  } else {
    return _TrendInfo(
        label: '${dispDiff.toStringAsFixed(1)} $unit',
        icon: Icons.trending_down,
        color: const Color(0xFF27AE60),
        bgColor: const Color(0xFFE9F7EF));
  }
}

// ─── Chart Filter ─────────────────────────────────────────────────────────────

enum _ChartFilter { day, week, month, year }

extension _ChartFilterExt on _ChartFilter {
  String get label => switch (this) {
        _ChartFilter.day   => 'Day',
        _ChartFilter.week  => 'Week',
        _ChartFilter.month => 'Month',
        _ChartFilter.year  => 'Year',
      };

  DateTime get cutoff {
    final now = DateTime.now();
    return switch (this) {
      _ChartFilter.day   => DateTime(now.year, now.month, now.day),
      _ChartFilter.week  => now.subtract(const Duration(days: 7)),
      _ChartFilter.month => DateTime(now.year, now.month - 1, now.day),
      _ChartFilter.year  => DateTime(now.year - 1, now.month, now.day),
    };
  }

  String dateFormat(DateTime dt) => switch (this) {
        _ChartFilter.day   => DateFormat('h:mm a').format(dt),
        _ChartFilter.week  => DateFormat('EEE d').format(dt),
        _ChartFilter.month => DateFormat('MMM d').format(dt),
        _ChartFilter.year  => DateFormat('MMM yy').format(dt),
      };
}

// ─── Main Widget ──────────────────────────────────────────────────────────────

class WeightHistoryView extends ConsumerStatefulWidget {
  final Pet pet;
  const WeightHistoryView({super.key, required this.pet});

  @override
  ConsumerState<WeightHistoryView> createState() => _WeightHistoryViewState();
}

class _WeightHistoryViewState extends ConsumerState<WeightHistoryView> {
  _ChartFilter _filter  = _ChartFilter.month;
  bool         _showLbs = false;

  static const _slate       = Color(0xFF455A64);
  static const _beige       = Color(0xFFD7CCC8);
  static const _listBg      = Color(0xFFF5F0EE);
  static const _todayAccent = Color(0xFF37474F);

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authProvider).user?.userID;
    return Scaffold(
      backgroundColor: _beige,
      body: Column(children: [
        _header(context),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: _listBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: _buildStream(context, uid),
          ),
        ),
      ]),
    );
  }

  // ── Stream ────────────────────────────────────────────────────────────────

  Widget _buildStream(BuildContext ctx, String? uid) {
    if (uid == null) return const Center(child: Text('Login Required'));

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('pets')
        .doc(widget.pet.petID)
        .collection('weight_history')
        .orderBy('recordedDate', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (ctx, snap) {
        if (snap.hasError) {
          debugPrint('Weight error: ${snap.error}');
          return Center(child: Text('Error: ${snap.error}'));
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData) return _emptyState(ctx);

        final docs = snap.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['is_archived'] != true;
        }).toList();

        if (docs.isEmpty) return _emptyState(ctx);
        return _buildContent(ctx, docs);
      },
    );
  }

  Widget _buildContent(BuildContext ctx, List<QueryDocumentSnapshot> docs) {
    // ✅ Use is_current field from Firestore — do NOT compute by date
    String? currentDocId;
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['is_current'] == true) {
        currentDocId = doc.id;
        break;
      }
    }

    // Sort: current first, then descending by date
    final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
    sortedDocs.sort((a, b) {
      if (a.id == currentDocId) return -1;
      if (b.id == currentDocId) return 1;
      final dateA = _parseDateForSort(a);
      final dateB = _parseDateForSort(b);
      final dateCmp = dateB.compareTo(dateA);
      if (dateCmp != 0) return dateCmp;
      final caA = (a.data() as Map)['createdAt'];
      final caB = (b.data() as Map)['createdAt'];
      final tsA = caA is Timestamp
          ? caA.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0);
      final tsB = caB is Timestamp
          ? caB.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0);
      return tsB.compareTo(tsA);
    });

    // Chart docs filtered by period
    final cutoff = _filter.cutoff;
    final chartDocs = docs
        .where((doc) {
          final d = _parseDateForSort(doc);
          return d.isAfter(cutoff) || d.isAtSameMomentAs(cutoff);
        })
        .toList()
      ..sort((a, b) => _parseDateForSort(a).compareTo(_parseDateForSort(b)));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        _unitToggle(),
        const SizedBox(height: 16),
        if (sortedDocs.length >= 2) ...[
          _buildChartSection(chartDocs),
          const SizedBox(height: 24),
        ],
        _actionRow(ctx),
        const SizedBox(height: 16),
        ...sortedDocs.asMap().entries.map((e) {
          final index = e.key;
          final doc   = e.value;
          double? prevWeight;
          if (sortedDocs.length > 1) {
            final pi = index + 1 < sortedDocs.length ? index + 1 : null;
            if (pi != null) {
              final pd = sortedDocs[pi].data() as Map<String, dynamic>;
              prevWeight = (pd['weight'] as num?)?.toDouble();
            }
          }
          return _entryCard(ctx, doc,
              isCurrent: doc.id == currentDocId,
              prevWeight: prevWeight);
        }),
      ],
    );
  }

  // ── Unit toggle ───────────────────────────────────────────────────────────

  Widget _unitToggle() => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: 32,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFECEFF1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _unitBtn('KG',  !_showLbs),
                _unitBtn('LBS', _showLbs),
              ],
            ),
          ),
        ],
      );

  Widget _unitBtn(String label, bool selected) => GestureDetector(
        onTap: () => setState(() => _showLbs = label == 'LBS'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? _slate : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: selected
                ? [BoxShadow(
                    color: _slate.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1))]
                : [],
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.grey.shade500)),
        ),
      );

  // ── Chart Section ─────────────────────────────────────────────────────────

  Widget _buildChartSection(List<QueryDocumentSnapshot> chartDocs) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(children: [
                Text('Weight Trend',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _slate.withOpacity(0.8),
                        letterSpacing: 0.3)),
                const Spacer(),
                _FilterTabs(
                    selected: _filter,
                    onChanged: (f) => setState(() => _filter = f)),
              ]),
            ),
            const SizedBox(height: 12),
            if (chartDocs.length < 2)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Row(children: [
                  Icon(Icons.bar_chart_outlined,
                      size: 18, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text('Not enough data for this period.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade400)),
                ]),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 16, 16),
                child: SizedBox(height: 180, child: _buildChart(chartDocs)),
              ),
          ],
        ),
      );

  Widget _buildChart(List<QueryDocumentSnapshot> docsAsc) {
    final spots      = <FlSpot>[];
    final dateLabels = <int, String>{};

    for (int i = 0; i < docsAsc.length; i++) {
      final data    = docsAsc[i].data() as Map<String, dynamic>;
      final rawKg   = (data['weight'] as num?)?.toDouble() ?? 0.0;
      final display = _toDisplay(rawKg, _showLbs);
      spots.add(FlSpot(i.toDouble(), double.parse(display.toStringAsFixed(2))));
      dateLabels[i] = _filter.dateFormat(_parseDateForSort(docsAsc[i]));
    }

    final weights = spots.map((s) => s.y).toList();
    final minY = (weights.reduce((a, b) => a < b ? a : b) -
            (_showLbs ? 2.0 : 1.0))
        .clamp(0.0, double.infinity);
    final maxY =
        weights.reduce((a, b) => a > b ? a : b) + (_showLbs ? 2.0 : 1.0);
    final showEvery = (spots.length / 4).ceil().clamp(1, spots.length);

    return LineChart(LineChartData(
      minY: minY,
      maxY: maxY,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxY - minY) / 3,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: Colors.grey.withOpacity(0.12), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 46,
            getTitlesWidget: (val, _) => Text(
              '${val.toStringAsFixed(1)}${_showLbs ? 'lbs' : 'kg'}',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
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
              if (!dateLabels.containsKey(idx)) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(dateLabels[idx]!,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
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
              colors: [_slate.withOpacity(0.18), _slate.withOpacity(0.0)],
            ),
          ),
        ),
      ],
    ));
  }

  // ── Entry Card ────────────────────────────────────────────────────────────

  Widget _entryCard(BuildContext ctx, QueryDocumentSnapshot doc,
      {required bool isCurrent, double? prevWeight}) {
    final data        = doc.data() as Map<String, dynamic>;
    final rawKg       = (data['weight'] as num?)?.toDouble() ?? 0.0;
    final storedUnit  = data['unit'] as String? ?? 'kg';
    final displayVal  = _toDisplay(rawKg, _showLbs);
    final displayUnit = _showLbs ? 'lbs' : 'kg';
    final dateString  = data['date_string'] ?? '';
    final isToday     = _isToday(doc);
    final trend       = _getTrend(rawKg, prevWeight, _showLbs);

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
              offset: const Offset(0, 3))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: isCurrent ? _slate : _slate.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.monitor_weight_outlined,
                color: isCurrent ? Colors.white : _slate, size: 24),
          ),
          const SizedBox(width: 14),
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
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      isToday ? 'CURRENT · TODAY' : 'CURRENT',
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2),
                    ),
                  ),
                Text(
                  '${displayVal.toStringAsFixed(1)} $displayUnit',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? _todayAccent : Colors.black87),
                ),
                if (_showLbs && storedUnit.toLowerCase() == 'kg')
                  Text('${rawKg.toStringAsFixed(1)} kg stored',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade400)),
                const SizedBox(height: 4),
                Row(children: [
                  Text(dateString,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                  if (prevWeight != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: trend.bgColor,
                          borderRadius: BorderRadius.circular(6)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(trend.icon, size: 10, color: trend.color),
                        const SizedBox(width: 3),
                        Text(trend.label,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: trend.color)),
                      ]),
                    ),
                  ],
                ]),
              ],
            ),
          ),
          if (isCurrent)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.lock_outline,
                  color: Colors.grey.shade400, size: 20),
            )
          else
            IconButton(
              tooltip: 'Delete',
              icon: Icon(Icons.delete_outline,
                  color: Colors.red.shade300, size: 20),
              onPressed: () => _confirmDelete(ctx, doc),
            ),
        ]),
      ),
    );
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(
      BuildContext ctx, QueryDocumentSnapshot doc) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Entry?'),
        content: const Text(
            'This weight entry will be permanently deleted. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(recordControllerProvider.notifier)
          .deleteWeightRecord(petId: widget.pet.petID, recordId: doc.id);
    }
  }

  // ── Static helpers ────────────────────────────────────────────────────────

  Widget _emptyState(BuildContext ctx) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.monitor_weight_outlined,
                size: 64, color: _slate.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('No weight records yet',
                style: TextStyle(
                    fontSize: 16,
                    color: _slate.withOpacity(0.5),
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  showAddWeightDialog(ctx, widget.pet.petID, widget.pet.name),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('LOG FIRST WEIGHT'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _slate,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12)),
            ),
          ],
        ),
      );

  Widget _header(BuildContext ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const CircleAvatar(
                    backgroundColor: _slate,
                    radius: 18,
                    child: Icon(Icons.arrow_back,
                        color: Colors.white, size: 18)),
              ),
              const Expanded(
                child: Text('WEIGHT HISTORY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _slate,
                        letterSpacing: 1.5)),
              ),
              IconButton(
                onPressed: () =>
                    Navigator.of(ctx).popUntil((route) => route.isFirst),
                icon: const CircleAvatar(
                    backgroundColor: _slate,
                    radius: 18,
                    child: Icon(Icons.home_outlined,
                        color: Colors.white, size: 18)),
              ),
            ],
          ),
        ),
      );

  Widget _actionRow(BuildContext ctx) => Row(children: [
        Text('All Records',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _slate.withOpacity(0.8))),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () =>
              showAddWeightDialog(ctx, widget.pet.petID, widget.pet.name),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('LOG WEIGHT',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8)),
          style: ElevatedButton.styleFrom(
              backgroundColor: _slate,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10)),
        ),
      ]);
}

// ─── Filter Tabs ──────────────────────────────────────────────────────────────

class _FilterTabs extends StatelessWidget {
  final _ChartFilter selected;
  final ValueChanged<_ChartFilter> onChanged;
  const _FilterTabs({required this.selected, required this.onChanged});

  static const _slate = Color(0xFF455A64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: const Color(0xFFECEFF1),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _ChartFilter.values.map((f) {
          final isSelected = f == selected;
          return GestureDetector(
            onTap: () => onChanged(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isSelected ? _slate : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                boxShadow: isSelected
                    ? [BoxShadow(
                        color: _slate.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 1))]
                    : [],
              ),
              child: Text(f.label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : Colors.grey.shade500)),
            ),
          );
        }).toList(),
      ),
    );
  }
}