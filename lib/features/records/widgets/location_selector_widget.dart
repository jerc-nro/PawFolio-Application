import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/records_theme.dart';

// ─── Data Models ─────────────────────────────────────────────────────────────

class _Province {
  final String name;
  final List<_City> cities;
  _Province({required this.name, required this.cities});
}

class _City {
  final String name;
  final List<String> barangays;
  _City({required this.name, required this.barangays});
}

// ─── Public location result ───────────────────────────────────────────────────

class ClinicLocation {
  final String province;
  final String city;
  final String barangay;

  const ClinicLocation({
    required this.province,
    required this.city,
    required this.barangay,
  });

  String get display {
    final parts = [barangay, city, province].where((s) => s.isNotEmpty).toList();
    return parts.join(', ');
  }

  @override
  String toString() => display;
}

// ─── Loader ───────────────────────────────────────────────────────────────────

Future<List<_Province>> _loadProvinces() async {
  final raw = await rootBundle.loadString('assets/data/calabarzon_full.json');
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final region = json['region'] as Map<String, dynamic>;
  final provinceList = region['provinces'] as List<dynamic>;

  return provinceList.map((p) {
    final cities = (p['cities_municipalities'] as List<dynamic>).map((c) {
      final barangays = (c['barangays'] as List<dynamic>)
          .map((b) => b.toString())
          .toList();
      return _City(name: c['name'].toString(), barangays: barangays);
    }).toList();
    return _Province(name: p['name'].toString(), cities: cities);
  }).toList();
}

// ─── Public Widget: LocationSelectorField ────────────────────────────────────
///
/// Drop-in TextFormField replacement.  Tapping opens a bottom-sheet that
/// walks the user through CALABARZON → Province → City → Barangay.
///
/// [value]       – currently selected location (null = nothing selected yet)
/// [onChanged]   – called whenever the selection changes
/// [decoration]  – pass your own InputDecoration; we just set the suffix icon
///

class LocationSelectorField extends StatelessWidget {
  final ClinicLocation? value;
  final ValueChanged<ClinicLocation?> onChanged;
  final InputDecoration? decoration;

  const LocationSelectorField({
    super.key,
    this.value,
    required this.onChanged,
    this.decoration,
  });

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<ClinicLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationSheet(initial: value),
    );
    // result is null when dismissed without completing — keep existing value
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final deco = (decoration ?? const InputDecoration()).copyWith(
      hintText: 'Tap to select location (optional)',
      hintStyle: TextStyle(
          color: RecordsPalette.muted.withOpacity(0.7), fontSize: 12),
      suffixIcon: value != null
          ? GestureDetector(
              onTap: () => onChanged(null),
              child: const Icon(Icons.clear, size: 18, color: RecordsPalette.muted),
            )
          : const Icon(Icons.location_on_outlined,
              size: 18, color: RecordsPalette.steel),
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: RecordsPalette.linenDeep, width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: RecordsPalette.steel, width: 2)),
    );

    return GestureDetector(
      onTap: () => _open(context),
      child: AbsorbPointer(
        child: TextFormField(
          readOnly: true,
          controller: TextEditingController(
              text: value?.display ?? ''),
          decoration: deco,
          style: const TextStyle(fontSize: 13, color: RecordsPalette.ink),
        ),
      ),
    );
  }
}

// ─── Bottom Sheet ─────────────────────────────────────────────────────────────

class _LocationSheet extends StatefulWidget {
  final ClinicLocation? initial;
  const _LocationSheet({this.initial});

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  List<_Province> _provinces = [];
  bool _loading = true;

  _Province? _selProvince;
  _City? _selCity;
  String? _selBarangay;

  // search
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tab.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final list = await _loadProvinces();
    if (!mounted) return;
    setState(() {
      _provinces = list;
      _loading = false;
      // restore initial selection
      if (widget.initial != null) {
        final i = widget.initial!;
        _selProvince = list.firstWhere(
            (p) => p.name == i.province,
            orElse: () => list.first);
        if (_selProvince != null) {
          _selCity = _selProvince!.cities.firstWhere(
              (c) => c.name == i.city,
              orElse: () => _selProvince!.cities.first);
          if (_selCity != null) {
            _selBarangay = i.barangay;
          }
        }
      }
    });
  }

  // ── Navigation helpers ──────────────────────────────────────────────────────

  void _pickProvince(_Province p) {
    setState(() {
      _selProvince = p;
      _selCity = null;
      _selBarangay = null;
      _query = '';
      _search.clear();
    });
    _tab.animateTo(1);
  }

  void _pickCity(_City c) {
    setState(() {
      _selCity = c;
      _selBarangay = null;
      _query = '';
      _search.clear();
    });
    _tab.animateTo(2);
  }

  void _pickBarangay(String b) {
    setState(() {
      _selBarangay = b;
      _query = '';
      _search.clear();
    });
    // Done — pop with result
    Navigator.pop(
      context,
      ClinicLocation(
        province: _selProvince!.name,
        city: _selCity!.name,
        barangay: b,
      ),
    );
  }

  // ── Build helpers ───────────────────────────────────────────────────────────

  Widget _buildSearchBar(String hint) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: TextField(
          controller: _search,
          onChanged: (v) => setState(() => _query = v.toLowerCase()),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(
                fontSize: 12,
                color: RecordsPalette.muted.withOpacity(0.6)),
            prefixIcon: const Icon(Icons.search,
                size: 18, color: RecordsPalette.muted),
            suffixIcon: _query.isNotEmpty
                ? GestureDetector(
                    onTap: () =>
                        setState(() { _query = ''; _search.clear(); }),
                    child: const Icon(Icons.clear,
                        size: 16, color: RecordsPalette.muted))
                : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            filled: true,
            fillColor: RecordsPalette.bg,
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: RecordsPalette.linenDeep.withOpacity(0.6))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: RecordsPalette.steel, width: 1.5)),
          ),
        ),
      );

  Widget _tile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    String? sub,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? RecordsPalette.steel.withOpacity(0.06)
              : Colors.transparent,
          border: Border(
              bottom: BorderSide(
                  color: RecordsPalette.linenDeep.withOpacity(0.5))),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? RecordsPalette.steel
                            : RecordsPalette.ink)),
                if (sub != null) ...[
                  const SizedBox(height: 1),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 10,
                          color: RecordsPalette.muted)),
                ],
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle_rounded,
                size: 16, color: RecordsPalette.steel)
          else
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: RecordsPalette.muted),
        ]),
      ),
    );
  }

  Widget _emptyState(String msg) => Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
            child: Text(msg,
                style: const TextStyle(
                    color: RecordsPalette.muted, fontSize: 13))),
      );

  // ── Province Tab ────────────────────────────────────────────────────────────

  Widget _provinceTab() {
    final list = _provinces
        .where((p) => p.name.toLowerCase().contains(_query))
        .toList();
    return Column(children: [
      _buildSearchBar('Search province…'),
      Expanded(
        child: list.isEmpty
            ? _emptyState('No results')
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final p = list[i];
                  return _tile(
                    label: p.name,
                    sub: '${p.cities.length} cities / municipalities',
                    selected: _selProvince?.name == p.name,
                    onTap: () => _pickProvince(p),
                  );
                },
              ),
      ),
    ]);
  }

  // ── City Tab ────────────────────────────────────────────────────────────────

  Widget _cityTab() {
    if (_selProvince == null) {
      return _emptyState('← Select a province first');
    }
    final list = _selProvince!.cities
        .where((c) => c.name.toLowerCase().contains(_query))
        .toList();
    return Column(children: [
      _buildSearchBar('Search city / municipality…'),
      Expanded(
        child: list.isEmpty
            ? _emptyState('No results')
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final c = list[i];
                  return _tile(
                    label: c.name,
                    sub: '${c.barangays.length} barangays',
                    selected: _selCity?.name == c.name,
                    onTap: () => _pickCity(c),
                  );
                },
              ),
      ),
    ]);
  }

  // ── Barangay Tab ─────────────────────────────────────────────────────────────

  Widget _barangayTab() {
    if (_selCity == null) {
      return _emptyState('← Select a city first');
    }
    final list = _selCity!.barangays
        .where((b) => b.toLowerCase().contains(_query))
        .toList();
    return Column(children: [
      _buildSearchBar('Search barangay…'),
      Expanded(
        child: list.isEmpty
            ? _emptyState('No results')
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final b = list[i];
                  return _tile(
                    label: b,
                    selected: _selBarangay == b,
                    onTap: () => _pickBarangay(b),
                  );
                },
              ),
      ),
    ]);
  }

  // ── Breadcrumb ───────────────────────────────────────────────────────────────

  Widget _breadcrumb() {
    final parts = <String>[];
    if (_selProvince != null) parts.add(_selProvince!.name);
    if (_selCity != null) parts.add(_selCity!.name);
    if (parts.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: RecordsPalette.steel.withOpacity(0.06),
      child: Text(
        parts.join(' › '),
        style: const TextStyle(
            fontSize: 11,
            color: RecordsPalette.steel,
            fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;

    return Container(
      height: sh * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        // Handle
        const SizedBox(height: 10),
        Center(
            child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                    color: RecordsPalette.linenDeep,
                    borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 14),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: RecordsPalette.steelLite,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.location_on_outlined,
                  size: 18, color: RecordsPalette.steel),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CLINIC LOCATION',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: RecordsPalette.terra,
                        letterSpacing: 1.5)),
                Text('Select Province → City → Barangay',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: RecordsPalette.ink)),
              ],
            ),
          ]),
        ),
        const SizedBox(height: 10),

        // Breadcrumb
        _breadcrumb(),

        // Tab bar
        Container(
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: RecordsPalette.linenDeep.withOpacity(0.6))),
          ),
          child: TabBar(
            controller: _tab,
            labelColor: RecordsPalette.steel,
            unselectedLabelColor: RecordsPalette.muted,
            indicatorColor: RecordsPalette.steel,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: [
              Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Province'),
                  if (_selProvince != null) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check_circle_rounded,
                        size: 12, color: RecordsPalette.steel),
                  ],
                ]),
              ),
              Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('City'),
                  if (_selCity != null) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check_circle_rounded,
                        size: 12, color: RecordsPalette.steel),
                  ],
                ]),
              ),
              Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Barangay'),
                  if (_selBarangay != null) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check_circle_rounded,
                        size: 12, color: RecordsPalette.steel),
                  ],
                ]),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tab,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _provinceTab(),
                    _cityTab(),
                    _barangayTab(),
                  ],
                ),
        ),
      ]),
    );
  }
}
