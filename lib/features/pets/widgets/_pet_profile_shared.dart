// lib/features/pets/widgets/_pet_profile_shared.dart

import 'package:flutter/material.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const kNavy    = Color(0xFF45617D);
const kBrown   = Color(0xFFBA7F57);
const kGreen   = Color(0xFF7A8C6A);
const kRed     = Color(0xFFBD4B4B);
const kLabel   = Color(0xFF8A7060);
const kDivider = Color(0xFFE0D4CB);

// ── Card wrapper ─────────────────────────────────────────────────────────────
class ProfileCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const ProfileCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kDivider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: kNavy, size: 17),
          const SizedBox(width: 7),
          Text(title,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: kNavy, letterSpacing: 0.3)),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }
}

// ── Label + child row ────────────────────────────────────────────────────────
class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const LabeledField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 110,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(label,
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold,
                  color: kLabel, letterSpacing: 0.8)),
          ),
        ),
        Expanded(child: child),
      ]),
    );
  }
}

// ── Value text ───────────────────────────────────────────────────────────────
class ValueText extends StatelessWidget {
  final String text;
  const ValueText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(text.isEmpty ? '—' : text,
        style: const TextStyle(
            fontSize: 13, color: Color(0xFF2C2C2C),
            fontWeight: FontWeight.w500, height: 1.4)),
    );
  }
}

// ── Text field ───────────────────────────────────────────────────────────────
class ProfileTextField extends StatelessWidget {
  final TextEditingController ctrl;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? hint;
  final ValueChanged<String>? onChanged;

  const ProfileTextField({
    super.key,
    required this.ctrl,
    this.keyboardType,
    this.maxLines = 1,
    this.hint,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: Color(0xFF2C2C2C)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kLabel, fontSize: 12),
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF5EFEB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kDivider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kNavy, width: 1.5)),
      ),
    );
  }
}

// ── Toggle row ───────────────────────────────────────────────────────────────
class ToggleRow extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onChanged;
  final bool compact;

  const ToggleRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((o) {
        final isSel = selected == o;
        return GestureDetector(
          onTap: () => onChanged(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: EdgeInsets.only(right: o == options.last ? 0 : 6),
            padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 14,
                vertical: compact ? 6 : 9),
            decoration: BoxDecoration(
              color: isSel ? kNavy : const Color(0xFFF5EFEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSel ? kNavy : kDivider)),
            child: Text(o,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: isSel ? Colors.white : kLabel)),
          ),
        );
      }).toList(),
    );
  }
}

// ── Status badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final bool positive;

  const StatusBadge({super.key, required this.label, required this.positive});

  @override
  Widget build(BuildContext context) {
    final color = positive ? kGreen : kLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}