import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// SAFE API KEY SETUP — never hardcode your key in source code.
//
// In your terminal, run the app with:
//   flutter run --dart-define=GEMINI_API_KEY=AIzaSyCV_kn7rLyMwrONvNXypGaOMVa33X3W7Sw
//
// Or in Android Studio / VS Code launch config, add:
//   --dart-define=GEMINI_API_KEY=AIzaSyCV_kn7rLyMwrONvNXypGaOMVa33X3W7Sw
//
// The key is then available at compile time via:
//   const String.fromEnvironment('GEMINI_API_KEY')
// ─────────────────────────────────────────────────────────────────────────────

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    debugListAvailableModels('AIzaSyCV_kn7rLyMwrONvNXypGaOMVa33X3W7Sw'); // ← call this once to see which models your key has access to, then update the model name below accordingly
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite', // Compare this to the names printed above
      apiKey: 'AIzaSyCV_kn7rLyMwrONvNXypGaOMVa33X3W7Sw',
    );
  }

  // Separate retry key from any other app using SharedPreferences
  static const _retryKey = 'pet_gemini_retry_after';

  Future<bool> get isAvailable async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_retryKey);
    if (saved != null) {
      final retryAfter = DateTime.parse(saved);
      if (DateTime.now().isBefore(retryAfter)) {
        print('Gemini still in cooldown until $retryAfter');
        return false;
      }
      await prefs.remove(_retryKey); // auto-clear expired cooldown
    }
    return true;
  }

  Future<void> clearCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_retryKey);
    print('Gemini cooldown cleared');
  }

  Future<void> _markQuotaHit(String errorMsg) async {
    final match = RegExp(r'retry[_\s]?(?:after|in)[_\s]?(\d+)')
        .firstMatch(errorMsg.toLowerCase());
    final seconds = int.tryParse(match?.group(1) ?? '120') ?? 120;
    final retryAfter = DateTime.now().add(Duration(seconds: seconds));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_retryKey, retryAfter.toIso8601String());
    print('Quota hit. Retry after: $retryAfter');
  }

  Future<void> debugListAvailableModels(String apiKey) async {
   final url = Uri.parse('https://generativelanguage.googleapis.com/v1/models?key=$apiKey');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('--- Available Models for your Key ---');
        for (var model in data['models']) {
          print('Name: ${model['name']}');
          print('DisplayName: ${model['displayName']}');
          print('---');
        }
      } else {
        print('Failed to list models: ${response.body}');
      }
    } catch (e) {
      print('Error listing models: $e');
    }
  }

  Future<T?> _callWithRetry<T>(Future<T> Function() fn) async {
    if (!await isAvailable) return null;
    try {
      return await fn();
     } catch (e) {
      final msg = e.toString();
      print('GEMINI FULL ERROR: $msg'); // ← already there but check your debug console
      if (msg.contains('quota') ||
          msg.contains('429') ||
          msg.contains('RESOURCE_EXHAUSTED')) {
        await _markQuotaHit(msg);
      }
      print('Gemini error: $msg');
      return null;
    }
  }

  // ─── PET RECOMMENDATIONS ─────────────────────────────────────────────────

  Future<PetRecommendation?> generatePetRecommendations({
    required String petType,
    required String breed,
    required String sex,
    required double weight,
    required String weightUnit,
    required String birthDate,
    required bool sterilized,
    required bool vaccinated,
  }) async {
    print('Gemini generating recommendations for $breed $petType');

    final result = await _callWithRetry(() async {
      final prompt = '''You are a veterinary health advisor. Given the following pet profile, 
provide practical, breed-specific health and care recommendations.

Pet Profile:
- Type: $petType
- Breed: $breed
- Sex: $sex
- Weight: $weight $weightUnit
- Date of Birth: $birthDate
- Sterilized: ${sterilized ? 'Yes' : 'No'}
- Vaccinated: ${vaccinated ? 'Yes' : 'No'}

Return ONLY a JSON object with this exact structure, no markdown, no extra text:
{
  "diet": "2-3 sentences on ideal diet and feeding for this breed",
  "exercise": "2-3 sentences on exercise needs",
  "health_watch": "2-3 sentences on breed-specific health concerns to watch for",
  "grooming": "1-2 sentences on grooming needs",
  "tip": "One short fun or important breed-specific tip"
}''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text!;
      print('Gemini pet recommendation raw: $text');

      final cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .replaceAll('\n', ' ')
          .replaceAll('\r', '')
          .trim();

      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      return PetRecommendation(
        diet:        parsed['diet']?.toString() ?? '',
        exercise:    parsed['exercise']?.toString() ?? '',
        healthWatch: parsed['health_watch']?.toString() ?? '',
        grooming:    parsed['grooming']?.toString() ?? '',
        tip:         parsed['tip']?.toString() ?? '',
      );
    });

    return result;
  }

  // ─── FLASHCARD METHODS ────────────────────────────────────────────────────

  Future<List<List<String>>> generateDistractors({
    required List<Map<String, String>> flashcards,
  }) async {
    print('Gemini generating distractors for ${flashcards.length} cards');
    final fallback = List.generate(
      flashcards.length,
      (_) => ['None of the above', 'All of the above', 'Cannot be determined'],
    );

    final result = await _callWithRetry(() async {
      final formatted = flashcards.asMap().entries
          .map((e) =>
              '${e.key + 1}. Question: ${e.value["question"]}\n   Answer: ${e.value["answer"]}')
          .join('\n\n');

      final prompt = '''You are a quiz generator. Given this Flashcard:

$formatted  

For each Flashcard, generate exactly 3 incorrect but plausible distractor answers.
Rules:
- The distractors should be related to the question but incorrect.
- Do not include the correct answer in the distractors.
- The distractors should be similar in length and complexity to the correct answer.
- The distractors should be unique and not repetitive.
Return ONLY a JSON array of arrays, one inner array per flashcard, nothing else.
- Example Output: [["D1","D2","D3"],["D1","D2","D3"]]''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text!;
      final cleaned = text
          .replaceAll('```json', '').replaceAll('```', '')
          .replaceAll('\n', '').replaceAll('\r', '').trim();

      final List<dynamic> parsed = jsonDecode(cleaned);
      return parsed
          .map((inner) => (inner as List<dynamic>)
              .map((e) => e.toString()).take(3).toList())
          .toList();
    });

    return result ?? fallback;
  }

  Future<List<Map<String, String>>> generateIdentificationQuestionsBatch({
    required List<Map<String, String>> flashcards,
  }) async {
    final result = await _callWithRetry(() async {
      final prompt = '''You are a quiz generator. Convert these flashcards into identification questions.
Flashcards: ${jsonEncode(flashcards)}

Rules:
- Rephrase each question into an identification question that the user can recall.
- Each question should be clear, concise, and end with a "?"
- Each answer should be a short, specific word or phrase.
- Do not give hints or include the answer in the question.
- Return ONLY a JSON array where each object has exactly two keys: "question" and "answer".
- The order must match the input order exactly.
- Example Output: [{"question": "What is the capital of Philippines?", "answer": "Manila"}]''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text!;
      final cleaned = text
          .replaceAll('```json', '').replaceAll('```', '')
          .replaceAll('\n', '').replaceAll('\r', '').trim();

      final List<dynamic> parsed = jsonDecode(cleaned);
      return List.generate(parsed.length, (i) => {
        'question': parsed[i]['question']?.toString() ?? flashcards[i]['question']!,
        'answer':   parsed[i]['answer']?.toString()   ?? flashcards[i]['answer']!,
      });
    });

    return result ?? flashcards;
  }

  Future<List<Map<String, dynamic>>> generateTrueFalseQuestions({
    required List<Map<String, String>> flashcards,
  }) async {
    final result = await _callWithRetry(() async {
      final prompt = '''You are a quiz generator. Convert these flashcards into true or false questions.
Flashcards: ${jsonEncode(flashcards)}

Rules:
- For each flashcard, create a statement that is either TRUE or FALSE.
- Mix roughly half true, half false.
- For FALSE statements, change the answer to something incorrect but plausible.
- Return ONLY a JSON array where each object has exactly two keys: "statement" and "answer".
  - "answer": either "True" or "False"
- The order must match the input order exactly.
- Example Output: [{"statement": "Manila is the capital of Philippines.", "answer": "True"}]''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text!;
      final cleaned = text
          .replaceAll('```json', '').replaceAll('```', '')
          .replaceAll('\n', '').replaceAll('\r', '').trim();

      final List<dynamic> parsed = jsonDecode(cleaned);
      return List.generate(parsed.length, (i) => {
        'statement': parsed[i]['statement']?.toString() ?? flashcards[i]['question']!,
        'answer':    parsed[i]['answer']?.toString()    ?? 'True',
      });
    });

    return result ??
        flashcards.map((f) => {'statement': f['question']!, 'answer': 'True'}).toList();
  }

  Future<Map<String, dynamic>?> generateFlashcardsFromText({
    required String extractedText,
  }) async {
    final result = await _callWithRetry(() async {
      final prompt = '''You are a flashcard generator. Given the following text, generate
a set of flashcard Q&A pairs covering the key concepts and important information.

Text:
"""
$extractedText
"""

Rules:
- Generate as many pairs as the content warrants (minimum 5, maximum 20).
- Each question should test understanding of a key concept.
- Each answer should be concise and clear.
- Determine a suitable deck title and subject from the content.
- Return ONLY a JSON object with this exact structure:
{
  "title": "deck title here",
  "subject": "subject here",
  "flashcards": [
    {"question": "question text", "answer": "answer text"}
  ]
}''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text!;
      final cleaned = text
          .replaceAll('```json', '').replaceAll('```', '')
          .replaceAll('\n', ' ').replaceAll('\r', '').trim();

      return jsonDecode(cleaned) as Map<String, dynamic>;
    });

    return result;
  }
}

// ─── DATA MODEL ──────────────────────────────────────────────────────────────

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