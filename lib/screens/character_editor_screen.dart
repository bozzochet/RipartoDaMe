import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/cozy_widgets.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';

class CharacterEditorScreen extends StatefulWidget {
  const CharacterEditorScreen({super.key});

  @override
  State<CharacterEditorScreen> createState() => _CharacterEditorScreenState();
}

class _CharacterEditorScreenState extends State<CharacterEditorScreen> with SingleTickerProviderStateMixin {
  final LocalStorageService _storageService = LocalStorageService();
  late UserModel _user;
  late TabController _tabController;

  // Stato Locale dell'Avatar per la personalizzazione
  String _selectedHairStyle = '💇‍♀️';
  Color _selectedHairColor = const Color(0xFF4A3525);
  Color _selectedSkinColor = const Color(0xFFF5D0A9);
  String _selectedOutfit = '🧶';
  String _selectedHeadwear = '👑';

  // Opzioni Disponibili per la Personalizzazione
  final List<Map<String, String>> _hairStyles = [
    {'name': 'Corti Cozy', 'icon': '💇‍♀️'},
    {'name': 'Trecce del Bosco', 'icon': '👩‍🦱'},
    {'name': 'Ricci Morbidi', 'icon': '👩‍🦱'},
    {'name': 'Chioma Lunga', 'icon': '👱‍♀️'},
  ];

  final List<Color> _hairColors = [
    const Color(0xFF4A3525), // Castano Scuro
    const Color(0xFF8B5A2B), // Castano Chiaro / Miele
    const Color(0xFFE5C158), // Biondo Dorato
    const Color(0xFFC05621), // Rosso Rame
    const Color(0xFFD69E2E), // Biondo Zenzero
    const Color(0xFF4A5568), // Grigio Argento
    const Color(0xFFED64A6), // Rosa Fata
  ];

  final List<Color> _skinColors = [
    const Color(0xFFFFF0E5), // Porcellana
    const Color(0xFFF5D0A9), // Naturale Chiaro
    const Color(0xFFE0AC69), // Dorato/Miele
    const Color(0xFF8D5524), // Ambra
    const Color(0xFF523318), // Cioccolato
  ];

  final List<Map<String, String>> _outfits = [
    {'name': 'Maglione Oversize', 'icon': '🧶'},
    {'name': 'Mantello del Bosco', 'icon': '🧥'},
    {'name': 'Abito Estivo', 'icon': '👗'},
    {'name': 'Giacca da Esploratore', 'icon': '🥼'},
  ];

  @override
  void initState() {
    super.initState();
    _user = _storageService.getUser();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _saveAvatar() async {
    // Salviamo le scelte dell'avatar sul profilo utente
    // (Puoi estendere UserModel per includere AvatarConfig)
    await _storageService.saveUser(_user);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('✨ Nuovo look salvato con successo!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Specchio Magico'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CozyButton(
              text: 'Salva',
              icon: Icons.check,
              onPressed: _saveAvatar,
            ),
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // 1. ANTEPRIMA AVATAR DINAMICA
          Center(
            child: CozyCard(
              padding: const EdgeInsets.all(20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cerchio Sfondo
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceDark,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                  ),

                  // Viso/Pelle dell'Avatar
                  Positioned(
                    bottom: 35,
                    child: Container(
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedSkinColor,
                      ),
                      child: const Center(
                        child: Text('😊', style: TextStyle(fontSize: 45)),
                      ),
                    ),
                  ),

                  // Capelli (Colore tinto tramite filtro tinta o icona)
                  Positioned(
                    top: 15,
                    child: Text(
                      _selectedHairStyle,
                      style: TextStyle(
                        fontSize: 50,
                        shadows: [
                          Shadow(
                            color: _selectedHairColor,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Accessorio Testa
                  Positioned(
                    top: 5,
                    child: Text(_selectedHeadwear, style: const TextStyle(fontSize: 30)),
                  ),

                  // Abito Indossato
                  Positioned(
                    bottom: 5,
                    child: Text(_selectedOutfit, style: const TextStyle(fontSize: 45)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // TAB BAR PER SELEZIONARE LA CATEGORIA
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.woodAccent,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(icon: Icon(Icons.face), text: 'Capelli'),
              Tab(icon: Icon(Icons.color_lens), text: 'Toni'),
              Tab(icon: Icon(Icons.checkroom), text: 'Abiti'),
            ],
          ),

          // 2. SELEZIONE OPZIONI
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // SCHEDA 1: CAPELLI & ACCONCIATURE
                _buildStyleSelector(),

                // SCHEDA 2: COLORI CAPELLI E PELLE
                _buildColorSelector(),

                // SCHEDA 3: ABITI & ACCESSORI
                _buildOutfitSelector(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Selettore Stile Capelli
  Widget _buildStyleSelector() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: _hairStyles.length,
      itemBuilder: (context, index) {
        final item = _hairStyles[index];
        final isSelected = _selectedHairStyle == item['icon'];

        return GestureDetector(
          onTap: () => setState(() => _selectedHairStyle = item['icon']!),
          child: CozyCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item['icon']!, style: const TextStyle(fontSize: 36)),
                const SizedBox(height: 8),
                Text(
                  item['name']!,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.woodAccent : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Selettore Colori (Palette Tinte e Carnagione)
  Widget _buildColorSelector() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Colore Capelli',
            style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _hairColors.map((color) {
              final isSelected = _selectedHairColor == color;
              return GestureDetector(
                onTap: () => setState(() => _selectedHairColor = color),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.woodAccent : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          const Text(
            'Tonalità della Pelle',
            style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _skinColors.map((color) {
              final isSelected = _selectedSkinColor == color;
              return GestureDetector(
                onTap: () => setState(() => _selectedSkinColor = color),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.woodAccent : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: isSelected ? const Icon(Icons.check, color: AppColors.textPrimary, size: 20) : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Selettore Abiti
  Widget _buildOutfitSelector() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _outfits.length,
      itemBuilder: (context, index) {
        final outfit = _outfits[index];
        final isSelected = _selectedOutfit == outfit['icon'];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => setState(() => _selectedOutfit = outfit['icon']!),
            child: CozyCard(
              child: Row(
                children: [
                  Text(outfit['icon']!, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  Text(
                    outfit['name']!,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  if (isSelected) const Icon(Icons.check_circle, color: AppColors.woodAccent),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
