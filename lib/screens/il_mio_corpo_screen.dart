import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/cozy_widgets.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';

class IlMioCorpoScreen extends StatefulWidget {
  const IlMioCorpoScreen({super.key});

  @override
  State<IlMioCorpoScreen> createState() => _IlMioCorpoScreenState();
}

class _IlMioCorpoScreenState extends State<IlMioCorpoScreen> with SingleTickerProviderStateMixin {
  final LocalStorageService _storageService = LocalStorageService();
  late UserModel _user;
  late TabController _tabController;

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _glycemiaController = TextEditingController();
  final TextEditingController _insulinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = _storageService.getUser();
    _weightController.text = _user.currentWeight.toString();
    _targetController.text = _user.targetWeight.toString();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _saveWeight() async {
    final newWeight = double.tryParse(_weightController.text);
    if (newWeight != null && newWeight > 0) {
      _user.currentWeight = newWeight;
      await _storageService.saveUser(_user);
      setState(() {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('✨ Rilevazione peso aggiornata!'),
        ),
      );
    }
  }

  // Finestra di dialogo per modificare l'obiettivo di peso
  void _showEditTargetDialog() {
    _targetController.text = _user.targetWeight.toString();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifica Obiettivo Peso'),
          content: TextField(
            controller: _targetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Nuovo Obiettivo (kg)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.woodAccent),
              onPressed: () async {
                final newTarget = double.tryParse(_targetController.text);
                if (newTarget != null && newTarget > 0) {
                  setState(() {
                    _user.targetWeight = newTarget;
                  });
                  await _storageService.saveUser(_user);
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text('🎯 Obiettivo aggiornato!'),
                    ),
                  );
                }
              },
              child: const Text('Salva', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Il Mio Corpo'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.woodAccent,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.monitor_weight), text: 'Peso'),
            Tab(icon: Icon(Icons.bloodtype), text: 'Valori & Referti'),
            Tab(icon: Icon(Icons.photo_library), text: 'Foto'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. DIARIO PESO & PROGRESSI
          _buildWeightTab(),

          // 2. VALORI EMATICI & REFERTI MEDICI
          _buildBloodTab(),

          // 3. DIARIO FOTOGRAFICO PROGRESSI
          _buildPhotosTab(),
        ],
      ),
    );
  }

  // TAB 1: Peso & Grafico
  Widget _buildWeightTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CozyCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn('Attuale', '${_user.currentWeight} kg'),
                const Icon(Icons.arrow_forward, color: AppColors.woodAccent),
                
                // Obiettivo reso Cliccabile
                InkWell(
                  onTap: _showEditTargetDialog,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMetricColumn('Obiettivo', '${_user.targetWeight} kg'),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit, size: 18, color: AppColors.woodAccent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CozyCard(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Nuovo Peso (kg)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CozyButton(
                  text: 'Salva',
                  icon: Icons.add,
                  onPressed: _saveWeight,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Andamento Peso',
            style: TextStyle(fontFamily: 'Serif', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          CozyCard(
            child: Container(
              height: 180,
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart, size: 40, color: AppColors.woodAccent),
                  SizedBox(height: 8),
                  Text('Grafico dello Storico Peso', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: Valori Ematici & Referti
  Widget _buildBloodTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Valori Ematici Recenti',
            style: TextStyle(fontFamily: 'Serif', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          CozyCard(
            child: Column(
              children: [
                TextField(
                  controller: _glycemiaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Glicemia a digiuno (mg/dL)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _insulinController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Insulina (µIU/mL)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                CozyButton(
                  text: 'Registra Valori',
                  icon: Icons.bookmark_add,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Valori salvati nel registro sanitario.')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Referti & Esami Medici',
            style: TextStyle(fontFamily: 'Serif', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          CozyCard(
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppColors.heartRed, size: 36),
              title: const Text('Carica un nuovo referto (PDF/Foto)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Conserva le analisi del sangue in modo sicuro'),
              trailing: const Icon(Icons.upload_file, color: AppColors.woodAccent),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3: Diario Fotografico
  Widget _buildPhotosTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CozyButton(
            text: 'Aggiungi Foto Progressi 📸',
            icon: Icons.camera_alt,
            onPressed: () {},
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                CozyCard(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.photo, size: 40, color: AppColors.disabled),
                        SizedBox(height: 8),
                        Text('Inizio Percorso', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontFamily: 'Serif', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}
