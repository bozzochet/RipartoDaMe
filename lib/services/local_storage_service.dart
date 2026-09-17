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

  // Salva una nuova foto
  Future<void> addProgressPhoto(ProgressPhotoEntry photo) async {
    await _photosBox.put(photo.id, photo.toMap());
  }

  // Recupera lo storico delle foto ordinate per data (dalla più recente)
  List<ProgressPhotoEntry> getProgressPhotosHistory() {
    final entries = _photosBox.values
    .map((e) => ProgressPhotoEntry.fromMap(Map<String, dynamic>.from(e)))
    .toList();

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  // Elimina una foto dallo storico
  Future<void> deleteProgressPhoto(String photoId) async {
    await _photosBox.delete(photoId);
  }

  // --- GESTIONE PROFILO UTENTE & GAMIFICATION ---

  // Salva o aggiorna i dati utente
  Future<void> saveUser(UserModel user) async {
    await _userBox.put('profile', user.toMap());
  }

  // Recupera i dati utente (se non esistono, ne crea uno di default)
  UserModel getUser() {
    final data = _userBox.get('profile');
    if (data != null) {
      return UserModel.fromMap(Map<String, dynamic>.from(data));
    } else {
      // Dati iniziali di default al primo avvio
      return UserModel(
        id: 'user_local',
        name: 'Glenda',
        currentWeight: 94.0,
        targetWeight: 80.0,
        startWeight: 95.0,
        height: 165.0,
        currentHearts: 0,
        maxHearts: 10,
        coins: 0,
        xp: 0,
        avatarConfig: AvatarConfig(),
      );
    }
  }

  // Aggiungi XP o Monete quando si completa una missione
  Future<void> addReward({int xpGained = 0, int coinsGained = 0, int heartsGained = 0}) async {
    final user = getUser();
    user.xp += xpGained;
    user.coins += coinsGained;
    if (user.heartsToday < user.maxHeartsDaily) {
      user.heartsToday += heartsGained;
    }
    await saveUser(user);
  }

  // --- GESTIONE ABITUDINI ("Cura di Me") ---

  // Salva una lista di abitudini
  Future<void> saveHabits(List<HabitModel> habits) async {
    final Map<String, dynamic> habitsMap = {
      for (var habit in habits) habit.id: habit.toMap()
    };
    await _habitsBox.putAll(habitsMap);
  }

  // Recupera tutte le abitudini
  List<HabitModel> getHabits() {
    if (_habitsBox.isEmpty) {
      // Abitudini predefinite della schermata "Cura di me"
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

  // Spunta/Despunta un'abitudine
  Future<void> toggleHabit(String habitId) async {
    final habits = getHabits();
    final habit = habits.firstWhere((h) => h.id == habitId);
    
    habit.isCompletedToday = !habit.isCompletedToday;
    await _habitsBox.put(habitId, habit.toMap());

    // Se completata, assegna XP e cuore
    if (habit.isCompletedToday) {
      await addReward(xpGained: habit.rewardXp, heartsGained: 1);
    }
  }

  // --- GESTIONE PESO E MAPPA ---

  // Salva un nuovo rilievo del peso (supporta anche una data personalizzata)
  Future<void> addWeightEntry(double weight, {DateTime? customDate}) async {
    final DateTime targetDate = customDate ?? DateTime.now();
    final String dateKey = targetDate.toIso8601String().split('T')[0];

    await _weightBox.put(dateKey, {
        'date': targetDate.toIso8601String(),
        'weight': weight,
    });

    // Aggiorna anche il peso attuale nel profilo utente
    final user = getUser();
    user.currentWeight = weight;
    await saveUser(user);
  }

  // Recupera lo storico completo ordinato in modo cronologico (dal meno recente al più recente)
  List<WeightEntry> getWeightHistory() {
    final entries = _weightBox.values
    .map((e) => WeightEntry.fromMap(Map<String, dynamic>.from(e)))
    .toList();

    // Ordina le date per il grafico
    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }

  // Elimina una registrazione dal peso tramite la chiave di data YYYY-MM-DD
  Future<void> deleteWeightEntry(DateTime date) async {
    final String dateKey = date.toIso8601String().split('T')[0];
    await _weightBox.delete(dateKey);
  }

  // --- GESTIONE MISURAZIONI CORPOREE (AGGIUNTA) ---

  Future<void> addBodyMeasurement(BodyMeasurementEntry entry) async {
    final String dateKey = entry.date.toIso8601String().split('T')[0];
    await _measurementsBox.put(dateKey, entry.toMap());
  }

  List<BodyMeasurementEntry> getBodyMeasurementsHistory() {
    final entries = _measurementsBox.values
    .map((e) => BodyMeasurementEntry.fromMap(Map<String, dynamic>.from(e)))
    .toList();

    entries.sort((a, b) => b.date.compareTo(a.date)); // Dalla più recente alla più vecchia
    return entries;
  }

  BodyMeasurementEntry? getLatestBodyMeasurement() {
    final history = getBodyMeasurementsHistory();
    return history.isNotEmpty ? history.first : null;
  }
  
  // --- GESTIONE ANALISI DEL SANGUE ---
  
  Future<void> addBloodTestEntry(BloodTestEntry entry) async {
    final String dateKey = entry.date.toIso8601String().split('T')[0];
    await _bloodTestsBox.put(dateKey, entry.toMap());
  }
  
  List<BloodTestEntry> getBloodTestsHistory() {
    final entries = _bloodTestsBox.values
    .map((e) => BloodTestEntry.fromMap(Map<String, dynamic>.from(e)))
    .toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }
  
  Future<void> deleteBloodTestEntry(String id) async {
    await _bloodTestsBox.delete(id);
  }

  // --- GESTIONE DIARIO ALIMENTARE (PASTI) ---

  // Salva la lista dei pasti per una data specifica (chiave es. "2026-09-17")
  Future<void> saveMealsForDate(DateTime date, List<MealEntryModel> meals) async {
    final String dateKey = date.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> serializedMeals = meals.map((m) => m.toMap()).toList();
    await _mealsBox.put(dateKey, serializedMeals);
  }

  // Recupera i pasti per una data specifica in modo sicuro
  List<MealEntryModel> getMealsForDate(DateTime date) {
    final String dateKey = date.toIso8601String().split('T')[0];
    final data = _mealsBox.get(dateKey);

    if (data != null) {
      try {
        final List<dynamic> list = data;
        return list.map((e) {
          // Converte in sicurezza la mappa gestendo i tipi dinamici di Hive
          final map = Map<dynamic, dynamic>.from(e);
          final stringKeyMap = map.map((k, v) => MapEntry(k.toString(), v));
          return MealEntryModel.fromMap(stringKeyMap);
        }).toList();
      } catch (e) {
        // Stampa l'errore in console se qualcosa va storto, così lo vediamo subito
        print("⚠️ Errore di decodifica pasti da Hive: $e");
      }
    }

    // Default se non ci sono dati salvati per quel giorno
    return [
      MealEntryModel(title: 'Colazione', icon: '🥐'),
      MealEntryModel(title: 'Pranzo', icon: '🍲'),
      MealEntryModel(title: 'Merenda', icon: '🍎'),
      MealEntryModel(title: 'Cena', icon: '🌙'),
    ];
  }  
  
}
