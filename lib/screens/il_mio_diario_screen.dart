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
  final TextEditingController _proteinsController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatsController = TextEditingController();

  // Tipo di metrica selezionata per il grafico settimanale ('calories', 'proteins', 'carbs', 'fats')
  String _selectedChartMetric = 'calories';

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
    _proteinsController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    super.dispose();
  }

  void _changeDate(int days) {
    setState(() {
        _selectedDate = _selectedDate.add(Duration(days: days));
        _loadMealsForSelectedDate();
    });
  }

  // --- TOTALI GIORNALIERI SICURI ---
  int get _totalDailyCalories {
    try {
      return _currentMealsList.fold(0, (sum, meal) => sum + (meal.totalCalories ?? 0));
    } catch (_) {
      return 0;
    }
  }

  int get _totalDailyProteins {
    try {
      return _currentMealsList.fold(0, (sum, meal) {
        return sum + meal.items.fold(0, (itemSum, item) {
          try {
            return itemSum + (item.proteins ?? 0).toInt();
          } catch (_) {
            return itemSum;
          }
        });
      });
    } catch (_) {
      return 0;
    }
  }

  int get _totalDailyCarbs {
    try {
      return _currentMealsList.fold(0, (sum, meal) {
        return sum + meal.items.fold(0, (itemSum, item) {
          try {
            return itemSum + (item.carbs ?? 0).toInt();
          } catch (_) {
            return itemSum;
          }
        });
      });
    } catch (_) {
      return 0;
    }
  }

  int get _totalDailyFats {
    try {
      return _currentMealsList.fold(0, (sum, meal) {
        return sum + meal.items.fold(0, (itemSum, item) {
          try {
            return itemSum + (item.fats ?? 0).toInt();
          } catch (_) {
            return itemSum;
          }
        });
      });
    } catch (_) {
      return 0;
    }
  }

  int _getMetricForDate(DateTime date, String metric) {
    try {
      final meals = _storageService.getMealsForDate(date);
      if (meals.isEmpty) return 0;
      
      if (metric == 'calories') {
        return meals.fold(0, (sum, meal) => sum + (meal.totalCalories ?? 0));
      } else {
        return meals.fold(0, (sum, meal) => sum + meal.items.fold(0, (iSum, item) {
          try {
            if (metric == 'proteins') return iSum + (item.proteins ?? 0).toInt();
            if (metric == 'carbs') return iSum + (item.carbs ?? 0).toInt();
            return iSum + (item.fats ?? 0).toInt();
          } catch (_) {
            return iSum;
          }
        }));
      }
    } catch (_) {
      return 0;
    }
  }

  List<String> _getMealPhotos(MealEntryModel meal) {
    if (meal.photoPath == null || meal.photoPath!.isEmpty) return [];
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
    final double prot = double.tryParse(_proteinsController.text) ?? 0.0;
    final double carb = double.tryParse(_carbsController.text) ?? 0.0;
    final double fat = double.tryParse(_fatsController.text) ?? 0.0;

    setState(() {
        final newItem = FoodItemModel(
          name: _foodController.text.trim(),
          quantity: _quantityController.text.trim().isEmpty ? '1 porzione' : _quantityController.text.trim(),
          calories: cals,
          proteins: prot,
          carbs: carb,
          fats: fat,
        );

        meal.items.add(newItem);

        _foodController.clear();
        _quantityController.clear();
        _caloriesController.clear();
        _proteinsController.clear();
        _carbsController.clear();
        _fatsController.clear();

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

  void _showEditFoodItemDialog(MealEntryModel meal, int index) {
    final foodItem = meal.items[index];
    final nameController = TextEditingController(text: foodItem.name);
    final qtyController = TextEditingController(text: foodItem.quantity);
    final calsController = TextEditingController(text: foodItem.calories.toString());
    final protController = TextEditingController(text: (foodItem.proteins ?? 0).toString());
    final carbController = TextEditingController(text: (foodItem.carbs ?? 0).toString());
    final fatController = TextEditingController(text: (foodItem.fats ?? 0).toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFDF6E3),
          title: const Text('Modifica Portata', style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome Alimento', isDense: true)),
                const SizedBox(height: 8),
                TextField(controller: qtyController, decoration: const InputDecoration(labelText: 'Quantità', isDense: true)),
                const SizedBox(height: 8),
                TextField(controller: calsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calorie (kcal)', isDense: true)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: protController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Proteine (g)', isDense: true))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: carbController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Carb. (g)', isDense: true))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: fatController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Grassi (g)', isDense: true))),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.woodAccent, foregroundColor: Colors.white),
              onPressed: () {
                setState(() {
                    final updatedItem = FoodItemModel(
                      name: nameController.text.trim(),
                      quantity: qtyController.text.trim(),
                      calories: int.tryParse(calsController.text) ?? 0,
                      proteins: double.tryParse(protController.text) ?? 0.0,
                      carbs: double.tryParse(carbController.text) ?? 0.0,
                      fats: double.tryParse(fatController.text) ?? 0.0,
                    );
                    meal.items[index] = updatedItem;
                });
                _storageService.saveUser(_user);
                _storageService.saveMealsForDate(_selectedDate, _currentMealsList);
                Navigator.pop(context);
              },
              child: const Text('Salva Modifiche'),
            ),
          ],
        );
      },
    );
  }

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
              title: Text('Fotografa il pasto & Analizza IA', style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
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
    throw Exception("Impossibile contattare i server.");
  }

  Future<void> _pickAndProcessMeal(MealEntryModel meal, ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image != null) {
      if (!mounted) return;
      _processImageFile(meal, image.path);
    }
  }

  Future<void> _reanalyzeExistingPhoto(MealEntryModel meal, String photoPathOrName) async {
    final appDir = await path_provider.getApplicationDocumentsDirectory();
    final fileName = path.basename(photoPathOrName.replaceFirst('file://', ''));
    final fullPath = '${appDir.path}/$fileName';
    if (File(fullPath).existsSync()) {
      _processImageFile(meal, fullPath, existingFileName: fileName);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossibile trovare il file immagine.')));
    }
  }

  Future<void> _processImageFile(MealEntryModel meal, String sourcePath, {String? existingFileName}) async {
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
                  Text('🪄 L\'Elfo Magico IA sta analizzando il piatto...', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold)),
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
        try { await Gal.putImage(savedImage.path); } catch (_) {}
      }

      final appDir = await path_provider.getApplicationDocumentsDirectory();
      final File targetFile = File('${appDir.path}/$fileName');
      final bytes = await targetFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=$_apiKey');
      final prompt = '''
      Analizza questa foto di cibo. Restituisci unicamente un oggetto JSON valido con questa struttura esatta:
      {
      "piatto": "Nome del piatto",
      "calorie_totali_stimate": 0,
      "proteine_totali": 0,
      "carboidrati_totali": 0,
      "grassi_totali": 0,
      "ingredienti": [
      {"nome": "Nome ingrediente", "peso_grammi": 100, "calorie": 150, "proteine": 10, "carboidrati": 20, "grassi": 5}
    ],
      "domande_per_utente": [
      {"domanda": "Hai aggiunto olio d'oliva o burro?", "impatto_calorie": 90, "impatto_proteine": 0, "impatto_carboidrati": 0, "impatto_grassi": 10, "selezionato": false}
    ]
    }
      ''';

      final body = jsonEncode({
          "contents": [{"parts": [{"text": prompt}, {"inline_data": {"mime_type": "image/jpeg", "data": base64Image}}]}] ,
          "generationConfig": {"responseMimeType": "application/json"}
      });

      final response = await _postWithExponentialBackoff(url, {'Content-Type': 'application/json'}, body);
      
      if (!mounted) return;
      
      // 1. Chiudiamo in modo sicuro il dialog di caricamento dell'Elfo Magico
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // 2. Gestiamo i codici di risposta HTTP senza sollevare eccezioni distruttive
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final jsonString = data['candidates'][0]['content']['parts'][0]['text'];
        final Map<String, dynamic> risultatoIA = jsonDecode(jsonString);
        _showAiResultModal(meal, fileName, risultatoIA);
      } else if (response.statusCode == 429) {
        // Gestione specifica per troppe richieste (Too Many Requests)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text('⚠️ L\'Elfo Magico è oberato di lavoro! Attendi qualche secondo prima di scattare un\'altra foto (Errore 429).'),
          ),
        );
      } else {
        // Altri errori del server
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red[700],
            content: Text('Errore del server (${response.statusCode}). Riprova più tardi.'),
          ),
        );
      }

    } catch (e) {
      if (!mounted) return;
      
      // Se si verifica un'eccezione di rete, chiudiamo il loader se è ancora aperto
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Mostriamo l'errore in basso con uno SnackBar, SENZA uscire dalla schermata del diario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[700],
          content: Text('Errore di connessione: $e'),
        ),
      );
    }
  }    

  void _showAiResultModal(MealEntryModel meal, String photoFileName, Map<String, dynamic> risultatoIA) {
    final parentContext = context; // Catturiamo il context della schermata principale

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            int calcolaTotale(String key) {
              final realKey = key == 'calorie' ? 'calorie_totali_stimate' : '${key}_totali';
              int totale = 0;
              final val = risultatoIA[realKey];
              if (val is num) totale = val.toInt();
              else if (val is String) totale = int.tryParse(val) ?? 0;

              if (risultatoIA['domande_per_utente'] != null) {
                for (var d in risultatoIA['domande_per_utente']) {
                  if (d['selezionato'] == true) {
                    final impatto = d['impatto_$key'];
                    if (impatto is num) totale += impatto.toInt();
                    else if (impatto is String) totale += int.tryParse(impatto) ?? 0;
                  }
                }
              }
              return totale;
            }

            int finalCals = calcolaTotale('calorie');
            int finalProt = calcolaTotale('proteine');
            int finalCarbs = calcolaTotale('carboidrati');
            int finalFats = calcolaTotale('grassi');

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
                          _buildNutrienteChip('Calorie', '$finalCals kcal', Colors.orange),
                          _buildNutrienteChip('Proteine', '${finalProt}g', Colors.red),
                          _buildNutrienteChip('Carb.', '${finalCarbs}g', Colors.blue),
                          _buildNutrienteChip('Grassi', '${finalFats}g', Colors.green),
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
                                  setStateModal(() { d['selezionato'] = val ?? false; });
                                },
                              );
                        })),
                        const Divider(height: 20),
                      ],
                      const Text('Ingredienti rilevati:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      if (risultatoIA['ingredienti'] != null)
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
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.woodAccent, foregroundColor: Colors.white),
                  onPressed: () {
                    try {
                      print("DEBUG: Avvio salvataggio pasto IA...");
                      
                      setState(() {
                          final photos = _getMealPhotos(meal);
                          if (!photos.contains(photoFileName)) photos.add(photoFileName);
                          _saveMealPhotos(meal, photos);

                          final newItem = FoodItemModel(
                            name: risultatoIA['piatto'] ?? 'Piatto IA',
                            quantity: '1 porzione',
                            calories: finalCals,
                            proteins: finalProt.toDouble(),
                            carbs: finalCarbs.toDouble(),
                            fats: finalFats.toDouble(),
                          );

                          meal.items.add(newItem);
                          if (!meal.isRewardClaimed) {
                            meal.isRewardClaimed = true;
                            _user.coins += 5;
                          }
                      });

                      _storageService.saveUser(_user);
                      _storageService.saveMealsForDate(_selectedDate, _currentMealsList);
                      
                      print("DEBUG: Salvataggio completato, chiusura dialog...");
                      
                      // Chiudiamo il dialog
                      Navigator.of(context).pop();
                      
                      // Mostriamo il feedback
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        const SnackBar(backgroundColor: Color(0xFF2E7D32), content: Text('✨ Piatto analizzato aggiunto con successo! +5 Rupie! 💎')),
                      );
                    } catch (e, stackTrace) {
                      print("ERRORE CRITICO SALVATAGGIO IA: $e");
                      print(stackTrace);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(backgroundColor: Colors.red[700], content: Text('Errore nel salvataggio: $e')),
                      );
                    }
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
              Center(child: InteractiveViewer(panEnabled: true, minScale: 0.5, maxScale: 4, child: _buildSafeImage(imagePath, fit: BoxFit.contain))),
              IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context)),
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
          return Container(height: height, width: width, color: Colors.grey[200], child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
        }
        final appDir = snapshot.data!;
        final fileName = path.basename(imagePathOrName.replaceFirst('file://', ''));
        final fullPath = '${appDir.path}/$fileName';
        final file = File(fullPath);

        if (!file.existsSync()) {
          return Container(height: height, width: width, color: Colors.grey[300], child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 36));
        }

        return Image.file(file, fit: fit, height: height, width: width, errorBuilder: (context, error, stackTrace) => Container(height: height, width: width, color: Colors.grey[300], child: const Icon(Icons.broken_image, color: Colors.grey, size: 36)));
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
          title: const Text('Il mio Diario & Storico', style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 20)),
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
                          IconButton(icon: const Icon(Icons.arrow_back_ios, size: 16, color: AppColors.textPrimary), onPressed: () => _changeDate(-1)),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: AppColors.woodAccent),
                              const SizedBox(width: 8),
                              Text(formattedDate, style: const TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                            ],
                          ),
                          IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textPrimary), onPressed: () => _changeDate(1)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Totale Giornaliero
                    CozyCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 22),
                                const SizedBox(width: 6),
                                Text('Totale Giornaliero: $_totalDailyCalories kcal', style: const TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text('Proteine: ${_totalDailyProteins}g', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                Text('Carb.: ${_totalDailyCarbs}g', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                Text('Grassi: ${_totalDailyFats}g', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lista Pasti
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: mealsList.length,
                      itemBuilder: (context, mealIndex) {
                        final meal = mealsList[mealIndex];
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
                                    Text(meal.title, style: const TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                                      child: Text('${meal.totalCalories} kcal', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

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
                                                  GestureDetector(onTap: () => _showMealPhotoDetail(photoPath), child: _buildSafeImage(photoPath, fit: BoxFit.cover)),
                                                  Positioned(
                                                    bottom: 4, right: 4,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                            mealPhotos.removeAt(photoIndex);
                                                            _saveMealPhotos(meal, mealPhotos);
                                                        });
                                                      },
                                                      child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 14)),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    bottom: 4, left: 4,
                                                    child: GestureDetector(
                                                      onTap: () => _reanalyzeExistingPhoto(meal, photoPath),
                                                      child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppColors.woodAccent.withOpacity(0.9), shape: BoxShape.circle), child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14)),
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
                                  ...meal.items.asMap().entries.map((entry) {
                                      final itemIndex = entry.key;
                                      final foodItem = entry.value;
                                      final p = foodItem.proteins ?? 0;
                                      final c = foodItem.carbs ?? 0;
                                      final f = foodItem.fats ?? 0;

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 6.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                                          child: Row(
                                            children: [
                                              GestureDetector(onTap: () => _showEditFoodItemDialog(meal, itemIndex), child: const Padding(padding: EdgeInsets.only(right: 8.0), child: Icon(Icons.edit, size: 16, color: AppColors.woodAccent))),
                                              Expanded(child: Text('${foodItem.name} (${foodItem.quantity}) - ${foodItem.calories} kcal [P:${p.toInt()}g C:${c.toInt()}g G:${f.toInt()}g]', style: const TextStyle(fontSize: 11, color: AppColors.textPrimary))),
                                              GestureDetector(onTap: () => _removeFoodItem(meal, itemIndex), child: const Icon(Icons.close, size: 16, color: Colors.redAccent)),
                                            ],
                                          ),
                                        ),
                                      );
                                  }),
                                  const SizedBox(height: 8),
                                ],

                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border.withOpacity(0.5))),
                                  child: Column(
                                    children: [
                                      TextField(
                                        controller: _foodController,
                                        decoration: const InputDecoration(hintText: 'Alimento (es. Petto di pollo)', hintStyle: TextStyle(fontSize: 11, color: AppColors.textSecondary), isDense: true, border: InputBorder.none),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const Divider(height: 8),
                                      Row(
                                        children: [
                                          Expanded(child: TextField(controller: _quantityController, decoration: const InputDecoration(hintText: 'Quantità (150g)', hintStyle: TextStyle(fontSize: 10, color: AppColors.textSecondary), isDense: true, border: InputBorder.none), style: const TextStyle(fontSize: 11))),
                                          Expanded(child: TextField(controller: _caloriesController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Kcal', hintStyle: TextStyle(fontSize: 10, color: AppColors.textSecondary), isDense: true, border: InputBorder.none), style: const TextStyle(fontSize: 11))),
                                        ],
                                      ),
                                      const Divider(height: 8),
                                      Row(
                                        children: [
                                          Expanded(child: TextField(controller: _proteinsController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Prot (g)', hintStyle: TextStyle(fontSize: 10, color: AppColors.textSecondary), isDense: true, border: InputBorder.none), style: const TextStyle(fontSize: 11))),
                                          Expanded(child: TextField(controller: _carbsController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Carb (g)', hintStyle: TextStyle(fontSize: 10, color: AppColors.textSecondary), isDense: true, border: InputBorder.none), style: const TextStyle(fontSize: 11))),
                                          Expanded(child: TextField(controller: _fatsController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Grassi (g)', hintStyle: TextStyle(fontSize: 10, color: AppColors.textSecondary), isDense: true, border: InputBorder.none), style: const TextStyle(fontSize: 11))),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 30,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.woodAccent, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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
                                      label: const Text('Aggiungi Foto & IA 🪄', style: TextStyle(fontSize: 11, color: AppColors.woodAccent, fontWeight: FontWeight.bold)),
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
                    _buildWeeklyChart(),
                  ],
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top - 18,
              right: 42.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(color: AppColors.background.withOpacity(0.88), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CurrencyBadge(icon: Icons.diamond, iconColor: AppColors.rupeeGreen, value: '${_user.coins}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final List<DateTime> pastDays = List.generate(7, (index) => _selectedDate.subtract(Duration(days: 6 - index)));
    int maxVal = _selectedChartMetric == 'calories' ? 2000 : 150;
    for (var day in pastDays) {
      final val = _getMetricForDate(day, _selectedChartMetric);
      if (val > maxVal) maxVal = val;
    }

    String getDateKey(DateTime d) => "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    String metricTitle = 'Calorie';
    if (_selectedChartMetric == 'proteins') metricTitle = 'Proteine (g)';
    if (_selectedChartMetric == 'carbs') metricTitle = 'Carboidrati (g)';
    if (_selectedChartMetric == 'fats') metricTitle = 'Grassi (g)';

    return CozyWoodCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bar_chart, size: 18, color: AppColors.woodAccent),
                  const SizedBox(width: 8),
                  Text('Andamento $metricTitle', style: const TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                ],
              ),
              DropdownButton<String>(
                value: _selectedChartMetric,
                dropdownColor: const Color(0xFFFDF6E3),
                style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontFamily: 'Serif'),
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'calories', child: Text('Calorie')),
                  DropdownMenuItem(value: 'proteins', child: Text('Proteine')),
                  DropdownMenuItem(value: 'carbs', child: Text('Carboidrati')),
                  DropdownMenuItem(value: 'fats', child: Text('Grassi')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() { _selectedChartMetric = val; });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: pastDays.map((day) {
                  final val = _getMetricForDate(day, _selectedChartMetric);
                  final double barHeight = maxVal > 0 ? (val / maxVal) * 80 : 0.0;
                  final bool isSelectedDay = getDateKey(day) == getDateKey(_selectedDate);
                  final dayLabel = '${day.day}/${day.month}';

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('$val', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isSelectedDay ? AppColors.woodAccent : AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Container(
                        width: 16,
                        height: barHeight < 4 ? 4 : barHeight,
                        decoration: BoxDecoration(color: isSelectedDay ? AppColors.woodAccent : AppColors.border, borderRadius: BorderRadius.circular(4)),
                      ),
                      const SizedBox(height: 6),
                      Text(dayLabel, style: TextStyle(fontSize: 9, color: isSelectedDay ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: isSelectedDay ? FontWeight.bold : FontWeight.normal)),
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
