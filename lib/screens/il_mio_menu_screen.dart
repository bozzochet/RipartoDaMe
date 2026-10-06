import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/local_storage_service.dart';
import '../models/app_menu_models.dart';
import '../theme/app_theme.dart';
import '../theme/cozy_styles.dart';
import '../widgets/cozy_background.dart';
import '../widgets/cozy_widgets.dart';

class IlMioMenuScreen extends StatefulWidget {
  const IlMioMenuScreen({super.key});

  @override
  State<IlMioMenuScreen> createState() => _IlMioMenuScreenState();
}

class _IlMioMenuScreenState extends State<IlMioMenuScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LocalStorageService _storageService = LocalStorageService();

  bool _isLoading = false;
  bool _showGenerator = false;
  File? _selectedDietFile;

  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _excludedFoodsController =
      TextEditingController();
  bool _isKeto = false;

  List<DailyMenuModel> _weeklyMenu = [];
  List<ShoppingItemModel> _shoppingList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _caloriesController.dispose();
    _excludedFoodsController.dispose();
    super.dispose();
  }

  void _loadSavedData() {
    setState(() {
      _weeklyMenu = _storageService.getWeeklyMenu();
      _shoppingList = _storageService.getShoppingList();
      _showGenerator = _weeklyMenu.isEmpty;
    });
  }

  Future<void> _pickDietDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );

    if (result != null && result.single.path != null) {
      setState(() {
        _selectedDietFile = File(result.single.path!);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dieta caricata con successo. Pronta per l\'analisi.'),
        ),
      );
    }
  }

  Future<void> _generateMenuWithAI() async {
    setState(() => _isLoading = true);

    try {
      // Dati demo invariati. La chiamata AI reale verra integrata in seguito.
      await Future.delayed(const Duration(seconds: 3));

      _weeklyMenu = [
        DailyMenuModel(dayName: 'Lunedì', meals: [
          MenuMealModel(
              mealType: 'Colazione',
              description: 'Yogurt greco con noci e frutti di bosco',
              ingredients: [
                MenuIngredientModel(
                    name: 'Yogurt greco',
                    quantity: 150,
                    unit: 'g',
                    category: 'Frigo'),
                MenuIngredientModel(
                    name: 'Noci',
                    quantity: 20,
                    unit: 'g',
                    category: 'Dispensa'),
                MenuIngredientModel(
                    name: 'Frutti di bosco',
                    quantity: 80,
                    unit: 'g',
                    category: 'Frutta')
              ]),
          MenuMealModel(
              mealType: 'Pranzo',
              description: 'Petto di pollo con insalata mista e olio EVO',
              ingredients: [
                MenuIngredientModel(
                    name: 'Petto di pollo',
                    quantity: 200,
                    unit: 'g',
                    category: 'Carne e Pesce'),
                MenuIngredientModel(
                    name: 'Insalata mista',
                    quantity: 150,
                    unit: 'g',
                    category: 'Verdura'),
                MenuIngredientModel(
                    name: 'Olio EVO',
                    quantity: 15,
                    unit: 'ml',
                    category: 'Dispensa')
              ]),
          MenuMealModel(
              mealType: 'Merenda',
              description: 'Mandorle',
              ingredients: [
                MenuIngredientModel(
                    name: 'Mandorle',
                    quantity: 25,
                    unit: 'g',
                    category: 'Dispensa')
              ]),
          MenuMealModel(
              mealType: 'Cena',
              description: 'Salmone al forno con asparagi',
              ingredients: [
                MenuIngredientModel(
                    name: 'Salmone fresco',
                    quantity: 180,
                    unit: 'g',
                    category: 'Carne e Pesce'),
                MenuIngredientModel(
                    name: 'Asparagi',
                    quantity: 200,
                    unit: 'g',
                    category: 'Verdura')
              ]),
        ]),
        DailyMenuModel(dayName: 'Martedì', meals: [
          MenuMealModel(
              mealType: 'Colazione',
              description: 'Uova strapazzate e tè verde',
              ingredients: [
                MenuIngredientModel(
                    name: 'Uova', quantity: 2, unit: 'pz', category: 'Frigo'),
                MenuIngredientModel(
                    name: 'Tè verde',
                    quantity: 1,
                    unit: 'bustina',
                    category: 'Dispensa')
              ]),
          MenuMealModel(
              mealType: 'Pranzo',
              description: 'Merluzzo con broccoli al vapore',
              ingredients: [
                MenuIngredientModel(
                    name: 'Merluzzo',
                    quantity: 200,
                    unit: 'g',
                    category: 'Carne e Pesce'),
                MenuIngredientModel(
                    name: 'Broccoli',
                    quantity: 250,
                    unit: 'g',
                    category: 'Verdura')
              ]),
          MenuMealModel(
              mealType: 'Merenda',
              description: 'Yogurt magro',
              ingredients: [
                MenuIngredientModel(
                    name: 'Yogurt magro',
                    quantity: 125,
                    unit: 'g',
                    category: 'Frigo')
              ]),
          MenuMealModel(
              mealType: 'Cena',
              description: 'Tacchino con zucchine',
              ingredients: [
                MenuIngredientModel(
                    name: 'Tacchino',
                    quantity: 180,
                    unit: 'g',
                    category: 'Carne e Pesce'),
                MenuIngredientModel(
                    name: 'Zucchine',
                    quantity: 250,
                    unit: 'g',
                    category: 'Verdura')
              ]),
        ]),
        DailyMenuModel(dayName: 'Mercoledì', meals: [
          MenuMealModel(
              mealType: 'Colazione',
              description: 'Porridge con banana',
              ingredients: [
                MenuIngredientModel(
                    name: 'Fiocchi di avena',
                    quantity: 50,
                    unit: 'g',
                    category: 'Dispensa'),
                MenuIngredientModel(
                    name: 'Banana',
                    quantity: 1,
                    unit: 'pz',
                    category: 'Frutta'),
                MenuIngredientModel(
                    name: 'Latte', quantity: 150, unit: 'ml', category: 'Frigo')
              ]),
          MenuMealModel(
              mealType: 'Pranzo',
              description: 'Riso basmati con pollo e verdure',
              ingredients: [
                MenuIngredientModel(
                    name: 'Riso basmati',
                    quantity: 80,
                    unit: 'g',
                    category: 'Dispensa'),
                MenuIngredientModel(
                    name: 'Petto di pollo',
                    quantity: 180,
                    unit: 'g',
                    category: 'Carne e Pesce'),
                MenuIngredientModel(
                    name: 'Verdure miste',
                    quantity: 200,
                    unit: 'g',
                    category: 'Verdura')
              ]),
          MenuMealModel(
              mealType: 'Merenda',
              description: 'Mela e noci',
              ingredients: [
                MenuIngredientModel(
                    name: 'Mela', quantity: 1, unit: 'pz', category: 'Frutta'),
                MenuIngredientModel(
                    name: 'Noci', quantity: 15, unit: 'g', category: 'Dispensa')
              ]),
          MenuMealModel(
              mealType: 'Cena',
              description: 'Frittata con spinaci',
              ingredients: [
                MenuIngredientModel(
                    name: 'Uova', quantity: 3, unit: 'pz', category: 'Frigo'),
                MenuIngredientModel(
                    name: 'Spinaci',
                    quantity: 200,
                    unit: 'g',
                    category: 'Verdura')
              ]),
        ]),
        DailyMenuModel(dayName: 'Giovedì', meals: [
          MenuMealModel(
              mealType: 'Colazione',
              description: 'Yogurt greco con mandorle',
              ingredients: [
                MenuIngredientModel(
                    name: 'Yogurt greco',
                    quantity: 150,
                    unit: 'g',
                    category: 'Frigo'),
                MenuIngredientModel(
                    name: 'Mandorle',
                    quantity: 20,
                    unit: 'g',
                    category: 'Dispensa')
              ]),
          MenuMealModel(
              mealType: 'Pranzo',
              description: 'Tacchino con quinoa e zucchine',
              ingredients: [
                MenuIngredientModel(
                    name: 'Tacchino',
                    quantity: 180,
                    unit: 'g',
                    category: 'Carne e Pesce'),
                MenuIngredientModel(
                    name: 'Quinoa',
                    quantity: 80,
                    unit: 'g',
                    category: 'Dispensa'),
                MenuIngredientModel(
                    name: 'Zucchine',
                    quantity: 200,
                    unit: 'g',
                    category: 'Verdura')
              ]),
          MenuMealModel(
              mealType: 'Merenda',
              description: 'Frutti di bosco',
              ingredients: [
                MenuIngredientModel(
                    name: 'Frutti di bosco',
                    quantity: 120,
                    unit: 'g',
                    category: 'Frutta')
              ]),
          MenuMealModel(
              mealType: 'Cena',
              description: 'Orata con insalata',
              ingredients: [
                MenuIngredientModel(
                    name: 'Orata',
                    quantity: 200,
                    unit: 'g',
                    category: 'Carne e Pesce'),
                MenuIngredientModel(
                    name: 'Insalata mista',
                    quantity: 180,
                    unit: 'g',
                    category: 'Verdura'),
                MenuIngredientModel(
                    name: 'Olio EVO',
                    quantity: 15,
                    unit: 'ml',
                    category: 'Dispensa')
              ]),
        ]),
        DailyMenuModel(dayName: 'Venerdì', meals: [
          MenuMealModel(
              mealType: 'Colazione',
              description: 'Pane integrale con ricotta',
              ingredients: [
                MenuIngredientModel(
                    name: 'Pane integrale',
                    quantity: 70,
                    unit: 'g',
                    category: 'Pane'),
                MenuIngredientModel(
                    name: 'Ricotta', quantity: 80, unit: 'g', category: 'Frigo')
              ]),
          MenuMealModel(
              mealType: 'Pranzo',
              description: 'Pasta integrale al pomodoro',
              ingredients: [
                MenuIngredientModel(
                    name: 'Pasta integrale',
                    quantity: 90,
                    unit: 'g',
                    category: 'Dispensa'),
                MenuIngredientModel(
                    name: 'Passata di pomodoro',
                    quantity: 120,
                    unit: 'g',
                    category: 'Dispensa')
              ]),
          MenuMealModel(
              mealType: 'Merenda',
              description: 'Yogurt magro',
              ingredients: [
                MenuIngredientModel(
                    name: 'Yogurt magro',
                    quantity: 125,
                    unit: 'g',
                    category: 'Frigo')
              ]),
          MenuMealModel(
              mealType: 'Cena',
              description: 'Pollo con verdure al forno',
              ingredients: [
                MenuIngredientModel(
                    name: 'Petto di pollo',
                    quantity: 200,
                    unit: 'g',
                    category: 'Carne e Pesce'),
                MenuIngredientModel(
                    name: 'Verdure miste',
                    quantity: 250,
                    unit: 'g',
                    category: 'Verdura')
              ]),
        ]),
        DailyMenuModel(dayName: 'Sabato', meals: [
          MenuMealModel(
              mealType: 'Colazione',
              description: 'Uova e pane integrale',
              ingredients: [
                MenuIngredientModel(
                    name: 'Uova', quantity: 2, unit: 'pz', category: 'Frigo'),
                MenuIngredientModel(
                    name: 'Pane integrale',
                    quantity: 60,
                    unit: 'g',
                    category: 'Pane')
              ]),
          MenuMealModel(
              mealType: 'Pranzo',
              description: 'Salmone con riso e broccoli',
              ingredients: [
                MenuIngredientModel(
                    name: 'Salmone fresco',
                    quantity: 180,
                    unit: 'g',
                    category: 'Carne e Pesce'),
                MenuIngredientModel(
                    name: 'Riso basmati',
                    quantity: 80,
                    unit: 'g',
                    category: 'Dispensa'),
                MenuIngredientModel(
                    name: 'Broccoli',
                    quantity: 200,
                    unit: 'g',
                    category: 'Verdura')
              ]),
          MenuMealModel(
              mealType: 'Merenda',
              description: 'Banana e mandorle',
              ingredients: [
                MenuIngredientModel(
                    name: 'Banana',
                    quantity: 1,
                    unit: 'pz',
                    category: 'Frutta'),
                MenuIngredientModel(
                    name: 'Mandorle',
                    quantity: 20,
                    unit: 'g',
                    category: 'Dispensa')
              ]),
          MenuMealModel(
              mealType: 'Cena',
              description: 'Tacchino con insalata',
              ingredients: [
                MenuIngredientModel(
                    name: 'Tacchino',
                    quantity: 180,
                    unit: 'g',
                    category: 'Carne e Pesce'),
                MenuIngredientModel(
                    name: 'Insalata mista',
                    quantity: 180,
                    unit: 'g',
                    category: 'Verdura')
              ]),
        ]),
        DailyMenuModel(dayName: 'Domenica', meals: [
          MenuMealModel(
              mealType: 'Colazione',
              description: 'Yogurt greco con frutta',
              ingredients: [
                MenuIngredientModel(
                    name: 'Yogurt greco',
                    quantity: 150,
                    unit: 'g',
                    category: 'Frigo'),
                MenuIngredientModel(
                    name: 'Mela', quantity: 1, unit: 'pz', category: 'Frutta')
              ]),
          MenuMealModel(
              mealType: 'Pranzo',
              description: 'Pollo con patate al forno',
              ingredients: [
                MenuIngredientModel(
                    name: 'Petto di pollo',
                    quantity: 220,
                    unit: 'g',
                    category: 'Carne e Pesce'),
                MenuIngredientModel(
                    name: 'Patate',
                    quantity: 250,
                    unit: 'g',
                    category: 'Verdura'),
                MenuIngredientModel(
                    name: 'Olio EVO',
                    quantity: 15,
                    unit: 'ml',
                    category: 'Dispensa')
              ]),
          MenuMealModel(
              mealType: 'Merenda',
              description: 'Noci e frutti di bosco',
              ingredients: [
                MenuIngredientModel(
                    name: 'Noci',
                    quantity: 20,
                    unit: 'g',
                    category: 'Dispensa'),
                MenuIngredientModel(
                    name: 'Frutti di bosco',
                    quantity: 100,
                    unit: 'g',
                    category: 'Frutta')
              ]),
          MenuMealModel(
              mealType: 'Cena',
              description: 'Merluzzo con spinaci',
              ingredients: [
                MenuIngredientModel(
                    name: 'Merluzzo',
                    quantity: 200,
                    unit: 'g',
                    category: 'Carne e Pesce'),
                MenuIngredientModel(
                    name: 'Spinaci',
                    quantity: 200,
                    unit: 'g',
                    category: 'Verdura')
              ]),
        ]),
      ];
      // 3A/3B: i dati demo passano dallo stesso contratto JSON e dallo
      // stesso parser rigoroso che useremo con la risposta reale di Gemini.
      _weeklyMenu = MenuAiContract.parseResponse(
        MenuAiContract.demoJsonFromMenu(_weeklyMenu),
      );
      _shoppingList = _storageService.buildShoppingListFromMenu(_weeklyMenu);
      await _storageService.saveWeeklyMenu(_weeklyMenu);
      await _storageService.saveShoppingList(_shoppingList);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _showGenerator = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Menu settimanale e lista della spesa creati.'),
        ),
      );
    } on MenuAiValidationException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Risposta AI non valida: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante la generazione: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CozyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Il mio Menu & Spesa',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Serif',
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(58),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _buildTabBar(),
            ),
          ),
        ),
        body: Stack(
          children: [
            SafeArea(
              top: false,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMenuTab(),
                  _buildShoppingTab(),
                ],
              ),
            ),
            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: AppColors.woodAccent,
      indicatorWeight: 4,
      labelColor: AppColors.woodAccent,
      unselectedLabelColor: AppColors.textSecondary,
      dividerColor: Colors.transparent,
      tabs: const [
        Tab(icon: Icon(Icons.restaurant_menu), text: 'Menu'),
        Tab(icon: Icon(Icons.shopping_cart_outlined), text: 'Spesa'),
      ],
    );
  }

  Widget _buildMenuTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (_weeklyMenu.isEmpty) ...[
          _buildEmptyMenuCard(),
          const SizedBox(height: 14),
          if (_showGenerator) _buildGeneratorCard(),
        ] else ...[
          if (_showGenerator) _buildGeneratorCard() else _buildMenuHeaderCard(),
          const SizedBox(height: 14),
          ..._weeklyMenu.map(_buildDayCard),
        ],
      ],
    );
  }

  Widget _buildEmptyMenuCard() {
    return CozyWoodCard(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(Icons.restaurant_menu,
                size: 42, color: AppColors.woodAccent),
            const SizedBox(height: 12),
            const Text(
              'Il tuo menu settimanale',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Serif',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea una settimana di pasti personalizzata e prepara automaticamente la lista della spesa.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 18),
            CozyButton(
              text: 'Crea il mio menu',
              icon: Icons.auto_awesome,
              onPressed: () => setState(() => _showGenerator = true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuHeaderCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CozyButton(
          text: 'Menu della Settimana',
          icon: Icons.calendar_month,
          isSelected: true,
          verticalPadding: 16,
          onPressed: () {},
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: CozyButton(
            text: 'Rigenera',
            icon: Icons.auto_awesome,
            isSecondary: true,
            verticalPadding: 8,
            onPressed: () => setState(() => _showGenerator = true),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratorCard() {
    final selectedName = _selectedDietFile == null
        ? null
        : _selectedDietFile!.path.split(Platform.pathSeparator).last;

    return CozyWoodCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppColors.woodAccent,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Crea con Intelligenza Artificiale',
                    style: TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (_weeklyMenu.isNotEmpty)
                  IconButton(
                    tooltip: 'Chiudi',
                    onPressed: () => setState(() => _showGenerator = false),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.woodAccent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Carica il piano del nutrizionista oppure indica le tue preferenze. Per ora la generazione usa ancora i dati demo.',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            if (selectedName == null)
              CozyButton(
                text: 'Carica PDF o foto dieta',
                icon: Icons.upload_file,
                woodAsset: 'assets/images/wood_texture_verylight.png',
                verticalPadding: 12,
                onPressed: _pickDietDocument,
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.woodAccent.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.woodAccent.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined,
                        color: AppColors.woodAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Piano alimentare caricato',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          Text(
                            selectedName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                        onPressed: _pickDietDocument,
                        child: const Text('Sostituisci')),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              decoration: CozyStyles.cozyInputDecoration(
                'Target calorie giornaliere (opzionale)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _excludedFoodsController,
              maxLines: 1,
              decoration: CozyStyles.cozyInputDecoration(
                'Alimenti da escludere (es. latticini, glutine)',
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile.adaptive(
                title: const Text('Dieta chetogenica'),
                subtitle: const Text('Solo se previsto dal tuo piano.'),
                value: _isKeto,
                onChanged: (value) => setState(() => _isKeto = value),
              ),
            ),
            const SizedBox(height: 12),
            CozyButton(
              text: _weeklyMenu.isEmpty
                  ? 'Crea Menu & Spesa'
                  : 'Rigenera Menu & Spesa',
              icon: Icons.auto_awesome,
              onPressed: _generateMenuWithAI,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(DailyMenuModel day) {
    return CozyWoodCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        title: Text(
          day.dayName,
          style: const TextStyle(
            fontFamily: 'Serif',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        children: day.meals.map((meal) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.woodAccent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.mealType,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.woodAccent)),
                const SizedBox(height: 4),
                Text(meal.description,
                    style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.textPrimary)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShoppingTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _buildShoppingHeaderCard(),
        const SizedBox(height: 14),
        if (_shoppingList.isEmpty)
          CozyWoodCard(
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 40, color: AppColors.woodAccent),
                  SizedBox(height: 10),
                  Text('La lista della spesa e vuota.',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          )
        else
          ..._buildShoppingSections(),
      ],
    );
  }

  Widget _buildShoppingHeaderCard() {
    final checked = _shoppingList.where((item) => item.isChecked).length;

    return CozyWoodCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.woodAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.shopping_basket_outlined,
                  color: AppColors.woodAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lista della spesa',
                    style: TextStyle(
                        fontFamily: 'Serif',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _shoppingList.isEmpty
                        ? 'Genera prima un menu settimanale.'
                        : '$checked di ${_shoppingList.length} prodotti acquistati',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildShoppingSections() {
    final grouped = <String, List<ShoppingItemModel>>{};

    for (final item in _shoppingList) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return grouped.entries.map((entry) {
      return CozyWoodCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  entry.key.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.bold,
                    color: AppColors.woodAccent,
                  ),
                ),
              ),
              const Divider(height: 12),
              ...entry.value.map((item) {
                return CheckboxListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 2),
                  dense: true,
                  controlAffinity: ListTileControlAffinity.trailing,
                  title: Text(
                    item.name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      decoration:
                          item.isChecked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: item.quantity == null
                      ? null
                      : Text(
                          '${item.quantity!.toStringAsFixed(item.quantity! % 1 == 0 ? 0 : 1)} ${item.unit ?? ''}'
                              .trim(),
                          style: const TextStyle(fontSize: 11),
                        ),
                  value: item.isChecked,
                  onChanged: (value) async {
                    setState(() => item.isChecked = value ?? false);
                    await _storageService.saveShoppingList(_shoppingList);
                  },
                );
              }),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        child: const Center(
          child: CozyCard(
            child: Padding(
              padding: EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.woodAccent),
                  SizedBox(height: 14),
                  Text(
                    'Sto creando il menu della settimana...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
