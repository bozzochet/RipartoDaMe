import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cozy_background.dart';
import '../widgets/cozy_widgets.dart';

class ImpostazioniScreen extends StatefulWidget {
  const ImpostazioniScreen({super.key});

  @override
  State<ImpostazioniScreen> createState() => _ImpostazioniScreenState();
}

class _ImpostazioniScreenState extends State<ImpostazioniScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  bool _isLoading = false;

  Future<void> _esportaDati() async {
    try {
      setState(() => _isLoading = true);
      
      // 1. Ottiene la stringa JSON con tutti i dati
      final jsonString = _storageService.exportToJsonString();

      // 2. Salva temporaneamente il file sul dispositivo
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('${directory.path}/riparto_da_me_backup_$timestamp.json');
      await file.writeAsString(jsonString);

      setState(() => _isLoading = false);

      // 3. Condivide il file (su iOS apre il pannello di condivisione nativo: Salva su File, AirDrop, Mail, ecc.)
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Backup dei dati di Riparto da Me',
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFC62828),
          content: Text('Errore durante l\'esportazione: $e'),
        ),
      );
    }
  }

  Future<void> _importaDati() async {
    try {
      // 1. Apre il selettore di file per scegliere il file JSON di backup (senza platform)
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result != null && result.isNotEmpty && result.single.path != null) {
        // Conferma di sicurezza prima di sovrascrivere i dati
        bool? conferma = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.background,
            title: const Text('Attenzione', style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold)),
            content: const Text(
              'Importando un file di backup verranno sovrascritti tutti i dati attuali presenti nell\'applicazione. Vuoi procedere?',
              style: TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annulla', style: TextStyle(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sovrascrivi', style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (conferma == true) {
          setState(() => _isLoading = true);

          final file = File(result.single.path!);
          final jsonString = await file.readAsString();
          final Map<String, dynamic> jsonData = jsonDecode(jsonString);

          // Esegue l'importazione nei box Hive
          await _storageService.importFromJsonMap(jsonData);

          setState(() => _isLoading = false);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF2E7D32),
              content: Text('✅ Dati importati con successo! Riavvia l\'app se necessario.'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFC62828),
          content: Text('Errore durante l\'importazione: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CozyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Impostazioni',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Serif',
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16.0,
                MediaQuery.of(context).padding.top + kToolbarHeight + 16.0,
                16.0,
                16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Gestione Dati & Backup',
                    style: TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Esporta i tuoi progressi per custodirli al sicuro o importali da un backup precedente.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card Esportazione
                  CozyWoodCard(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('📤', style: TextStyle(fontSize: 24)),
                              SizedBox(width: 12),
                              Text(
                                'Esporta Backup',
                                style: TextStyle(
                                  fontFamily: 'Serif',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Crea un file di salvataggio JSON contenente tutte le misurazioni, il diario, le foto e il profilo.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: CozyButton(
                              text: 'Esporta Dati',
                              icon: Icons.upload_file,
                              onPressed: _isLoading ? null : _esportaDati,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Card Importazione
                  CozyWoodCard(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('📥', style: TextStyle(fontSize: 24)),
                              SizedBox(width: 12),
                              Text(
                                'Importa Backup',
                                style: TextStyle(
                                  fontFamily: 'Serif',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ripristina i dati caricando un file di backup JSON precedentemente salvato.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: CozyButton(
                              text: 'Importa Dati',
                              icon: Icons.download,
                              onPressed: _isLoading ? null : _importaDati,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
