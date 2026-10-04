import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;
import 'package:saver_gallery/saver_gallery.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../theme/app_theme.dart';
import '../widgets/cozy_widgets.dart';
import '../widgets/cozy_background.dart';
import '../theme/cozy_styles.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';
import '../models/body_measurement_entry.dart';
import '../models/progress_photo_entry.dart';
import '../models/bloodurine_test_entry.dart';

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

  // Controllers Referti (Aggiornati con tutte le nuove grandezze)
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
  final TextEditingController _hematocritController = TextEditingController();
  final TextEditingController _mcvController = TextEditingController();
  final TextEditingController _neutrophilsController = TextEditingController();
  final TextEditingController _lymphocytesController = TextEditingController();

  final TextEditingController _totalCholesterolController = TextEditingController();
  final TextEditingController _hdlCholesterolController = TextEditingController();
  final TextEditingController _ldlCholesterolController = TextEditingController();
  final TextEditingController _triglyceridesController = TextEditingController();

  final TextEditingController _creatinineController = TextEditingController();
  final TextEditingController _gfrController = TextEditingController();

  final TextEditingController _ptController = TextEditingController();
  final TextEditingController _apttController = TextEditingController();
  final TextEditingController _fibrinogenController = TextEditingController();
  final TextEditingController _vesController = TextEditingController();

  // Controllers Esame Urine
  final TextEditingController _urineSpecificGravityController = TextEditingController();
  final TextEditingController _urinePhController = TextEditingController();
  final TextEditingController _urineProteinsController = TextEditingController();
  final TextEditingController _urineGlucoseController = TextEditingController();
  final TextEditingController _urineKetonesController = TextEditingController();
  final TextEditingController _urineHemoglobinController = TextEditingController();
  final TextEditingController _urineBilirubinController = TextEditingController();
  final TextEditingController _urineUrobilinogenController = TextEditingController();
  final TextEditingController _urineNitritesController = TextEditingController();
  final TextEditingController _urineLeukocytesController = TextEditingController();
  final TextEditingController _urineSedimentController = TextEditingController();

  // File temporaneo associato all'analisi corrente
  String? _tempBloodFilePath;

  // Tipo di metrica selezionata per il grafico degli esami del sangue
  String _selectedBloodChartMetric = 'glycemia';

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
    _hematocritController.dispose();
    _mcvController.dispose();
    _neutrophilsController.dispose();
    _lymphocytesController.dispose();
    _totalCholesterolController.dispose();
    _hdlCholesterolController.dispose();
    _ldlCholesterolController.dispose();
    _triglyceridesController.dispose();
    _creatinineController.dispose();
    _gfrController.dispose();
    _ptController.dispose();
    _apttController.dispose();
    _fibrinogenController.dispose();
    _vesController.dispose();
    _urineSpecificGravityController.dispose();
    _urinePhController.dispose();
    _urineProteinsController.dispose();
    _urineGlucoseController.dispose();
    _urineKetonesController.dispose();
    _urineHemoglobinController.dispose();
    _urineBilirubinController.dispose();
    _urineUrobilinogenController.dispose();
    _urineNitritesController.dispose();
    _urineLeukocytesController.dispose();
    _urineSedimentController.dispose();

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

      final bytes = await savedImage.readAsBytes();
      await SaverGallery.saveImage(bytes, fileName: fileName, skipIfExists: false);
      
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

  // --- GESTIONE REFERTI E IA ---
  void _showBloodFileSourceDialog() {
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
              title: Text('Carica Referto & Analizza IA', style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.woodAccent),
              title: const Text('Scatta una foto al referto', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _pickAndProcessBloodFile(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.woodAccent),
              title: const Text('Scegli dalla galleria foto', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _pickAndProcessBloodFile(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: AppColors.woodAccent),
              title: const Text('Scegli dai Documenti (PDF / File)', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _pickAndProcessBloodDocument();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndProcessBloodFile(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image != null) {
      if (!mounted) return;
      _processBloodFileBytes(await File(image.path).readAsBytes(), 'image/jpeg', 'jpg');
    }
  }

  Future<void> _pickAndProcessBloodDocument() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.isNotEmpty && result.single.path != null) {
        final filePath = result.single.path!;
        final fileBytes = await File(filePath).readAsBytes();
        final extension = path.extension(filePath).toLowerCase().replaceAll('.', '');
        final mimeType = extension == 'pdf' ? 'application/pdf' : 'image/jpeg';

        if (!mounted) return;
        _processBloodFileBytes(fileBytes, mimeType, extension.isEmpty ? 'jpg' : extension);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text('Errore nella selezione del file: $e')),
      );
    }
  }

  Future<void> _processBloodFileBytes(Uint8List bytes, String mimeType, String extension) async {
    final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: Center(
          child: CozyCard(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.woodAccent),
                  SizedBox(height: 16),
                  Text('🪄 L\'IA sta leggendo le analisi del sangue...', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final appDir = await path_provider.getApplicationDocumentsDirectory();
      final fileName = 'blood_test_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final File savedFile = File('${appDir.path}/$fileName');
      await savedFile.writeAsBytes(bytes);
      
      if (mimeType.startsWith('image/')) {
        await SaverGallery.saveImage(bytes, fileName: fileName, skipIfExists: false);
      }

      final model = GenerativeModel(
        model: 'gemini-3.6-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );

      const prompt = '''
      Analizza questo documento (referto di analisi del sangue e/o delle urine). Estrai i valori numerici o testuali corrispondenti a questi campi se presenti e restituisci unicamente un oggetto JSON valido con questa struttura esatta (usa null se il valore non è presente):
      {
        "glycemia": 0.0,
        "hba1c": 0.0,
        "insulin": 0.0,
        "iron": 0.0,
        "ferritin": 0.0,
        "potassium": 0.0,
        "vitaminD": 0.0,
        "vitaminB12": 0.0,
        "ast": 0.0,
        "alt": 0.0,
        "ggt": 0.0,
        "hemoglobin": 0.0,
        "redBloodCells": 0.0,
        "whiteBloodCells": 0.0,
        "platelets": 0.0,
        "hematocrit": 0.0,
        "mcv": 0.0,
        "neutrophils": 0.0,
        "lymphocytes": 0.0,
        "totalCholesterol": 0.0,
        "hdlCholesterol": 0.0,
        "ldlCholesterol": 0.0,
        "triglycerides": 0.0,
        "creatinine": 0.0,
        "gfr": 0.0,
        "pt": 0.0,
        "aptt": 0.0,
        "fibrinogen": 0.0,
        "ves": 0.0,
        "urineSpecificGravity": 0.0,
        "urinePh": 0.0,
        "urineProteins": 0.0,
        "urineGlucose": 0.0,
        "urineKetones": 0.0,
        "urineHemoglobin": 0.0,
        "urineBilirubin": 0.0,
        "urineUrobilinogen": 0.0,
        "urineNitrites": 0.0,
        "urineLeukocytes": 0.0,
        "urineSediment": ""
      }
      ''';

      int maxAttempts = 4;
      int delayMs = 1500;
      GenerateContentResponse? response;

      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          response = await model.generateContent([
              Content.multi([
                  TextPart(prompt),
                  DataPart(mimeType, bytes),
              ])
          ]);
          break;
        } catch (e) {
          if (attempt == maxAttempts) rethrow;
          await Future.delayed(Duration(milliseconds: delayMs));
          delayMs *= 2;
        }
      }

      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.of(context).pop();

      if (response != null && response.text != null) {
        final jsonString = response.text!;
        final Map<String, dynamic> parsedValues = jsonDecode(jsonString);

        setState(() {
            if (parsedValues['glycemia'] != null) _glycemiaController.text = parsedValues['glycemia'].toString();
            if (parsedValues['hba1c'] != null) _hba1cController.text = parsedValues['hba1c'].toString();
            if (parsedValues['insulin'] != null) _insulinController.text = parsedValues['insulin'].toString();
            if (parsedValues['iron'] != null) _ironController.text = parsedValues['iron'].toString();
            if (parsedValues['ferritin'] != null) _ferritinController.text = parsedValues['ferritin'].toString();
            if (parsedValues['potassium'] != null) _potassiumController.text = parsedValues['potassium'].toString();
            if (parsedValues['vitaminD'] != null) _vitaminDController.text = parsedValues['vitaminD'].toString();
            if (parsedValues['vitaminB12'] != null) _vitaminB12Controller.text = parsedValues['vitaminB12'].toString();
            if (parsedValues['ast'] != null) _astController.text = parsedValues['ast'].toString();
            if (parsedValues['alt'] != null) _altController.text = parsedValues['alt'].toString();
            if (parsedValues['ggt'] != null) _ggtController.text = parsedValues['ggt'].toString();
            if (parsedValues['hemoglobin'] != null) _hemoglobinController.text = parsedValues['hemoglobin'].toString();
            if (parsedValues['redBloodCells'] != null) _redBloodCellsController.text = parsedValues['redBloodCells'].toString();
            if (parsedValues['whiteBloodCells'] != null) _whiteBloodCellsController.text = parsedValues['whiteBloodCells'].toString();
            if (parsedValues['platelets'] != null) _plateletsController.text = parsedValues['platelets'].toString();
            if (parsedValues['hematocrit'] != null) _hematocritController.text = parsedValues['hematocrit'].toString();
            if (parsedValues['mcv'] != null) _mcvController.text = parsedValues['mcv'].toString();
            if (parsedValues['neutrophils'] != null) _neutrophilsController.text = parsedValues['neutrophils'].toString();
            if (parsedValues['lymphocytes'] != null) _lymphocytesController.text = parsedValues['lymphocytes'].toString();
            if (parsedValues['totalCholesterol'] != null) _totalCholesterolController.text = parsedValues['totalCholesterol'].toString();
            if (parsedValues['hdlCholesterol'] != null) _hdlCholesterolController.text = parsedValues['hdlCholesterol'].toString();
            if (parsedValues['ldlCholesterol'] != null) _ldlCholesterolController.text = parsedValues['ldlCholesterol'].toString();
            if (parsedValues['triglycerides'] != null) _triglyceridesController.text = parsedValues['triglycerides'].toString();
            if (parsedValues['creatinine'] != null) _creatinineController.text = parsedValues['creatinine'].toString();
            if (parsedValues['gfr'] != null) _gfrController.text = parsedValues['gfr'].toString();
            if (parsedValues['pt'] != null) _ptController.text = parsedValues['pt'].toString();
            if (parsedValues['aptt'] != null) _apttController.text = parsedValues['aptt'].toString();
            if (parsedValues['fibrinogen'] != null) _fibrinogenController.text = parsedValues['fibrinogen'].toString();
            if (parsedValues['ves'] != null) _vesController.text = parsedValues['ves'].toString();
            if (parsedValues['urineSpecificGravity'] != null) _urineSpecificGravityController.text = parsedValues['urineSpecificGravity'].toString();
            if (parsedValues['urinePh'] != null) _urinePhController.text = parsedValues['urinePh'].toString();
            if (parsedValues['urineProteins'] != null) _urineProteinsController.text = parsedValues['urineProteins'].toString();
            if (parsedValues['urineGlucose'] != null) _urineGlucoseController.text = parsedValues['urineGlucose'].toString();
            if (parsedValues['urineKetones'] != null) _urineKetonesController.text = parsedValues['urineKetones'].toString();
            if (parsedValues['urineHemoglobin'] != null) _urineHemoglobinController.text = parsedValues['urineHemoglobin'].toString();
            if (parsedValues['urineBilirubin'] != null) _urineBilirubinController.text = parsedValues['urineBilirubin'].toString();
            if (parsedValues['urineUrobilinogen'] != null) _urineUrobilinogenController.text = parsedValues['urineUrobilinogen'].toString();
            if (parsedValues['urineNitrites'] != null) _urineNitritesController.text = parsedValues['urineNitrites'].toString();
            if (parsedValues['urineLeukocytes'] != null) _urineLeukocytesController.text = parsedValues['urineLeukocytes'].toString();
            if (parsedValues['urineSediment'] != null) _urineSedimentController.text = parsedValues['urineSediment'].toString();
        });

        _tempBloodFilePath = fileName;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('✨ Valori letti con successo! Controllali e premi Salva Analisi.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text('Errore di connessione: $e')),
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
                  ],
                ),
              ),
            ),
          ],
        ),
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

          SizedBox(
            width: double.infinity,
            child: CozyButton(
              text: 'Andamento Peso',
              isSelected: true,
              onPressed: () {},
            ),
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
                    isSelected: isSelected,
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
          SizedBox(
            width: double.infinity,
            child: CozyButton(
              text: 'Andamento $title',
              isSelected: true,
              onPressed: () {},
            ),
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

  // --- METODI DI SUPPORTO PER IL GRAFICO DEGLI ESAMI DEL SANGUE ---
  double? _getBloodMetricValue(BloodUrineTestEntry entry, String metric) {
    switch (metric) {
      case 'glycemia': return entry.glycemia;
      case 'hba1c': return entry.hba1c;
      case 'insulin': return entry.insulin;
      case 'iron': return entry.iron;
      case 'ferritin': return entry.ferritin;
      case 'potassium': return entry.potassium;
      case 'vitaminD': return entry.vitaminD;
      case 'vitaminB12': return entry.vitaminB12;
      case 'ast': return entry.ast;
      case 'alt': return entry.alt;
      case 'ggt': return entry.ggt;
      case 'hemoglobin': return entry.hemoglobin;
      case 'redBloodCells': return entry.redBloodCells;
      case 'whiteBloodCells': return entry.whiteBloodCells;
      case 'platelets': return entry.platelets;
      case 'hematocrit': return entry.hematocrit;
      case 'mcv': return entry.mcv;
      case 'neutrophils': return entry.neutrophils;
      case 'lymphocytes': return entry.lymphocytes;
      case 'totalCholesterol': return entry.totalCholesterol;
      case 'hdlCholesterol': return entry.hdlCholesterol;
      case 'ldlCholesterol': return entry.ldlCholesterol;
      case 'triglycerides': return entry.triglycerides;
      case 'creatinine': return entry.creatinine;
      case 'gfr': return entry.gfr;
      case 'pt': return entry.pt;
      case 'aptt': return entry.aptt;
      case 'fibrinogen': return entry.fibrinogen;
      case 'ves': return entry.ves;
      case 'urineSpecificGravity': return entry.specificGravity;
      case 'urinePh': return entry.ph;
      case 'urineProteins': 
      return double.tryParse(entry.proteins?.toString() ?? '');
      case 'urineGlucose': 
      return double.tryParse(entry.urineGlucose?.toString() ?? '');
      case 'urineKetones': 
      return double.tryParse(entry.ketones?.toString() ?? '');
      case 'urineNitrites': 
      return double.tryParse(entry.nitrites?.toString() ?? '');
      case 'urineLeukocytes': 
      return double.tryParse(entry.leukocyteEsterase?.toString() ?? '');
      case 'urineHemoglobin': return entry.hemoglobin;
      case 'urineBilirubin': return entry.bilirubin;
      case 'urineUrobilinogen': return entry.urobilinogen;
      default: return null;
    }
  }

  String _getBloodMetricLabel(String metric) {
    switch (metric) {
      case 'glycemia': return 'Glicemia (mg/dL)';
      case 'hba1c': return 'Emoglobina Glicata (%)';
      case 'insulin': return 'Insulina (µIU/mL)';
      case 'iron': return 'Sideremia (µg/dL)';
      case 'ferritin': return 'Ferritina (ng/mL)';
      case 'potassium': return 'Potassio (mEq/L)';
      case 'vitaminD': return 'Vitamina D (ng/mL)';
      case 'vitaminB12': return 'Vitamina B12 (pg/mL)';
      case 'ast': return 'AST / GOT (U/L)';
      case 'alt': return 'ALT / GPT (U/L)';
      case 'ggt': return 'GGT (U/L)';
      case 'hemoglobin': return 'Emoglobina (g/dL)';
      case 'redBloodCells': return 'Globuli Rossi (x10^6/µL)';
      case 'whiteBloodCells': return 'Globuli Bianchi (x10^3/µL)';
      case 'platelets': return 'Piastrine (x10^3/µL)';
      case 'hematocrit': return 'Ematocrito (%)';
      case 'mcv': return 'MCV (fL)';
      case 'neutrophils': return 'Neutrofili (%)';
      case 'lymphocytes': return 'Linfociti (%)';
      case 'totalCholesterol': return 'Colesterolo Totale (mg/dL)';
      case 'hdlCholesterol': return 'Colesterolo HDL (mg/dL)';
      case 'ldlCholesterol': return 'Colesterolo LDL (mg/dL)';
      case 'triglycerides': return 'Trigliceridi (mg/dL)';
      case 'creatinine': return 'Creatinina (mg/dL)';
      case 'gfr': return 'GFR (mL/min)';
      case 'pt': return 'PT (sec)';
      case 'aptt': return 'APTT (sec)';
      case 'fibrinogen': return 'Fibrinogeno (mg/dL)';
      case 'ves': return 'VES (mm/h)';
      case 'urineSpecificGravity': return 'Peso Specifico Urine';
      case 'urinePh': return 'pH Urine';
      case 'urineProteins': return 'Proteine Urine';
      case 'urineGlucose': return 'Glucosio Urine';
      case 'urineKetones': return 'Corpi Chetonici';
      case 'urineHemoglobin': return 'Emoglobina Urine';
      case 'urineBilirubin': return 'Bilirubina Urine';
      case 'urineUrobilinogen': return 'Urobilinogeno';
      case 'urineNitrites': return 'Nitriti';
      case 'urineLeukocytes': return 'Leucociti Urine';
      default: return 'Valore';
    }
  }

  Widget _buildBloodTestHistoryChart() {
    final allEntries = _storageService.getBloodTestsHistory();
    if (allEntries.isEmpty) return const SizedBox.shrink();

    final sortedEntries = List<BloodUrineTestEntry>.from(allEntries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final chartEntries = sortedEntries.length > 7 ? sortedEntries.sublist(sortedEntries.length - 7) : sortedEntries;

    double maxVal = 0.0;
    for (var entry in chartEntries) {
      final val = _getBloodMetricValue(entry, _selectedBloodChartMetric);
      if (val != null && val > maxVal) {
        maxVal = val;
      }
    }
    if (maxVal == 0.0) {
      maxVal = 100.0;
    } else {
      maxVal *= 1.2;
    }

    final metricTitle = _getBloodMetricLabel(_selectedBloodChartMetric);

    return CozyWoodCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.show_chart, size: 18, color: AppColors.woodAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Andamento $metricTitle',
                        style: const TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownButton<String>(
                value: _selectedBloodChartMetric,
                dropdownColor: const Color(0xFFFDF6E3),
                style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontFamily: 'Serif'),
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'glycemia', child: Text('Glicemia')),
                  DropdownMenuItem(value: 'hba1c', child: Text('Emoglobina Glicata')),
                  DropdownMenuItem(value: 'insulin', child: Text('Insulina')),
                  DropdownMenuItem(value: 'iron', child: Text('Sideremia')),
                  DropdownMenuItem(value: 'ferritin', child: Text('Ferritina')),
                  DropdownMenuItem(value: 'potassium', child: Text('Potassio')),
                  DropdownMenuItem(value: 'vitaminD', child: Text('Vitamina D')),
                  DropdownMenuItem(value: 'vitaminB12', child: Text('Vitamina B12')),
                  DropdownMenuItem(value: 'ast', child: Text('AST')),
                  DropdownMenuItem(value: 'alt', child: Text('ALT')),
                  DropdownMenuItem(value: 'ggt', child: Text('GGT')),
                  DropdownMenuItem(value: 'hemoglobin', child: Text('Emoglobina')),
                  DropdownMenuItem(value: 'redBloodCells', child: Text('Globuli Rossi')),
                  DropdownMenuItem(value: 'whiteBloodCells', child: Text('Globuli Bianchi')),
                  DropdownMenuItem(value: 'platelets', child: Text('Piastrine')),
                  DropdownMenuItem(value: 'hematocrit', child: Text('Ematocrito')),
                  DropdownMenuItem(value: 'mcv', child: Text('MCV')),
                  DropdownMenuItem(value: 'neutrophils', child: Text('Neutrofili')),
                  DropdownMenuItem(value: 'lymphocytes', child: Text('Linfociti')),
                  DropdownMenuItem(value: 'totalCholesterol', child: Text('Colesterolo Totale')),
                  DropdownMenuItem(value: 'hdlCholesterol', child: Text('Colesterolo HDL')),
                  DropdownMenuItem(value: 'ldlCholesterol', child: Text('Colesterolo LDL')),
                  DropdownMenuItem(value: 'triglycerides', child: Text('Trigliceridi')),
                  DropdownMenuItem(value: 'creatinine', child: Text('Creatinina')),
                  DropdownMenuItem(value: 'gfr', child: Text('GFR')),
                  DropdownMenuItem(value: 'pt', child: Text('PT')),
                  DropdownMenuItem(value: 'aptt', child: Text('APTT')),
                  DropdownMenuItem(value: 'fibrinogen', child: Text('Fibrinogeno')),
                  DropdownMenuItem(value: 'ves', child: Text('VES')),
                  DropdownMenuItem(value: 'urineSpecificGravity', child: Text('Urine - Densità')),
                  DropdownMenuItem(value: 'urinePh', child: Text('Urine - pH')),
                  DropdownMenuItem(value: 'urineProteins', child: Text('Urine - Proteine')),
                  DropdownMenuItem(value: 'urineGlucose', child: Text('Urine - Glucosio')),
                  DropdownMenuItem(value: 'urineKetones', child: Text('Urine - Corpi Chetonici')),
                  DropdownMenuItem(value: 'urineHemoglobin', child: Text('Urine - Emoglobina')),
                  DropdownMenuItem(value: 'urineBilirubin', child: Text('Urine - Bilirubina')),
                  DropdownMenuItem(value: 'urineUrobilinogen', child: Text('Urine - Urobilinogeno')),
                  DropdownMenuItem(value: 'urineNitrites', child: Text('Urine - Nitriti')),
                  DropdownMenuItem(value: 'urineLeukocytes', child: Text('Urine - Leucociti')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() { _selectedBloodChartMetric = val; });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: chartEntries.isEmpty
                ? const Center(child: Text('Nessun dato disponibile', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: chartEntries.map((entry) {
                      final val = _getBloodMetricValue(entry, _selectedBloodChartMetric);
                      final double barHeight = (val != null && maxVal > 0) ? (val / maxVal) * 80 : 0.0;
                      final dateLabel = '${entry.date.day}/${entry.date.month}';
                      final valString = val != null ? (val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1)) : '-';

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(valString, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.woodAccent)),
                          const SizedBox(height: 4),
                          Container(
                            width: 16,
                            height: barHeight < 4 ? 4 : barHeight,
                            decoration: BoxDecoration(
                              color: val != null ? AppColors.woodAccent : AppColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(dateLabel, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.normal)),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  // TAB 3: VALORI EMATICI & ANALISI IA
  Widget _buildBloodTab() {
    final history = _storageService.getBloodTestsHistory();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: CozyButton(
              text: 'Inserisci Nuovi Esami',
              isSelected: true,
              onPressed: () {},
            ),
          ),
          const SizedBox(height: 10),

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
          const SizedBox(height: 8),

          _buildExpansionWoodSection(
            title: 'Assetto Marziale (Ferro)',
            children: [
              _buildBloodField(_ironController, 'Sideremia / Ferro', 'µg/dL'),
              const SizedBox(height: 10),
              _buildBloodField(_ferritinController, 'Ferritina', 'ng/mL'),
            ],
          ),
          const SizedBox(height: 8),

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
          const SizedBox(height: 8),

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
          const SizedBox(height: 8),

          _buildExpansionWoodSection(
            title: 'Emocromo Avanzato',
            children: [
              _buildBloodField(_hemoglobinController, 'Emoglobina', 'g/dL'),
              const SizedBox(height: 10),
              _buildBloodField(_redBloodCellsController, 'Globuli Rossi', 'x10^6/µL'),
              const SizedBox(height: 10),
              _buildBloodField(_whiteBloodCellsController, 'Globuli Bianchi', 'x10^3/µL'),
              const SizedBox(height: 10),
              _buildBloodField(_plateletsController, 'Piastrine', 'x10^3/µL'),
              const SizedBox(height: 10),
              _buildBloodField(_hematocritController, 'Ematocrito', '%'),
              const SizedBox(height: 10),
              _buildBloodField(_mcvController, 'MCV', 'fL'),
              const SizedBox(height: 10),
              _buildBloodField(_neutrophilsController, 'Neutrofili', '%'),
              const SizedBox(height: 10),
              _buildBloodField(_lymphocytesController, 'Linfociti', '%'),
            ],
          ),
          const SizedBox(height: 8),

          _buildExpansionWoodSection(
            title: 'Profilo Lipidico',
            children: [
              _buildBloodField(_totalCholesterolController, 'Colesterolo Totale', 'mg/dL'),
              const SizedBox(height: 10),
              _buildBloodField(_hdlCholesterolController, 'Colesterolo HDL', 'mg/dL'),
              const SizedBox(height: 10),
              _buildBloodField(_ldlCholesterolController, 'Colesterolo LDL', 'mg/dL'),
              const SizedBox(height: 10),
              _buildBloodField(_triglyceridesController, 'Trigliceridi', 'mg/dL'),
            ],
          ),
          const SizedBox(height: 8),

          _buildExpansionWoodSection(
            title: 'Profilo Renale',
            children: [
              _buildBloodField(_creatinineController, 'Creatinina', 'mg/dL'),
              const SizedBox(height: 10),
              _buildBloodField(_gfrController, 'GFR (VFG)', 'mL/min'),
            ],
          ),
          const SizedBox(height: 8),

          _buildExpansionWoodSection(
            title: 'Coagulazione & Infiammazione',
            children: [
              _buildBloodField(_ptController, 'Tempo di Protrombina (PT)', 'sec'),
              const SizedBox(height: 10),
              _buildBloodField(_apttController, 'APTT', 'sec'),
              const SizedBox(height: 10),
              _buildBloodField(_fibrinogenController, 'Fibrinogeno', 'mg/dL'),
              const SizedBox(height: 10),
              _buildBloodField(_vesController, 'VES', 'mm/h'),
            ],
          ),
          const SizedBox(height: 8),

          _buildExpansionWoodSection(
            title: 'Esame Urine',
            children: [
              _buildBloodField(_urineSpecificGravityController, 'Peso Specifico', 'densità'),
              const SizedBox(height: 10),
              _buildBloodField(_urinePhController, 'pH', 'unit'),
              const SizedBox(height: 10),
              _buildBloodField(_urineProteinsController, 'Proteine', 'mg/dL'),
              const SizedBox(height: 10),
              _buildBloodField(_urineGlucoseController, 'Glucosio', 'mg/dL'),
              const SizedBox(height: 10),
              _buildBloodField(_urineKetonesController, 'Corpi Chetonici', 'mg/dL'),
              const SizedBox(height: 10),
              _buildBloodField(_urineHemoglobinController, 'Emoglobina', 'mg/dL'),
              const SizedBox(height: 10),
              _buildBloodField(_urineBilirubinController, 'Bilirubina', 'mg/dL'),
              const SizedBox(height: 10),
              _buildBloodField(_urineUrobilinogenController, 'Urobilinogeno', 'mg/dL'),
              const SizedBox(height: 10),
              _buildBloodField(_urineNitritesController, 'Nitriti', 'pos/neg'),
              const SizedBox(height: 10),
              _buildBloodField(_urineLeukocytesController, 'Leucociti / Esterasi', 'cell/µL'),
              const SizedBox(height: 10),
              TextField(
                controller: _urineSedimentController,
                decoration: CozyStyles.cozyInputDecoration('Sedimento Urinario (note)'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: CozyButton(
              text: 'Salva Analisi del Sangue',
              icon: Icons.bookmark_add,
              onPressed: _saveBloodTest,
            ),
          ),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: CozyButton(
              text: 'Carica Referto & Analizza IA 🪄',
              icon: Icons.auto_awesome,
              onPressed: _showBloodFileSourceDialog,
            ),
          ),
          const SizedBox(height: 16),

          _buildBloodTestHistoryChart(),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: CozyButton(
              text: 'Storico Esami Registrati',
              isSelected: true,
              onPressed: () {},
            ),
          ),
          const SizedBox(height: 8),

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
              padding: EdgeInsets.zero,
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
                      title: Row(
                        children: [
                          Text(
                            'Analisi del $dateStr',
                            style: const TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          if (entry.filePath != null && entry.filePath!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.attach_file, size: 16, color: AppColors.woodAccent),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        'Glicemia: ${entry.glycemia ?? "-"} | Vit. D: ${entry.vitaminD ?? "-"} | Ferro: ${entry.iron ?? "-"}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () async {
                          await _storageService.deleteBloodUrineTestEntry(entry.id);
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

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              SizedBox(
                width: double.infinity,
                child: CozyButton(
                  text: 'Aggiungi Foto Progressi',
                  icon: Icons.camera_alt,
                  onPressed: _showImageSourceDialog,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CozyButton(
                  text: 'Storico Foto',
                  isSelected: true,
                  onPressed: () {},
                ),
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ),
        if (photos.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CozyWoodCard(
                child: Center(
                  child: Padding(
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
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
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
                childCount: photos.length,
              ),
            ),
          ),
      ],
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

  // Funzione di supporto locale per convertire in sicurezza (gestendo anche "Assente", "Negativo" o simili mappandoli a 0.0)
  double? parseUrineValue(String text) {
    final cleaned = text.trim().toLowerCase().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    
    // Se l'utente scrive "assente", "negativo" o simili, lo mappiamo a 0.0
    if (cleaned == 'assente' || cleaned == 'negativo' || cleaned == 'neg' || cleaned == '-' || cleaned == 'ass') {
      return 0.0;
    }
    
    return double.tryParse(cleaned);
  }
  
  void _saveBloodTest() async {
    final entry = BloodUrineTestEntry(
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
      hematocrit: double.tryParse(_hematocritController.text.replaceAll(',', '.')),
      mcv: double.tryParse(_mcvController.text.replaceAll(',', '.')),
      neutrophils: double.tryParse(_neutrophilsController.text.replaceAll(',', '.')),
      lymphocytes: double.tryParse(_lymphocytesController.text.replaceAll(',', '.')),
      totalCholesterol: double.tryParse(_totalCholesterolController.text.replaceAll(',', '.')),
      hdlCholesterol: double.tryParse(_hdlCholesterolController.text.replaceAll(',', '.')),
      ldlCholesterol: double.tryParse(_ldlCholesterolController.text.replaceAll(',', '.')),
      triglycerides: double.tryParse(_triglyceridesController.text.replaceAll(',', '.')),
      creatinine: double.tryParse(_creatinineController.text.replaceAll(',', '.')),
      gfr: double.tryParse(_gfrController.text.replaceAll(',', '.')),
      pt: double.tryParse(_ptController.text.replaceAll(',', '.')),
      aptt: double.tryParse(_apttController.text.replaceAll(',', '.')),
      fibrinogen: double.tryParse(_fibrinogenController.text.replaceAll(',', '.')),
      ves: double.tryParse(_vesController.text.replaceAll(',', '.')),
      // Parametri urine gestiti con la nuova funzione protetta per "Assente" / "Negativo"
      specificGravity: parseUrineValue(_urineSpecificGravityController.text),
      ph: parseUrineValue(_urinePhController.text),
      proteins: parseUrineValue(_urineProteinsController.text),
      urineGlucose: parseUrineValue(_urineGlucoseController.text),
      ketones: parseUrineValue(_urineKetonesController.text),
      bilirubin: parseUrineValue(_urineBilirubinController.text),
      urobilinogen: parseUrineValue(_urineUrobilinogenController.text),
      nitrites: parseUrineValue(_urineNitritesController.text),
      leukocyteEsterase: parseUrineValue(_urineLeukocytesController.text),
      urineSediment: _urineSedimentController.text.trim().isNotEmpty ? _urineSedimentController.text.trim() : null,
      filePath: _tempBloodFilePath,
    );
  
    await _storageService.addBloodUrineTestEntry(entry);
    _tempBloodFilePath = null;

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
    _hematocritController.clear();
    _mcvController.clear();
    _neutrophilsController.clear();
    _lymphocytesController.clear();
    _totalCholesterolController.clear();
    _hdlCholesterolController.clear();
    _ldlCholesterolController.clear();
    _triglyceridesController.clear();
    _creatinineController.clear();
    _gfrController.clear();
    _ptController.clear();
    _apttController.clear();
    _fibrinogenController.clear();
    _vesController.clear();
    _urineSpecificGravityController.clear();
    _urinePhController.clear();
    _urineProteinsController.clear();
    _urineGlucoseController.clear();
    _urineKetonesController.clear();
    _urineHemoglobinController.clear();
    _urineBilirubinController.clear();
    _urineUrobilinogenController.clear();
    _urineNitritesController.clear();
    _urineLeukocytesController.clear();
    _urineSedimentController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('🩸 Analisi del sangue e urine salvate con successo!'),
        ),
      );
      setState(() {});
    }
  }
  
  void _showBloodTestDetailsDialog(BloodUrineTestEntry entry) {
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
      if (entry.hematocrit != null) 'Ematocrito': '${entry.hematocrit} %',
      if (entry.mcv != null) 'MCV': '${entry.mcv} fL',
      if (entry.neutrophils != null) 'Neutrofili': '${entry.neutrophils} %',
      if (entry.lymphocytes != null) 'Linfociti': '${entry.lymphocytes} %',
      if (entry.totalCholesterol != null) 'Colesterolo Totale': '${entry.totalCholesterol} mg/dL',
      if (entry.hdlCholesterol != null) 'Colesterolo HDL': '${entry.hdlCholesterol} mg/dL',
      if (entry.ldlCholesterol != null) 'Colesterolo LDL': '${entry.ldlCholesterol} mg/dL',
      if (entry.triglycerides != null) 'Trigliceridi': '${entry.triglycerides} mg/dL',
      if (entry.creatinine != null) 'Creatinina': '${entry.creatinine} mg/dL',
      if (entry.gfr != null) 'GFR': '${entry.gfr} mL/min',
      if (entry.pt != null) 'PT': '${entry.pt} sec',
      if (entry.aptt != null) 'APTT': '${entry.aptt} sec',
      if (entry.fibrinogen != null) 'Fibrinogeno': '${entry.fibrinogen} mg/dL',
      if (entry.ves != null) 'VES': '${entry.ves} mm/h',
      if (entry.specificGravity != null) 'Urine - Densità': '${entry.specificGravity}',
      if (entry.ph != null) 'Urine - pH': '${entry.ph}',
      if (entry.proteins != null) 'Urine - Proteine': '${entry.proteins}',
      if (entry.urineGlucose != null) 'Urine - Glucosio': '${entry.urineGlucose}',
      if (entry.urineSediment != null && entry.urineSediment!.isNotEmpty) 'Urine - Sedimento': '${entry.urineSediment}',
      if (entry.ketones != null) 'Urine - Corpi Chetonici': '${entry.ketones}',
      if (entry.bilirubin != null) 'Urine - Bilirubina': '${entry.bilirubin}',
      if (entry.urobilinogen != null) 'Urine - Urobilinogeno': '${entry.urobilinogen}',
      if (entry.nitrites != null) 'Urine - Nitriti': '${entry.nitrites}',
      if (entry.leukocyteEsterase != null) 'Urine - Leucociti': '${entry.leukocyteEsterase}',
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry.filePath != null && entry.filePath!.isNotEmpty) ...[
                    const Text('Referto allegato:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.woodAccent)),
                    const SizedBox(height: 8),
                    if (entry.filePath!.endsWith('.pdf'))
                      InkWell(
                        onTap: () async {
                          final filePath = entry.filePath; 
                          if (filePath != null && filePath.isNotEmpty) {
                            final appDir = await path_provider.getApplicationDocumentsDirectory();
                            final fullPath = '${appDir.path}/${path.basename(filePath)}';
                            final file = File(fullPath);
                            
                            if (await file.exists()) {
                              await OpenFilex.open(fullPath);
                            } else {
                              final directFile = File(filePath);
                              if (await directFile.exists()) {
                                await OpenFilex.open(filePath);
                              } else {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Colors.red,
                                    content: Text('File PDF non trovato sul dispositivo.'),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.woodAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.woodAccent),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.picture_as_pdf, color: AppColors.woodAccent, size: 28),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Documento PDF allegato',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                              ),
                              Icon(Icons.open_in_new, size: 18, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.black,
                              child: InteractiveViewer(
                                child: _buildSafeImage(entry.filePath!, fit: BoxFit.contain),
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            height: 150,
                            width: double.infinity,
                            child: _buildSafeImage(entry.filePath!, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    const Divider(height: 20),
                  ],
                  if (valuesMap.isEmpty)
                    const Text('Nessun valore registrato per questo referto.')
                  else
                    ...valuesMap.entries.map((item) {
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
                    }),
                ],
              ),
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
                Text('File non trovato', style: TextStyle(fontSize: 10, color: Colors.grey)),
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
