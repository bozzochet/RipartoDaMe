import 'package:shared_preferences/shared_preferences.dart';

import 'ai_feature.dart';

class AiDemoService {
  static final AiDemoService instance = AiDemoService._();

  AiDemoService._();

  static const String _prefix = 'ai_demo_used_';

  String _keyFor(AiFeature feature) {
    switch (feature) {
      case AiFeature.dietPlanAnalysis:
        return '${_prefix}diet_plan_analysis';
      case AiFeature.menuGeneration:
        return '${_prefix}menu_generation';
      case AiFeature.diaryAnalysis:
        return '${_prefix}diary_analysis';
      case AiFeature.bodyAnalysis:
        return '${_prefix}body_analysis';
    }
  }

  Future<bool> hasConsumedDemo(AiFeature feature) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFor(feature)) ?? false;
  }

  Future<bool> canUseDemo(AiFeature feature) async {
    return !(await hasConsumedDemo(feature));
  }

  Future<void> consumeDemo(AiFeature feature) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFor(feature), true);
  }

  Future<void> resetDemo(AiFeature feature) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(feature));
  }
}
