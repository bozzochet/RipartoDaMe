import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/local_storage_service.dart';
import '../models/app_menu_models.dart';
import '../theme/app_theme.dart';
import '../widgets/cozy_background.dart';
import '../widgets/cozy_widgets.dart';

class IlMioMenuScreen extends StatefulWidget {
  const IlMioMenuScreen({super.key});

  @override
  State<IlMioMenuScreen> createState() => _IlMioMenuScreenState();
}

class _IlMioMenuScreenState extends State<IlMioMenuScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LocalStorageService _storageService = LocalStorageService();
  
  bool _isLoading = false;
  File? _selectedDietFile;
  
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _excludedFoodsController = TextEditingController();
  bool _isKeto = false;

  List<DailyMenuModel> _weeklyMenu = [];
  List<ShoppingItemModel> _shoppingList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedData();
  }

  void _loadSavedData() {
    setState(() {
      _weeklyMenu = _storageService.getWeeklyMenu();
      _shoppingList = _storageService.getShoppingList();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📄 Dieta caricata con successo! Pronta per l\'analisi.')),
      );
    }
  }

  Future<void> _generateMenuWithAI() async {
    setState(() => _isLoading = true);

    try {
      // Qui integreresti la chiamata al tuo servizio Gemini passando:
      // - Il file (_selectedDietFile) se presente
      // - Le calorie (_caloriesController.text)
      // - Se è chetogenica (_isKeto)
      // - Gli alimenti esclusi (_excludedFoodsController.text)
      
      // Simulazione di risposta strutturata dell'IA per testare l'UI:
      await Future.delayed(const Duration(seconds: 3));

      _weeklyMenu = [
        DailyMenuModel(dayName: 'Lunedì', meals: {
          'Colazione': 'Yogurt greco con noci e frutti di bosco',
          'Pranzo': 'Petto di pollo alla griglia con insalata mista e olio EVO',
          'Merenda': 'Una manciata di mandorle',
          'Cena': 'Salmone al forno con asparagi saltati',
        }),
        DailyMenuModel(dayName: 'Martedì', meals: {
          'Colazione': 'Uova strapazzate e tè verde',
          'Pranzo': 'Filetto di merluzzo con broccoli al vapore',
          'Merenda': 'Yogurt magro',
          'Cena': 'Tacchino con zucchine padellate',
        }),
      ];

      _shoppingList = [
        ShoppingItemModel(id: '1', name: 'Yogurt greco', category: 'Frigo'),
        ShoppingItemModel(id: '2', name: 'Petto di pollo', category: 'Carne e Pesce'),
        ShoppingItemModel(id: '3', name: 'Salmone fresco', category: 'Carne e Pesce'),
        ShoppingItemModel(id: '4', name: 'Asparagi', category: 'Verdura'),
        ShoppingItemModel(id: '5', name: 'Mandorle', category: 'Dispensa'),
      ];

      await _storageService.saveWeeklyMenu(_weeklyMenu);
      await _storageService.saveShoppingList(_shoppingList);

      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.green, content: Text('✨ Menù settimanale e lista della spesa generati!')),
      );
      _tabController.animateTo(0); // Sposta sulla tab del Menu
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text('Errore generazione: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CozyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Il mio Menù & Spesa',
            style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Serif', fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.textPrimary,
            indicatorColor: AppColors.textPrimary,
            tabs: const [
              Tab(text: '📅 Menù Settimanale', icon: Icon(Icons.restaurant_menu, size: 18)),
              Tab(text: '🛒 Lista della Spesa', icon: Icon(Icons.shopping_cart, size: 18)),
            ],
          ),
        ),
        body: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.0, MediaQuery.of(context).padding.top + kToolbarHeight + 60.0, 16.0, 16.0),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMenuTab(),
                  _buildShoppingTab(),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('L\'IA sta creando il tuo menu su misura...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sezione Generazione / Parametri
          CozyWoodCard(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🤖 Genera con Intelligenza Artificiale', style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Carica la dieta del nutrizzionista o imposta i tuoi obiettivi personalizzati.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  
                  // Bottone Carica Dieta
                  OutlinedButton.icon(
                    onPressed: _pickDietDocument,
                    icon: const Icon(Icons.upload_file),
                    label: Text(_selectedDietFile == null ? 'Carica PDF/Foto Dieta' : 'Dieta caricata: ${_selectedDietFile!.path.split('/').last}'),
                  ),
                  const SizedBox(height: 12),

                  // Input Calorie
                  TextField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Target Kcal giornalorie (opzionale)', isDense: true),
                  ),
                  const SizedBox(height: 8),

                  // Input Alimenti da evitare
                  TextField(
                    controller: _excludedFoodsController,
                    decoration: const InputDecoration(labelText: 'Alimenti da escludere (es. latticini, glutine)', isDense: true),
                  ),
                  const SizedBox(height: 8),

                  // Switch Chetogenica
                  SwitchListTile(
                    title: const Text('Dieta Chetogenica', style: TextStyle(fontSize: 14)),
                    value: _isKeto,
                    onChanged: (val) => setState(() => _isKeto = val),
                    dense: true,
                  ),
                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerRight,
                    child: CozyButton(
                      text: 'Crea Menù & Spesa',
                      icon: Icons.auto_awesome,
                      onPressed: _generateMenuWithAI,
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Visualizzazione Menu Generato
          if (_weeklyMenu.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('Nessun menu generato. Usa il pannello sopra per iniziare!', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary))))
          else
            ..._weeklyMenu.map((day) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(day.dayName, style: const TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold)),
                    children: day.meals.entries.map((meal) => ListTile(
                      dense: true,
                      title: Text(meal.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(meal.value, style: const TextStyle(fontSize: 13)),
                    )).toList(),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildShoppingTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Lista della Spesa Automatica', style: TextStyle(fontFamily: 'Serif', fontSize: 16, fontWeight: FontWeight.bold)),
        const Text('Modifica o spunta gli ingredienti necessari per la settimana.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        Expanded(
          child: _shoppingList.isEmpty
              ? const Center(child: Text('La lista della spesa è vuota.', style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  itemCount: _shoppingList.length,
                  itemBuilder: (context, index) {
                    final item = _shoppingList[index];
                    return CheckboxListTile(
                      title: Text(item.name, style: TextStyle(decoration: item.isChecked ? TextDecoration.lineThrough : null)),
                      subtitle: Text(item.category, style: const TextStyle(fontSize: 11)),
                      value: item.isChecked,
                      onChanged: (val) async {
                        setState(() {
                          item.isChecked = val ?? false;
                        });
                        await _storageService.saveShoppingList(_shoppingList);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
