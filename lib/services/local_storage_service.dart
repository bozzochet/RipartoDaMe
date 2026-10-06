import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import '../models/app_menu_models.dart';
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
  final Box _menuBox = Hive.box('menuBox');
  final Box _shoppingBox = Hive.box('shoppingBox');

  // --- GESTIONE MENU SETTIMANALE & SPESA ---

  Future<void> saveWeeklyMenu(List<DailyMenuModel> menu) async {
    final Map<String, dynamic> mapData = {
      for (var item in menu) item.dayName: item.toMap()
    };
    await _menuBox.put('current_menu', mapData);
  }

  List<DailyMenuModel> getWeeklyMenu() {
    final data = _menuBox.get('current_menu');
    if (data != null) {
      final Map<dynamic, dynamic> map = data;
      return map.values
          .map((e) => DailyMenuModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  Future<void> saveShoppingList(List<ShoppingItemModel> items) async {
    final Map<String, dynamic> mapData = {
      for (var item in items) item.id: item.toMap()
    };
    await _shoppingBox.put('current_shopping', mapData);
  }

  List<ShoppingItemModel> getShoppingList() {
    final data = _shoppingBox.get('current_shopping');
    if (data != null) {
      final Map<dynamic, dynamic> map = data;
      return map.values
          .map((e) => ShoppingItemModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

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

  Future<void> addReward(
      {int xpGained = 0, int coinsGained = 0, int heartsGained = 0}) async {
    final user = getUser();
    user.xp += xpGained;
    user.coins += coinsGained;

    if (user.heartsToday < user.maxHeartsDaily) {
      final int oldHearts = user.heartsToday;
      user.heartsToday += heartsGained;

      if (oldHearts < user.maxHeartsDaily &&
          user.heartsToday >= user.maxHeartsDaily) {
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
    final String dateKey =
        (entry.id.isNotEmpty) ? entry.id : entry.date.toIso8601String();
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
        print(
            "⚠️ Trovata entry corrotta nel box bloodTestsBox con chiave $key, la rimuovo: $e");
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

        if (storedId == id ||
            key.toString() == id ||
            key.toString().contains(id)) {
          keyToDelete = key;
          break;
        }
      }
    }

    if (keyToDelete != dataNullCheckSafe(keyToDelete)) {
      // Pulito
      if (keyToDelete != null) {
        await _bloodTestsBox.delete(keyToDelete);
        print(
            "✅ Entry eliminata con successo tramite chiave secondaria: $keyToDelete");
      }
    } else {
      final matchingKeys =
          _bloodTestsBox.keys.where((k) => k.toString().contains(id)).toList();
      for (var k in matchingKeys) {
        await _bloodTestsBox.delete(k);
      }
    }
  }

  // Metodo di comodo richiesto dalle schermate
  List<BloodUrineTestEntry> getBloodUrineTestEntries() =>
      getBloodTestsHistory();

  // --- GESTIONE DIARIO ALIMENTARE (PASTI) ---

  Future<void> saveMealsForDate(
      DateTime date, List<MealEntryModel> meals) async {
    final String dateKey = date.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> serializedMeals =
        meals.map((m) => m.toMap()).toList();
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
  Future<FileMaintenanceReport> consolidateExternalFiles() async {
    final appDir = await getApplicationDocumentsDirectory();
    final report = FileMaintenanceReport();

    final String appDirPath = path.normalize(appDir.path);

    bool isManagedFileName(String fileName) {
      return fileName.startsWith('body_photo_') ||
          fileName.startsWith('blood_test_') ||
          fileName.startsWith('meal_photo_');
    }

    String normalizeStoredPath(String storedPath) {
      final cleaned = storedPath.replaceFirst('file://', '');

      if (path.isAbsolute(cleaned)) {
        return path.normalize(cleaned);
      }

      return path.normalize(
        path.join(appDir.path, path.basename(cleaned)),
      );
    }

    bool isInsideAppDir(String filePath) {
      final normalized = path.normalize(filePath);

      return path.isWithin(appDirPath, normalized) ||
          path.equals(appDirPath, path.dirname(normalized));
    }

    Future<String> fileHash(File file) async {
      final digest = await sha256.bind(file.openRead()).first;
      return digest.toString();
    }

    // ------------------------------------------------------------
    // 1. CONSOLIDA UN SINGOLO FILE
    // ------------------------------------------------------------

    Future<String?> consolidateFile(
      String storedPath, {
      required String prefix,
    }) async {
      final normalizedStoredPath = normalizeStoredPath(storedPath);

      File sourceFile = File(normalizedStoredPath);

      if (!await sourceFile.exists()) {
        final fallback = File(
          path.join(appDir.path, path.basename(storedPath)),
        );

        if (await fallback.exists()) {
          sourceFile = fallback;
        }
      }

      if (!await sourceFile.exists()) {
        report.missingFiles++;
        return null;
      }

      report.checkedFiles++;

      final sourcePath = path.normalize(sourceFile.path);

      if (isInsideAppDir(sourcePath)) {
        report.alreadySafe++;
        return sourcePath;
      }

      final extension = path.extension(sourcePath);

      final destinationName =
          '${prefix}_${DateTime.now().microsecondsSinceEpoch}$extension';

      final destinationPath = path.join(
        appDir.path,
        destinationName,
      );

      await sourceFile.copy(destinationPath);

      report.consolidatedFiles++;

      return path.normalize(destinationPath);
    }

    // ------------------------------------------------------------
    // 2. CONSOLIDAMENTO + NORMALIZZAZIONE RIFERIMENTI HIVE
    // ------------------------------------------------------------

    // FOTO PROGRESSI
    for (final key in _photosBox.keys.toList()) {
      final data = _photosBox.get(key);
      if (data == null) continue;

      try {
        final map = Map<String, dynamic>.from(data);
        final storedPath = (map['imagePath'] ?? map['path'])?.toString();

        if (storedPath == null || storedPath.isEmpty) continue;

        final finalPath = await consolidateFile(
          storedPath,
          prefix: 'body_photo',
        );

        if (finalPath != null) {
          final newReference = path.basename(finalPath);

          if (map['imagePath'] != newReference) {
            map['imagePath'] = newReference;
            await _photosBox.put(key, map);
            report.updatedReferences++;
          }
        }
      } catch (e) {
        report.errors++;
        debugPrint('Errore foto progressi $key: $e');
      }
    }

    // REFERTI
    for (final key in _bloodTestsBox.keys.toList()) {
      final data = _bloodTestsBox.get(key);
      if (data == null) continue;

      try {
        final map = Map<String, dynamic>.from(data);
        final storedPath = (map['filePath'] ?? map['pdfPath'])?.toString();

        if (storedPath == null || storedPath.isEmpty) continue;

        final finalPath = await consolidateFile(
          storedPath,
          prefix: 'blood_test',
        );

        if (finalPath != null) {
          final newReference = path.basename(finalPath);

          if (map['filePath'] != newReference) {
            map['filePath'] = newReference;
            await _bloodTestsBox.put(key, map);
            report.updatedReferences++;
          }
        }
      } catch (e) {
        report.errors++;
        debugPrint('Errore referto $key: $e');
      }
    }

    // FOTO PASTI
    for (final key in _mealsBox.keys.toList()) {
      final data = _mealsBox.get(key);
      if (data == null) continue;

      try {
        final mealsData = List<dynamic>.from(data);
        bool changed = false;

        for (int i = 0; i < mealsData.length; i++) {
          final mealMap = Map<String, dynamic>.from(mealsData[i]);

          final rawPhotoPath = mealMap['photoPath']?.toString();

          if (rawPhotoPath == null || rawPhotoPath.isEmpty) {
            continue;
          }

          final oldReferences = rawPhotoPath
              .split('|')
              .where((item) => item.trim().isNotEmpty)
              .toList();

          final List<String> newReferences = [];

          for (final storedPath in oldReferences) {
            final finalPath = await consolidateFile(
              storedPath,
              prefix: 'meal_photo',
            );

            if (finalPath != null) {
              newReferences.add(path.basename(finalPath));
            } else {
              newReferences.add(storedPath);
            }
          }

          final newPhotoPath = newReferences.join('|');

          if (newPhotoPath != rawPhotoPath) {
            mealMap['photoPath'] = newPhotoPath;
            mealsData[i] = mealMap;
            changed = true;
            report.updatedReferences++;
          }
        }

        if (changed) {
          await _mealsBox.put(key, mealsData);
        }
      } catch (e) {
        report.errors++;
        debugPrint('Errore foto pasti $key: $e');
      }
    }

    // ------------------------------------------------------------
    // 3. FUNZIONE CHE RICOSTRUISCE I RIFERIMENTI DA HIVE
    // ------------------------------------------------------------

    Set<String> collectReferencedPaths() {
      final result = <String>{};

      for (final key in _photosBox.keys) {
        final data = _photosBox.get(key);
        if (data == null) continue;

        try {
          final map = Map<String, dynamic>.from(data);
          final storedPath = (map['imagePath'] ?? map['path'])?.toString();

          if (storedPath != null && storedPath.isNotEmpty) {
            result.add(normalizeStoredPath(storedPath));
          }
        } catch (_) {}
      }

      for (final key in _bloodTestsBox.keys) {
        final data = _bloodTestsBox.get(key);
        if (data == null) continue;

        try {
          final map = Map<String, dynamic>.from(data);
          final storedPath = (map['filePath'] ?? map['pdfPath'])?.toString();

          if (storedPath != null && storedPath.isNotEmpty) {
            result.add(normalizeStoredPath(storedPath));
          }
        } catch (_) {}
      }

      for (final key in _mealsBox.keys) {
        final data = _mealsBox.get(key);
        if (data == null) continue;

        try {
          final mealsData = List<dynamic>.from(data);

          for (final meal in mealsData) {
            final mealMap = Map<String, dynamic>.from(meal);

            final rawPhotoPath = mealMap['photoPath']?.toString();

            if (rawPhotoPath == null || rawPhotoPath.isEmpty) {
              continue;
            }

            for (final storedPath in rawPhotoPath.split('|')) {
              if (storedPath.trim().isNotEmpty) {
                result.add(normalizeStoredPath(storedPath));
              }
            }
          }
        } catch (_) {}
      }

      return result;
    }

    // ------------------------------------------------------------
    // 4. FUNZIONE CHE LEGGE I FILE FISICI GESTITI
    // ------------------------------------------------------------

    List<File> getManagedFiles() {
      if (!appDir.existsSync()) return [];

      return appDir
          .listSync(recursive: false, followLinks: false)
          .whereType<File>()
          .where(
            (file) => isManagedFileName(
              path.basename(file.path),
            ),
          )
          .toList();
    }

    // Prima fotografia dello stato.
    var referencedPaths = collectReferencedPaths();
    var managedFiles = getManagedFiles();

    report.managedFilesBefore = managedFiles.length;
    report.uniqueReferencedFiles = referencedPaths.length;

    // ------------------------------------------------------------
    // 5. INDICE SHA-256
    // ------------------------------------------------------------

    final Map<String, List<File>> filesByHash = {};

    for (final file in managedFiles) {
      try {
        final hash = await fileHash(file);

        filesByHash.putIfAbsent(hash, () => []).add(file);
      } catch (e) {
        report.errors++;
        debugPrint(
          'Impossibile calcolare hash di ${file.path}: $e',
        );
      }
    }

    // ------------------------------------------------------------
    // 6. DEDUPLICAZIONE DEI FILE REFERENZIATI
    // ------------------------------------------------------------

    for (final group in filesByHash.values) {
      if (group.length <= 1) continue;

      report.duplicateGroups++;

      final referencedFiles = group.where((file) {
        return referencedPaths.contains(
          path.normalize(file.path),
        );
      }).toList();

      if (referencedFiles.isEmpty) {
        // Tutto il gruppo è orfano.
        // Verrà trattato nella pulizia degli orfani.
        continue;
      }

      // Scegliamo come canonico il primo file realmente referenziato.
      final canonicalFile = referencedFiles.first;
      final canonicalName = path.basename(canonicalFile.path);
      final canonicalPath = path.normalize(canonicalFile.path);

      final duplicatePaths = group
          .map((file) => path.normalize(file.path))
          .where((filePath) => filePath != canonicalPath)
          .toSet();

      if (duplicatePaths.isEmpty) continue;

      // ----------------------------------------------------------
      // 6A. AGGIORNA FOTO PROGRESSI
      // ----------------------------------------------------------

      for (final key in _photosBox.keys.toList()) {
        final data = _photosBox.get(key);
        if (data == null) continue;

        try {
          final map = Map<String, dynamic>.from(data);
          final storedPath = (map['imagePath'] ?? map['path'])?.toString();

          if (storedPath == null || storedPath.isEmpty) {
            continue;
          }

          final normalized = normalizeStoredPath(storedPath);

          if (duplicatePaths.contains(normalized)) {
            map['imagePath'] = canonicalName;
            await _photosBox.put(key, map);
            report.updatedReferences++;
          }
        } catch (e) {
          report.errors++;
        }
      }

      // ----------------------------------------------------------
      // 6B. AGGIORNA REFERTI
      // ----------------------------------------------------------

      for (final key in _bloodTestsBox.keys.toList()) {
        final data = _bloodTestsBox.get(key);
        if (data == null) continue;

        try {
          final map = Map<String, dynamic>.from(data);
          final storedPath = (map['filePath'] ?? map['pdfPath'])?.toString();

          if (storedPath == null || storedPath.isEmpty) {
            continue;
          }

          final normalized = normalizeStoredPath(storedPath);

          if (duplicatePaths.contains(normalized)) {
            map['filePath'] = canonicalName;
            await _bloodTestsBox.put(key, map);
            report.updatedReferences++;
          }
        } catch (e) {
          report.errors++;
        }
      }

      // ----------------------------------------------------------
      // 6C. AGGIORNA FOTO PASTI
      // ----------------------------------------------------------

      for (final key in _mealsBox.keys.toList()) {
        final data = _mealsBox.get(key);
        if (data == null) continue;

        try {
          final mealsData = List<dynamic>.from(data);
          bool changed = false;

          for (int i = 0; i < mealsData.length; i++) {
            final mealMap = Map<String, dynamic>.from(mealsData[i]);

            final rawPhotoPath = mealMap['photoPath']?.toString();

            if (rawPhotoPath == null || rawPhotoPath.isEmpty) {
              continue;
            }

            final refs = rawPhotoPath
                .split('|')
                .where((value) => value.trim().isNotEmpty)
                .toList();

            bool mealChanged = false;

            final newRefs = refs.map((storedPath) {
              final normalized = normalizeStoredPath(storedPath);

              if (duplicatePaths.contains(normalized)) {
                mealChanged = true;
                return canonicalName;
              }

              return storedPath;
            }).toList();

            // Se nello stesso pasto due riferimenti sono diventati
            // la stessa immagine, ne teniamo uno solo.
            final deduplicatedRefs = <String>[];

            for (final reference in newRefs) {
              if (!deduplicatedRefs.contains(reference)) {
                deduplicatedRefs.add(reference);
              }
            }

            if (mealChanged || deduplicatedRefs.length != refs.length) {
              mealMap['photoPath'] = deduplicatedRefs.join('|');
              mealsData[i] = mealMap;
              changed = true;
            }
          }

          if (changed) {
            await _mealsBox.put(key, mealsData);
            report.updatedReferences++;
          }
        } catch (e) {
          report.errors++;
        }
      }
    }

    // ------------------------------------------------------------
    // 7. BARRIERA DI SICUREZZA
    //
    // RICOSTRUIAMO I RIFERIMENTI DA HIVE DOPO GLI AGGIORNAMENTI.
    // ------------------------------------------------------------

    referencedPaths = collectReferencedPaths();
    managedFiles = getManagedFiles();

    // Se un riferimento Hive dovrebbe indicare un file gestito ma
    // quel file non esiste, non eseguiamo nessuna cancellazione.
    final existingManagedPaths =
        managedFiles.map((file) => path.normalize(file.path)).toSet();

    final managedReferences = referencedPaths.where((reference) {
      return isManagedFileName(path.basename(reference));
    }).toSet();

    final invalidReferences = managedReferences
        .where(
          (reference) => !existingManagedPaths.contains(reference),
        )
        .toList();

    report.invalidReferences = invalidReferences.length;

    if (report.invalidReferences > 0 || report.errors > 0) {
      report.cleanupAborted = true;
      report.managedFilesAfter = managedFiles.length;
      return report;
    }

    // ------------------------------------------------------------
    // 8. PIANO DI CANCELLAZIONE
    //
    // DOPO LA DEDUPLICAZIONE, QUALSIASI FILE GESTITO CHE NON È
    // REFERENZIATO DA HIVE È REALMENTE ORFANO.
    // ------------------------------------------------------------

    final filesToDelete = managedFiles.where((file) {
      final normalized = path.normalize(file.path);
      return !referencedPaths.contains(normalized);
    }).toList();

    int bytesToRecover = 0;

    for (final file in filesToDelete) {
      try {
        bytesToRecover += await file.length();
      } catch (_) {}
    }

    // ------------------------------------------------------------
    // 9. ULTIMO CONTROLLO SUBITO PRIMA DELLA DELETE
    // ------------------------------------------------------------

    final finalReferencesBeforeDelete = collectReferencedPaths();

    for (final file in filesToDelete) {
      final normalized = path.normalize(file.path);

      if (finalReferencesBeforeDelete.contains(normalized)) {
        report.cleanupAborted = true;
        report.errors++;
        report.managedFilesAfter = managedFiles.length;

        debugPrint(
          'Pulizia interrotta: ${file.path} '
          'risulta ancora referenziato.',
        );

        return report;
      }
    }

    // ------------------------------------------------------------
    // 10. CANCELLAZIONE DEFINITIVA
    // ------------------------------------------------------------

    for (final file in filesToDelete) {
      try {
        final filePath = path.normalize(file.path);

        // Classificazione solo per report.
        final hash = await fileHash(file);
        final group = filesByHash[hash] ?? const <File>[];

        final hasAnotherCopy = group.any(
          (other) =>
              path.normalize(other.path) != filePath &&
              !filesToDelete.any(
                (candidate) =>
                    path.normalize(candidate.path) ==
                    path.normalize(other.path),
              ),
        );

        await file.delete();

        report.deletedFiles++;

        if (hasAnotherCopy) {
          report.deletedDuplicateFiles++;
        } else {
          report.deletedOrphanFiles++;
        }
      } catch (e) {
        report.errors++;

        debugPrint(
          'Errore eliminando ${file.path}: $e',
        );
      }
    }

    report.recoveredBytes = bytesToRecover;

    // ------------------------------------------------------------
    // 11. VERIFICA FINALE
    // ------------------------------------------------------------

    final finalManagedFiles = getManagedFiles();
    final finalReferences = collectReferencedPaths();

    report.managedFilesAfter = finalManagedFiles.length;

    final finalManagedPaths =
        finalManagedFiles.map((file) => path.normalize(file.path)).toSet();

    // Ogni file gestito rimasto deve essere referenziato.
    final remainingOrphans = finalManagedPaths
        .where(
          (filePath) => !finalReferences.contains(filePath),
        )
        .toList();

    // Ogni riferimento gestito deve avere il relativo file.
    final remainingInvalidReferences = finalReferences
        .where(
          (reference) =>
              isManagedFileName(path.basename(reference)) &&
              !finalManagedPaths.contains(reference),
        )
        .toList();

    // Verifichiamo anche che non esistano più copie fisiche
    // identiche tra i file gestiti rimasti.
    final Map<String, int> finalHashes = {};

    for (final file in finalManagedFiles) {
      try {
        final hash = await fileHash(file);
        finalHashes[hash] = (finalHashes[hash] ?? 0) + 1;
      } catch (e) {
        report.errors++;
      }
    }

    final remainingDuplicateCopies =
        finalHashes.values.where((count) => count > 1).fold<int>(
              0,
              (total, count) => total + count - 1,
            );

    report.remainingOrphans = remainingOrphans.length;
    report.remainingDuplicates = remainingDuplicateCopies;
    report.invalidReferences = remainingInvalidReferences.length;

    report.integrityVerified = report.errors == 0 &&
        report.remainingOrphans == 0 &&
        report.remainingDuplicates == 0 &&
        report.invalidReferences == 0;

    return report;
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
      await _habitsBox
          .putAll(Map<dynamic, dynamic>.from(jsonData['habitsBox']));
    }
    if (jsonData.containsKey('weightLogsBox') &&
        jsonData['weightLogsBox'] != null) {
      await _weightBox.clear();
      await _weightBox
          .putAll(Map<dynamic, dynamic>.from(jsonData['weightLogsBox']));
    }
    if (jsonData.containsKey('measurementsBox') &&
        jsonData['measurementsBox'] != null) {
      await _measurementsBox.clear();
      await _measurementsBox
          .putAll(Map<dynamic, dynamic>.from(jsonData['measurementsBox']));
    }
    if (jsonData.containsKey('photosBox') && jsonData['photosBox'] != null) {
      await _photosBox.clear();
      await _photosBox
          .putAll(Map<dynamic, dynamic>.from(jsonData['photosBox']));
    }
    if (jsonData.containsKey('bloodTestsBox') &&
        jsonData['bloodTestsBox'] != null) {
      await _bloodTestsBox.clear();
      await _bloodTestsBox
          .putAll(Map<dynamic, dynamic>.from(jsonData['bloodTestsBox']));
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

class FileMaintenanceReport {
  int checkedFiles = 0;
  int consolidatedFiles = 0;
  int alreadySafe = 0;
  int missingFiles = 0;

  int managedFilesBefore = 0;
  int managedFilesAfter = 0;
  int uniqueReferencedFiles = 0;

  int duplicateGroups = 0;

  int updatedReferences = 0;

  int deletedFiles = 0;
  int deletedOrphanFiles = 0;
  int deletedDuplicateFiles = 0;

  int invalidReferences = 0;
  int remainingOrphans = 0;
  int remainingDuplicates = 0;

  int recoveredBytes = 0;
  int errors = 0;

  bool cleanupAborted = false;
  bool integrityVerified = false;

  double get recoveredMegabytes => recoveredBytes / (1024 * 1024);
}

// Funzione di supporto interna per evitare ambiguità
dataNullCheckSafe(val) => val;
