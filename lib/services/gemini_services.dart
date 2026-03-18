import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GeminiService — cloud inference via Firebase AI (Gemini 2.5 Flash)
// ─────────────────────────────────────────────────────────────────────────────

// ─── Status enum (consumed by PetAiRecommendationCard) ───────────────────────
enum GeminiStatus { success, quotaExceeded, noInternet, error }

// ─── Result wrapper ───────────────────────────────────────────────────────────
class GeminiResult {
  final GeminiStatus status;
  final PetRecommendation? recommendation;

  const GeminiResult({required this.status, this.recommendation});
}

// ─── Data model ───────────────────────────────────────────────────────────────
class PetRecommendation {
  final String diet;
  final String exercise;
  final String healthWatch;
  final String grooming;
  final String tip;

  const PetRecommendation({
    required this.diet,
    required this.exercise,
    required this.healthWatch,
    required this.grooming,
    required this.tip,
  });
}

// ─── Service ──────────────────────────────────────────────────────────────────
class GeminiService {
  final _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash-lite');

  // ─── Low-level inference ──────────────────────────────────────────────────
  Future<({String? text, GeminiStatus? errorStatus})> _generate(
      String prompt) async {
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return (text: response.text, errorStatus: null);
    } on SocketException {
      debugPrint('GeminiService: no internet');
      return (text: null, errorStatus: GeminiStatus.noInternet);
    } on FirebaseException catch (e) {
      final isQuota = e.code == 'quota-exceeded' ||
          (e.message?.contains('429') ?? false) ||
          (e.message?.contains('quota') ?? false);
      debugPrint('GeminiService FirebaseException: ${e.message}');
      return (
        text: null,
        errorStatus: isQuota ? GeminiStatus.quotaExceeded : GeminiStatus.error,
      );
    } catch (e) {
      debugPrint('GeminiService error: $e');
      // Catch no-internet on platforms that throw a general exception
      final msg = e.toString().toLowerCase();
      if (msg.contains('socketexception') ||
          msg.contains('network') ||
          msg.contains('unreachable') ||
          msg.contains('failed host lookup')) {
        return (text: null, errorStatus: GeminiStatus.noInternet);
      }
      return (text: null, errorStatus: GeminiStatus.error);
    }
  }

  // ─── Pet recommendations ──────────────────────────────────────────────────
  Future<GeminiResult> generatePetRecommendations({
    required String petType,
    required String breed,
    required String sex,
    required double weight,
    required String weightUnit,
    required String birthDate,
    required bool sterilized,
    required bool vaccinated,
  }) async {
    debugPrint('GeminiService: generating recommendations for $breed $petType');

    const structure = '''
{
  "diet": "2-3 sentences on ideal diet and feeding for this breed",
  "exercise": "2-3 sentences on exercise needs",
  "health_watch": "2-3 sentences on breed-specific health concerns to watch for",
  "grooming": "1-2 sentences on grooming needs",
  "tip": "One short fun or important breed-specific tip"
}''';

    final prompt = '''You are a veterinary health advisor. Given this pet profile, provide breed-specific care recommendations.

Pet Profile:
- Type: $petType
- Breed: $breed
- Sex: $sex
- Weight: $weight $weightUnit
- Date of Birth: $birthDate
- Sterilized: ${sterilized ? 'Yes' : 'No'}
- Vaccinated: ${vaccinated ? 'Yes' : 'No'}

Return ONLY a JSON object with this exact structure, no markdown, no extra text:
$structure''';

    final (:text, :errorStatus) = await _generate(prompt);

    // ── Propagate network / quota errors immediately ───────────────────────
    if (errorStatus != null) {
      return GeminiResult(status: errorStatus);
    }

    if (text == null || text.trim().isEmpty) {
      return const GeminiResult(status: GeminiStatus.error);
    }

    // ── Parse JSON ────────────────────────────────────────────────────────
    try {
      final cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .replaceAll('\n', ' ')
          .replaceAll('\r', '')
          .trim();

      final jsonStart = cleaned.indexOf('{');
      final jsonEnd = cleaned.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1) {
        debugPrint('GeminiService: no JSON object found in response');
        return const GeminiResult(status: GeminiStatus.error);
      }

      final parsed =
          jsonDecode(cleaned.substring(jsonStart, jsonEnd + 1))
              as Map<String, dynamic>;

      return GeminiResult(
        status: GeminiStatus.success,
        recommendation: PetRecommendation(
          diet: parsed['diet']?.toString() ?? '',
          exercise: parsed['exercise']?.toString() ?? '',
          healthWatch: parsed['health_watch']?.toString() ?? '',
          grooming: parsed['grooming']?.toString() ?? '',
          tip: parsed['tip']?.toString() ?? '',
        ),
      );
    } catch (e) {
      debugPrint('GeminiService: JSON parse error: $e');
      return const GeminiResult(status: GeminiStatus.error);
    }
  }
}