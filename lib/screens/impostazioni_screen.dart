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
      final conferma = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.background,
          title: const Text(
            'Manutenzione File',
            style: TextStyle(
              fontFamily: 'Serif',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'La manutenzione controllerà tutti i file gestiti '
            'dall’app, eliminerà i file non più utilizzati e '
            'rimuoverà eventuali copie duplicate dopo aver '
            'verificato i riferimenti salvati.\n\n'
            'Vuoi procedere?',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Annulla',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Procedi',
                style: TextStyle(
                  color: AppColors.woodAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      if (conferma != true) return;

      setState(() => _isLoading = true);

      final report = await _storageService.consolidateExternalFiles();

      if (!mounted) return;

      setState(() => _isLoading = false);

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.background,
          title: Row(
            children: [
              Icon(
                report.integrityVerified
                    ? Icons.verified_user
                    : Icons.warning_amber_rounded,
                color: report.integrityVerified
                    ? const Color(0xFF2E7D32)
                    : Colors.orange.shade800,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  report.integrityVerified
                      ? 'Manutenzione completata'
                      : 'Manutenzione da verificare',
                  style: const TextStyle(
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
                  'File iniziali',
                  report.managedFilesBefore,
                  Icons.folder_open,
                ),
                _buildMaintenanceRow(
                  'File finali',
                  report.managedFilesAfter,
                  Icons.folder,
                ),
                _buildMaintenanceRow(
                  'File referenziati univoci',
                  report.uniqueReferencedFiles,
                  Icons.link,
                ),
                _buildMaintenanceRow(
                  'File consolidati',
                  report.consolidatedFiles,
                  Icons.security,
                ),
                const Divider(height: 24),
                _buildMaintenanceRow(
                  'Gruppi duplicati rilevati',
                  report.duplicateGroups,
                  Icons.content_copy,
                ),
                _buildMaintenanceRow(
                  'Riferimenti aggiornati',
                  report.updatedReferences,
                  Icons.sync_alt,
                ),
                _buildMaintenanceRow(
                  'File eliminati',
                  report.deletedFiles,
                  Icons.delete_outline,
                ),
                _buildMaintenanceRow(
                  'Orfani eliminati',
                  report.deletedOrphanFiles,
                  Icons.delete_sweep_outlined,
                ),
                _buildMaintenanceRow(
                  'Copie duplicate eliminate',
                  report.deletedDuplicateFiles,
                  Icons.file_copy_outlined,
                ),
                const SizedBox(height: 12),
                Text(
                  'Spazio liberato: '
                  '${report.recoveredMegabytes.toStringAsFixed(2)} MB',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Divider(height: 24),
                _buildMaintenanceRow(
                  'Riferimenti non validi',
                  report.invalidReferences,
                  Icons.broken_image_outlined,
                  warning: report.invalidReferences > 0,
                ),
                _buildMaintenanceRow(
                  'Orfani residui',
                  report.remainingOrphans,
                  Icons.warning_amber,
                  warning: report.remainingOrphans > 0,
                ),
                _buildMaintenanceRow(
                  'Duplicati residui',
                  report.remainingDuplicates,
                  Icons.content_copy,
                  warning: report.remainingDuplicates > 0,
                ),
                _buildMaintenanceRow(
                  'Errori',
                  report.errors,
                  Icons.error_outline,
                  warning: report.errors > 0,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: report.integrityVerified
                        ? const Color(0xFF2E7D32).withValues(alpha: 0.10)
                        : Colors.orange.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    report.integrityVerified
                        ? '✓ Integrità verificata. Ogni file '
                            'gestito rimasto è referenziato e '
                            'non risultano copie duplicate.'
                        : report.cleanupAborted
                            ? 'Pulizia interrotta prima della '
                                'cancellazione perché è stata '
                                'rilevata un’incongruenza.'
                            : 'La verifica finale ha rilevato '
                                'una o più anomalie.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: report.integrityVerified
                          ? const Color(0xFF2E7D32)
                          : Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Chiudi',
                style: TextStyle(
                  color: AppColors.woodAccent,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC62828),
            content: Text(
              'Errore durante la manutenzione: $e',
            ),
          ),
        );
      }
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
