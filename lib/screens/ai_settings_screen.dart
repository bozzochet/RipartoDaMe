import 'package:flutter/material.dart';

import '../services/ai/gemini_settings_service.dart';
import '../services/ai/gemini_service.dart';
import '../services/ai/ai_demo_service.dart';
import '../services/ai/ai_feature.dart';
import '../widgets/cozy_widgets.dart';
import '../widgets/cozy_background.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final TextEditingController _apiKeyController =
      TextEditingController();

  bool _isLoading = true;
  bool _hasApiKey = false;
  bool _obscureApiKey = true;
  bool _isSaving = false;

  bool _dietPlanDemoUsed = false;
  bool _menuDemoUsed = false;
  bool _diaryDemoUsed = false;
  bool _bodyDemoUsed = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final apiKey =
    await GeminiSettingsService.instance.getPersonalApiKey();

    final dietPlanDemoUsed =
    await AiDemoService.instance.hasConsumedDemo(
      AiFeature.dietPlanAnalysis,
    );

    final menuDemoUsed =
    await AiDemoService.instance.hasConsumedDemo(
      AiFeature.menuGeneration,
    );

    final diaryDemoUsed =
    await AiDemoService.instance.hasConsumedDemo(
      AiFeature.diaryAnalysis,
    );

    final bodyDemoUsed =
    await AiDemoService.instance.hasConsumedDemo(
      AiFeature.bodyAnalysis,
    );

    if (!mounted) return;

    setState(() {
        _apiKeyController.text = apiKey ?? '';
        _hasApiKey = apiKey != null && apiKey.isNotEmpty;

        _dietPlanDemoUsed = dietPlanDemoUsed;
        _menuDemoUsed = menuDemoUsed;
        _diaryDemoUsed = diaryDemoUsed;
        _bodyDemoUsed = bodyDemoUsed;

        _isLoading = false;
    });
  }

  Future<void> _validateAndSaveApiKey() async {
    final apiKey = _apiKeyController.text.trim();

    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Inserisci una API Key valida.',
          ),
        ),
      );
      return;
    }

    setState(() {
        _isSaving = true;
    });

    try {
      await GeminiService.instance.validateApiKey(
        apiKey,
      );

      await GeminiSettingsService.instance
      .savePersonalApiKey(apiKey);

      if (!mounted) return;

      setState(() {
          _hasApiKey = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            '✅ API Key verificata e salvata.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            '❌ API Key non valida: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
            _isSaving = false;
        });
      }
    }
  }
  
  Future<void> _removeApiKey() async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Rimuovere la API Key?'),
            content: const Text(
              'Le funzionalità AI torneranno ad utilizzare '
              'soltanto le prove gratuite disponibili.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop(true),
                child: const Text('Rimuovi'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    await GeminiSettingsService.instance.removePersonalApiKey();

    if (!mounted) return;

    _apiKeyController.clear();

    setState(() {
      _hasApiKey = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('API Key rimossa.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CozyBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Column(
                  children: [
                    AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      title: const Text(
                        'Intelligenza Artificiale',
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            _buildStatusCard(),
                            const SizedBox(height: 16),
                            _buildDemoStatusCard(),
                            const SizedBox(height: 16),
                            _buildApiKeyCard(),
                            const SizedBox(height: 16),
                            _buildInfoCard(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return CozyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stato configurazione',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                _hasApiKey
                    ? Icons.check_circle
                    : Icons.warning_amber_rounded,
                color:
                    _hasApiKey ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _hasApiKey
                      ? 'API Key Gemini configurata'
                      : 'API Key Gemini non configurata',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemoStatusCard() {
    return CozyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prove gratuite',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _buildDemoRow(
            'Analisi piano alimentare',
            _dietPlanDemoUsed,
          ),

          _buildDemoRow(
            'Generazione menu',
            _menuDemoUsed,
          ),

          _buildDemoRow(
            'Analisi diario',
            _diaryDemoUsed,
          ),

          _buildDemoRow(
            'Analisi referti',
            _bodyDemoUsed,
          ),
        ],
      ),
    );
  }
  
  Widget _buildApiKeyCard() {
    return CozyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gemini API Key',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureApiKey,
            minLines: 1,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Incolla qui la tua API Key',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureApiKey
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureApiKey = !_obscureApiKey;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed:
                _isSaving ? null : _validateAndSaveApiKey,
                icon: _isSaving
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                : const Icon(Icons.verified),
                label: Text(
                  _hasApiKey
                  ? 'Verifica e aggiorna'
                  : 'Verifica e salva'
                ),
              ),
              if (_hasApiKey)
              OutlinedButton.icon(
                onPressed: _removeApiKey,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Rimuovi'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return CozyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Informazioni',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Le funzionalità AI di RipartoDaMe utilizzano '
            'Gemini di Google.\n\n'
            'Puoi ottenere gratuitamente una API Key personale '
            'tramite Google AI Studio.\n\n'
            'RipartoDaMe non applica costi aggiuntivi e non '
            'riceve compensi dall\'utilizzo della tua API Key.\n\n'
            'Se vorrai aumentare i limiti disponibili potrai '
            'eventualmente aggiungere credito direttamente al '
            'tuo account Google, ma non è necessario per iniziare.',
          ),
        ],
      ),
    );
  }

  Widget _buildDemoRow(
    String label,
    bool used,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        children: [
          Icon(
            used
            ? Icons.check_circle
            : Icons.radio_button_unchecked,
            color:
            used ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label ${used ? '✅ usata' : '❌ disponibile'}',
            ),
          ),
        ],
      ),
    );
  }
  
}
