import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../../records/providers/record_provider.dart';
import '../../records/widgets/add_weight_dialog.dart';
import '../../../models/pet_model.dart';

class WeightHistoryView extends ConsumerWidget {
  final Pet pet;
  const WeightHistoryView({super.key, required this.pet});

  static const _navBlue = Color(0xFF455A64);
  static const _beige   = Color(0xFFD7CCC8);
  static const _listBg  = Color(0xFFEFEBE9);
  static const _green   = Color(0xFF388E3C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authProvider).user?.userID;
    final sw  = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _beige,
      body: Column(children: [
        SafeArea(child: Column(children: [
          const SizedBox(height: 10),
          _header(context),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: sw * 0.06, vertical: 15),
            child: _petCard(),
          ),
        ])),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: _listBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                const SizedBox(height: 20),
                _actionRow(context),
                const SizedBox(height: 16),
                Expanded(child: _buildStream(context, ref, uid)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Delete (smart restore) ────────────────────────────────
  Future<void> _delete(BuildContext ctx, WidgetRef ref, String id) async {
    if (pet.isArchived) return;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Entry',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'Remove this weight entry?\n\nThe pet\'s current weight will be restored to the previous log, or back to the original registration weight if no logs remain.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL',
                  style: TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('DELETE',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    ) ?? false;
    if (!ok) return;

    // Use smart delete that restores pet weight
    await ref.read(recordControllerProvider.notifier).deleteWeightRecord(
        petId: pet.petID, recordId: id);

    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Entry removed. Pet weight restored.')));
    }
  }

  // ── Edit with confirmation ────────────────────────────────
  Future<void> _edit(BuildContext ctx, WidgetRef ref, String docId,
      Map<String, dynamic> current) async {
    if (pet.isArchived) return;

    final weightCtrl = TextEditingController(
        text: (current['weight'] as num?)?.toDouble().toString() ?? '');
    final dateCtrl = TextEditingController(
        text: current['date_string'] ?? '');
    final notesCtrl = TextEditingController(
        text: current['notes'] ?? '');
    String unit = current['unit'] ?? 'kg';
    bool weightErr = false;
    bool dateErr   = false;

    await showDialog(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          const textBlue   = Color(0xFF455A64);
          const borderBlue = Color(0xFF0277BD);

          InputDecoration deco({String? hint, bool err = false, Widget? suffix}) {
            final bc = err ? Colors.red : borderBlue;
            return InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
              suffixIcon: suffix,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: bc, width: 1.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: bc, width: 2)),
            );
          }

          Widget label(String t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(t,
                  style: const TextStyle(
                      color: textBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)));

          Widget unitPill(String u) {
            final sel = unit == u;
            return GestureDetector(
              onTap: () => setDialogState(() => unit = u),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? borderBlue : Colors.transparent,
                  border: Border.all(color: borderBlue, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(u,
                    style: TextStyle(
                        color: sel ? Colors.white : borderBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            );
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(dialogCtx).size.width * 0.88,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EDE5),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.edit_outlined,
                            color: textBlue, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Edit Weight',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: textBlue)),
                          Text('Modify this entry',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Weight + unit
                    label('Weight'),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                      Expanded(
                        child: TextField(
                          controller: weightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) =>
                              setDialogState(() => weightErr = false),
                          decoration: deco(
                              hint: 'e.g. 4.5', err: weightErr),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        unitPill('kg'),
                        const SizedBox(width: 6),
                        unitPill('lbs'),
                      ]),
                    ]),
                    if (weightErr)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('Enter a valid weight',
                            style:
                                TextStyle(color: Colors.red, fontSize: 11)),
                      ),
                    const SizedBox(height: 14),

                    // Date
                    label('Date Recorded'),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogCtx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            dateCtrl.text =
                                DateFormat('dd.MM.yyyy').format(picked);
                            dateErr = false;
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: dateCtrl,
                          decoration: deco(
                            hint: 'DD.MM.YYYY',
                            err: dateErr,
                            suffix: Icon(Icons.calendar_month,
                                color: dateErr
                                    ? Colors.red
                                    : Colors.black54,
                                size: 20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Notes
                    label('Notes (optional)'),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: deco(
                          hint: 'e.g. After meal, before bath…'),
                    ),
                    const SizedBox(height: 24),

                    // Buttons row
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textBlue,
                            side: const BorderSide(color: textBlue),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('CANCEL',
                              style:
                                  TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final w = double.tryParse(
                                weightCtrl.text.trim());
                            setDialogState(() {
                              weightErr = w == null || w <= 0;
                              dateErr =
                                  dateCtrl.text.trim().isEmpty;
                            });
                            if (weightErr || dateErr) return;

                            // Confirmation before saving
                            final confirm =
                                await showDialog<bool>(
                              context: dialogCtx,
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(20)),
                                title: const Text('Save Changes',
                                    style: TextStyle(
                                        fontWeight:
                                            FontWeight.bold)),
                                content: const Text(
                                    'Are you sure you want to update this weight entry? The pet\'s current weight may also be updated if this is the latest entry.'),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator
                                          .pop(dialogCtx, false),
                                      child: const Text('CANCEL',
                                          style: TextStyle(
                                              color: Colors.grey))),
                                  TextButton(
                                      onPressed: () => Navigator
                                          .pop(dialogCtx, true),
                                      child: const Text('CONFIRM',
                                          style: TextStyle(
                                              color: borderBlue,
                                              fontWeight:
                                                  FontWeight.bold))),
                                ],
                              ),
                            ) ?? false;

                            if (!confirm) return;

                            Navigator.pop(dialogCtx);
                            await ref
                                .read(recordControllerProvider
                                    .notifier)
                                .editWeightRecord(
                                  petId:      pet.petID,
                                  recordId:   docId,
                                  weight:     w!,
                                  unit:       unit,
                                  dateString: dateCtrl.text.trim(),
                                  notes:      notesCtrl.text.trim(),
                                );

                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Weight entry updated!')));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: borderBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                          ),
                          child: const Text('SAVE',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    weightCtrl.dispose();
    dateCtrl.dispose();
    notesCtrl.dispose();
  }

  // ── Stream ────────────────────────────────────────────────
  Widget _buildStream(BuildContext ctx, WidgetRef ref, String? uid) {
    if (uid == null) return const Center(child: Text('Please log in.'));

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('pets')
        .doc(pet.petID)
        .collection('weight_history')
        .orderBy('recordedDate', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting &&
            !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _empty();

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            if (docs.length >= 2) ...[
              _trendBanner(docs),
              const SizedBox(height: 14),
            ],
            ...docs.asMap().entries.map((e) {
              final idx  = e.key;
              final doc  = e.value;
              final data = doc.data() as Map<String, dynamic>;

              double? delta;
              if (idx < docs.length - 1) {
                final prev  = docs[idx + 1].data() as Map<String, dynamic>;
                final currW = (data['weight'] as num?)?.toDouble();
                final prevW = (prev['weight'] as num?)?.toDouble();
                final currU = data['unit'] ?? 'kg';
                final prevU = prev['unit'] ?? 'kg';
                if (currW != null && prevW != null && currU == prevU) {
                  delta = currW - prevW;
                }
              }

              return _entry(
                ctx:       ctx,
                ref:       ref,
                docId:     doc.id,
                data:      data,
                weight:    (data['weight'] as num?)?.toDouble() ?? 0,
                unit:      data['unit'] ?? 'kg',
                date:      data['date_string'] ?? '',
                notes:     data['notes'] ?? '',
                delta:     delta,
                isLatest:  idx == 0,
                totalDocs: docs.length,
              );
            }),
          ],
        );
      },
    );
  }

  // ── Trend banner ──────────────────────────────────────────
  Widget _trendBanner(List<QueryDocumentSnapshot> docs) {
    final latest    = docs[0].data() as Map<String, dynamic>;
    final prev      = docs[1].data() as Map<String, dynamic>;
    final lw        = (latest['weight'] as num?)?.toDouble() ?? 0;
    final pw        = (prev['weight']   as num?)?.toDouble() ?? 0;
    final unit      = latest['unit'] ?? 'kg';
    final prevUnit  = prev['unit']   ?? 'kg';
    if (unit != prevUnit) return const SizedBox.shrink();

    final diff   = lw - pw;
    final stable = diff.abs() < 0.05;
    final Color color;
    final IconData icon;
    final String msg;

    if (stable) {
      color = Colors.blueGrey; icon = Icons.horizontal_rule;
      msg   = 'Weight is stable';
    } else if (diff > 0) {
      color = Colors.orange; icon = Icons.trending_up;
      msg   = 'Gained ${diff.abs().toStringAsFixed(2)} $unit since last entry';
    } else {
      color = _green; icon = Icons.trending_down;
      msg   = 'Lost ${diff.abs().toStringAsFixed(2)} $unit since last entry';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13))),
      ]),
    );
  }

  // ── Entry card ────────────────────────────────────────────
  Widget _entry({
    required BuildContext ctx,
    required WidgetRef ref,
    required String docId,
    required Map<String, dynamic> data,
    required double weight,
    required String unit,
    required String date,
    required String notes,
    double? delta,
    required bool isLatest,
    required int totalDocs,
  }) {
    // Cannot delete the only remaining entry — must add a new one first
    final canDelete = !(isLatest && totalDocs == 1);
    Color? dc; String dt = '';
    if (delta != null) {
      if (delta.abs() < 0.05) { dc = Colors.blueGrey; dt = 'No change'; }
      else if (delta > 0)     { dc = Colors.orange;   dt = '+${delta.toStringAsFixed(2)} $unit'; }
      else                    { dc = _green;           dt = '${delta.toStringAsFixed(2)} $unit'; }
    }

    return GestureDetector(
      onLongPress: (pet.isArchived || !canDelete) ? null : () => _delete(ctx, ref, docId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isLatest
              ? Border.all(color: _navBlue.withOpacity(0.4), width: 1.5)
              : null,
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          // Weight bubble
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
                color: _navBlue.withOpacity(0.08),
                shape: BoxShape.circle),
            child: Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(weight.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 17,
                        fontWeight: FontWeight.bold, color: _navBlue)),
                Text(unit, style: const TextStyle(fontSize: 10,
                    color: Colors.blueGrey, fontWeight: FontWeight.w600)),
              ],
            )),
          ),
          const SizedBox(width: 14),

          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(date, style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14,
                    color: Color(0xFF263238))),
                if (isLatest) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: _navBlue,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text('LATEST', style: TextStyle(
                        color: Colors.white, fontSize: 9,
                        fontWeight: FontWeight.bold)),
                  ),
                ],
              ]),
              if (dt.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(dt, style: TextStyle(
                    color: dc, fontSize: 12,
                    fontWeight: FontWeight.w600)),
              ],
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(notes, style: const TextStyle(
                    fontSize: 11, color: Colors.grey),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ],
          )),

          // Edit + Delete buttons
          if (!pet.isArchived) ...[
            IconButton(
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.only(left: 4),
              icon: const Icon(Icons.edit_outlined,
                  color: Color(0xFF0277BD), size: 20),
              onPressed: () => _edit(ctx, ref, docId, data),
              tooltip: 'Edit',
            ),
            IconButton(
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.only(left: 4),
              icon: Icon(Icons.delete_outline,
                  color: canDelete ? Colors.redAccent : Colors.grey.shade300,
                  size: 20),
              onPressed: canDelete ? () => _delete(ctx, ref, docId) : null,
              tooltip: canDelete ? 'Delete' : 'Add a new entry before deleting',
            ),
          ],
        ]),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────
  Widget _empty() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.monitor_weight_outlined,
          size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      const Text('No weight entries yet',
          style: TextStyle(fontSize: 16,
              fontWeight: FontWeight.bold, color: Colors.grey)),
      const SizedBox(height: 8),
      const Text(
        'Log your pet\'s weight to track\nhealthy growth over time.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: Colors.grey),
      ),
    ],
  ));

  Widget _actionRow(BuildContext ctx) {
    if (pet.isArchived) {
      return const Align(
        alignment: Alignment.centerRight,
        child: Text('READ ONLY (ARCHIVED)',
            style: TextStyle(color: Colors.grey,
                fontWeight: FontWeight.bold, fontSize: 10)),
      );
    }
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: () => showAddWeightDialog(ctx, pet.petID, petType: pet.type),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('LOG WEIGHT'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _navBlue, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _header(BuildContext ctx) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('WEIGHT TRACKER',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                color: _navBlue, letterSpacing: 1.0)),
        IconButton(
          onPressed: () => Navigator.pop(ctx),
          icon: const CircleAvatar(
              backgroundColor: _navBlue,
              child: Icon(Icons.arrow_back, color: Colors.white, size: 20)),
        ),
      ],
    ),
  );

  Widget _petCard() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: const Color(0xFF546E7A),
        borderRadius: BorderRadius.circular(25)),
    child: Row(children: [
      Container(
        width: 50, height: 50,
        decoration: BoxDecoration(
            color: const Color(0xFF8D8D76),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white, width: 2)),
        child: const Icon(Icons.pets, color: Colors.white, size: 25),
      ),
      const SizedBox(width: 15),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(pet.name, style: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(pet.breed, style: const TextStyle(
            color: Colors.white70, fontSize: 12)),
      ]),
    ]),
  );
}
