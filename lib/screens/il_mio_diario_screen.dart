import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../theme/cozy_styles.dart';
import '../widgets/cozy_background.dart';
import '../widgets/cozy_widgets.dart';

class FoodItem {
  final String name;
  final String quantity;
  final int calories;

  FoodItem({required this.name, required this.quantity, required this.calories});
}

class MealEntry {
  final String title;
  final String icon;
  final List<FoodItem> items;
  String? photoPath;
  bool isRewardClaimed;

  MealEntry({
    required this.title,
    required this.icon,
    List<FoodItem>? items,
    this.photoPath,
    this.isRewardClaimed = false,
  }) : items = items ?? [];

  int get totalCalories => items.fold(0, (sum, item) => sum + item.calories);
}

class IlMioDiarioScreen extends StatefulWidget {
  const IlMioDiarioScreen({super.key});

  @override
  State<IlMioDiarioScreen> createState() => _IlMioDiarioScreenState();
}

class _IlMioDiarioScreenState extends State<IlMioDiarioScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  late UserModel _user;

  // Data selezionata per lo storico
  DateTime _selectedDate = DateTime.now();

  // Mappa che associa la stringa della data (es. "2026-09-17") ai pasti di quel giorno
  Map<String, List<MealEntry>> _dailyMealsMap = {};

  // Controller temporanei per l'inserimento della nuova portata
  final TextEditingController _foodController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = _storageService.getUser();
    // In un'applicazione reale potresti caricare la mappa dallo storage utente. 
    // Per ora inizializziamo la vista sulla data corrente.
  }

  @override
  void dispose() {
    _foodController.dispose();
    _quantityController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  // Ottiene la chiave stringa formattata per la data (es. "2026-09-17")
  String get _selectedDateKey {
    return "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
  }

  // Restituisce i pasti del giorno selezionato (creandoli vuoti se non esistono ancora)
  List<MealEntry> get _currentMeals {
    if (!_dailyMealsMap.containsKey(_selectedDateKey)) {
      _dailyMealsMap[_selectedDateKey] = [
        MealEntry(title: 'Colazione', icon: '🥐'),
        MealEntry(title: 'Pranzo', icon: '🍲'),
        MealEntry(title: 'Merenda', icon: '🍎'),
        MealEntry(title: 'Cena', icon: '🌙'),
      ];
    }
    return _dailyMealsMap[_selectedDateKey]!;
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  int get _totalDailyCalories {
    return _currentMeals.fold(0, (sum, meal) => sum + meal.totalCalories);
  }

  // Aggiunge una portata al pasto del giorno corrente
  void _addFoodItemToMeal(MealEntry meal) {
    if (_foodController.text.trim().isEmpty) return;

    final int cals = int.tryParse(_caloriesController.text) ?? 0;

    setState(() {
      meal.items.add(FoodItem(
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
  }

  void _removeFoodItem(MealEntry meal, int index) {
    setState(() {
      meal.items.removeAt(index);
    });
    _storageService.saveUser(_user);
  }

  void _simulateAiPhotoAnalysis(MealEntry meal) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CozyCard(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.woodAccent),
                SizedBox(height: 16),
                Text(
                  '🪄 L\'Elfo Magico IA sta analizzando il piatto...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.pop(context);

    setState(() {
      meal.photoPath = 'assets/images/placeholder_meal.png';
      meal.items.add(FoodItem(
        name: 'Piatto misto analizzato da IA',
        quantity: '1 porzione',
        calories: 450,
      ));

      if (!meal.isRewardClaimed) {
        meal.isRewardClaimed = true;
        _user.coins += 5;
      }
    });

    await _storageService.saveUser(_user);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF2E7D32),
        content: Text('✨ IA: Aggiunta portata da 450 kcal! +5 Rupie! 💎'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';
    final mealsList = _currentMeals; // Pasti legati unicamente al giorno selezionato

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
                    // 📅 Selettore Storico Data
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
                                style: const TextStyle(
                                  fontFamily: 'Serif',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
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

                    // 📊 Riepilogo Calorie Totali della Giornata Selezionata
                    CozyCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Totale Giornaliero: $_totalDailyCalories kcal',
                            style: const TextStyle(
                              fontFamily: 'Serif',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 📝 Lista Pasti del Giorno Selezionato
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: mealsList.length,
                      itemBuilder: (context, index) {
                        final meal = mealsList[index];

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
                                      style: const TextStyle(
                                        fontFamily: 'Serif',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.textPrimary,
                                      ),
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

                                // Portate salvate per questo pasto in questa specifica data
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

                                // Sezione inserimento nuova portata
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
                                      onPressed: () => _simulateAiPhotoAnalysis(meal),
                                      icon: const Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.woodAccent),
                                      label: const Text(
                                        'Foto & Calcola IA 🪄',
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
}
