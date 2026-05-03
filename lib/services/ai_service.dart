import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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
    final key = Platform.environment['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: key,
    );
  }

  Future<List<Map<String, String>>> generateCardsFromText(
      String text, int count) async {
    try {
      final prompt =
          'Generate exactly $count flashcard pairs from this study material. '
          'Respond ONLY with a JSON array. No markdown backticks. '
          'Format: [{"front":"...","back":"..."}]. '
          'Front max 100 chars. Back max 200 chars. Material:\n$text';

      final response =
          await _model.generateContent([Content.text(prompt)]);
      final raw = response.text ?? '';

      final jsonStr = _extractJson(raw);
      final json = jsonDecode(jsonStr) as List;
      return json
          .cast<Map<String, dynamic>>()
          .map((e) => {
                'front': (e['front'] as String?) ?? '',
                'back': (e['back'] as String?) ?? '',
              })
          .toList();
    } catch (e) {
      throw AiServiceException('AI generation failed. Please try again.');
    }
  }

  Future<List<Map<String, String>>> generateCardsFromImage(
      List<int> imageBytes, int count) async {
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
          .map((e) => {
                'front': (e['front'] as String?) ?? '',
                'back': (e['back'] as String?) ?? '',
              })
          .toList();
    } catch (e) {
      throw AiServiceException('AI generation failed. Please try again.');
    }
  }

  Future<String> generateSummary(String text) async {
    try {
      final prompt =
          'Summarize this study material in 3-5 bullet points. Be concise:\n$text';
      final response =
          await _model.generateContent([Content.text(prompt)]);
      return response.text ?? '';
    } catch (e) {
      throw AiServiceException('Summary generation failed. Please try again.');
    }
  }

  Future<String> suggestCardBack(String front) async {
    try {
      final prompt =
          'You are a study assistant. Provide a clear, concise answer or definition for this flashcard front. '
          'Keep it under 200 characters. Front: "$front"';
      final response =
          await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? '';
    } catch (e) {
      throw AiServiceException('AI suggestion failed. Please try again.');
    }
  }

  String _extractJson(String raw) {
    final startIdx = raw.indexOf('[');
    final endIdx = raw.lastIndexOf(']');
    if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
      return raw.substring(startIdx, endIdx + 1);
    }
    return raw;
  }
}
