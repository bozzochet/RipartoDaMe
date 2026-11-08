class AiDemoLimitReachedException implements Exception {
  AiDemoLimitReachedException(this.featureName);

  final String featureName;

  @override
  String toString() =>
      'La prova gratuita per "$featureName" è stata utilizzata.';
}

class GeminiApiKeyMissingException implements Exception {
  @override
  String toString() => 'Nessuna API key Gemini disponibile.';
}
