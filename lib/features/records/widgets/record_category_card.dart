import 'package:flutter/material.dart';

import '../widgets/record_category.dart';
import '../theme/records_theme.dart';

/// Tappable card that represents one health-record category in the 2-column grid.
class CategoryCard extends StatefulWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  final RecordCategory category;
  final VoidCallback onTap;

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:  (_) => setState(() => _pressed = true),
      onTapUp:    (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale:    _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color:         widget.category.cardColor,
            borderRadius:  BorderRadius.circular(24),
            border: Border.all(
              color: widget.category.iconBg.withOpacity(0.7),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color:     RecordsPalette.ink.withOpacity(_pressed ? 0.04 : 0.08),
                blurRadius: _pressed ? 6 : 14,
                offset:    Offset(0, _pressed ? 2 : 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Icon bubble ──────────────────────────────────────────────
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color:        widget.category.iconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    widget.category.icon,
                    color: RecordsPalette.steel,
                    size: 26,
                  ),
                ),

                const Spacer(),

                // ── Label ────────────────────────────────────────────────────
                Text(
                  widget.category.label,
                  style: const TextStyle(
                    fontSize:     15,
                    fontWeight:   FontWeight.w800,
                    color:        RecordsPalette.ink,
                    letterSpacing: 0.1,
                    height:       1.2,
                  ),
                ),
                const SizedBox(height: 3),

                // ── Subtitle ─────────────────────────────────────────────────
                Text(
                  widget.category.subtitle,
                  style: const TextStyle(
                    fontSize:   11,
                    color:      RecordsPalette.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),

                // ── Arrow cue ────────────────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width:  28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: RecordsPalette.steel.withOpacity(0.11),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size:  12,
                      color: RecordsPalette.steel,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}