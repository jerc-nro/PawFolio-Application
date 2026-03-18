// lib/features/pets/widgets/pet_ai_recommendation_card.dart

import 'package:flutter/material.dart';
import '../../../services/gemini_service.dart';
import '_pet_profile_shared.dart';

/// States the AI recommendation card can be in.
enum _CardState { idle, loading, loaded, unavailable, error }

class PetAiRecommendationCard extends StatefulWidget {
  final String petType;
  final String breed;
  final String sex;
  final double weight;
  final String weightUnit;
  final String birthDate;
  final bool sterilized;
  final bool vaccinated;

  const PetAiRecommendationCard({
    super.key,
    required this.petType,
    required this.breed,
    required this.sex,
    required this.weight,
    required this.weightUnit,
    required this.birthDate,
    required this.sterilized,
    required this.vaccinated,
  });

  @override
  State<PetAiRecommendationCard> createState() =>
      _PetAiRecommendationCardState();
}

class _PetAiRecommendationCardState extends State<PetAiRecommendationCard>
    with SingleTickerProviderStateMixin {
  final _gemini = GeminiService();
  _CardState _state = _CardState.idle;
  PetRecommendation? _rec;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() => _state = _CardState.loading);

    // Check quota first without burning a request
    final available = await _gemini.isAvailable;
    if (!available) {
      if (mounted) setState(() => _state = _CardState.unavailable);
      return;
    }

    final rec = await _gemini.generatePetRecommendations(
      petType:    widget.petType,
      breed:      widget.breed,
      sex:        widget.sex,
      weight:     widget.weight,
      weightUnit: widget.weightUnit,
      birthDate:  widget.birthDate,
      sterilized: widget.sterilized,
      vaccinated: widget.vaccinated,
    );

    if (!mounted) return;
    if (rec == null) {
      setState(() => _state = _CardState.unavailable);
    } else {
      setState(() {
        _rec   = rec;
        _state = _CardState.loaded;
      });
      _fadeCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kDivider),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Card Header ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: kNavy.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_outlined,
                  color: kNavy, size: 16),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Recommendations',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kNavy,
                          letterSpacing: 0.3)),
                  Text('Breed-specific health & care tips',
                      style: TextStyle(fontSize: 11, color: kLabel)),
                ],
              ),
            ),
            // AI badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: kBrown.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kBrown.withOpacity(0.25)),
              ),
              child: const Text('Gemini',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: kBrown,
                      letterSpacing: 0.3)),
            ),
          ]),
        ),

        const SizedBox(height: 14),
        const Divider(height: 1, color: kDivider, indent: 18, endIndent: 18),
        const SizedBox(height: 14),

        // ── Body ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: _buildBody(),
        ),
      ]),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _CardState.idle:
        return _IdlePrompt(breed: widget.breed, onTap: _generate);

      case _CardState.loading:
        return const _LoadingState();

      case _CardState.unavailable:
        return _UnavailableState(onRetry: _generate);

      case _CardState.error:
        return _UnavailableState(onRetry: _generate);

      case _CardState.loaded:
        return FadeTransition(
          opacity: _fadeAnim,
          child: _RecommendationContent(rec: _rec!),
        );
    }
  }
}

// ── Idle prompt ───────────────────────────────────────────────────────────────

class _IdlePrompt extends StatelessWidget {
  final String breed;
  final VoidCallback onTap;
  const _IdlePrompt({required this.breed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'Get personalised care tips for your $breed based on breed, age, weight and health status.',
        style: const TextStyle(
            fontSize: 12, color: kLabel, height: 1.5),
      ),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.auto_awesome, size: 15),
          label: const Text('Generate Recommendations',
              style:
                  TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: kNavy,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ]);
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: kNavy.withOpacity(0.6)),
        ),
        const SizedBox(width: 12),
        const Text('Analysing breed profile…',
            style: TextStyle(fontSize: 12, color: kLabel)),
      ]),
      const SizedBox(height: 8),
    ]);
  }
}

// ── Unavailable ───────────────────────────────────────────────────────────────

class _UnavailableState extends StatelessWidget {
  final VoidCallback onRetry;
  const _UnavailableState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBrown.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBrown.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.info_outline, size: 15, color: kBrown.withOpacity(0.8)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Recommendations unavailable right now',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kBrown),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        const Text(
          'The AI service has reached its usage limit. Please try again in a few minutes.',
          style: TextStyle(fontSize: 11, color: kLabel, height: 1.4),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onRetry,
          child: Row(children: [
            Icon(Icons.refresh, size: 14, color: kNavy.withOpacity(0.7)),
            const SizedBox(width: 6),
            Text('Try again',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kNavy.withOpacity(0.7))),
          ]),
        ),
      ]),
    );
  }
}

// ── Loaded content ────────────────────────────────────────────────────────────

class _RecommendationContent extends StatelessWidget {
  final PetRecommendation rec;
  const _RecommendationContent({required this.rec});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _RecSection(
        icon: Icons.restaurant_outlined,
        iconColor: const Color(0xFF7A8C6A),
        label: 'Diet',
        text: rec.diet,
      ),
      _RecSection(
        icon: Icons.directions_run_outlined,
        iconColor: const Color(0xFF45617D),
        label: 'Exercise',
        text: rec.exercise,
      ),
      _RecSection(
        icon: Icons.monitor_heart_outlined,
        iconColor: const Color(0xFFBD4B4B),
        label: 'Health Watch',
        text: rec.healthWatch,
      ),
      _RecSection(
        icon: Icons.content_cut_outlined,
        iconColor: const Color(0xFFBA7F57),
        label: 'Grooming',
        text: rec.grooming,
      ),
      // Tip banner
      Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kNavy.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kNavy.withOpacity(0.12)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('💡', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(rec.tip,
                style: const TextStyle(
                    fontSize: 12, color: kNavy, height: 1.5)),
          ),
        ]),
      ),
    ]);
  }
}

class _RecSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String text;

  const _RecSection({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: iconColor,
                        letterSpacing: 0.8)),
                const SizedBox(height: 3),
                Text(text,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4A4A4A),
                        height: 1.5)),
              ]),
        ),
      ]),
    );
  }
}