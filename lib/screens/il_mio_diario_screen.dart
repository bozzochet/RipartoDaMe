import 'package:flutter/material.dart';
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
  late UserModel _user;

  // Data selezionata per lo storico
  DateTime _selectedDate = DateTime.now();
  
  // Lista locale dei pasti in memoria per evitare ricaricamenti errati
  List<MealEntryModel> _currentMealsList = [];

  // Controller temporanei per l'inserimento della nuova portata
  final TextEditingController _foodController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();

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
      _loadMealsForSelectedDate(); // Ricarica i pasti corretti per la nuova data
    });
  }

  int get _totalDailyCalories {
    return _currentMealsList.fold(0, (sum, meal) => sum + meal.totalCalories);
  }

  // Calcola le calorie totali per una specifica data (per il grafico)
  int _getCaloriesForDate(DateTime date) {
    final meals = _storageService.getMealsForDate(date);
    return meals.fold(0, (sum, meal) => sum + meal.totalCalories);
  }

  // Aggiunge una portata al pasto del giorno corrente e salva su Hive
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

  // Rimuove una portata specifica e aggiorna Hive
  void _removeFoodItem(MealEntryModel meal, int index) {
    setState(() {
      meal.items.removeAt(index);
    });
    _storageService.saveUser(_user);
    _storageService.saveMealsForDate(_selectedDate, _currentMealsList);
  }

  // Simulazione IA per scattare foto e aggiungere la portata automaticamente
  void _simulateAiPhotoAnalysis(MealEntryModel meal) async {
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
      meal.items.add(FoodItemModel(
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
    await _storageService.saveMealsForDate(_selectedDate, _currentMealsList);

    if (!mounted) return;
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

                    // 📊 Riepilogo Calorie Totali Giornaliere
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

                    // 📝 Lista Pasti
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

                    const SizedBox(height: 10),

                    // 📈 GRAFICO DELLE CALORIE DEGLI ULTIMI 7 GIORNI
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

  // Widget grafico a barre personalizzato per gli ultimi 7 giorni
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
                style: TextStyle(
                  fontFamily: 'Serif',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
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
                final cals = _getCaloriesForDate(day);
                final double barHeight = maxCals > 0 ? (cals / maxCals) * 80 : 0.0;
                final bool isSelectedDay = getDateKey(day) == getDateKey(_selectedDate);
                final dayLabel = '${day.day}/${day.month}';

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$cals',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isSelectedDay ? AppColors.woodAccent : AppColors.textSecondary,
                      ),
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
                      style: TextStyle(
                        fontSize: 9,
                        color: isSelectedDay ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: isSelectedDay ? FontWeight.bold : FontWeight.normal,
                      ),
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
