import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/cozy_widgets.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';
import 'character_editor_screen.dart';
import 'il_mio_corpo_screen.dart';
import 'la_mia_casa_screen.dart';
import 'shop_screen.dart';
import 'cura_di_me_screen.dart';
import 'la_mia_mappa_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  late UserModel _user;

  final TextEditingController _nameController = TextEditingController();
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    _user = _storageService.getUser();
    _nameController.text = _user.name;
  }

  void _refreshData() {
    setState(() {
      _loadUser();
    });
  }

  void _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      _user.name = newName;
      await _storageService.saveUser(_user);
      setState(() {
        _isEditingName = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 60,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/home_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // CONTENUTO PRINCIPALE
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // -------------------------------------------------------------
                  // 1. CARD AVATAR PRINCIPALE (FISSA IN ALTO E COMPATTA)
                  // -------------------------------------------------------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 38.0),
                    child: Opacity(
                      opacity: 0.68, // Rende la card dell'avatar leggermente trasparente
                      child: CozyCard(
                        // Padding verticale ridotto per ridurre l'altezza della box
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // Occupa solo la spessore strettamente necessario
                          children: [
                            CozyAvatar(
                              size: 85,
                              user: _user, // Passa l'utente aggiornato
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const CharacterEditorScreen()),
                                );
                                _refreshData();
                              },
                            ),
                            const SizedBox(height: 2), // Distanza ridotta
                            if (_isEditingName)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 140,
                                  child: TextField(
                                    controller: _nameController,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Serif',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 2),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                                  onPressed: _saveName,
                                ),
                              ],
                            )
                            else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _user.name,
                                  style: const TextStyle(
                                    fontFamily: 'Serif',
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.only(left: 4),
                                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                                  onPressed: () {
                                    setState(() {
                                        _isEditingName = true;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const Text(
                              'Tocca l\'avatar per cambiare look 🪞',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // -------------------------------------------------------------
                  // 2. AREA SCROLLABILE (SOLO GRIDVIEW E TITOLO)
                  // -------------------------------------------------------------
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 38.0, vertical: 8.0),
                      child: Column(
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Esplora il tuo mondo',
                              style: TextStyle(
                                fontFamily: 'Serif',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.1,
                            children: [
                              _buildMenuCard(
                                title: 'Il Mio Corpo',
                                subtitle: 'Peso, Valori & Foto',
                                icon: '🩸',
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const IlMioCorpoScreen()),
                                  );
                                  _refreshData();
                                },
                              ),
                              _buildMenuCard(
                                title: 'Cura di me',
                                subtitle: 'Ricarica i Cuori',
                                icon: '🌿',
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const CuraDiMeScreen()),
                                  );
                                  _refreshData();
                                },
                              ),
                              _buildMenuCard(
                                title: 'La mia Casa',
                                subtitle: 'Arreda la stanza',
                                icon: '🏡',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LaMiaCasaScreen()),
                                  );
                                },
                              ),
                              _buildMenuCard(
                                title: 'La mia Mappa',
                                subtitle: 'Il tuo percorso & Tappe',
                                icon: '🗺️',
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LaMiaMappaScreen()),
                                  );
                                  _refreshData();
                                },
                              ),
                              _buildMenuCard(
                                title: 'Bottega',
                                subtitle: 'Spendi Rupie & Cuori',
                                icon: '🛍️',
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ShopScreen()),
                                  );
                                  _refreshData();
                                },
                              ),
                              _buildMenuCard(
                                title: 'Specchio Magico',
                                subtitle: 'Capelli & Abiti',
                                icon: '🪞',
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const CharacterEditorScreen()),
                                  );
                                  _refreshData();
                                },
                              ),
                                                            _buildMenuCard(
                                title: 'Bottega 2',
                                subtitle: 'Spendi Rupie & Cuori',
                                icon: '🛍️',
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ShopScreen()),
                                  );
                                  _refreshData();
                                },
                              ),
                              _buildMenuCard(
                                title: 'Specchio Magico 2',
                                subtitle: 'Capelli & Abiti',
                                icon: '🪞',
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const CharacterEditorScreen()),
                                  );
                                  _refreshData();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. CONTATORI IN ALTO A DESTRA (FISSI E INVARIATI)
            Positioned(
              top: MediaQuery.of(context).padding.top - 14,
              right: 42.0,
              child: Row(
                children: [
                  CurrencyBadge(
                    icon: Icons.favorite,
                    iconColor: AppColors.heartRed,
                    value: '${_user.currentHearts}',
                  ),
                  const SizedBox(width: 12),
                  CurrencyBadge(
                    icon: Icons.diamond,
                    iconColor: AppColors.rupeeGreen,
                    value: '${_user.coins}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required String icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: 0.78, // Rende la singola card della griglia leggermente trasparente
        child: CozyCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
