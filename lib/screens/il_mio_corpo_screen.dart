import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;
import 'package:gal/gal.dart';
import '../theme/app_theme.dart';
import '../widgets/cozy_widgets.dart';
import '../widgets/cozy_background.dart';
import '../theme/cozy_styles.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';
import '../models/body_measurement_entry.dart';
import '../models/progress_photo_entry.dart';
import '../models/blood_test_entry.dart';

class IlMioCorpoScreen extends StatefulWidget {
  const IlMioCorpoScreen({super.key});

  @override
  State<IlMioCorpoScreen> createState() => _IlMioCorpoScreenState();
}

class _IlMioCorpoScreenState extends State<IlMioCorpoScreen> with TickerProviderStateMixin {
  final LocalStorageService _storageService = LocalStorageService();
  final ImagePicker _picker = ImagePicker();
  late UserModel _user;
  late TabController _mainTabController;
  late TabController _measurementsTabController;

  // Controllers Peso e Altezza
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  // Controllers Misure Corporee
  final TextEditingController _waistController = TextEditingController();
  final TextEditingController _hipsController = TextEditingController();
  final TextEditingController _armsController = TextEditingController();
  final TextEditingController _legsController = TextEditingController();

  // Controllers Referti
  final TextEditingController _glycemiaController = TextEditingController();
  final TextEditingController _hba1cController = TextEditingController();
  final TextEditingController _insulinController = TextEditingController();

  final TextEditingController _ironController = TextEditingController();
  final TextEditingController _ferritinController = TextEditingController();

  final TextEditingController _potassiumController = TextEditingController();
  final TextEditingController _vitaminDController = TextEditingController();
  final TextEditingController _vitaminB12Controller = TextEditingController();

  final TextEditingController _astController = TextEditingController();
  final TextEditingController _altController = TextEditingController();
  final TextEditingController _ggtController = TextEditingController();

  final TextEditingController _hemoglobinController = TextEditingController();
  final TextEditingController _redBloodCellsController = TextEditingController();
  final TextEditingController _whiteBloodCellsController = TextEditingController();
  final TextEditingController _plateletsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = _storageService.getUser();
    _weightController.text = _user.currentWeight > 0 ? _user.currentWeight.toString() : '';
    _targetController.text = _user.targetWeight > 0 ? _user.targetWeight.toString() : '';
    _heightController.text = _user.height > 0 ? _user.height.toString() : '';
    
    _mainTabController = TabController(length: 4, vsync: this);
    _measurementsTabController = TabController(length: 4, vsync: this);
    
    _mainTabController.addListener(() {
        if (!_mainTabController.indexIsChanging) {
          setState(() {});
        }
    });
    
    _measurementsTabController.addListener(() {
        if (!_measurementsTabController.indexIsChanging) {
          setState(() {});
        }
    });
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _measurementsTabController.dispose();
    _weightController.dispose();
    _targetController.dispose();
    _heightController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    _armsController.dispose();
    _legsController.dispose();

    _glycemiaController.dispose();
    _hba1cController.dispose();
    _insulinController.dispose();
    _ironController.dispose();
    _ferritinController.dispose();
    _potassiumController.dispose();
    _vitaminDController.dispose();
    _vitaminB12Controller.dispose();
    _astController.dispose();
    _altController.dispose();
    _ggtController.dispose();
    _hemoglobinController.dispose();
    _redBloodCellsController.dispose();
    _whiteBloodCellsController.dispose();
    _plateletsController.dispose();

    super.dispose();
  }

  double? get _calculatedBMI {
    if (_user.height <= 0 || _user.currentWeight <= 0) return null;
    final heightInMeters = _user.height / 100.0;
    return _user.currentWeight / (heightInMeters * heightInMeters);
  }

  String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Sottopeso';
    if (bmi >= 18.5 && bmi < 25.0) return 'Normopeso';
    if (bmi >= 25.0 && bmi < 30.0) return 'Sovrappeso';
    if (bmi >= 30.0 && bmi < 35.0) return 'Obesità I';
    if (bmi >= 35.0 && bmi < 40.0) return 'Obesità II';
    return 'Obesità III';
  }

  Color getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25.0) return Colors.green;
    if (bmi < 30.0) return Colors.orange;
    if (bmi < 35.0) return Colors.deepOrange;
    if (bmi < 40.0) return Colors.red;
    return Colors.purple;
  }
  
  void _saveHeight() async {
    final cleanText = _heightController.text.replaceAll(',', '.');
    final newHeight = double.tryParse(cleanText);
    if (newHeight != null && newHeight > 0) {
      setState(() {
        _user.height = newHeight;
      });
      await _storageService.saveUser(_user);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('📏 Altezza e BMI aggiornati!'),
        ),
      );
    }
  }

  void _saveWeight() async {
    final cleanText = _weightController.text.replaceAll(',', '.');
    final newWeight = double.tryParse(cleanText);
    if (newWeight != null && newWeight > 0) {
      await _storageService.addWeightEntry(newWeight);
      setState(() {
        _user = _storageService.getUser();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('✨ Rilevazione peso aggiornata!'),
        ),
      );
    }
  }

  void _saveMeasurement({
    double? waist,
    double? hips,
    double? arms,
    double? thighs,
    double? legs,
    double? chest,
  }) async {
    final entry = BodyMeasurementEntry(
      date: DateTime.now(),
      waist: waist,
      hips: hips,
      arms: arms,
      thighs: thighs ?? legs,
      chest: chest,
    );
    
    await _storageService.addBodyMeasurement(entry);
    setState(() {});

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('📐 Misura registrata con successo!'),
      ),
    );
  }

  void _showEditTargetDialog() {
    _targetController.text = _user.targetWeight.toString();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFDF6E3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF8B5A2B), width: 2),
          ),
          title: const Text(
            'Modifica Obiettivo Peso',
            style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          content: TextField(
            key: const ValueKey('target_input_field'),
            controller: _targetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: CozyStyles.cozyInputDecoration('Nuovo Obiettivo (kg)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.woodAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final cleanText = _targetController.text.replaceAll(',', '.');
                final newTarget = double.tryParse(cleanText);
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
  
  Future<void> _pickAndSavePhoto(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (image != null) {
      final appDir = await path_provider.getApplicationDocumentsDirectory();
      final String fileName = 'body_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File savedImage = await File(image.path).copy('${appDir.path}/$fileName');

      final newPhoto = ProgressPhotoEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        imagePath: fileName,
      );

      await Gal.putImage(savedImage.path);
      await _storageService.addProgressPhoto(newPhoto);
      setState(() {});
    }
  }
  
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFDF6E3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0xFF8B5A2B), width: 1.5),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          children: [
            const ListTile(
              title: Text(
                'Aggiungi Foto Progressi',
                style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.woodAccent),
              title: const Text('Scatta una foto', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _pickAndSavePhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.woodAccent),
              title: const Text('Scegli dalla galleria', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _pickAndSavePhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    return CozyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true, // Estende il body dietro l'AppBar come nella mappa
        appBar: AppBar(
          backgroundColor: Colors.transparent, // AppBar trasparente
          elevation: 0,
          title: const Text('Il Mio Corpo', style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold)),
          bottom: TabBar(
            controller: _mainTabController,
            indicatorColor: AppColors.woodAccent,
            indicatorWeight: 3,
            labelColor: AppColors.woodAccent,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold),
            tabs: const [
              Tab(icon: Icon(Icons.monitor_weight), text: 'Peso'),
              Tab(icon: Icon(Icons.straighten), text: 'Misure'),
              Tab(icon: Icon(Icons.bloodtype), text: 'Analisi'),
              Tab(icon: Icon(Icons.photo_camera_outlined), text: 'Foto'),
            ],
          ),
        ),
        body: Stack(
          children: [
            // Contenuto delle tab traslato in basso per non coprire l'AppBar con TabBar
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 84.0,
              ),
              child: TabBarView(
                controller: _mainTabController,
                children: [
                  _buildWeightAndBMITab(),
                  _buildBodyMeasurementsTab(),
                  _buildBloodTab(),
                  _buildPhotoGalleryTab(),
                ],
              ),
            ),

            // Contatore rupie in alto a destra (stessa posizione e stile della mappa)
            Positioned(
              top: MediaQuery.of(context).padding.top - 18,
              left: 42.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CurrencyBadge(
                      icon: Icons.favorite,
                      iconColor: AppColors.heartRed,
                      value: '${_user.currentHearts}',
                    ),
                    /*
                    const SizedBox(width: 12),
                    CurrencyBadge(
                      icon: Icons.diamond,
                      iconColor: AppColors.rupeeGreen,
                      value: '${_user.coins}',
                    ),
                    */
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: _mainTabController.index == 3
        ? FloatingActionButton.extended(
          onPressed: _showImageSourceDialog,
          icon: const Icon(Icons.add_a_photo),
          label: const Text('Nuova Foto'),
          backgroundColor: AppColors.woodAccent,
          foregroundColor: Colors.white,
        )
        : null,
      ),
    );
  }

  // TAB 1: PESO E BMI
  Widget _buildWeightAndBMITab() {
    final bmi = _calculatedBMI;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CozyWoodCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn('Attuale', '${_user.currentWeight} kg'),
                const Icon(Icons.arrow_forward, color: AppColors.woodAccent),
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

          CozyWoodCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calcolo BMI (Indice di Massa Corporea)',
                  style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('height_input_field'),
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: CozyStyles.cozyInputDecoration('Altezza (cm)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CozyButton(
                      text: 'Aggiorna',
                      icon: Icons.height,
                      onPressed: _saveHeight,
                    ),
                  ],
                ),
                if (bmi != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'BMI: ${bmi.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    getBMICategory(bmi),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: getBMIColor(bmi),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          CozyWoodCard(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('weight_input_field'),
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: CozyStyles.cozyInputDecoration('Nuovo Peso (kg)'),
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
          CozyWoodCard(
            padding: const EdgeInsets.only(top: 16, right: 16, bottom: 8, left: 8),
            child: SizedBox(
              height: 220,
              child: _buildWeightGraph(),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: MISURE CORPOREE
  Widget _buildBodyMeasurementsTab() {
    final List<BodyMeasurementEntry> history = _storageService.getBodyMeasurementsHistory();
    final tabs = ['Vita', 'Fianchi', 'Braccia', 'Gambe'];
    
    final currentIndex = _measurementsTabController.index;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: List.generate(tabs.length, (index) {
              final isSelected = currentIndex == index;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: CozyButton(
                    text: tabs[index],
                    isSelected: isSelected, // Passiamo semplicemente lo stato!
                    onPressed: () {
                      _measurementsTabController.animateTo(index);
                    },
                  ),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _measurementsTabController,
            children: [
              _buildSingleMeasurementView('Vita', _waistController, history, (val) => _saveMeasurement(waist: val), (e) => e.waist),
              _buildSingleMeasurementView('Fianchi', _hipsController, history, (val) => _saveMeasurement(hips: val), (e) => e.hips),
              _buildSingleMeasurementView('Braccia', _armsController, history, (val) => _saveMeasurement(arms: val), (e) => e.arms),
              _buildSingleMeasurementView('Gambe', _legsController, history, (val) => _saveMeasurement(legs: val), (e) => e.legs),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSingleMeasurementView(
    String title,
    TextEditingController controller,
    List<BodyMeasurementEntry> history,
    Function(double) onSave,
    double? Function(BodyMeasurementEntry) valueExtractor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CozyWoodCard(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: ValueKey('input_$title'),
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: CozyStyles.cozyInputDecoration('Misura $title (cm)'),
                  ),
                ),
                const SizedBox(width: 12),
                CozyButton(
                  text: 'Salva',
                  icon: Icons.add,
                  onPressed: () {
                    final cleanText = controller.text.replaceAll(',', '.');
                    final val = double.tryParse(cleanText);
                    if (val != null && val > 0) {
                      onSave(val);
                      controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Andamento $title',
            style: const TextStyle(fontFamily: 'Serif', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          CozyWoodCard(
            padding: const EdgeInsets.only(top: 16, right: 16, bottom: 8, left: 8),
            child: SizedBox(
              height: 220,
              child: _buildMeasurementGraph(history, valueExtractor, title),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3: VALORI EMATICI
  Widget _buildBloodTab() {
    final history = _storageService.getBloodTestsHistory();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inserisci Nuovi Esami',
            style: TextStyle(
              fontFamily: 'Serif',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          _buildExpansionWoodSection(
            title: 'Glicemia & Insulina',
            children: [
              _buildBloodField(_glycemiaController, 'Glicemia', 'mg/dL'),
              const SizedBox(height: 10),
              _buildBloodField(_hba1cController, 'Emoglobina Glicata (HbA1c)', '%'),
              const SizedBox(height: 10),
              _buildBloodField(_insulinController, 'Insulina', 'µIU/mL'),
            ],
          ),
          const SizedBox(height: 10),

          _buildExpansionWoodSection(
            title: 'Assetto Marziale (Ferro)',
            children: [
              _buildBloodField(_ironController, 'Sideremia / Ferro', 'µg/dL'),
              const SizedBox(height: 10),
              _buildBloodField(_ferritinController, 'Ferritina', 'ng/mL'),
            ],
          ),
          const SizedBox(height: 10),

          _buildExpansionWoodSection(
            title: 'Vitamine ed Elettroliti',
            children: [
              _buildBloodField(_potassiumController, 'Potassio', 'mEq/L'),
              const SizedBox(height: 10),
              _buildBloodField(_vitaminDController, 'Vitamina D', 'ng/mL'),
              const SizedBox(height: 10),
              _buildBloodField(_vitaminB12Controller, 'Vitamina B12', 'pg/mL'),
            ],
          ),
          const SizedBox(height: 10),

          _buildExpansionWoodSection(
            title: 'Funzionalità Epatica',
            children: [
              _buildBloodField(_astController, 'AST (GOT)', 'U/L'),
              const SizedBox(height: 10),
              _buildBloodField(_altController, 'ALT (GPT)', 'U/L'),
              const SizedBox(height: 10),
              _buildBloodField(_ggtController, 'GGT', 'U/L'),
            ],
          ),
          const SizedBox(height: 10),

          _buildExpansionWoodSection(
            title: 'Emocromo',
            children: [
              _buildBloodField(_hemoglobinController, 'Emoglobina', 'g/dL'),
              const SizedBox(height: 10),
              _buildBloodField(_redBloodCellsController, 'Globuli Rossi', 'x10^6/µL'),
              const SizedBox(height: 10),
              _buildBloodField(_whiteBloodCellsController, 'Globuli Bianchi', 'x10^3/µL'),
              const SizedBox(height: 10),
              _buildBloodField(_plateletsController, 'Piastrine', 'x10^3/µL'),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: CozyButton(
              text: 'Salva Analisi del Sangue',
              icon: Icons.bookmark_add,
              onPressed: _saveBloodTest,
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Storico Esami Registrati',
            style: TextStyle(
              fontFamily: 'Serif',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          if (history.isEmpty)
            const CozyWoodCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Nessun esame salvato finora.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                final dateStr =
                    "${entry.date.day.toString().padLeft(2, '0')}/${entry.date.month.toString().padLeft(2, '0')}/${entry.date.year}";

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: CozyWoodCard(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      onTap: () => _showBloodTestDetailsDialog(entry),
                      title: Text(
                        'Analisi del $dateStr',
                        style: const TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        'Glicemia: ${entry.glycemia ?? "-"} | Vit. D: ${entry.vitaminD ?? "-"} | Ferro: ${entry.iron ?? "-"}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () async {
                          await _storageService.deleteBloodTestEntry(entry.date.toIso8601String().split('T')[0]);
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // TAB 4: FOTO GALLERIA
  Widget _buildPhotoGalleryTab() {
    final List<ProgressPhotoEntry> photos = _storageService.getProgressPhotosHistory();

    if (photos.isEmpty) {
      return Center(
        child: CozyWoodCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.photo_library_outlined, size: 54, color: AppColors.textSecondary),
              SizedBox(height: 12),
              Text(
                'Nessuna foto salvata',
                style: TextStyle(fontFamily: 'Serif', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              SizedBox(height: 6),
              Text(
                'Scatta o carica uno scatto per tracciare i tuoi progressi visivi!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0), // Margine esterno uniforme per tutta la griglia
      itemCount: photos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final photo = photos[index];
        final day = photo.date.day.toString().padLeft(2, '0');
        final month = photo.date.month.toString().padLeft(2, '0');
        final year = photo.date.year;
        final hour = photo.date.hour.toString().padLeft(2, '0');
        final minute = photo.date.minute.toString().padLeft(2, '0');
        final formattedDate = "$day/$month/$year - $hour:$minute";
        
        return GestureDetector(
          onTap: () => _showPhotoDetailDialog(photo),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF8B5A2B), width: 1.5),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildSafeImage(photo.imagePath, fit: BoxFit.cover),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    color: Colors.black.withOpacity(0.7),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            await _storageService.deleteProgressPhoto(photo.id);
                            setState(() {});
                          },
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // --- HELPER WIDGETS ---
  Widget _buildExpansionWoodSection({required String title, required List<Widget> children}) {
    return CozyWoodCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            title,
            style: const TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          iconColor: AppColors.woodAccent,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(children: children),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodField(TextEditingController controller, String label, String unit) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: CozyStyles.cozyInputDecoration('$label ($unit)'),
    );
  }

  Widget _buildMeasurementGraph(
    List<BodyMeasurementEntry> history,
    double? Function(BodyMeasurementEntry) valueExtractor,
    String unitLabel,
  ) {
    final validEntries = history
        .where((e) => valueExtractor(e) != null && valueExtractor(e)! > 0)
        .toList();

    validEntries.sort((a, b) => a.date.compareTo(b.date));

    if (validEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.show_chart, size: 36, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(
              'Nessuna misurazione di $unitLabel presente.\nInserisci il primo valore per attivare il grafico!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final DateTime startDate = validEntries.first.date;
    final DateTime endDate = validEntries.last.date;

    final List<FlSpot> spots = validEntries.map((entry) {
      final double xValue = entry.date.difference(startDate).inHours / 24.0;
      return FlSpot(xValue, valueExtractor(entry)!);
    }).toList();

    final double totalDaysDifference = endDate.difference(startDate).inHours / 24.0;
    final double minX = -1.0;
    final double maxX = totalDaysDifference + 1.0;

    final List<double> values = validEntries.map((e) => valueExtractor(e)!).toList();
    final double minValue = values.reduce((a, b) => a < b ? a : b);
    final double maxValue = values.reduce((a, b) => a > b ? a : b);

    final double minY = (minValue == maxValue) ? minValue - 5.0 : minValue - 2.0;
    final double maxY = (minValue == maxValue) ? maxValue + 5.0 : maxValue + 2.0;

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final entry = validEntries.reduce((a, b) {
                  final diffA = (a.date.difference(startDate).inHours / 24.0 - spot.x).abs();
                  final diffB = (b.date.difference(startDate).inHours / 24.0 - spot.x).abs();
                  return diffA < diffB ? a : b;
                });
                final dateStr = '${entry.date.day}/${entry.date.month}';
                return LineTooltipItem(
                  '${valueExtractor(entry)!.toStringAsFixed(1)} cm\n$dateStr',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                final String formatted = (value % 1 == 0)
                    ? value.toInt().toString()
                    : value.toStringAsFixed(1);
                return Text(
                  '$formatted cm',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (maxX - minX) > 10 ? ((maxX - minX) / 5) : 1.0,
              getTitlesWidget: (value, meta) {
                final DateTime calculatedDate = startDate.add(Duration(hours: (value * 24).round()));
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    '${calculatedDate.day}/${calculatedDate.month}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.disabled.withOpacity(0.3)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: validEntries.length > 2,
            color: AppColors.woodAccent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.woodAccent.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightGraph() {
    final List<WeightEntry> history = _storageService.getWeightHistory();

    if (history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 36, color: AppColors.textSecondary),
            SizedBox(height: 8),
            Text(
              'Nessuna registrazione presente.\nInserisci il tuo primo peso per attivare il grafico!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    history.sort((a, b) => a.date.compareTo(b.date));

    final DateTime startDate = history.first.date;
    final DateTime endDate = history.last.date;

    final List<FlSpot> spots = history.map((entry) {
      final double xValue = entry.date.difference(startDate).inHours / 24.0;
      return FlSpot(xValue, entry.weight);
    }).toList();

    final double totalDaysDifference = endDate.difference(startDate).inHours / 24.0;
    final double minX = -1.0; 
    final double maxX = totalDaysDifference + 1.0;

    final List<double> weights = history.map((e) => e.weight).toList();
    final double minWeight = weights.reduce((a, b) => a < b ? a : b);
    final double maxWeight = weights.reduce((a, b) => a > b ? a : b);
    
    final double minY = (minWeight == maxWeight) ? minWeight - 5.0 : minWeight - 2.0;
    final double maxY = (minWeight == maxWeight) ? maxWeight + 5.0 : maxWeight + 2.0;

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final entry = history.reduce((a, b) {
                  final diffA = (a.date.difference(startDate).inHours / 24.0 - spot.x).abs();
                  final diffB = (b.date.difference(startDate).inHours / 24.0 - spot.x).abs();
                  return diffA < diffB ? a : b;
                });
                final dateStr = '${entry.date.day}/${entry.date.month}';
                return LineTooltipItem(
                  '${entry.weight.toStringAsFixed(1)} kg\n$dateStr',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                final String formatted = (value % 1 == 0)
                    ? value.toInt().toString()
                    : value.toStringAsFixed(1);
                return Text(
                  '$formatted kg',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (maxX - minX) > 10 ? ((maxX - minX) / 5) : 1.0,
              getTitlesWidget: (value, meta) {
                final DateTime calculatedDate = startDate.add(Duration(hours: (value * 24).round()));
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    '${calculatedDate.day}/${calculatedDate.month}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.disabled.withOpacity(0.3)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: history.length > 2,
            color: AppColors.woodAccent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.woodAccent.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }

  void _saveBloodTest() async {
    final entry = BloodTestEntry(
      id: DateTime.now().toIso8601String(),
      date: DateTime.now(),
      glycemia: double.tryParse(_glycemiaController.text.replaceAll(',', '.')),
      hba1c: double.tryParse(_hba1cController.text.replaceAll(',', '.')),
      insulin: double.tryParse(_insulinController.text.replaceAll(',', '.')),
      iron: double.tryParse(_ironController.text.replaceAll(',', '.')),
      ferritin: double.tryParse(_ferritinController.text.replaceAll(',', '.')),
      potassium: double.tryParse(_potassiumController.text.replaceAll(',', '.')),
      vitaminD: double.tryParse(_vitaminDController.text.replaceAll(',', '.')),
      vitaminB12: double.tryParse(_vitaminB12Controller.text.replaceAll(',', '.')),
      ast: double.tryParse(_astController.text.replaceAll(',', '.')),
      alt: double.tryParse(_altController.text.replaceAll(',', '.')),
      ggt: double.tryParse(_ggtController.text.replaceAll(',', '.')),
      hemoglobin: double.tryParse(_hemoglobinController.text.replaceAll(',', '.')),
      redBloodCells: double.tryParse(_redBloodCellsController.text.replaceAll(',', '.')),
      whiteBloodCells: double.tryParse(_whiteBloodCellsController.text.replaceAll(',', '.')),
      platelets: double.tryParse(_plateletsController.text.replaceAll(',', '.')),
    );

    await _storageService.addBloodTestEntry(entry);

    _glycemiaController.clear();
    _hba1cController.clear();
    _insulinController.clear();
    _ironController.clear();
    _ferritinController.clear();
    _potassiumController.clear();
    _vitaminDController.clear();
    _vitaminB12Controller.clear();
    _astController.clear();
    _altController.clear();
    _ggtController.clear();
    _hemoglobinController.clear();
    _redBloodCellsController.clear();
    _whiteBloodCellsController.clear();
    _plateletsController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('🩸 Analisi del sangue salvate con successo!'),
        ),
      );
      setState(() {});
    }
  }

  void _showBloodTestDetailsDialog(BloodTestEntry entry) {
    final dateStr =
        "${entry.date.day.toString().padLeft(2, '0')}/${entry.date.month.toString().padLeft(2, '0')}/${entry.date.year}";

    final Map<String, String> valuesMap = {
      if (entry.glycemia != null) 'Glicemia': '${entry.glycemia} mg/dL',
      if (entry.hba1c != null) 'Emoglobina Glicata': '${entry.hba1c} %',
      if (entry.insulin != null) 'Insulina': '${entry.insulin} µIU/mL',
      if (entry.iron != null) 'Sideremia (Ferro)': '${entry.iron} µg/dL',
      if (entry.ferritin != null) 'Ferritina': '${entry.ferritin} ng/mL',
      if (entry.potassium != null) 'Potassio': '${entry.potassium} mEq/L',
      if (entry.vitaminD != null) 'Vitamina D': '${entry.vitaminD} ng/mL',
      if (entry.vitaminB12 != null) 'Vitamina B12': '${entry.vitaminB12} pg/mL',
      if (entry.ast != null) 'AST (GOT)': '${entry.ast} U/L',
      if (entry.alt != null) 'ALT (GPT)': '${entry.alt} U/L',
      if (entry.ggt != null) 'GGT': '${entry.ggt} U/L',
      if (entry.hemoglobin != null) 'Emoglobina': '${entry.hemoglobin} g/dL',
      if (entry.redBloodCells != null) 'Globuli Rossi': '${entry.redBloodCells} x10^6/µL',
      if (entry.whiteBloodCells != null) 'Globuli Bianchi': '${entry.whiteBloodCells} x10^3/µL',
      if (entry.platelets != null) 'Piastrine': '${entry.platelets} x10^3/µL',
    };

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFDF6E3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF8B5A2B), width: 2),
          ),
          title: Text(
            'Analisi del $dateStr',
            style: const TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: valuesMap.isEmpty
                ? const Text('Nessun valore registrato per questo referto.')
                : ListView(
                    shrinkWrap: true,
                    children: valuesMap.entries.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.key, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                            Text(item.value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.woodAccent)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Chiudi', style: TextStyle(color: AppColors.woodAccent)),
            ),
          ],
        );
      },
    );
  }

  void _showPhotoDetailDialog(ProgressPhotoEntry photo) {
    final day = photo.date.day.toString().padLeft(2, '0');
    final month = photo.date.month.toString().padLeft(2, '0');
    final year = photo.date.year;
    final hour = photo.date.hour.toString().padLeft(2, '0');
    final minute = photo.date.minute.toString().padLeft(2, '0');
    
    final formattedDate = "$day/$month/$year alle $hour:$minute";
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Foto del $formattedDate',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Flexible(
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 4,
                      child: _buildSafeImage(photo.imagePath, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSafeImage(String imagePathOrName, {BoxFit fit = BoxFit.cover}) {
    return FutureBuilder<Directory>(
      future: path_provider.getApplicationDocumentsDirectory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            color: Colors.grey[200],
            child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }

        final appDir = snapshot.data!;
        final fileName = path.basename(imagePathOrName.replaceFirst('file://', ''));
        final fullPath = '${appDir.path}/$fileName';
        final file = File(fullPath);

        if (!file.existsSync()) {
          return Container(
            color: Colors.grey[300],
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_outlined, color: Colors.grey, size: 36),
                SizedBox(height: 4),
                Text('Foto non trovata', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          );
        }

        return Image.file(
          file,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, color: Colors.grey, size: 36),
            );
          },
        );
      },
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
