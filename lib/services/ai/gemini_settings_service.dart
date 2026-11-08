import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GeminiSettingsService {
  GeminiSettingsService._();

  static final GeminiSettingsService instance =
      GeminiSettingsService._();

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const String _personalApiKeyKey =
      'gemini_personal_api_key';

  Future<String?> getPersonalApiKey() async {
    final value = await _storage.read(
      key: _personalApiKeyKey,
    );

    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return value.trim();
  }

  Future<bool> hasPersonalApiKey() async {
    final value = await getPersonalApiKey();
    return value != null;
  }

  Future<void> savePersonalApiKey(String apiKey) async {
    await _storage.write(
      key: _personalApiKeyKey,
      value: apiKey.trim(),
    );
  }

  Future<void> removePersonalApiKey() async {
    await _storage.delete(
      key: _personalApiKeyKey,
    );
  }
}
