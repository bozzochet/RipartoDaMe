import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/cozy_styles.dart';
import '../widgets/cozy_widgets.dart';
import '../widgets/cozy_background.dart';
import '../widgets/avatar_view.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';
import '../constants/app_assets.dart';

class CharacterEditorScreen extends StatefulWidget {
  const CharacterEditorScreen({super.key});

  @override
  State<CharacterEditorScreen> createState() => _CharacterEditorScreenState();
}

class _CharacterEditorScreenState extends State<CharacterEditorScreen> with SingleTickerProviderStateMixin {
  final LocalStorageService _storageService = LocalStorageService();
  late UserModel _user;
  late TabController _tabController;

  late String _selectedBody;
  late String _selectedHair;
  late String _selectedOutfit;

  final List<Map<String, String>> _bodies = [
    {'id': 'body_1', 'name': 'Tono 1', 'asset': AppAssets.bodyBase1},
    {'id': 'body_2', 'name': 'Tono 2', 'asset': AppAssets.bodyBase2},
    {'id': 'body_3', 'name': 'Tono 3', 'asset': AppAssets.bodyBase3},
    {'id': 'body_4', 'name': 'Tono 4', 'asset': AppAssets.bodyBase4},
    {'id': 'body_5', 'name': 'Tono 5', 'asset': AppAssets.bodyBase5},
    {'id': 'body_6', 'name': 'Tono 6', 'asset': AppAssets.bodyBase6},
  ];  
  
  final List<Map<String, String>> _outfits = [
    {'id': 'outfit_1', 'name': 'Alchimista', 'asset': AppAssets.outfitAlchemist},
    {'id': 'outfit_2', 'name': 'Hero', 'asset': AppAssets.outfitHero},
    {'id': 'outfit_3', 'name': 'Butterfly', 'asset': AppAssets.outfitButterfly},
	  {'id': 'outfit_4', 'name': 'Fairy', 'asset': AppAssets.outfitFairy},
	  {'id': 'outfit_5', 'name': 'Hunter', 'asset': AppAssets.outfitHunter},
	  {'id': 'outfit_6', 'name': 'Princess', 'asset': AppAssets.outfitPrincess},
	  {'id': 'outfit_7', 'name': 'Thief', 'asset': AppAssets.outfitThief},
	  {'id': 'outfit_8', 'name': 'Witch', 'asset': AppAssets.outfitWitch},
    {'id': 'outfit_9', 'name': 'Nudo / Intimo', 'asset': ''},
  ];

  final List<Map<String, String>> _hairs = [
    {'id': 'hair_1', 'name': 'Trecce Bionde', 'asset': AppAssets.hairBlondeBraids},
    {'id': 'hair_2', 'name': 'Caschetto Castani', 'asset': AppAssets.hairBrownBob},
    {'id': 'hair_3', 'name': 'Caschetto Rossi', 'asset': AppAssets.hairRedBob},
    {'id': 'hair_4', 'name': 'Coda Castani', 'asset': AppAssets.hairBrunettePonytail},
    {'id': 'hair_5', 'name': 'Mossi Biondi', 'asset': AppAssets.hairBlondeWaves},
    {'id': 'hair_6', 'name': 'Mossi Castani', 'asset': AppAssets.hairBrownWaves},
    {'id': 'hair_7', 'name': 'Classici Biondi', 'asset': AppAssets.hairBlondeClassic},
    {'id': 'hair_8', 'name': 'Nonna Argentati', 'asset': AppAssets.hairSilverGranny},
    {'id': 'hair_9', 'name': 'Nessuno', 'asset': ''},
  ];

  @override
  void initState() {
    super.initState();
    _user = _storageService.getUser();
    _tabController = TabController(length: 3, vsync: this);

    _selectedBody = _user.avatarConfig.bodyPath;
    _selectedHair = _user.avatarConfig.hairPath;
    _selectedOutfit = _user.avatarConfig.outfitPath;
  }

  void _saveAvatar() async {
    _user.avatarConfig.bodyPath = _selectedBody;
    _user.avatarConfig.hairPath = _selectedHair;
    _user.avatarConfig.outfitPath = _selectedOutfit;

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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CozyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Specchio Magico', style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold)),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: SizedBox(
                  height: 38,
                  child: CozyButton(
                    text: 'Salva',
                    icon: Icons.check,
                    isSelected: true,
                    verticalPadding: 4,
                    onPressed: _saveAvatar,
                  ),
                ),
              ),
            )
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 12),

            Center(
              child: CozyWoodCard(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: 220,
                  height: 320,
                  child: AvatarView(
                    bodyPath: _selectedBody,
                    hairPath: _selectedHair,
                    outfitPath: _selectedOutfit,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.woodAccent,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(icon: Icon(Icons.person), text: 'Corpo'),
                Tab(icon: Icon(Icons.checkroom), text: 'Abiti'),
                Tab(icon: Icon(Icons.face), text: 'Capelli'),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAssetGrid(_bodies, _selectedBody, (asset) => setState(() => _selectedBody = asset)),
                  _buildAssetGrid(_outfits, _selectedOutfit, (asset) => setState(() => _selectedOutfit = asset)),
                  _buildAssetGrid(_hairs, _selectedHair, (asset) => setState(() => _selectedHair = asset)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetGrid(List<Map<String, String>> items, String currentSelected, Function(String) onSelect) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final assetPath = item['asset']!;
        final isSelected = currentSelected == assetPath;

        return GestureDetector(
          onTap: () => onSelect(assetPath),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.woodAccent : Colors.transparent,
                width: isSelected ? 3.0 : 0.0,
              ),
            ),
            child: CozyWoodCard(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: assetPath.isNotEmpty
                          ? Image.asset(assetPath, fit: BoxFit.contain)
                          : const Icon(Icons.block, color: AppColors.textSecondary),
                    ),
                  ),
                  Text(
                    item['name']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.woodAccent : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
