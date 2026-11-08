import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'ai_demo_service.dart';
import 'ai_exceptions.dart';
import 'ai_feature.dart';
import 'gemini_settings_service.dart';

class GeminiService {
  GeminiService._();

  static const int _maxAttempts = 3;
  static const int _initialDelayMs = 1000;
  static const Duration _timeout = Duration(seconds: 90);
  
  static final GeminiService instance = GeminiService._();

  Future<String> _resolveApiKey(AiFeature feature) async {
    final personalKey =
        await GeminiSettingsService.instance.getPersonalApiKey();

    if (personalKey != null && personalKey.isNotEmpty) {
      return personalKey;
    }

    final canUseDemo =
        await AiDemoService.instance.canUseDemo(feature);

    if (!canUseDemo) {
      throw AiDemoLimitReachedException(
        _featureLabel(feature),
      );
    }

    final demoKey = dotenv.env['GEMINI_API_KEY']?.trim();

    if (demoKey == null || demoKey.isEmpty) {
      throw GeminiApiKeyMissingException();
    }

    return demoKey;
  }

  Future<GenerateContentResponse> generateContent({
      required AiFeature feature,
      required List<Content> contents,
      GenerationConfig? generationConfig,
  }) async {
    final apiKey = await _resolveApiKey(feature);

    final generator = GenerativeModel(
      model: _modelFor(feature),
      apiKey: apiKey,
      generationConfig: generationConfig,
    );

    int delayMs = _initialDelayMs;

    for (int attempt = 1;
      attempt <= _maxAttempts;
      attempt++) {
      try {
        final response = await generator
        .generateContent(contents)
        .timeout(_timeout);

        final usingPersonalKey =
        await GeminiSettingsService.instance
        .hasPersonalApiKey();

        if (!usingPersonalKey) {
          await AiDemoService.instance
          .consumeDemo(feature);
        }

        return response;
      } catch (e) {
        if (attempt == _maxAttempts) {
          rethrow;
        }

        await Future.delayed(
          Duration(milliseconds: delayMs),
        );

        delayMs *= 2;
      }
    }

    throw StateError(
      'Unexpected generateContent exit',
    );
  }  

  String _modelFor(AiFeature feature) {
    switch (feature) {
      case AiFeature.menuGeneration:
      return 'gemini-3.6-flash';

      case AiFeature.diaryAnalysis:
      return 'gemini-3.6-flash';

      case AiFeature.bodyAnalysis:
      return 'gemini-3.6-flash';
    }
  }
  
  String _featureLabel(AiFeature feature) {
    switch (feature) {
      case AiFeature.menuGeneration:
        return 'Generazione menu';
      case AiFeature.diaryAnalysis:
        return 'Analisi diario';
      case AiFeature.bodyAnalysis:
        return 'Analisi corpo';
    }
  }
}
