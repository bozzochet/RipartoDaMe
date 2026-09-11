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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  late UserModel _user;

  @override
  void initState() {
    super.initState();
    _user = _storageService.getUser();
  }

  // Ricarica i dati dell'utente quando si torna indietro dalle altre schermate
  void _refreshData() {
    setState(() {
      _user = _storageService.getUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Benvenuta, ${_user.name}'),
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
                  Text(
                    _user.name,
                    style: const TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
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
