import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import '../models/user_model.dart';
import '../models/habit_model.dart';
import '../models/body_measurement_entry.dart';
import '../models/progress_photo_entry.dart';
import '../models/bloodurine_test_entry.dart';
import '../models/meal_entry_model.dart';
import '../constants/app_assets.dart';

/// Modello per rappresentare la singola misurazione del peso con la sua data
class WeightEntry {
  final DateTime date;
  final double weight;

  WeightEntry({required this.date, required this.weight});

  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'weight': weight,
  };

  factory WeightEntry.fromMap(Map<String, dynamic> map) => WeightEntry(
    date: DateTime.parse(map['date']),
    weight: (map['weight'] as num).toDouble(),
  );
}

class LocalStorageService {
  final Box _userBox = Hive.box('userBox');
  final Box _habitsBox = Hive.box('habitsBox');
  final Box _weightBox = Hive.box('weightLogsBox');
  final Box _measurementsBox = Hive.box('measurementsBox');
  final Box _photosBox = Hive.box('photosBox');
  final Box _bloodTestsBox = Hive.box('bloodTestsBox');
  final Box _mealsBox = Hive.box('mealsBox');

  // --- GESTIONE FOTO PROGRESSI ---

  Future<void> addProgressPhoto(ProgressPhotoEntry photo) async {
    await _photosBox.put(photo.id, photo.toMap());
  }

  List<ProgressPhotoEntry> getProgressPhotosHistory() {
    final entries = _photosBox.values
        .map((e) => ProgressPhotoEntry.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  Future<void> deleteProgressPhoto(String photoId) async {
    await _photosBox.delete(photoId);
  }

  // --- GESTIONE PROFILO UTENTE & GAMIFICATION ---

  Future<void> saveUser(UserModel user) async {
    await _userBox.put('profile', user.toMap());
  }

  UserModel getUser() {
    final data = _userBox.get('profile');
    if (data != null) {
      return UserModel.fromMap(Map<String, dynamic>.from(data));
    } else {
      return UserModel(
        id: 'user_local',
        name: 'Giada',
        currentWeight: 94.0,
        targetWeight: 80.0,
        startWeight: 95.0,
        height: 165.0,
        currentHearts: 0,
        maxHearts: 10,
        coins: 0,
        xp: 0,
        goldenChests: 0,
        avatarConfig: AvatarConfig(),
      );
    }
  }

  // Metodi di utilità per risorse e valute
  Future<void> addHearts(int amount) async {
    final user = getUser();
    user.currentHearts = (user.currentHearts + amount).clamp(0, user.maxHearts);
    await saveUser(user);
  }

  Future<void> addCoins(int amount) async {
    final user = getUser();
    user.coins += amount;
    await saveUser(user);
  }

  Future<void> addGoldenChests(int amount) async {
    final user = getUser();
    user.goldenChests += amount;
    await saveUser(user);
  }

  Future<bool> consumeGoldenChest() async {
    final user = getUser();
    if (user.goldenChests > 0) {
      user.goldenChests -= 1;
      await saveUser(user);
      return true;
    }
    return false;
  }

  Future<void> addReward({int xpGained = 0, int coinsGained = 0, int heartsGained = 0}) async {
    final user = getUser();
    user.xp += xpGained;
    user.coins += coinsGained;

    if (user.heartsToday < user.maxHeartsDaily) {
      final int oldHearts = user.heartsToday;
      user.heartsToday += heartsGained;

      if (oldHearts < user.maxHeartsDaily && user.heartsToday >= user.maxHeartsDaily) {
        user.goldenChests += 1;
      }
    }
    
    await saveUser(user);
  }

  // --- GESTIONE ABITUDINI ("Cura di Me") ---

  Future<void> saveHabits(List<HabitModel> habits) async {
    final Map<String, dynamic> habitsMap = {
      for (var habit in habits) habit.id: habit.toMap()
    };
    await _habitsBox.putAll(habitsMap);
  }

  List<HabitModel> getHabits() {
    if (_habitsBox.isEmpty) {
      return [
        HabitModel(id: '1', title: 'Bere secondo il mio obiettivo'),
        HabitModel(id: '2', title: 'Prendermi cura della pelle'),
        HabitModel(id: '3', title: 'Prendermi cura dei capelli'),
        HabitModel(id: '4', title: 'Crema e profumo'),
        HabitModel(id: '5', title: 'Ascoltare musica'),
        HabitModel(id: '6', title: 'Fare qualcosa solo per me'),
        HabitModel(id: '7', title: 'Riposare'),
        HabitModel(id: '8', title: 'Ascoltare il mio corpo'),
      ];
    }

    return _habitsBox.values
        .map((e) => HabitModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> toggleHabit(String habitId) async {
    final habits = getHabits();
    final habit = habits.firstWhere((h) => h.id == habitId);
    
    habit.isCompletedToday = !habit.isCompletedToday;
    await _habitsBox.put(habitId, habit.toMap());

    if (habit.isCompletedToday) {
      await addReward(xpGained: habit.rewardXp, heartsGained: 1);
    }
  }

  // --- GESTIONE PESO E MAPPA ---

  Future<void> addWeightEntry(double weight, {DateTime? customDate}) async {
    final DateTime targetDate = customDate ?? DateTime.now();
    final String dateKey = targetDate.toIso8601String().split('T')[0];

    await _weightBox.put(dateKey, {
      'date': targetDate.toIso8601String(),
      'weight': weight,
    });

    final user = getUser();
    user.currentWeight = weight;
    await saveUser(user);
  }

  List<WeightEntry> getWeightHistory() {
    final entries = _weightBox.values
        .map((e) => WeightEntry.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }

  Future<void> deleteWeightEntry(DateTime date) async {
    final String dateKey = date.toIso8601String().split('T')[0];
    await _weightBox.delete(dateKey);
  }

  // --- GESTIONE MISURAZIONI CORPOREE ---

  Future<void> addBodyMeasurement(BodyMeasurementEntry entry) async {
    final String dateKey = entry.date.toIso8601String().split('T')[0];
    await _measurementsBox.put(dateKey, entry.toMap());
  }

  List<BodyMeasurementEntry> getBodyMeasurementsHistory() {
    final entries = _measurementsBox.values
        .map((e) => BodyMeasurementEntry.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    entries.sort((a, b) => b.date.compareTo(b.date));
    return entries;
  }

  BodyMeasurementEntry? getLatestBodyMeasurement() {
    final history = getBodyMeasurementsHistory();
    return history.isNotEmpty ? history.first : null;
  }

  // --- GESTIONE ANALISI DEL SANGUE E URINE ---
  
  Future<void> addBloodUrineTestEntry(BloodUrineTestEntry entry) async {
    final String dateKey = (entry.id.isNotEmpty) ? entry.id : entry.date.toIso8601String();
    await _bloodTestsBox.put(dateKey, entry.toMap());
  }

  List<BloodUrineTestEntry> getBloodTestsHistory() {
    final entries = <BloodUrineTestEntry>[];
    
    for (var key in _bloodTestsBox.keys) {
      try {
        final data = _bloodTestsBox.get(key);
        if (data != null) {
          final map = Map<String, dynamic>.from(data);
          map['id'] = map['id'] ?? key.toString();
          
          if (map['date'] != null) {
            entries.add(BloodUrineTestEntry.fromMap(map));
          }
        }
      } catch (e) {
        print("⚠️ Trovata entry corrotta nel box bloodTestsBox con chiave $key, la rimuovo: $e");
        _bloodTestsBox.delete(key);
      }
    }
    
    entries.sort((a, b) => b.date.compareTo(b.date));
    return entries;
  }

  Future<void> deleteBloodUrineTestEntry(String id) async {
    if (_bloodTestsBox.containsKey(id)) {
      await _bloodTestsBox.delete(id);
      return;
    }

    dynamic keyToDelete;
    for (var key in _bloodTestsBox.keys) {
      final data = _bloodTestsBox.get(key);
      if (data != null) {
        final map = Map<String, dynamic>.from(data);
        final storedId = map['id']?.toString();
        
        if (storedId == id || key.toString() == id || key.toString().contains(id)) {
          keyToDelete = key;
          break;
        }
      }
    }

    if (keyToDelete != dataNullCheckSafe(keyToDelete)) { // Pulito
      if (keyToDelete != null) {
        await _bloodTestsBox.delete(keyToDelete);
        print("✅ Entry eliminata con successo tramite chiave secondaria: $keyToDelete");
      }
    } else {
      final matchingKeys = _bloodTestsBox.keys.where((k) => k.toString().contains(id)).toList();
      for (var k in matchingKeys) {
        await _bloodTestsBox.delete(k);
      }
    }
  }

  // Metodo di comodo richiesto dalle schermate
  List<BloodUrineTestEntry> getBloodUrineTestEntries() => getBloodTestsHistory();
  
  // --- GESTIONE DIARIO ALIMENTARE (PASTI) ---

  Future<void> saveMealsForDate(DateTime date, List<MealEntryModel> meals) async {
    final String dateKey = date.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> serializedMeals = meals.map((m) => m.toMap()).toList();
    await _mealsBox.put(dateKey, serializedMeals);
  }

  List<MealEntryModel> getMealsForDate(DateTime date) {
    final String dateKey = date.toIso8601String().split('T')[0];
    final data = _mealsBox.get(dateKey);

    if (data != null) {
      try {
        final List<dynamic> list = data;
        return list.map((e) {
          final map = Map<dynamic, dynamic>.from(e);
          final stringKeyMap = map.map((k, v) => MapEntry(k.toString(), v));
          return MealEntryModel.fromMap(stringKeyMap);
        }).toList();
      } catch (e) {
        print("⚠️ Errore di decodifica pasti da Hive: $e");
      }
    }

    return [
      MealEntryModel(title: 'Colazione', icon: '🥐'),
      MealEntryModel(title: 'Pranzo', icon: '🍲'),
      MealEntryModel(title: 'Merenda', icon: '🍎'),
      MealEntryModel(title: 'Cena', icon: '🌙'),
    ];
  }

  /// Consolida i file esterni (es. rullino o documenti) copiandoli nella sandbox locale
  /// e aggiornando i relativi riferimenti nei box Hive.
  Future<int> consolidateExternalFiles() async {
    final appDir = await getApplicationDocumentsDirectory();
    int consolidatedCount = 0;

    // 1. Consolidamento Foto Progressi (_photosBox)
    for (var key in _photosBox.keys) {
      final data = _photosBox.get(key);
      if (data != null) {
        final map = Map<String, dynamic>.from(data);
        final String? imagePath = map['imagePath'] ?? map['path'];
        
        if (imagePath != null && imagePath.isNotEmpty) {
          final file = File(imagePath);
          if (await file.exists() && !imagePath.contains(appDir.path)) {
            try {
              final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imagePath.split('/').last}';
              final newPath = '${appDir.path}/$fileName';
              
              await file.copy(newPath);
              
              map['imagePath'] = newPath;
              await _photosBox.put(key, map);
              consolidatedCount++;
            } catch (e) {
              print("⚠️ Errore durante il consolidamento della foto $key: $e");
            }
          }
        }
      }
    }

    // 2. Consolidamento Analisi del Sangue/Urine (_bloodTestsBox)
    for (var key in _bloodTestsBox.keys) {
      final data = _bloodTestsBox.get(key);
      if (data != null) {
        final map = Map<String, dynamic>.from(data);
        final String? filePath = map['filePath'] ?? map['pdfPath'];
        
        if (filePath != null && filePath.isNotEmpty) {
          final file = File(filePath);
          if (await file.exists() && !filePath.contains(appDir.path)) {
            try {
              final fileName = '${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';
              final newPath = '${appDir.path}/$fileName';
              
              await file.copy(newPath);
              
              map['filePath'] = newPath;
              await _bloodTestsBox.put(key, map);
              consolidatedCount++;
            } catch (e) {
              print("⚠️ Errore durante il consolidamento del referto $key: $e");
            }
          }
        }
      }
    }

    return consolidatedCount;
  }
  
  // --- ESPORTAZIONE E IMPORTAZIONE DATI (BACKUP) ---

  /// Raccoglie tutti i dati da tutti i box di Hive e li restituisce come mappa JSON serializzabile
  Map<String, dynamic> exportAllData() {
    return {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'userBox': Map.from(_userBox.toMap()),
      'habitsBox': Map.from(_habitsBox.toMap()),
      'weightLogsBox': Map.from(_weightBox.toMap()),
      'measurementsBox': Map.from(_measurementsBox.toMap()),
      'photosBox': Map.from(_photosBox.toMap()),
      'bloodTestsBox': Map.from(_bloodTestsBox.toMap()),
      'mealsBox': Map.from(_mealsBox.toMap()),
    };
  }

  /// Converte tutti i dati in una stringa JSON formattata
  String exportToJsonString() {
    final data = exportAllData();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Sovrascrive o aggiorna i box di Hive con i dati provenienti da una mappa JSON di backup
  Future<void> importFromJsonMap(Map<String, dynamic> jsonData) async {
    if (jsonData.containsKey('userBox') && jsonData['userBox'] != null) {
      await _userBox.clear();
      await _userBox.putAll(Map<dynamic, dynamic>.from(jsonData['userBox']));
    }
    if (jsonData.containsKey('habitsBox') && jsonData['habitsBox'] != null) {
      await _habitsBox.clear();
      await _habitsBox.putAll(Map<dynamic, dynamic>.from(jsonData['habitsBox']));
    }
    if (jsonData.containsKey('weightLogsBox') && jsonData['weightLogsBox'] != null) {
      await _weightBox.clear();
      await _weightBox.putAll(Map<dynamic, dynamic>.from(jsonData['weightLogsBox']));
    }
    if (jsonData.containsKey('measurementsBox') && jsonData['measurementsBox'] != null) {
      await _measurementsBox.clear();
      await _measurementsBox.putAll(Map<dynamic, dynamic>.from(jsonData['measurementsBox']));
    }
    if (jsonData.containsKey('photosBox') && jsonData['photosBox'] != null) {
      await _photosBox.clear();
      await _photosBox.putAll(Map<dynamic, dynamic>.from(jsonData['photosBox']));
    }
    if (jsonData.containsKey('bloodTestsBox') && jsonData['bloodTestsBox'] != null) {
      await _bloodTestsBox.clear();
      await _bloodTestsBox.putAll(Map<dynamic, dynamic>.from(jsonData['bloodTestsBox']));
    }
    if (jsonData.containsKey('mealsBox') && jsonData['mealsBox'] != null) {
      await _mealsBox.clear();
      await _mealsBox.putAll(Map<dynamic, dynamic>.from(jsonData['mealsBox']));
    }
  }

  /// Esporta tutti i dati (JSON + file multimediali nella sandbox) in un unico archivio ZIP
  Future<String> exportToZipFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final zipPath = '${tempDir.path}/riparto_da_me_backup_$timestamp.zip';

    // 1. Crea il JSON dei dati
    final jsonString = exportToJsonString();
    
    // 2. Inizializza l'encoder ZIP
    final encoder = ZipFileEncoder();
    encoder.create(zipPath);

    // 3. Aggiunge temporaneamente il file JSON alla cartella temporanea e lo include nello zip
    final jsonFile = File('${tempDir.path}/backup.json');
    await jsonFile.writeAsString(jsonString);
    encoder.addFile(jsonFile);

    // 4. Aggiunge tutti i file presenti nella sandbox dell'app
    if (await appDir.exists()) {
      final List<FileSystemEntity> entities = appDir.listSync(recursive: false);
      for (var entity in entities) {
        if (entity is File) {
          encoder.addFile(entity);
        }
      }
    }

    encoder.close();
    if (await jsonFile.exists()) {
      await jsonFile.delete();
    }

    return zipPath;
  }

  /// Importa un archivio ZIP ripristinando il database JSON e tutti i file multimediali nella sandbox
  Future<void> importFromZipFile(File zipFile) async {
    final appDir = await getApplicationDocumentsDirectory();

    // 1. Legge e decodifica l'archivio ZIP
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    String? jsonContent;

    // 2. Estrae i file dall'archivio
    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        
        if (filename.endsWith('backup.json')) {
          jsonContent = utf8.decode(data);
        } else {
          final cleanName = filename.split('/').last;
          final targetFile = File('${appDir.path}/$cleanName');
          await targetFile.writeAsBytes(data);
        }
      }
    }

    // 3. Importa i dati nei box Hive se il file di backup è presente
    if (jsonContent != null) {
      final Map<String, dynamic> jsonData = jsonDecode(jsonContent);
      await importFromJsonMap(jsonData);
    } else {
      throw Exception('File backup.json non trovato nell\'archivio ZIP.');
    }
  }
  
}

// Funzione di supporto interna per evitare ambiguità
dataNullCheckSafe(val) => val;
