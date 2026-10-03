import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../theme/cozy_styles.dart';
import '../widgets/cozy_background.dart';
import '../widgets/cozy_widgets.dart';

enum CurrencyType { rupees, hearts }

class ShopItem {
  final String id;
  final String title;
  final String category;
  final String? room;
  final String icon;
  final int price;
  final CurrencyType currency;
  bool isPurchased;

  ShopItem({
    required this.id,
    required this.title,
    required this.category,
    this.room,
    required this.icon,
    required this.price,
    required this.currency,
    this.isPurchased = false,
  });
}

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  final LocalStorageService _storageService = LocalStorageService();
  late UserModel _user;
  late TabController _tabController;

  final List<ShopItem> _catalog = [
    ShopItem(
      id: 'plant_moon',
      title: 'Pianta della Luna',
      category: 'casa',
      room: 'giardino',
      icon: '🪴',
      price: 3,
      currency: CurrencyType.hearts,
    ),
    ShopItem(
      id: 'tea_set',
      title: 'Set Tisana Relax',
      category: 'casa',
      room: 'cucina',
      icon: '🫖',
      price: 5,
      currency: CurrencyType.hearts,
    ),
    ShopItem(
      id: 'vintage_chair',
      title: 'Poltrona da Lettura',
      category: 'casa',
      room: 'salone',
      icon: '🛋',
      price: 40,
      currency: CurrencyType.rupees,
    ),
    ShopItem(
      id: 'fireplace',
      title: 'Caminetto in Pietra',
      category: 'casa',
      room: 'salone',
      icon: '🪵',
      price: 100,
      currency: CurrencyType.rupees,
    ),
    ShopItem(
      id: 'flower_crown',
      title: 'Corona di Margherita',
      category: 'vestiti',
      room: null,
      icon: '👑',
      price: 4,
      currency: CurrencyType.hearts,
    ),
    ShopItem(
      id: 'cozy_sweater',
      title: 'Maglione Oversize',
      category: 'vestiti',
      room: null,
      icon: '🧶',
      price: 6,
      currency: CurrencyType.hearts,
    ),
    ShopItem(
      id: 'adventure_cloak',
      title: 'Mantello del Bosco',
      category: 'vestiti',
      room: null,
      icon: '🧥',
      price: 50,
      currency: CurrencyType.rupees,
    ),
    ShopItem(
      id: 'boots_leather',
      title: 'Stivali da Esploratrice',
      category: 'vestiti',
      room: null,
      icon: '🥾',
      price: 75,
      currency: CurrencyType.rupees,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _user = _storageService.getUser();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
        _user = _storageService.getUser();
    });
  }
  
  void _buyItem(ShopItem item) async {
    if (item.isPurchased) return;

    bool canAfford = false;

    if (item.currency == CurrencyType.rupees && _user.coins >= item.price) {
      canAfford = true;
      _user.coins -= item.price;
    } else if (item.currency == CurrencyType.hearts && _user.currentHearts >= item.price) {
      canAfford = true;
      _user.currentHearts -= item.price;
    }

    if (canAfford) {
      setState(() {
        item.isPurchased = true;
      });
      await _storageService.saveUser(_user);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2E7D32),
          content: Text('🎉 Hai acquistato: ${item.title}!'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFC62828),
          content: Text(
            item.currency == CurrencyType.rupees
                ? '❌ Non hai abbastanza Rupie!'
                : '❌ Non hai abbastanza Cuori!',
          ),
        ),
      );
    }
  }

  void _openGoldenChest() async {
    bool success = await _storageService.consumeGoldenChest();
    if (!mounted) return;

    if (success) {
      setState(() {
        _user = _storageService.getUser();
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: CozyWoodCard(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '✨ Tesoro Sbloccato! ✨',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Serif',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Icon(
                      Icons.auto_awesome,
                      size: 56,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'La cassa si è aperta rivelando un abito o un arredo a sorpresa per la tua collezione!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: CozyButton(
                        text: 'Evviva! 🎉',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFC62828),
          content: Text('❌ Non hai casse dorate disponibili! Completa le attività nella sezione Cura di me.'),
        ),
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
            'Bottega delle Meraviglie',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Serif',
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.woodAccent,
            labelColor: AppColors.woodAccent,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(icon: Icon(Icons.home_work_outlined), text: 'Arredo'),
              Tab(icon: Icon(Icons.checkroom_outlined), text: 'Abiti'),
              Tab(icon: Icon(Icons.card_giftcard), text: 'Casse'),
            ],
          ),
        ),
        body: Stack(
          children: [
            SafeArea(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildShopGrid('casa'),
                  _buildShopGrid('vestiti'),
                  _buildChestSection(),
                ],
              ),
            ),
            // Contatore rupie in alto a destra
            Positioned(
              top: MediaQuery.of(context).padding.top - 18,
              right: 42.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CurrencyBadge(
                      icon: Icons.diamond,
                      iconColor: AppColors.rupeeGreen,
                      value: '${_user.coins}',
                    ),
                  ],
                ),
              ),
            ),
            // Contatore cuori in alto a sinistra
            Positioned(
              top: MediaQuery.of(context).padding.top - 18,
              left: 42.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CurrencyBadge(
                      icon: Icons.favorite,
                      iconColor: AppColors.heartRed,
                      value: '${_user.currentHearts}',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopGrid(String category) {
    final items = _catalog.where((element) => element.category == category).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.88, // Ottimizzato per ridurre lo spazio verticale in eccesso
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return CozyWoodCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Padding interno super compatto per eliminare spazi vuoti
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.icon, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 2),
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.currency == CurrencyType.rupees ? Icons.diamond : Icons.favorite,
                    size: 13,
                    color: item.currency == CurrencyType.rupees ? const Color(0xFF00E676) : Colors.redAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.price}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.woodAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 18,
                  maxHeight: 36,
                ),
                child: item.isPurchased
                ? Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.woodAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.woodAccent, width: 1),
                  ),
                  child: const Text(
                    'Sbloccato',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.woodAccent,
                    ),
                  ),
                )
                : CozyButton(
                  verticalPadding: 4,
                  text: 'Acquista',
                  onPressed: () => _buyItem(item),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Sezione delle Casse Dorate
  Widget _buildChestSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: CozyWoodCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '📦 Emporio delle Casse Dorate',
              style: TextStyle(
                fontFamily: 'Serif',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Colleziona le casse completando le tue attività nella sezione "Cura di me" e aprila qui per scoprire premi a sorpresa!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: CozyButton(
                text: 'Casse disponibili: ${_user.goldenChests}',
                onPressed: () {}, // Pulsante puramente informativo o disattivabile all'occorrenza
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _user.goldenChests > 0 ? _openGoldenChest : null,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _user.goldenChests > 0 ? Colors.amber[200] : Colors.grey[300],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _user.goldenChests > 0 ? Colors.amber[800]! : Colors.grey,
                    width: 3,
                  ),
                  boxShadow: _user.goldenChests > 0
                  ? [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 4,
                    )
                  ]
                  : [],
                ),
                child: Icon(
                  Icons.card_giftcard,
                  size: 64,
                  color: _user.goldenChests > 0 ? Colors.amber[900] : Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _user.goldenChests > 0 ? 'Tocca la cassa per aprirla!' : 'Nessuna cassa da aprire',
              style: TextStyle(
                fontFamily: 'Serif',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: _user.goldenChests > 0 ? AppColors.woodAccent : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
