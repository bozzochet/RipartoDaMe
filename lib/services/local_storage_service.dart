import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/habit_model.dart';
import '../models/body_measurement_entry.dart';
import '../models/progress_photo_entry.dart';
import '../models/blood_test_entry.dart';
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

  // --- GESTIONE ANALISI DEL SANGUE ---
  
  Future<void> addBloodTestEntry(BloodTestEntry entry) async {
    // Se l'id è vuoto o nullo, generiamone uno sicuro basato sulla data o su un timestamp
    final String dateKey = (entry.id.isNotEmpty) ? entry.id : entry.date.toIso8601String();
    await _bloodTestsBox.put(dateKey, entry.toMap());
  }

  List<BloodTestEntry> getBloodTestsHistory() {
    final entries = <BloodTestEntry>[];
    
    for (var key in _bloodTestsBox.keys) {
      try {
        final data = _bloodTestsBox.get(key);
        if (data != null) {
          final map = Map<String, dynamic>.from(data);
          
          // Se per caso c'è un'entry con dati vuoti o corrotti che blocca la UI, la scartiamo o la fixiamo
          map['id'] = map['id'] ?? key.toString();
          
          // Controllo di sicurezza: se la data non è valida, evitiamo che faccia crashare la lista
          if (map['date'] != null) {
            entries.add(BloodTestEntry.fromMap(map));
          }
        }
      } catch (e) {
        print("⚠️ Trovata entry corrotta nel box bloodTestsBox con chiave $key, la rimuovo: $e");
        // Rimuove automaticamente dal database Hive la chiave corrotta che non si riusciva a cancellare!
        _bloodTestsBox.delete(key);
      }
    }
    
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  Future<void> deleteBloodTestEntry(String id) async {
    // 1. Tentativo standard con la chiave diretta
    if (_bloodTestsBox.containsKey(id)) {
      await _bloodTestsBox.delete(id);
      return;
    }

    // 2. Tentativo di ricerca avanzata: se la chiave diretta non corrisponde, 
    // controlliamo tutti gli elementi per trovare quello che ha quell'id o quella data/percorso simile
    dynamic keyToDelete;
    for (var key in _bloodTestsBox.keys) {
      final data = _bloodTestsBox.get(key);
      if (data != null) {
        final map = Map<String, dynamic>.from(data);
        final storedId = map['id']?.toString();
        
        // Se troviamo corrispondenza con l'ID o la chiave contiene l'ID cercato
        if (storedId == id || key.toString() == id || key.toString().contains(id)) {
          keyToDelete = key;
          break;
        }
      }
    }

    if (keyToDelete != null) {
      await _bloodTestsBox.delete(keyToDelete);
      print("✅ Entry eliminata con successo tramite chiave secondaria: $keyToDelete");
    } else {
      print("⚠️ Impossibile trovare la chiave esatta per l'id: $id. Provo una pulizia forzata per ID parziale.");
      // Ultimo tentativo estremo: cancella qualsiasi chiave che contenga la stringa dell'id
      final matchingKeys = _bloodTestsBox.keys.where((k) => k.toString().contains(id)).toList();
      for (var k in matchingKeys) {
        await _bloodTestsBox.delete(k);
      }
    }
  }
  
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
}
