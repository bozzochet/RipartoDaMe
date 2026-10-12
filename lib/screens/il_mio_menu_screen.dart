import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:open_filex/open_filex.dart';
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
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _showGenerator = false;
  File? _selectedDietFile;

  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _excludedFoodsController =
      TextEditingController();
  String _dietStyle = 'Standard';
  bool _isHalal = false;
  bool _isKosher = false;
  bool _isAnalyzingDiet = false;
  bool _dietAnalysisComplete = false;

  List<DailyMenuModel> _weeklyMenu = [];
  List<ShoppingItemModel> _shoppingList = [];
  MenuGenerationInfo? _menuGenerationInfo;
  List<MenuHistoryEntry> _menuHistory = [];

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

  Future<void> _loadSavedData() async {
    final weeklyMenu = _storageService.getWeeklyMenu();
    final shoppingList = _storageService.getShoppingList();
    final generationInfo = _storageService.getMenuGenerationInfo();
    final menuHistory = await _storageService.getMenuHistory();
    if (!mounted) return;
    setState(() {
      _weeklyMenu = weeklyMenu;
      _shoppingList = shoppingList;
      _menuGenerationInfo = generationInfo;
      _menuHistory = menuHistory;
      _showGenerator = weeklyMenu.isEmpty;
    });
  }

  void _showDietFileSourceDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFFDF6E3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0xFF8B5A2B), width: 1.5),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            children: [
              const ListTile(
                title: Text(
                  'Aggiungi piano alimentare',
                  style: TextStyle(
                    fontFamily: 'Serif',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: AppColors.woodAccent,
                ),
                title: const Text(
                  'Scatta una foto',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickDietImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.woodAccent,
                ),
                title: const Text(
                  'Scegli dal rullino',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickDietImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.insert_drive_file,
                  color: AppColors.woodAccent,
                ),
                title: const Text(
                  'Scegli dai Documenti (PDF o immagine)',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickDietDocument();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDietImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (image == null) return;
      _setSelectedDietFile(File(image.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nella selezione della foto: $e')),
      );
    }
  }

  Future<void> _pickDietDocument() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
      );
      final selectedPath = result?.single.path;
      if (selectedPath == null) return;
      _setSelectedDietFile(File(selectedPath));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nella selezione del documento: $e')),
      );
    }
  }

  void _setSelectedDietFile(File file) {
    if (!mounted) return;
    setState(() {
      _selectedDietFile = file;
      _dietAnalysisComplete = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Piano caricato con successo. Pronto per l\'analisi.'),
      ),
    );
  }

  Future<void> _analyzeDietDocument() async {
    final dietFile = _selectedDietFile;
    if (dietFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Carica prima un PDF o una foto della dieta.')),
      );
      return;
    }

    final apiKey = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gemini non è configurato: manca GEMINI_API_KEY.')),
      );
      return;
    }

    setState(() => _isAnalyzingDiet = true);

    try {
      if (!await dietFile.exists()) {
        throw const MenuAiValidationException(
          'Il piano alimentare selezionato non è più disponibile.',
        );
      }

      final extension = dietFile.path.split('.').last.toLowerCase();
      late final String mimeType;
      switch (extension) {
        case 'pdf':
          mimeType = 'application/pdf';
          break;
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        default:
          throw MenuAiValidationException(
            'Formato del piano alimentare non supportato: .$extension',
          );
      }

      final bytes = await dietFile.readAsBytes();
      if (bytes.isEmpty) {
        throw const MenuAiValidationException(
            'Il piano alimentare selezionato è vuoto.');
      }

      const prompt = '''
Analizza il piano alimentare allegato e restituisci ESCLUSIVAMENTE un oggetto JSON valido con questa struttura:
{
  "targetCalories": 0,
  "dietStyle": "Standard",
  "excludedFoods": [],
  "halal": false,
  "kosher": false
}

Regole:
- targetCalories: usa il target calorico giornaliero esplicitamente indicato nel documento; se non è presente o non è affidabile, usa null.
- dietStyle deve essere ESATTAMENTE uno fra Standard, Vegetariano, Vegano, Chetogenico.
- Usa Chetogenico solo se il documento indica chiaramente un regime chetogenico/VLCKD.
- excludedFoods deve contenere solo alimenti o categorie esplicitamente vietati/esclusi nel documento. Non dedurre esclusioni dalle semplici assenze.
- halal deve essere true solo se il documento indica esplicitamente un requisito Halal.
- kosher deve essere true solo se il documento indica esplicitamente un requisito Kosher.
- Non aggiungere spiegazioni, markdown o testo fuori dal JSON.
''';

      final model = GenerativeModel(
        model: 'gemini-3.6-flash',
        apiKey: apiKey,
        generationConfig:
            GenerationConfig(responseMimeType: 'application/json'),
      );
      final response = await model.generateContent([
        Content.multi([TextPart(prompt), DataPart(mimeType, bytes)]),
      ]);
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
      final data = Map<String, dynamic>.from(decoded);

      final rawCalories = data['targetCalories'];
      int? targetCalories;
      if (rawCalories != null) {
        if (rawCalories is! num || rawCalories <= 0) {
          throw const MenuAiValidationException(
              'Il target calorico estratto non è valido.');
        }
        targetCalories = rawCalories.round();
      }

      final dietStyle = data['dietStyle']?.toString().trim() ?? '';
      const allowedStyles = {
        'Standard',
        'Vegetariano',
        'Vegano',
        'Chetogenico'
      };
      if (!allowedStyles.contains(dietStyle)) {
        throw MenuAiValidationException(
            'Stile alimentare estratto non valido: "$dietStyle".');
      }

      final rawExcluded = data['excludedFoods'];
      if (rawExcluded is! List) {
        throw const MenuAiValidationException(
            'La lista degli alimenti esclusi non è valida.');
      }
      final excludedFoods = rawExcluded
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();

      final halal = data['halal'];
      final kosher = data['kosher'];
      if (halal is! bool || kosher is! bool) {
        throw const MenuAiValidationException(
            'I requisiti Halal/Kosher estratti non sono validi.');
      }

      if (!mounted) return;
      setState(() {
        _caloriesController.text = targetCalories?.toString() ?? '';
        _excludedFoodsController.text = excludedFoods.join(', ');
        _dietStyle = dietStyle;
        _isHalal = halal;
        _isKosher = kosher;
        _dietAnalysisComplete = true;
        _isAnalyzingDiet = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            targetCalories == null
                ? 'Piano analizzato: stile $dietStyle. Controlla i campi prima di generare il menu.'
                : 'Piano analizzato: $dietStyle, $targetCalories kcal. Controlla i campi prima di generare il menu.',
          ),
        ),
      );
    } on FormatException catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzingDiet = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JSON Gemini non valido: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzingDiet = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l’analisi del piano: $e')),
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

      Uint8List? dietDocumentBytes;
      String? dietDocumentMimeType;
      String? dietDocumentName;

      if (_selectedDietFile != null) {
        final dietFile = _selectedDietFile!;
        if (!await dietFile.exists()) {
          throw const MenuAiValidationException(
            'Il piano alimentare selezionato non è più disponibile.',
          );
        }

        final extension = dietFile.path.split('.').last.toLowerCase();
        switch (extension) {
          case 'pdf':
            dietDocumentMimeType = 'application/pdf';
            break;
          case 'jpg':
          case 'jpeg':
            dietDocumentMimeType = 'image/jpeg';
            break;
          case 'png':
            dietDocumentMimeType = 'image/png';
            break;
          default:
            throw MenuAiValidationException(
              'Formato del piano alimentare non supportato: .$extension',
            );
        }

        dietDocumentBytes = await dietFile.readAsBytes();
        if (dietDocumentBytes.isEmpty) {
          throw const MenuAiValidationException(
            'Il piano alimentare selezionato è vuoto.',
          );
        }
        dietDocumentName = dietFile.path.split(Platform.pathSeparator).last;
      }

      final documentInstructions = dietDocumentName == null
          ? '- Nessun piano alimentare allegato.'
          : '''- Piano alimentare allegato: $dietDocumentName.
- Usa il piano alimentare allegato come fonte principale per alimenti, porzioni, frequenze e indicazioni nutrizionali.
- Se il documento non è organizzato su 7 giorni, distribuisci le indicazioni sui 7 giorni senza contraddirle.
- Non inventare sostituzioni che violino esplicitamente il piano allegato.
- Le esclusioni esplicite inserite dall'utente devono comunque essere rispettate; in caso di conflitto, evita gli alimenti esclusi e scegli un'alternativa compatibile con il resto del piano.''';

      final prompt = '''
Crea un menu alimentare settimanale in italiano per una persona adulta.

VINCOLI OBBLIGATORI:
- Genera esattamente 7 giorni: Lunedì, Martedì, Mercoledì, Giovedì, Venerdì, Sabato, Domenica.
- Ogni giorno deve contenere esattamente 5 pasti: Colazione, Spuntino, Pranzo, Merenda, Cena.
- Stile alimentare: $_dietStyle.
- Target calorico giornaliero: ${calories == null ? 'non specificato' : '$calories kcal'}.
- Requisiti aggiuntivi: ${requirements.isEmpty ? 'nessuno' : requirements.join(', ')}.
- Alimenti da escludere: ${excludedFoods.isEmpty ? 'nessuno' : excludedFoods}.
$documentInstructions
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
      final List<Content> content;
      if (dietDocumentBytes != null && dietDocumentMimeType != null) {
        content = [
          Content.multi([
            TextPart(prompt),
            DataPart(dietDocumentMimeType, dietDocumentBytes),
          ]),
        ];
      } else {
        content = [Content.text(prompt)];
      }

      final response = await model.generateContent(content);
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
      String? persistedDietDocumentPath;
      if (_selectedDietFile != null) {
        persistedDietDocumentPath =
            await _storageService.persistMenuDietDocument(_selectedDietFile!);
      }
      final generationInfo = MenuGenerationInfo(
        targetCalories: calories,
        dietStyle: _dietStyle,
        excludedFoods: excludedFoods
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(),
        halal: _isHalal,
        kosher: _isKosher,
        dietDocumentName: dietDocumentName,
        dietDocumentPath: persistedDietDocumentPath,
        generatedAt: DateTime.now(),
      );

      await _storageService.saveGeneratedMenu(
        menu: parsedMenu,
        shoppingList: parsedShoppingList,
        generationInfo: generationInfo,
      );
      final updatedHistory = await _storageService.getMenuHistory();

      if (!mounted) return;
      setState(() {
        _weeklyMenu = parsedMenu;
        _shoppingList = parsedShoppingList;
        _menuGenerationInfo = generationInfo;
        _menuHistory = updatedHistory;
        _isLoading = false;
        _showGenerator = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            dietDocumentName == null
                ? 'Menu AI e lista della spesa creati.'
                : 'Menu creato usando il piano alimentare allegato.',
          ),
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

  Future<void> _openDietDocument([MenuGenerationInfo? selectedInfo]) async {
    final info = selectedInfo ?? _menuGenerationInfo;
    final storedPath = info?.dietDocumentPath;
    final file = await _storageService.getMenuDietDocument(storedPath);
    if (!mounted) return;

    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Il piano alimentare salvato non è disponibile.'),
        ),
      );
      return;
    }

    final extension = file.path.split('.').last.toLowerCase();
    if (extension == 'pdf') {
      final result = await OpenFilex.open(file.path);
      if (!mounted) return;
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message.isEmpty
                  ? 'Impossibile aprire il piano alimentare.'
                  : result.message,
            ),
          ),
        );
      }
      return;
    }

    if (extension == 'jpg' || extension == 'jpeg' || extension == 'png') {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: AppColors.background,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 6, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        info?.dietDocumentName ?? 'Piano alimentare',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Serif',
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Chiudi',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5,
                  child: Image.file(
                    file,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Impossibile visualizzare questa immagine.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Formato del piano alimentare non supportato: .$extension'),
      ),
    );
  }

  String _formatMenuDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year} alle '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _activateHistoryEntry(
    MenuHistoryEntry entry, {
    bool closeOverlay = true,
  }) async {
    await _storageService.activateMenuHistoryEntry(entry);
    if (!mounted) return;
    if (closeOverlay && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    setState(() {
      _weeklyMenu = entry.menu;
      _shoppingList = entry.shoppingList
          .map((item) => ShoppingItemModel.fromMap(item.toMap()))
          .toList();
      _menuGenerationInfo = entry.generationInfo;
      _showGenerator = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Menu storico impostato come menu corrente.')),
    );
  }

  Future<void> _showMenuHistoryEntry(MenuHistoryEntry entry) async {
    final info = entry.generationInfo;
    final isCurrent = _menuGenerationInfo?.generatedAt == info.generatedAt;
    final details = <String>[
      if (info.targetCalories != null) '${info.targetCalories} kcal',
      info.dietStyle,
      if (info.halal) 'Halal',
      if (info.kosher) 'Kosher',
    ];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Row(
          children: [
            const Icon(Icons.history, color: AppColors.woodAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _formatMenuDate(info.generatedAt),
                style: const TextStyle(
                  fontFamily: 'Serif',
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: CozyWoodCard(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    details.join(' · '),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${entry.menu.length} giorni · '
                    '${entry.shoppingList.length} elementi nella spesa',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  if (info.excludedFoods.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Esclusi: ${info.excludedFoods.join(', ')}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                  if (info.dietDocumentName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Piano: ${info.dietDocumentName}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (info.dietDocumentPath != null)
                        TextButton.icon(
                          onPressed: () => _openDietDocument(info),
                          icon: const Icon(Icons.description_outlined),
                          label: const Text('Apri piano'),
                        ),
                      if (!isCurrent)
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _activateHistoryEntry(
                              entry,
                              closeOverlay: false,
                            );
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Rendi corrente'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteHistoryEntry(MenuHistoryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminare questo menu?'),
        content: Text(
          'Il menu del ${_formatMenuDate(entry.generationInfo.generatedAt)} '
          'verrà eliminato dallo storico. Il piano allegato sarà rimosso '
          'solo se non è usato da altri menu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _storageService.deleteMenuHistoryEntry(entry.id);
    final history = await _storageService.getMenuHistory();
    if (!mounted) return;
    setState(() {
      _menuHistory = history;
      _weeklyMenu = _storageService.getWeeklyMenu();
      _shoppingList = _storageService.getShoppingList();
      _menuGenerationInfo = _storageService.getMenuGenerationInfo();
      _showGenerator = _weeklyMenu.isEmpty;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Menu eliminato dallo storico.')),
    );
  }

  Widget _buildMenuHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: CozyButton(
            text: 'Storico Menu Generati',
            isSelected: true,
            onPressed: () {},
          ),
        ),
        const SizedBox(height: 8),
        if (_menuHistory.isEmpty)
          const CozyWoodCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Nessun menu salvato finora.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: _menuHistory.length,
            itemBuilder: (context, index) {
              final entry = _menuHistory[index];
              final info = entry.generationInfo;
              final date = info.generatedAt;
              final dateStr = '${date.day.toString().padLeft(2, '0')}/'
                  '${date.month.toString().padLeft(2, '0')}/${date.year}';
              final isCurrent = _menuGenerationInfo?.generatedAt == date;
              final preview = <String>[
                if (info.targetCalories != null) '${info.targetCalories} kcal',
                info.dietStyle,
                '${entry.menu.length} giorni',
              ].join(' · ');

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CozyWoodCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -2),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    onTap: () => _showMenuHistoryEntry(entry),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Menu del $dateStr',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Serif',
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (info.dietDocumentPath != null &&
                            info.dietDocumentPath!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.attach_file,
                            size: 16,
                            color: AppColors.woodAccent,
                          ),
                        ],
                        if (isCurrent) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.check_circle,
                            size: 15,
                            color: AppColors.woodAccent,
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: 'Elimina menu',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => _confirmDeleteHistoryEntry(entry),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
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
        _buildMenuHistorySection(),
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
    final info = _menuGenerationInfo;
    final headlineParts = <String>[
      if (info?.targetCalories != null) '${info!.targetCalories} kcal',
      if (info != null && info.dietStyle.isNotEmpty) info.dietStyle,
    ];
    final constraintParts = <String>[
      if (info?.halal == true) 'Halal',
      if (info?.kosher == true) 'Kosher',
      if (info != null && info.excludedFoods.isNotEmpty)
        'Esclusi: ${info.excludedFoods.join(', ')}',
    ];
    final generatedAtLabel = info == null
        ? null
        : '${info.generatedAt.day.toString().padLeft(2, '0')}/'
            '${info.generatedAt.month.toString().padLeft(2, '0')}/'
            '${info.generatedAt.year} alle '
            '${info.generatedAt.hour.toString().padLeft(2, '0')}:'
            '${info.generatedAt.minute.toString().padLeft(2, '0')}';

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
        if (info != null) ...[
          const SizedBox(height: 10),
          CozyWoodCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            overlayOpacity: 0.78,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (headlineParts.isNotEmpty)
                  Text(
                    headlineParts.join(' · '),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                if (info.dietDocumentName != null &&
                    info.dietDocumentName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Piano: ${info.dietDocumentName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (info.dietDocumentPath != null &&
                          info.dietDocumentPath!.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => _openDietDocument(),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Apri'),
                        ),
                    ],
                  ),
                ],
                if (constraintParts.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    constraintParts.join(' · '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (generatedAtLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Generato il $generatedAtLabel',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
              'Carica il piano del nutrizionista oppure indica le tue preferenze. Puoi verificare e modificare i dati rilevati prima di generare il menu.',
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
                onPressed: _showDietFileSourceDialog,
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
                          Text(
                              _dietAnalysisComplete
                                  ? 'Piano alimentare analizzato'
                                  : 'Piano alimentare caricato',
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
                        onPressed: _showDietFileSourceDialog,
                        child: const Text('Sostituisci')),
                  ],
                ),
              ),
            if (selectedName != null) ...[
              const SizedBox(height: 10),
              CozyButton(
                text: _isAnalyzingDiet
                    ? 'Analisi in corso...'
                    : (_dietAnalysisComplete
                        ? 'Rianalizza piano'
                        : 'Analizza piano'),
                icon:
                    _dietAnalysisComplete ? Icons.verified : Icons.auto_awesome,
                isSelected: _dietAnalysisComplete,
                onPressed: _isAnalyzingDiet ? null : _analyzeDietDocument,
              ),
              if (_dietAnalysisComplete) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 18, color: AppColors.success),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Piano analizzato. Verifica o modifica i campi prima di generare il menu.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
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
                Text(
                  meal.description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (meal.ingredients.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: meal.ingredients.map((ingredient) {
                      final quantity = ingredient.quantity.toStringAsFixed(
                        ingredient.quantity % 1 == 0 ? 0 : 1,
                      );
                      return Text(
                        '${ingredient.name}: $quantity ${ingredient.unit}',
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.25,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                ],
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
