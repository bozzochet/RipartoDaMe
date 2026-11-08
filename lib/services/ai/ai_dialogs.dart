import 'package:flutter/material.dart';
import '../../screens/ai_settings_screen.dart';

class AiDialogs {
  static Future<void> showDemoLimitDialog(
    BuildContext context,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: Colors.amber,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hai terminato la prova gratuita',
              ),
            ),
          ],
        ),
        content: const Text(
          'Hai già utilizzato la prova gratuita di questa funzionalità.\n\n'
          'Per continuare ad utilizzare l\'Intelligenza Artificiale di RipartoDaMe puoi configurare una tua API Key Gemini personale.\n\n'

          'Google AI Studio mette a disposizione una quota gratuita individuale che, per molti utenti, è sufficiente per un utilizzo normale dell\'app.\n\n'

          'RipartoDaMe non applica costi aggiuntivi, non riceve commissioni e non guadagna dall\'utilizzo della tua API Key personale.\n\n'

          'Se in futuro vorrai aumentare i limiti disponibili potrai eventualmente attivare del credito direttamente sul tuo account Google, ma non è necessario per iniziare.\n\n',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non ora'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(context);

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AiSettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.key_outlined),
            label: const Text('Configura Gemini'),
          ),
        ],
      ),
    );
  }
}
