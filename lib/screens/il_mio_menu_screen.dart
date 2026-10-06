import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
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
  String _dietStyle = 'Standard';
  bool _isHalal = false;
  bool _isKosher = false;

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
    final apiKey = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';

    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gemini non è configurato: manca GEMINI_API_KEY.'),
        ),
      );
      return;
    }

    final caloriesText = _caloriesController.text.trim();
    final calories = caloriesText.isEmpty ? null : int.tryParse(caloriesText);
    if (caloriesText.isNotEmpty && (calories == null || calories <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un target calorico valido.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final requirements = <String>[
        if (_isHalal) 'Halal',
        if (_isKosher) 'Kosher',
      ];
      final excludedFoods = _excludedFoodsController.text.trim();
      final prompt = '''
Crea un menu alimentare settimanale in italiano per una persona adulta.

VINCOLI OBBLIGATORI:
- Genera esattamente 7 giorni: Lunedì, Martedì, Mercoledì, Giovedì, Venerdì, Sabato, Domenica.
- Ogni giorno deve contenere esattamente 4 pasti: Colazione, Pranzo, Merenda, Cena.
- Stile alimentare: $_dietStyle.
- Target calorico giornaliero: ${calories == null ? 'non specificato' : '$calories kcal'}.
- Requisiti aggiuntivi: ${requirements.isEmpty ? 'nessuno' : requirements.join(', ')}.
- Alimenti da escludere: ${excludedFoods.isEmpty ? 'nessuno' : excludedFoods}.
- Rispetta rigorosamente stile alimentare, requisiti ed esclusioni.
- Ogni pasto deve avere una descrizione sintetica e almeno un ingrediente.
- Per ogni ingrediente fornisci quantity come numero positivo e unit separata.
- Usa unità semplici e coerenti, preferendo g, ml e pz quando appropriato.
- category deve essere ESATTAMENTE una fra: Frigo, Carne e Pesce, Frutta, Verdura, Dispensa, Pane, Generale.
- calories è opzionale; se presente deve essere un numero positivo.
- Non generare la lista della spesa: verrà calcolata dall'app a partire dagli ingredienti.
- Non aggiungere testo, markdown o spiegazioni fuori dal JSON.

Restituisci esclusivamente un oggetto JSON conforme a questa struttura:
${MenuAiContract.jsonShape}
''';

      final model = GenerativeModel(
        model: 'gemini-3.6-flash',
        apiKey: apiKey,
        generationConfig:
            GenerationConfig(responseMimeType: 'application/json'),
      );
      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text?.trim();
      if (responseText == null || responseText.isEmpty) {
        throw const MenuAiValidationException(
            'Gemini ha restituito una risposta vuota.');
      }

      final decoded = jsonDecode(responseText);
      if (decoded is! Map) {
        throw const MenuAiValidationException(
            'Gemini non ha restituito un oggetto JSON.');
      }
      final parsedMenu =
          MenuAiContract.parseResponse(Map<String, dynamic>.from(decoded));
      final parsedShoppingList =
          _storageService.buildShoppingListFromMenu(parsedMenu);

      await _storageService.saveWeeklyMenu(parsedMenu);
      await _storageService.saveShoppingList(parsedShoppingList);

      if (!mounted) return;
      setState(() {
        _weeklyMenu = parsedMenu;
        _shoppingList = parsedShoppingList;
        _isLoading = false;
        _showGenerator = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Menu AI e lista della spesa creati.'),
        ),
      );
    } on MenuAiValidationException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Risposta AI non valida: ${e.message}')),
      );
    } on FormatException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JSON Gemini non valido: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante la generazione AI: $e')),
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
            DropdownButtonFormField<String>(
              value: _dietStyle,
              decoration: CozyStyles.cozyInputDecoration('Stile alimentare'),
              items: const [
                DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                DropdownMenuItem(
                    value: 'Vegetariano', child: Text('Vegetariano')),
                DropdownMenuItem(value: 'Vegano', child: Text('Vegano')),
                DropdownMenuItem(
                    value: 'Chetogenico', child: Text('Chetogenico')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _dietStyle = value);
              },
            ),
            const SizedBox(height: 10),
            CozyWoodCard(
              padding: EdgeInsets.zero,
              overlayOpacity: 0.78,
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    dense: true,
                    title: const Text('Halal'),
                    subtitle:
                        const Text('Applica i requisiti alimentari Halal.'),
                    value: _isHalal,
                    onChanged: (value) => setState(() => _isHalal = value),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    dense: true,
                    title: const Text('Kosher'),
                    subtitle:
                        const Text('Applica i requisiti alimentari Kosher.'),
                    value: _isKosher,
                    onChanged: (value) => setState(() => _isKosher = value),
                  ),
                ],
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
