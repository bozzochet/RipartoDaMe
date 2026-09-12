import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/cozy_widgets.dart';
import '../widgets/cozy_avatar.dart';
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

  // Controller e stato per la modifica del nome
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

  // Ricarica i dati dell'utente quando si torna indietro dalle altre schermate
  void _refreshData() {
    setState(() {
      _loadUser();
    });
  }

  // Salva il nuovo nome nel LocalStorage
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isEditingName
            ? Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.black, fontSize: 18),
                      decoration: const InputDecoration(
                        hintText: 'Inserisci nome...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: AppColors.success),
                    onPressed: _saveName,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      'Benvenuta, ${_user.name}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () {
                      setState(() {
                        _isEditingName = true;
                      });
                    },
                  ),
                ],
              ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 1. CARD AVATAR PRINCIPALE
            CozyCard(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                children: [
                  // Avatar personalizzato con tocco per aprire lo Specchio Magico
                  CozyAvatar(
                    size: 120,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CharacterEditorScreen()),
                      );
                      _refreshData();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Nome utente o campo di modifica
                  if (_isEditingName)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 160,
                          child: TextField(
                            controller: _nameController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Serif',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: AppColors.success),
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                          onPressed: () {
                            setState(() {
                              _isEditingName = true;
                            });
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 4),
                  const Text(
                    'Tocca l\'avatar per cambiare look 🪞',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. MENU DI NAVIGAZIONE RAPIDA
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
                  color: const Color(0xFFE8DFC8),
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
                  color: const Color(0xFFE8DFC8),
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
                  color: const Color(0xFFE8DFC8),
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
                  color: const Color(0xFFE8DFC8),
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
                  color: const Color(0xFFE8DFC8),
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
                  color: const Color(0xFFE8DFC8),
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
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
    );
  }
}
