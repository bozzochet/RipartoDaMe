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

      // 1. Genera l'archivio ZIP contenente database e file multimediali
      final zipPath = await _storageService.exportToZipFile();

      setState(() => _isLoading = false);

      // 2. Condivide il file ZIP tramite il pannello nativo
      await Share.shareXFiles(
        [XFile(zipPath)],
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
      // 1. Apre il selettore di file per scegliere l'archivio ZIP di backup
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result != null && result.isNotEmpty && result.single.path != null) {
        // Conferma di sicurezza prima di sovrascrivere i dati
        bool? conferma = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.background,
            title: const Text('Attenzione',
                style: TextStyle(
                    fontFamily: 'Serif', fontWeight: FontWeight.bold)),
            content: const Text(
              'Importando un file di backup ZIP verranno sovrascritti i dati e ripristinati i file multimediali associati. Vuoi procedere?',
              style: TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annulla',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sovrascrivi',
                    style: TextStyle(
                        color: Color(0xFFC62828), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (conferma == true) {
          setState(() => _isLoading = true);

          final file = File(result.single.path!);

          // Esegue l'importazione e il ripristino dell'archivio ZIP
          await _storageService.importFromZipFile(file);

          setState(() => _isLoading = false);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF2E7D32),
              content: Text(
                  '✅ Dati importati con successo! Riavvia l\'app se necessario.'),
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

  Future<void> _consolidaFile() async {
    try {
      setState(() => _isLoading = true);

      final report = await _storageService.consolidateExternalFiles();

      setState(() => _isLoading = false);

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.background,
          title: const Row(
            children: [
              Icon(Icons.health_and_safety, color: AppColors.woodAccent),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Manutenzione completata',
                  style: TextStyle(
                    fontFamily: 'Serif',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMaintenanceRow(
                  'File referenziati controllati',
                  report.checkedFiles,
                  Icons.search,
                ),
                _buildMaintenanceRow(
                  'Già al sicuro',
                  report.alreadySafe,
                  Icons.verified,
                ),
                _buildMaintenanceRow(
                  'File consolidati',
                  report.consolidatedFiles,
                  Icons.security,
                ),
                _buildMaintenanceRow(
                  'File gestiti presenti',
                  report.managedFilesOnDisk,
                  Icons.folder,
                ),
                const Divider(height: 24),
                _buildMaintenanceRow(
                  'Possibili duplicati',
                  report.duplicateFiles,
                  Icons.content_copy,
                  warning: report.duplicateFiles > 0,
                ),
                _buildMaintenanceRow(
                  'File orfani',
                  report.orphanFiles,
                  Icons.delete_sweep_outlined,
                  warning: report.orphanFiles > 0,
                ),
                _buildMaintenanceRow(
                  'File mancanti',
                  report.missingFiles,
                  Icons.broken_image_outlined,
                  warning: report.missingFiles > 0,
                ),
                _buildMaintenanceRow(
                  'Errori',
                  report.errors,
                  Icons.error_outline,
                  warning: report.errors > 0,
                ),
                if (report.duplicateFiles > 0 || report.orphanFiles > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.4),
                      ),
                    ),
                    child: const Text(
                      'Sono stati individuati file potenzialmente '
                      'inutilizzati o duplicati. Per sicurezza, in questa '
                      'fase non è stato cancellato automaticamente nulla.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
                if (!report.hasWarnings) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '✅ Archivio in ordine. Non sono state rilevate '
                      'anomalie nei file gestiti dall’app.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Chiudi',
                style: TextStyle(color: AppColors.woodAccent),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFC62828),
          content: Text('Errore durante la manutenzione: $e'),
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
                            'Crea un archivio ZIP contenente tutte le misurazioni, il profilo, il diario, le foto e i documenti protetti.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
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
                            'Ripristina i dati e i file multimediali caricando un archivio ZIP precedentemente salvato.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
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

                  const SizedBox(height: 16),

                  // Card Consolidamento File
                  CozyWoodCard(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('🔒', style: TextStyle(fontSize: 24)),
                              SizedBox(width: 12),
                              Text(
                                'Manutenzione File',
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
                            'Controlla foto e documenti dell’app, consolida eventuali file esterni e individua file mancanti, orfani o duplicati.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: CozyButton(
                              text: 'Controlla File',
                              icon: Icons.health_and_safety,
                              onPressed: _isLoading ? null : _consolidaFile,
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

  Widget _buildMaintenanceRow(
    String label,
    int value,
    IconData icon, {
    bool warning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: warning ? Colors.orange.shade800 : AppColors.woodAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: warning ? Colors.orange.shade800 : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
