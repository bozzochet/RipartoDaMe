import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/cozy_widgets.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';

class FurnitureItem {
  final String id;
  final String name;
  final String icon;
  final String category; // 'piante', 'sedute', 'decorazioni'

  FurnitureItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.category,
  });
}

class LaMiaCasaScreen extends StatefulWidget {
  const LaMiaCasaScreen({super.key});

  @override
  State<LaMiaCasaScreen> createState() => _LaMiaCasaScreenState();
}

class _LaMiaCasaScreenState extends State<LaMiaCasaScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  late UserModel _user;

  // Inventario degli oggetti posseduti dall'utente
  final List<FurnitureItem> _inventory = [
    FurnitureItem(id: 'plant_1', name: 'Pianta della Luna', icon: '🪴', category: 'piante'),
    FurnitureItem(id: 'plant_2', name: 'Bonsai Antico', icon: '🪴', category: 'piante'),
    FurnitureItem(id: 'chair_1', name: 'Poltrona da Lettura', icon: '🛋️', category: 'sedute'),
    FurnitureItem(id: 'chair_2', name: 'Sedia in Legno', icon: '🪑', category: 'sedute'),
    FurnitureItem(id: 'decor_1', name: 'Set Tisana Relax', icon: '🫖', category: 'decorazioni'),
    FurnitureItem(id: 'decor_2', name: 'Caminetto Scoppiettante', icon: '🪵', category: 'decorazioni'),
  ];

  // Mobili attualmente posizionati negli slot della stanza
  String? _placedPlantIcon = '🪴';
  String? _placedChairIcon = '🛋️';
  String? _placedDecorIcon = '🫖';

  @override
  void initState() {
    super.initState();
    _user = _storageService.getUser();
  }

  // Apre il menu per scegliere cosa posizionare nello slot selezionato
  void _openFurniturePicker(String categoryName, String categoryKey, Function(String) onSelect) {
    final availableItems = _inventory.where((item) => item.category == categoryKey).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scegli arredo: $categoryName',
                style: const TextStyle(
                  fontFamily: 'Serif',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (availableItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Non possiedi ancora oggetti per questa categoria. Visita la Bottega!',
                    style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: availableItems.length,
                  itemBuilder: (context, index) {
                    final item = availableItems[index];
                    return GestureDetector(
                      onTap: () {
                        onSelect(item.icon);
                        Navigator.pop(context);
                      },
                      child: CozyCard(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(item.icon, style: const TextStyle(fontSize: 32)),
                            const SizedBox(height: 4),
                            Text(
                              item.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('La mia Casa'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. ANTEPRIMA STANZA INTERATTIVA CON SLOT POSIZIONATI
            CozyCard(
              padding: EdgeInsets.zero,
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Sfondo Stanza / Finestra
                    const Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Text(
                          '🪟 Vista sul Bosco',
                          style: TextStyle(
                            fontFamily: 'Serif',
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    // SLOT 1: Pianta (Sinistra)
                    Positioned(
                      left: 20,
                      bottom: 40,
                      child: _buildFurnitureSlot(
                        icon: _placedPlantIcon,
                        label: 'Davanzale',
                        onTap: () {
                          _openFurniturePicker('Pianti e Fiori', 'piante', (newIcon) {
                            setState(() => _placedPlantIcon = newIcon);
                          });
                        },
                      ),
                    ),

                    // SLOT 2: Tavolino / Decorazione (Centro)
                    Positioned(
                      left: 130,
                      bottom: 20,
                      child: _buildFurnitureSlot(
                        icon: _placedDecorIcon,
                        label: 'Tavolino',
                        onTap: () {
                          _openFurniturePicker('Decorazioni & Relax', 'decorazioni', (newIcon) {
                            setState(() => _placedDecorIcon = newIcon);
                          });
                        },
                      ),
                    ),

                    // SLOT 3: Poltrona / Seduta (Destra)
                    Positioned(
                      right: 20,
                      bottom: 40,
                      child: _buildFurnitureSlot(
                        icon: _placedChairIcon,
                        label: 'Angolo Lettura',
                        onTap: () {
                          _openFurniturePicker('Sedute & Comfort', 'sedute', (newIcon) {
                            setState(() => _placedChairIcon = newIcon);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 2. ISTRUZIONI E PANNELLO INVENTARIO
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Arredamento Stanza',
                style: TextStyle(
                  fontFamily: 'Serif',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tocca un punto della stanza qui sopra per cambiare o posizionare i mobili che possiedi.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget singolo slot di arredo con cerchio o icona
  Widget _buildFurnitureSlot({
    required String? icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.woodAccent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Text(
              icon ?? '➕',
              style: TextStyle(fontSize: icon != null ? 36 : 24),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
