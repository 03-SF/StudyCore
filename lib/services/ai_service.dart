import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiServiceException implements Exception {
  final String message;
  AiServiceException(this.message);

  @override
  String toString() => message;
}

class AiService {
  late final GenerativeModel _model;

  AiService() {
    final key = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (key.isEmpty) {
      throw AiServiceException(
        'Gemini API key not configured. Please add GEMINI_API_KEY to .env file.',
      );
    }
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: key);
  }

  Future<List<Map<String, String>>> generateCardsFromText(
    String text,
    int count,
  ) async {
    try {
      final prompt =
          'Generate exactly $count flashcard pairs from this study material. '
          'Respond ONLY with a JSON array. No markdown, no code blocks, no explanation. '
          'Format: [{"question":"question text","answer":"answer text"}]. '
          'Question max 100 chars. Answer max 200 chars. Material:\n$text';

      final response = await _model.generateContent([Content.text(prompt)]);
      final raw = response.text ?? '';

      if (raw.isEmpty) {
        throw AiServiceException('AI returned empty response');
      }

      final jsonStr = _extractJson(raw);

      if (!jsonStr.contains('[')) {
        throw AiServiceException('AI response does not contain valid JSON');
      }

      final json = jsonDecode(jsonStr) as List;

      if (json.isEmpty) {
        throw AiServiceException('AI generated no flashcards');
      }

      final result = json
          .cast<Map<String, dynamic>>()
          .map((e) {
            // Support both formats from AI
            final front = (e['question'] ?? e['front'] ?? '') as String;
            final back = (e['answer'] ?? e['back'] ?? '') as String;
            return {'front': front.trim(), 'back': back.trim()};
          })
          .where(
            (card) => card['front']!.isNotEmpty && card['back']!.isNotEmpty,
          )
          .toList();

      if (result.isEmpty) {
        throw AiServiceException('No valid flashcards generated');
      }

      return result;
    } on AiServiceException {
      rethrow;
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('not found for API version') ||
          errorStr.contains('not supported')) {
        throw AiServiceException(
          'API key error: Gemini model not available. '
          'Please ensure:\n'
          '1. Generative Language API is enabled in Google Cloud Console\n'
          '2. API key has access to Gemini 1.5 Flash\n'
          '3. Test your key at: aistudio.google.com',
        );
      }
      throw AiServiceException('Error: ${e.toString()}');
    }
  }

  Future<List<Map<String, String>>> generateCardsFromImage(
    List<int> imageBytes,
    int count,
  ) async {
    try {
      final prompt =
          'Look at this image. Extract the study material and generate exactly $count flashcard pairs. '
          'Respond ONLY with a JSON array. No markdown backticks. '
          'Format: [{"front":"...","back":"..."}].';

      final response = await _model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', Uint8List.fromList(imageBytes)),
        ]),
      ]);
      final raw = response.text ?? '';
      final jsonStr = _extractJson(raw);
      final json = jsonDecode(jsonStr) as List;
      return json
          .cast<Map<String, dynamic>>()
          .map(
            (e) => {
              'front': (e['front'] as String?) ?? '',
              'back': (e['back'] as String?) ?? '',
            },
          )
          .toList();
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('not found for API version') ||
          errorStr.contains('not supported')) {
        throw AiServiceException(
          'API key error: Gemini model not available. '
          'Please ensure the Generative Language API is enabled in Google Cloud Console.',
        );
      }
      throw AiServiceException('Image analysis failed: ${e.toString()}');
    }
  }

  Future<String> generateSummary(String text) async {
    try {
      final prompt =
          'Summarize this study material in 3-5 bullet points. Be concise:\n$text';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? '';
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('not found for API version') ||
          errorStr.contains('not supported')) {
        throw AiServiceException('API key error: Gemini model not available.');
      }
      throw AiServiceException('Summary generation failed: ${e.toString()}');
    }
  }

  Future<String> suggestCardBack(String front) async {
    try {
      final prompt =
          'You are a study assistant. Provide a clear, concise answer or definition for this flashcard front. '
          'Keep it under 200 characters. Front: "$front"';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? '';
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('not found for API version') ||
          errorStr.contains('not supported')) {
        throw AiServiceException('API key error: Gemini model not available.');
      }
      throw AiServiceException('AI suggestion failed: ${e.toString()}');
    }
  }

  String _extractJson(String raw) {
    // Remove markdown code blocks if present
    var cleaned = raw;
    if (cleaned.contains('```json')) {
      final start = cleaned.indexOf('```json') + 7;
      final end = cleaned.lastIndexOf('```');
      if (start < end) {
        cleaned = cleaned.substring(start, end);
      }
    } else if (cleaned.contains('```')) {
      final start = cleaned.indexOf('```') + 3;
      final end = cleaned.lastIndexOf('```');
      if (start < end) {
        cleaned = cleaned.substring(start, end);
      }
    }

    // Extract JSON array
    final startIdx = cleaned.indexOf('[');
    final endIdx = cleaned.lastIndexOf(']');
    if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
      return cleaned.substring(startIdx, endIdx + 1);
    }
    return cleaned.trim();
  }
}
