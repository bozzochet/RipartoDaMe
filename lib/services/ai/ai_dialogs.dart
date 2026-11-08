import 'package:flutter/material.dart';

class AiDialogs {
  static Future<void> showDemoLimitDialog(
    BuildContext context,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hai terminato la prova gratuita'),
        content: const Text(
          'Hai già utilizzato la prova gratuita di questa funzione.\n\n'
          'Per continuare puoi configurare gratuitamente una tua API Key Gemini tramite Google AI Studio.',
        ),
      ),
    );
  }
}
