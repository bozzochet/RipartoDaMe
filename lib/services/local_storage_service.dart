import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/habit_model.dart';

class LocalStorageService {
  final Box _userBox = Hive.box('userBox');
  final Box _habitsBox = Hive.box('habitsBox');
  final Box _weightBox = Hive.box('weightLogsBox');

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
        name: 'Giada',
        currentWeight: 94.0,
        targetWeight: 80.0,
        avatarConfig: AvatarConfig(
          hairStyle: 'short',
          outfitId: 'adventure',
        ),
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

  // Salva un nuovo rilievo del peso
  Future<void> addWeightEntry(double weight) async {
    final String dateKey = DateTime.now().toIso8601String().split('T')[0];
    await _weightBox.put(dateKey, {
      'date': DateTime.now().toIso8601String(),
      'weight': weight,
    });

    // Aggiorna anche il peso attuale nel profilo utente
    final user = getUser();
    user.currentWeight = weight;
    await saveUser(user);
  }
}
