import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';

enum CurrencyType { rupees, hearts }

class ShopItem {
  final String id;
  final String title;
  final String category; // 'casa' oppure 'vestiti'
  final String icon; // Emoji o path asset
  final int price;
  final CurrencyType currency;
  bool isPurchased;

  ShopItem({
    required this.id,
    required this.title,
    required this.category,
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

  // Catalogo Oggetti dello Shop
  final List<ShopItem> _catalog = [
    // --- SEZIONE CASA ---
    ShopItem(id: 'plant_moon', title: 'Pianta della Luna', category: 'casa', icon: '🪴', price: 3, currency: CurrencyType.hearts),
    ShopItem(id: 'tea_set', title: 'Set Tisana Relax', category: 'casa', icon: '🫖', price: 5, currency: CurrencyType.hearts),
    ShopItem(id: 'vintage_chair', title: 'Poltrona da Lettura', category: 'casa', icon: '🛋️', price: 40, currency: CurrencyType.rupees),
    ShopItem(id: 'fireplace', title: 'Caminetto in Pietra', category: 'casa', icon: '🪵', price: 100, currency: CurrencyType.rupees),

    // --- SEZIONE VESTITI ---
    ShopItem(id: 'flower_crown', title: 'Corona di Margherita', category: 'vestiti', icon: '👑', price: 4, currency: CurrencyType.hearts),
    ShopItem(id: 'cozy_sweater', title: 'Maglione Oversize', category: 'vestiti', icon: '🧶', price: 6, currency: CurrencyType.hearts),
    ShopItem(id: 'adventure_cloak', title: 'Mantello del Bosco', category: 'vestiti', icon: '🧥', price: 50, currency: CurrencyType.rupees),
    ShopItem(id: 'boots_leather', title: 'Stivali da Esploratrice', category: 'vestiti', icon: '🥾', price: 75, currency: CurrencyType.rupees),
  ];

  @override
  void initState() {
    super.initState();
    _user = _storageService.getUser();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Logica di acquisto
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F1E3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEFE3CE),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Bottega delle Meraviglie',
          style: TextStyle(
            color: Color(0xFF4A3525),
            fontFamily: 'Serif',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // Indicatori Valuta in alto a destra
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Row(
              children: [
                // Contatore Cuori
                const Icon(Icons.favorite, color: Colors.redAccent, size: 18),
                const SizedBox(width: 3),
                Text(
                  '${_user.currentHearts}',
                  style: const TextStyle(color: Color(0xFF4A3525), fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                // Contatore Rupie
                const Icon(Icons.diamond, color: Color(0xFF00E676), size: 18),
                const SizedBox(width: 3),
                Text(
                  '${_user.coins}',
                  style: const TextStyle(color: Color(0xFF4A3525), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF8B5A2B),
          labelColor: const Color(0xFF8B5A2B),
          unselectedLabelColor: const Color(0xFF7A6855),
          tabs: const [
            Tab(icon: Icon(Icons.home_work_outlined), text: 'Arredo Casa'),
            Tab(icon: Icon(Icons.checkroom_outlined), text: 'Guardaroba'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildShopGrid('casa'),
          _buildShopGrid('vestiti'),
        ],
      ),
    );
  }

  // Griglia degli articoli in vendita
  Widget _buildShopGrid(String category) {
    final items = _catalog.where((element) => element.category == category).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEFE6D5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC4B296)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.icon, style: const TextStyle(fontSize: 42)),
              const SizedBox(height: 8),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF4A3525),
                ),
              ),
              const SizedBox(height: 6),

              // Prezzo e tipo di valuta
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.currency == CurrencyType.rupees ? Icons.diamond : Icons.favorite,
                    size: 16,
                    color: item.currency == CurrencyType.rupees ? const Color(0xFF00E676) : Colors.redAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.price}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF8B5A2B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Pulsante Acquista
              SizedBox(
                height: 30,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item.isPurchased ? const Color(0xFFA89885) : const Color(0xFF8B5A2B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: item.isPurchased ? null : () => _buyItem(item),
                  child: Text(
                    item.isPurchased ? 'Sbloccato' : 'Acquista',
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
