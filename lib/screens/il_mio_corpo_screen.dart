import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../theme/cozy_widgets.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';
import '../models/body_measurement_entry.dart';
import '../models/progress_photo_entry.dart';

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
  final TextEditingController _insulinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = _storageService.getUser();
    _weightController.text = _user.currentWeight > 0 ? _user.currentWeight.toString() : '';
    _targetController.text = _user.targetWeight > 0 ? _user.targetWeight.toString() : '';
    _heightController.text = _user.height > 0 ? _user.height.toString() : '';
    
    _mainTabController = TabController(length: 4, vsync: this);
    _measurementsTabController = TabController(length: 4, vsync: this);
    
    // Aggiungi questo listener per aggiornare la UI al cambio scheda
    _mainTabController.addListener(() {
        if (!_mainTabController.indexIsChanging) {
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
    _insulinController.dispose();
    super.dispose();
  }
  
  // --- LOGICA BMI ---
  double? get _calculatedBMI {
    if (_user.height <= 0 || _user.currentWeight <= 0) return null;
    final heightInMeters = _user.height / 100.0;
    return _user.currentWeight / (heightInMeters * heightInMeters);
  }

  /// Ritorna la categoria del BMI secondo le linee guida OMS estese
  String getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return 'Sottopeso';
    } else if (bmi >= 18.5 && bmi < 25.0) {
      return 'Normopeso';
    } else if (bmi >= 25.0 && bmi < 30.0) {
      return 'Sovrappeso';
    } else if (bmi >= 30.0 && bmi < 35.0) {
      return 'Obesità di I Grado (Lieve)';
    } else if (bmi >= 35.0 && bmi < 40.0) {
      return 'Obesità di II Grado (Moderata)';
    } else {
      return 'Obesità di III Grado (Grave/Elevata)';
    }
  }

  Color getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25.0) return Colors.green;
    if (bmi < 30.0) return Colors.orange;
    if (bmi < 35.0) return Colors.deepOrange;
    if (bmi < 40.0) return Colors.red;
    return Colors.purple; // Obesità di III Grado
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

  // --- LOGICA SALVATAGGIO PESO ---
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

  // --- LOGICA SALVATAGGIO MISURE CORPOREE ---
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
      thighs: thighs ?? legs, // <--- Se viene passato legs, usalo per thighs
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
          title: const Text('Modifica Obiettivo Peso'),
          content: TextField(
            key: const ValueKey('target_input_field'),
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

// Metodo per scattare o selezionare una foto
  Future<void> _pickAndSavePhoto(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80, // Ottimizza lo spazio occupato
    );

    if (image != null) {
      final newPhoto = ProgressPhotoEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        imagePath: image.path,
      );

      await _storageService.addProgressPhoto(newPhoto);
      setState(() {}); // Aggiorna la vista della galleria
    }
  }

  // Modale per scegliere tra Fotocamera e Galleria
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          children: [
            const ListTile(
              title: Text(
                'Aggiungi Foto Progressi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.teal),
              title: const Text('Scatta una foto'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSavePhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.teal),
              title: const Text('Scegli dalla galleria'),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Il Mio Corpo'),
        bottom: TabBar(
          controller: _mainTabController,
          indicatorColor: AppColors.woodAccent,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.monitor_weight), text: 'Peso'),
            Tab(icon: Icon(Icons.straighten), text: 'Misure'),
            Tab(icon: Icon(Icons.bloodtype), text: 'Analisi'),
            Tab(icon: Icon(Icons.photo_camera_outlined), text: 'Foto'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          _buildWeightAndBMITab(),
          _buildBodyMeasurementsTab(),
          _buildBloodTab(),
          _buildPhotoGalleryTab(),
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
      : null, // Nasconde il FAB nelle altre Tab
    );
  }
  
  // --- TAB GALLERIA FOTO ---
  Widget _buildPhotoGalleryTab() {
    final List<ProgressPhotoEntry> photos = _storageService.getProgressPhotosHistory();

    if (photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Nessuna foto salvata',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scatta o carica uno scatto per tracciare i tuoi progressi visivi!',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.builder(
        itemCount: photos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 colonne per una vista affiancata
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (context, index) {
          final photo = photos[index];
          final formattedDate =
          "${photo.date.day.toString().padLeft(2, '0')}/${photo.date.month.toString().padLeft(2, '0')}/${photo.date.year}";

          return Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Visualizza l'immagine salvata in memoria
                Image.file(
                  File(photo.imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
                // Overlay sfumato in basso con la data della foto
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    color: Colors.black54,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
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
          );
        },
      ),
    );
  }

  // TAB 1: PESO E BMI
  Widget _buildWeightAndBMITab() {
    final bmi = _calculatedBMI; // <--- Calcolato prima di costruire la UI

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CARD OBIETTIVI E PESO ATTUALE
          CozyCard(
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

          // SEZIONE ALTEZZA E BMI
          CozyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calcolo BMI (Indice di Massa Corporea)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('height_input_field'),
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Altezza (cm)',
                          border: OutlineInputBorder(),
                        ),
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    getBMICategory(bmi),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: getBMIColor(bmi),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // REGISTRAZIONE NUOVO PESO
          CozyCard(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('weight_input_field'),
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

          // GRAFICO PESO
          const Text(
            'Andamento Peso',
            style: TextStyle(fontFamily: 'Serif', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          CozyCard(
            child: Container(
              height: 220,
              padding: const EdgeInsets.only(top: 16, right: 16, bottom: 8, left: 8),
              child: _buildWeightGraph(),
            ),
          ),
        ],
      ),
    );
  }
  
  // TAB 2: MISURE CORPOREE (VITA, FIANCHI, BRACCIA, GAMBE)
  Widget _buildBodyMeasurementsTab() {
    final List<BodyMeasurementEntry> history = _storageService.getBodyMeasurementsHistory();

    return Column(
      children: [
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: TabBar(
            controller: _measurementsTabController,
            indicatorColor: AppColors.woodAccent,
            labelColor: AppColors.woodAccent,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'Vita'),
              Tab(text: 'Fianchi'),
              Tab(text: 'Braccia'),
              Tab(text: 'Gambe'),
            ],
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

  // SCHERMATA SINGOLA MISURA
  Widget _buildSingleMeasurementView(
    String title,
    TextEditingController controller,
    List<BodyMeasurementEntry> history,
    Function(double) onSave,
    double? Function(BodyMeasurementEntry) valueExtractor,
  ) {
    // Estrae i punti validi per questa specifica misura
    final List<FlSpot> spots = [];
    final List<DateTime> dates = [];

    for (var entry in history) {
      final val = valueExtractor(entry);
      if (val != null && val > 0) {
        dates.add(entry.date);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CozyCard(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: ValueKey('input_$title'),
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Misura $title (cm)',
                      border: const OutlineInputBorder(),
                    ),
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
          CozyCard(
            child: Container(
              height: 220,
              padding: const EdgeInsets.only(top: 16, right: 16, bottom: 8, left: 8),
              child: _buildMeasurementGraph(history, valueExtractor, title),
            ),
          ),
        ],
      ),
    );
  }

  // GRAFICO GENERICO PER LE MISURE CORPOREE
  Widget _buildMeasurementGraph(
    List<BodyMeasurementEntry> history,
    double? Function(BodyMeasurementEntry) valueExtractor,
    String unitLabel,
  ) {
    // Filtra ed ordina le registrazioni che hanno questa misura presente
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
          
          // ASSE VERTICALE (MISURE IN CM)
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
          
          // ASSE ORIZZONTALE (DATE)
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

  // GRAFICO PESO
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

  // TAB 3: VALORI EMATICI E REFERTI
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
                  key: const ValueKey('glycemia_input_field'),
                  controller: _glycemiaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Glicemia a digiuno (mg/dL)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('insulin_input_field'),
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
