import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;
import 'package:gal/gal.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';
import '../models/meal_entry_model.dart';
import '../theme/app_theme.dart';
import '../theme/cozy_styles.dart';
import '../widgets/cozy_background.dart';
import '../widgets/cozy_widgets.dart';

class IlMioDiarioScreen extends StatefulWidget {
  const IlMioDiarioScreen({super.key});

  @override
  State<IlMioDiarioScreen> createState() => _IlMioDiarioScreenState();
}

class _IlMioDiarioScreenState extends State<IlMioDiarioScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  final ImagePicker _picker = ImagePicker();
  late UserModel _user;

  // Data selezionata per lo storico
  DateTime _selectedDate = DateTime.now();
  
  // Lista locale dei pasti in memoria
  List<MealEntryModel> _currentMealsList = [];

  // Controller temporanei per l'inserimento manuale della portata
  final TextEditingController _foodController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();

  // Chiave API Gemini
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  @override
  void initState() {
    super.initState();
    _user = _storageService.getUser();
    _loadMealsForSelectedDate();
  }

  void _loadMealsForSelectedDate() {
    _currentMealsList = _storageService.getMealsForDate(_selectedDate);
  }

  @override
  void dispose() {
    _foodController.dispose();
    _quantityController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      _loadMealsForSelectedDate();
    });
  }

  int get _totalDailyCalories {
    return _currentMealsList.fold(0, (sum, meal) => sum + meal.totalCalories);
  }

  int _getCaloriesForDate(DateTime date) {
    final meals = _storageService.getMealsForDate(date);
    return meals.fold(0, (sum, meal) => sum + meal.totalCalories);
  }

  // --- GESTIONE FOTO MULTIPLE (Supporto retrocompatibile) ---
  List<String> _getMealPhotos(MealEntryModel meal) {
    if (meal.photoPath == null || meal.photoPath!.isEmpty) return [];
    // Se contiene un separatore (es. virgola o pipe), separiamo, altrimenti restituiamo l'elemento singolo in una lista
    if (meal.photoPath!.contains('|')) {
      return meal.photoPath!.split('|').where((s) => s.isNotEmpty).toList();
    }
    return [meal.photoPath!];
  }

  void _saveMealPhotos(MealEntryModel meal, List<String> photos) {
    setState(() {
      meal.photoPath = photos.isEmpty ? null : photos.join('|');
    });
    _storageService.saveUser(_user);
    _storageService.saveMealsForDate(_selectedDate, _currentMealsList);
  }

  void _addFoodItemToMeal(MealEntryModel meal) {
    if (_foodController.text.trim().isEmpty) return;

    final int cals = int.tryParse(_caloriesController.text) ?? 0;

    setState(() {
      meal.items.add(FoodItemModel(
        name: _foodController.text.trim(),
        quantity: _quantityController.text.trim().isEmpty ? '1 porzione' : _quantityController.text.trim(),
        calories: cals,
      ));

      _foodController.clear();
      _quantityController.clear();
      _caloriesController.clear();

      if (!meal.isRewardClaimed) {
        meal.isRewardClaimed = true;
        _user.coins += 5;
      }
    });

    _storageService.saveUser(_user);
    _storageService.saveMealsForDate(_selectedDate, _currentMealsList);
  }

  void _removeFoodItem(MealEntryModel meal, int index) {
    setState(() {
      meal.items.removeAt(index);
    });
    _storageService.saveUser(_user);
    _storageService.saveMealsForDate(_selectedDate, _currentMealsList);
  }

  // --- SELETTORE FONTE FOTO ---
  void _showImageSourceDialog(MealEntryModel meal) {
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
                'Fotografa il pasto & Analizza IA',
                style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.woodAccent),
              title: const Text('Scatta una foto', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _pickAndProcessMeal(meal, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.woodAccent),
              title: const Text('Scegli dalla galleria', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _pickAndProcessMeal(meal, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- CHIAMATA HTTP CON RETRY ESPONENZIALE ---
  Future<http.Response> _postWithExponentialBackoff(Uri url, Map<String, String> headers, String body) async {
    int maxAttempts = 4;
    int delayMs = 1500;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await http.post(url, headers: headers, body: body);
        if ((response.statusCode == 503 || response.statusCode == 429) && attempt < maxAttempts) {
          await Future.delayed(Duration(milliseconds: delayMs));
          delayMs *= 2;
          continue;
        }
        return response;
      } catch (e) {
        if (attempt == maxAttempts) rethrow;
        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs *= 2;
      }
    }
    throw Exception("Impossibile contattare i server dopo vari tentativi.");
  }

  // --- GESTIONE FOTO, SALVATAGGIO LOCALE E CHIAMATA API GEMINI ---
  Future<void> _pickAndProcessMeal(MealEntryModel meal, ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 85);

    if (image != null) {
      if (!mounted) return;
      _processImageFile(meal, image.path);
    }
  }

  // Metodo per rianalizzare una foto già esistente
  Future<void> _reanalyzeExistingPhoto(MealEntryModel meal, String photoPathOrName) async {
    final appDir = await path_provider.getApplicationDocumentsDirectory();
    final fileName = path.basename(photoPathOrName.replaceFirst('file://', ''));
    final fullPath = '${appDir.path}/$fileName';
    
    if (File(fullPath).existsSync()) {
      _processImageFile(meal, fullPath, existingFileName: fileName);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile trovare il file immagine sul dispositivo.')),
      );
    }
  }

  Future<void> _processImageFile(MealEntryModel meal, String sourcePath, {String? existingFileName}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => PopScope(
        canPop: false,
        child: const Center(
          child: CozyCard(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.woodAccent),
                  SizedBox(height: 16),
                  Text(
                    '🪄 L\'Elfo Magico IA sta analizzando il piatto...\n(Se c\'è traffico, attendo qualche secondo in più)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      String fileName;
      if (existingFileName != null) {
        fileName = existingFileName;
      } else {
        final appDir = await path_provider.getApplicationDocumentsDirectory();
        fileName = 'meal_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File savedImage = await File(sourcePath).copy('${appDir.path}/$fileName');
        try {
          await Gal.putImage(savedImage.path);
        } catch (_) {}
      }

      final appDir = await path_provider.getApplicationDocumentsDirectory();
      final File targetFile = File('${appDir.path}/$fileName');

      // Chiamata API Gemini
      final bytes = await targetFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=$_apiKey'
      );

      final prompt = '''
Analizza questa foto di cibo. Restituisci unicamente un oggetto JSON valido con questa struttura esatta:
{
  "piatto": "Nome del piatto",
  "calorie_totali_stimate": 0,
  "proteine_totali": 0,
  "carboidrati_totali": 0,
  "grassi_totali": 0,
  "ingredienti": [
    {"nome": "Nome ingrediente", "peso_grammi": 100, "calorie": 150}
  ],
  "domande_per_utente": [
    {"domanda": "Hai aggiunto olio d'oliva o burro?", "impatto_calorie": 90, "selezionato": false}
  ]
}
Stima in modo realistico i grammi e i macronutrienti.
''';

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "responseMimeType": "application/json"
        }
      });

      final response = await _postWithExponentialBackoff(url, {'Content-Type': 'application/json'}, body);

      if (!mounted) return;
      Navigator.of(context).pop(); // Chiude il loader

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final jsonString = data['candidates'][0]['content']['parts'][0]['text'];
        final Map<String, dynamic> risultatoIA = jsonDecode(jsonString);

        _showAiResultModal(meal, fileName, risultatoIA);
      } else {
        throw Exception("Errore server (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.brown[800],
            content: Text('Errore durante l\'analisi IA: $e'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // --- MODALE INTERATTIVA PER LA REVISIONE DEI RISULTATI IA ---
  void _showAiResultModal(MealEntryModel meal, String photoFileName, Map<String, dynamic> risultatoIA) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            int calcolaTotaleDinamicamente() {
              int totale = 0;
              for (var ing in risultatoIA['ingredienti']) {
                totale += (ing['calorie'] as num).toInt();
              }
              if (risultatoIA['domande_per_utente'] != null) {
                for (var d in risultatoIA['domande_per_utente']) {
                  if (d['selezionato'] == true) {
                    totale += (d['impatto_calorie'] as num).toInt();
                  }
                }
              }
              return totale;
            }

            return AlertDialog(
              backgroundColor: const Color(0xFFFDF6E3),
              title: Text(risultatoIA['piatto'] ?? 'Piatto Riconosciuto', style: const TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNutrienteChip('Calorie', '${calcolaTotaleDinamicamente()} kcal', Colors.orange),
                          _buildNutrienteChip('Proteine', '${risultatoIA['proteine_totali']}g', Colors.red),
                          _buildNutrienteChip('Carb.', '${risultatoIA['carboidrati_totali']}g', Colors.blue),
                          _buildNutrienteChip('Grassi', '${risultatoIA['grassi_totali']}g', Colors.green),
                        ],
                      ),
                      const Divider(height: 20),
                      if (risultatoIA['domande_per_utente'] != null && (risultatoIA['domande_per_utente'] as List).isNotEmpty) ...[
                        const Text('Personalizzazione condimenti:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ...((risultatoIA['domande_per_utente'] as List).map((d) {
                          return CheckboxListTile(
                            dense: true,
                            title: Text(d['domanda'], style: const TextStyle(fontSize: 12)),
                            subtitle: Text('+${d['impatto_calorie']} kcal', style: const TextStyle(fontSize: 10)),
                            value: d['selezionato'] ?? false,
                            onChanged: (val) {
                              setStateModal(() {
                                d['selezionato'] = val ?? false;
                              });
                            },
                          );
                        })),
                        const Divider(height: 20),
                      ],
                      const Text('Ingredienti rilevati:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ...((risultatoIA['ingredienti'] as List).map((ing) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text('• ${ing['nome']} (${ing['peso_grammi']}g) - ${ing['calorie']} kcal', style: const TextStyle(fontSize: 12)),
                        );
                      })),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annulla', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.woodAccent, foregroundColor: Colors.white),
                  onPressed: () {
                    final int finalCalories = calcolaTotaleDinamicamente();
                    setState(() {
                      // Aggiunge la foto alla lista esistente senza sovrascrivere le altre
                      final photos = _getMealPhotos(meal);
                      if (!photos.contains(photoFileName)) {
                        photos.add(photoFileName);
                      }
                      _saveMealPhotos(meal, photos);

                      meal.items.add(FoodItemModel(
                        name: risultatoIA['piatto'] ?? 'Piatto IA',
                        quantity: '1 porzione',
                        calories: finalCalories,
                      ));

                      if (!meal.isRewardClaimed) {
                        meal.isRewardClaimed = true;
                        _user.coins += 5;
                      }
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF2E7D32),
                        content: Text('✨ Piatto analizzato dall\'IA aggiunto con successo! +5 Rupie! 💎'),
                      ),
                    );
                  },
                  child: const Text('Conferma e Salva'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNutrienteChip(String label, String valore, Color colore) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(valore, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colore)),
      ],
    );
  }

  // --- VISUALIZZATORE FOTO A SCHERMO INTERO ---
  void _showMealPhotoDetail(String imagePath) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4,
                  child: _buildSafeImage(imagePath, fit: BoxFit.contain),
                ),
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

  Widget _buildSafeImage(String imagePathOrName, {BoxFit fit = BoxFit.cover, double? height, double? width}) {
    return FutureBuilder<Directory>(
      future: path_provider.getApplicationDocumentsDirectory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: height,
            width: width,
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
            height: height,
            width: width,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 36),
          );
        }

        return Image.file(
          file,
          fit: fit,
          height: height,
          width: width,
          errorBuilder: (context, error, stackTrace) => Container(
            height: height,
            width: width,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, color: Colors.grey, size: 36),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';
    final mealsList = _currentMealsList;

    return CozyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Il mio Diario & Storico',
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
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selettore Data
                    CozyWoodCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, size: 16, color: AppColors.textPrimary),
                            onPressed: () => _changeDate(-1),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: AppColors.woodAccent),
                              const SizedBox(width: 8),
                              Text(
                                formattedDate,
                                style: const TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textPrimary),
                            onPressed: () => _changeDate(1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Calorie Totali Giornaliere
                    CozyCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Totale Giornaliero: $_totalDailyCalories kcal',
                            style: const TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lista Pasti
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: mealsList.length,
                      itemBuilder: (context, index) {
                        final meal = mealsList[index];
                        final mealPhotos = _getMealPhotos(meal);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14.0),
                          child: CozyWoodCard(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(meal.icon, style: const TextStyle(fontSize: 22)),
                                    const SizedBox(width: 8),
                                    Text(
                                      meal.title,
                                      style: const TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Text(
                                        '${meal.totalCalories} kcal',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // --- GRIGLIA / LISTA FOTO MULTIPLE CON ELIMINAZIONE E RIPRESA ANALISI IA ---
                                if (mealPhotos.isNotEmpty) ...[
                                  SizedBox(
                                    height: 130,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: mealPhotos.length,
                                      itemBuilder: (context, photoIndex) {
                                        final photoPath = mealPhotos[photoIndex];
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: SizedBox(
                                              width: 130,
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () => _showMealPhotoDetail(photoPath),
                                                    child: _buildSafeImage(photoPath, fit: BoxFit.cover),
                                                  ),
                                                  // Bottone X rossa in basso a destra per eliminare la foto
                                                  Positioned(
                                                    bottom: 4,
                                                    right: 4,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          mealPhotos.removeAt(photoIndex);
                                                          _saveMealPhotos(meal, mealPhotos);
                                                        });
                                                      },
                                                      child: Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: const BoxDecoration(
                                                          color: Colors.red,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                                                      ),
                                                    ),
                                                  ),
                                                  // Bottone IA in basso a sinistra per rianalizzare la foto esistente
                                                  Positioned(
                                                    bottom: 4,
                                                    left: 4,
                                                    child: GestureDetector(
                                                      onTap: () => _reanalyzeExistingPhoto(meal, photoPath),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.woodAccent.withOpacity(0.9),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],

                                if (meal.items.isNotEmpty) ...[
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: meal.items.length,
                                    itemBuilder: (context, itemIndex) {
                                      final foodItem = meal.items[itemIndex];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 6.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '• ${foodItem.name} (${foodItem.quantity}) - ${foodItem.calories} kcal',
                                                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () => _removeFoodItem(meal, itemIndex),
                                                child: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                ],

                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border.withOpacity(0.5)),
                                  ),
                                  child: Column(
                                    children: [
                                      TextField(
                                        controller: _foodController,
                                        decoration: const InputDecoration(
                                          hintText: 'Alimento (es. Petto di pollo)',
                                          hintStyle: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          isDense: true,
                                          border: InputBorder.none,
                                        ),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const Divider(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _quantityController,
                                              decoration: const InputDecoration(
                                                hintText: 'Quantità (es. 150g)',
                                                hintStyle: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                                isDense: true,
                                                border: InputBorder.none,
                                              ),
                                              style: const TextStyle(fontSize: 11),
                                            ),
                                          ),
                                          Expanded(
                                            child: TextField(
                                              controller: _caloriesController,
                                              keyboardType: TextInputType.number,
                                              decoration: const InputDecoration(
                                                hintText: 'Calorie (kcal)',
                                                hintStyle: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                                isDense: true,
                                                border: InputBorder.none,
                                              ),
                                              style: const TextStyle(fontSize: 11),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 30,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.woodAccent,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          onPressed: () => _addFoodItemToMeal(meal),
                                          child: const Text('Salva Portata ➕', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _showImageSourceDialog(meal),
                                      icon: const Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.woodAccent),
                                      label: const Text(
                                        'Aggiungi Foto & IA 🪄',
                                        style: TextStyle(fontSize: 11, color: AppColors.woodAccent, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildWeeklyCaloriesChart(),
                  ],
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top - 18,
              right: 42.0,
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
                      icon: Icons.diamond,
                      iconColor: AppColors.rupeeGreen,
                      value: '${_user.coins}',
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

Widget _buildWeeklyCaloriesChart() {
    final List<DateTime> pastDays = List.generate(7, (index) {
      return _selectedDate.subtract(Duration(days: 6 - index));
    });

    int maxCals = 2000;
    for (var day in pastDays) {
      final cals = _getCaloriesForDate(day);
      if (cals > maxCals) maxCals = cals;
    }

    String getDateKey(DateTime d) => "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

    return CozyWoodCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, size: 18, color: AppColors.woodAccent),
              SizedBox(width: 8),
              Text(
                'Andamento Calorie (Ultimi 7 Giorni)',
                style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              // CORRETTO da .app a .map
              children: pastDays.map((day) {
                final cals = _getCaloriesForDate(day);
                final double barHeight = maxCals > 0 ? (cals / maxCals) * 80 : 0.0;
                final bool isSelectedDay = getDateKey(day) == getDateKey(_selectedDate);
                final dayLabel = '${day.day}/${day.month}';

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$cals',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isSelectedDay ? AppColors.woodAccent : AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 16,
                      height: barHeight < 4 ? 4 : barHeight,
                      decoration: BoxDecoration(
                        color: isSelectedDay ? AppColors.woodAccent : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dayLabel,
                      style: TextStyle(fontSize: 9, color: isSelectedDay ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: isSelectedDay ? FontWeight.bold : FontWeight.normal),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
