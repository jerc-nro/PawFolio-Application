import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/record_model.dart';
import '../providers/calendar_record_provider.dart';
import '../../../../core/main_navigation_screen.dart';

String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
const _days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
const _orange = Color(0xFFE8947E);
const _sage   = Color(0xFF8B947E);
const _red    = Color(0xFFCF6679);
const _medCol = Color(0xFFBA7F57);
const _dark   = Color(0xFF2D3A4A);

// Each calendar cell is exactly this wide (matches SizedBox width in the row)
const _cellW  = 34.0;
const _cellH  = 44.0;
// The span bar sits at this vertical offset inside the cell and is this tall
const _barTop  = 7.0;
const _barH    = 26.0;

// ── Status helpers (Firestore uses UPPER_CASE) ────────────────────────────────
bool _isOverdue(PetRecord r) => r.status == 'OVERDUE';
bool _isOngoing(PetRecord r) => r.status == 'ONGOING';

String _statusLabel(String s) => switch (s) {
  'COMPLETED' => 'Done',
  'ONGOING'   => 'Ongoing',
  'UPCOMING'  => 'Upcoming',
  'OVERDUE'   => 'Overdue',
  _           => s,
};
Color _statusBg(String s) => switch (s) {
  'COMPLETED' => const Color(0xFFE8F5E9),
  'ONGOING'   => const Color(0xFFFFF8E1),
  'UPCOMING'  => const Color(0xFFE3F2FD),
  'OVERDUE'   => const Color(0xFFFFEBEE),
  _           => const Color(0xFFF5F5F5),
};
Color _statusColor(String s) => switch (s) {
  'COMPLETED' => const Color(0xFF4CAF50),
  'ONGOING'   => const Color(0xFFFF9800),
  'UPCOMING'  => const Color(0xFF2196F3),
  'OVERDUE'   => const Color(0xFFE53935),
  _           => const Color(0xFF9E9E9E),
};

class HomeScheduleCalendar extends ConsumerStatefulWidget {
  const HomeScheduleCalendar({super.key});
  @override
  ConsumerState<HomeScheduleCalendar> createState() => _State();
}

class _State extends ConsumerState<HomeScheduleCalendar> {
  final _today = DateTime.now();
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime(_today.year, _today.month);
  }

  void _shift(int d) =>
      setState(() => _month = DateTime(_month.year, _month.month + d));
  void _setMonth(DateTime m) => setState(() => _month = m);

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MonthYearPicker(
        selected: _month,
        onPick: (m) { Navigator.pop(context); _setMonth(m); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(navigationIndexProvider, (_, idx) {
      if (idx == 0 && mounted) {
        final now = DateTime.now();
        setState(() => _month = DateTime(now.year, now.month));
      }
    });

    final byDate      = ref.watch(calendarRecordsProvider).valueOrNull ?? {};
    final firstWD     = DateTime(_month.year, _month.month, 1).weekday - 1;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final rows        = ((firstWD + daysInMonth) / 7).ceil();

    return GestureDetector(
      onHorizontalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) < -300) _shift(1);
        if ((d.primaryVelocity ?? 0) >  300) _shift(-1);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: _dark, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Nav ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavBtn(Icons.chevron_left, () => _shift(-1)),
                GestureDetector(
                  onTap: () => _showPicker(context),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(DateFormat('MMMM yyyy').format(_month),
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white54, size: 18),
                  ]),
                ),
                _NavBtn(Icons.chevron_right, () => _shift(1)),
              ],
            ),
            const SizedBox(height: 12),

            // ── Day labels ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _days.map((l) => SizedBox(
                width: _cellW,
                child: Text(l,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white38,
                        fontSize: 10, fontWeight: FontWeight.w600)),
              )).toList(),
            ),
            const SizedBox(height: 6),

            // ── Grid rows ─────────────────────────────────────
            // Each row is a LayoutBuilder → Stack so we can draw the
            // medication span bar as one continuous Positioned rectangle
            // with no gaps, then layer the day cells on top.
            for (int r = 0; r < rows; r++) ...[
              _CalendarRow(
                row: r,
                firstWD: firstWD,
                daysInMonth: daysInMonth,
                month: _month,
                today: _today,
                byDate: byDate,
              ),
              if (r < rows - 1) const SizedBox(height: 2),
            ],

            const SizedBox(height: 12),

            // ── Legend ───────────────────────────────────────
            Row(children: const [
              _Dot(_orange, 'Today'),      SizedBox(width: 12),
              _Dot(_sage,   'Events'),     SizedBox(width: 12),
              _Dot(_red,    'Overdue'),    SizedBox(width: 12),
              _Dot(_medCol, 'Medication'),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Calendar row ──────────────────────────────────────────────────────────────
// Draws the 7-cell row as a LayoutBuilder so we know the exact pixel width,
// then uses a Stack to place the medication bar as a single unbroken rect
// behind the day-number circles.
class _CalendarRow extends StatelessWidget {
  final int row, firstWD, daysInMonth;
  final DateTime month, today;
  final Map<String, List<PetRecord>> byDate;

  const _CalendarRow({
    required this.row,
    required this.firstWD,
    required this.daysInMonth,
    required this.month,
    required this.today,
    required this.byDate,
  });

  @override
  Widget build(BuildContext context) {
    // Build per-cell data for all 7 columns
    final cells = List.generate(7, (c) {
      final n = row * 7 + c - firstWD + 1;
      if (n < 1 || n > daysInMonth) return _CellData(col: c);

      final date    = DateTime(month.year, month.month, n);
      final records = byDate[_dateKey(date)] ?? [];
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final overdue  = records.any(_isOverdue);
      final hasMed   = records.any((r) => r.category == 'Medication');
      final hasOther = records.any((r) =>
          r.category != 'Medication' && !_isOverdue(r));
      final isActive = hasMed &&
          records.where((r) => r.category == 'Medication').any(_isOngoing);

      // Neighbour med check for cap logic
      bool neighbourMed(int offset) {
        final nd = date.add(Duration(days: offset));
        return (byDate[_dateKey(nd)] ?? [])
            .any((r) => r.category == 'Medication');
      }

      return _CellData(
        col: c, day: n, isToday: isToday,
        hasEvent: hasOther, hasOverdue: overdue,
        hasMed: hasMed, isActive: isActive,
        hasPrevMed: neighbourMed(-1),
        hasNextMed: neighbourMed(1),
        records: records,
      );
    });

    // Compute medication span segments for this row.
    // A segment is a continuous run of columns that all have hasMed == true.
    // We draw each segment as one Positioned rect.
    final segments = <_Segment>[];
    int? segStart;
    for (int c = 0; c < 7; c++) {
      if (cells[c].hasMed) {
        segStart ??= c;
        if (c == 6 || !cells[c + 1].hasMed) {
          segments.add(_Segment(
            startCol: segStart!,
            endCol: c,
            // Round left cap if the first cell in this segment has no prev med
            // (i.e. it's the true start of the medication, not just a week wrap)
            capLeft:  !cells[segStart!].hasPrevMed,
            capRight: !cells[c].hasNextMed,
            isActive: cells.sublist(segStart!, c + 1).any((cd) => cd.isActive),
          ));
          segStart = null;
        }
      }
    }

    return LayoutBuilder(builder: (context, constraints) {
      // Total row width available; we'll divide it equally into 7 slots.
      final rowW  = constraints.maxWidth;
      final slotW = rowW / 7;

      return SizedBox(
        width: rowW,
        height: _cellH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Medication span bars (drawn first, behind cells) ──
            for (final seg in segments)
              Positioned(
                top: _barTop,
                height: _barH,
                left:  slotW * seg.startCol + (seg.capLeft  ? 6 : 0),
                right: rowW - slotW * (seg.endCol + 1) + (seg.capRight ? 6 : 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: seg.isActive
                        ? _medCol.withOpacity(0.30)
                        : _medCol.withOpacity(0.18),
                    border: seg.isActive
                        ? Border.all(color: _medCol.withOpacity(0.50), width: 0.8)
                        : null,
                    borderRadius: BorderRadius.horizontal(
                      left:  seg.capLeft  ? const Radius.circular(13) : Radius.zero,
                      right: seg.capRight ? const Radius.circular(13) : Radius.zero,
                    ),
                  ),
                ),
              ),

            // ── Day cells (drawn on top of the bar) ──────────────
            Row(
              children: cells.map((cd) {
                if (cd.day == null) {
                  return const SizedBox(width: _cellW, height: _cellH);
                }
                return Expanded(
                  child: _DayCell(
                    day: cd.day!,
                    isToday: cd.isToday,
                    hasEvent: cd.hasEvent,
                    hasOverdue: cd.hasOverdue,
                    records: cd.records,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }
}

class _CellData {
  final int col;
  final int? day;
  final bool isToday, hasEvent, hasOverdue, hasMed, isActive,
      hasPrevMed, hasNextMed;
  final List<PetRecord> records;

  const _CellData({
    required this.col,
    this.day,
    this.isToday = false,
    this.hasEvent = false,
    this.hasOverdue = false,
    this.hasMed = false,
    this.isActive = false,
    this.hasPrevMed = false,
    this.hasNextMed = false,
    this.records = const [],
  });
}

class _Segment {
  final int startCol, endCol;
  final bool capLeft, capRight, isActive;
  const _Segment({
    required this.startCol,
    required this.endCol,
    required this.capLeft,
    required this.capRight,
    required this.isActive,
  });
}

// ── Month/Year picker ─────────────────────────────────────────────────────────
class _MonthYearPicker extends StatefulWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onPick;
  const _MonthYearPicker({required this.selected, required this.onPick});
  @override
  State<_MonthYearPicker> createState() => _PickerState();
}

class _PickerState extends State<_MonthYearPicker> {
  late int _year, _pickedMonth;
  final int _baseYear = DateTime.now().year - 5;
  final int _endYear  = DateTime.now().year + 5;

  @override
  void initState() {
    super.initState();
    _year        = widget.selected.year;
    _pickedMonth = widget.selected.month;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E2D3A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 38, height: 4,
          decoration: BoxDecoration(color: Colors.white24,
              borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _NavBtn(Icons.chevron_left, () {
            if (_year > _baseYear) setState(() => _year--);
          }),
          const SizedBox(width: 20),
          Text('$_year', style: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(width: 20),
          _NavBtn(Icons.chevron_right, () {
            if (_year < _endYear) setState(() => _year++);
          }),
        ]),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 4, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.2,
          children: List.generate(12, (i) {
            final isSelected =
                i + 1 == _pickedMonth && _year == widget.selected.year;
            final isToday =
                i + 1 == DateTime.now().month && _year == DateTime.now().year;
            return GestureDetector(
              onTap: () => widget.onPick(DateTime(_year, i + 1)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? _orange
                      : isToday ? _sage.withOpacity(0.3)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                  border: isToday && !isSelected
                      ? Border.all(color: _sage, width: 1) : null,
                ),
                child: Text(_months[i], style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.white70,
                )),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => widget.onPick(
              DateTime(DateTime.now().year, DateTime.now().month)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.white10,
                borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: const Text('Go to Today',
                style: TextStyle(color: Colors.white70,
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ),
      ]),
    );
  }
}

// ── Day cell ──────────────────────────────────────────────────────────────────
// No longer draws its own span bar — that's handled by _CalendarRow.
class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday, hasEvent, hasOverdue;
  final List<PetRecord> records;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.hasEvent,
    required this.hasOverdue,
    required this.records,
  });

  Color get _circleBg => isToday
      ? _orange
      : hasOverdue
          ? _red.withOpacity(0.25)
          : hasEvent
              ? _sage.withOpacity(0.25)
              : Colors.transparent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: records.isEmpty
          ? null
          : () => showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (_) => _Overlay(records: records)),
      child: SizedBox(
        height: _cellH,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28, height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _circleBg,
                shape: BoxShape.circle,
                border: hasOverdue && !isToday
                    ? Border.all(color: _red, width: 1.5)
                    : null,
              ),
              child: Text('$day', style: TextStyle(
                fontSize: 11,
                color: isToday || records.isNotEmpty
                    ? Colors.white : Colors.white54,
                fontWeight: isToday || records.isNotEmpty
                    ? FontWeight.w700 : FontWeight.w400,
              )),
            ),
            const SizedBox(height: 2),
            if (hasEvent || hasOverdue)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasOverdue) _dot(_red),
                  if (hasOverdue && hasEvent) const SizedBox(width: 2),
                  if (hasEvent)   _dot(_sage),
                ],
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color c) => Container(
    width: 4, height: 4,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

// ── Record overlay ────────────────────────────────────────────────────────────
class _Overlay extends StatelessWidget {
  final List<PetRecord> records;
  const _Overlay({required this.records});

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.45, minChildSize: 0.3, maxChildSize: 0.85,
    builder: (_, sc) => Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F2EE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        Padding(padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Container(width: 38, height: 4,
            decoration: BoxDecoration(color: Colors.black12,
                borderRadius: BorderRadius.circular(2)))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Row(children: [
            const Icon(Icons.event_note_rounded, color: _sage, size: 20),
            const SizedBox(width: 8),
            Text(
              '${records.length} record${records.length > 1 ? "s" : ""} on this day',
              style: const TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w700, color: _dark)),
          ]),
        ),
        const Divider(height: 1, color: Colors.black12),
        Expanded(child: ListView.separated(
          controller: sc, padding: const EdgeInsets.all(16),
          itemCount: records.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _Tile(records[i]),
        )),
      ]),
    ),
  );
}

// ── Record tile ───────────────────────────────────────────────────────────────
class _Tile extends StatelessWidget {
  final PetRecord r;
  const _Tile(this.r);

  static const _icons = <String, IconData>{
    'Vaccination':  Icons.verified_outlined,
    'Medication':   Icons.science_outlined,
    'Vet Visit':    Icons.local_hospital_outlined,
    'Grooming':     Icons.content_cut_outlined,
    'Preventative': Icons.shield_outlined,
  };
  static const _ibg = <String, Color>{
    'Vaccination':  Color(0xFFE8F5E9), 'Medication': Color(0xFFFFF3E0),
    'Vet Visit':    Color(0xFFE3F2FD), 'Grooming':   Color(0xFFF3E5F5),
    'Preventative': Color(0xFFE8EAF6),
  };
  static const _icol = <String, Color>{
    'Vaccination':  Color(0xFF4CAF50), 'Medication': Color(0xFFFF9800),
    'Vet Visit':    Color(0xFF2196F3), 'Grooming':   Color(0xFF9C27B0),
    'Preventative': Color(0xFF3F51B5),
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))]),
    child: Row(children: [
      Container(width: 40, height: 40,
        decoration: BoxDecoration(
            color: _ibg[r.category] ?? const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(_icons[r.category] ?? Icons.medical_services_outlined,
            color: _icol[r.category] ?? _sage, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r.title, style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14, color: _dark)),
          const SizedBox(height: 2),
          Text('${r.petName} · ${r.category}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
        ],
      )),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: _statusBg(r.status),
            borderRadius: BorderRadius.circular(20)),
        child: Text(_statusLabel(r.status), style: TextStyle(fontSize: 11,
            fontWeight: FontWeight.w600, color: _statusColor(r.status))),
      ),
    ]),
  );
}

// ── Micro widgets ─────────────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _NavBtn(this.icon, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Colors.white12,
          borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: Colors.white70, size: 18)),
  );
}

class _Dot extends StatelessWidget {
  final Color color; final String label;
  const _Dot(this.color, this.label);
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 7, height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
  ]);
}