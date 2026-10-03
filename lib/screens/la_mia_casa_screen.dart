import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/cozy_styles.dart';
import '../widgets/cozy_background.dart';
import '../widgets/cozy_widgets.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';

class CasaRoom {
  final String id;
  final String name;
  final String emoji;

  const CasaRoom({
    required this.id,
    required this.name,
    required this.emoji,
  });
}

class PlacedFurniture {
  final String itemId;
  double x;
  double y;
  double scale;
  double rotation;

  PlacedFurniture({
    required this.itemId,
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.rotation = 0.0,
  });
}

// Modello per i temi di stile Zelda delle stanze
class RoomThemeStyle {
  final String id;
  final String name;
  final List<Color> gradientColors;
  final String symbol;

  const RoomThemeStyle({
    required this.id,
    required this.name,
    required this.gradientColors,
    required this.symbol,
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

  final List<CasaRoom> _rooms = const [
    CasaRoom(id: 'salone', name: 'Salone', emoji: '🛋️'),
    CasaRoom(id: 'bagno', name: 'Bagno', emoji: '🛁'),
    CasaRoom(id: 'camera', name: 'Camera', emoji: '🛏️'),
    CasaRoom(id: 'cucina', name: 'Cucina', emoji: '🍳'),
    CasaRoom(id: 'giardino', name: 'Giardino', emoji: '🌿'),
  ];

  String _selectedRoom = 'salone';

  // Temi ispirati a Zelda per personalizzare l'aspetto delle stanze
  final List<RoomThemeStyle> _availableThemes = const [
    RoomThemeStyle(
      id: 'hyrule',
      name: 'Reggia di Hyrule',
      gradientColors: [Color(0xFF3F5D45), Color(0xFF233528)], // Verde foresta profondo
      symbol: '🛡️',
    ),
    RoomThemeStyle(
      id: 'sheikah',
      name: 'Santuario Antico',
      gradientColors: [Color(0xFF1E3D59), Color(0xFF17252A)], // Blu tecnologico Sheikah
      symbol: '👁️',
    ),
    RoomThemeStyle(
      id: 'kakariko',
      name: 'Villaggio Kakariko',
      gradientColors: [Color(0xFF7B3F00), Color(0xFF4A2511)], // Legno e toni caldi/bordeaux
      symbol: '🪵',
    ),
  ];

  // Mappa per memorizzare il tema scelto per ogni singola stanza
  final Map<String, String> _roomThemes = {
    'salone': 'hyrule',
    'bagno': 'sheikah',
    'camera': 'kakariko',
    'cucina': 'kakariko',
    'giardino': 'hyrule',
  };

  final List<CasaFurniture> _inventory = [
    CasaFurniture(id: 'plant_moon', title: 'Pianta della Luna', room: 'giardino', icon: '🪴', purchased: true),
    CasaFurniture(id: 'tea_set', title: 'Set Tisana Relax', room: 'cucina', icon: '🫖', purchased: true),
    CasaFurniture(id: 'vintage_chair', title: 'Poltrona da Lettura', room: 'salone', icon: '🛋️', purchased: true),
    CasaFurniture(id: 'fireplace', title: 'Caminetto in Pietra', room: 'salone', icon: '🪵', purchased: true),
  ];

  final Map<String, List<PlacedFurniture>> _placedFurniture = {
    'salone': [],
    'bagno': [],
    'camera': [],
    'cucina': [],
    'giardino': [],
  };

  String? _selectedFurnitureId;

  @override
  void initState() {
    super.initState();
    _user = _storageService.getUser();
    _placedFurniture['salone'] = [
      PlacedFurniture(itemId: 'vintage_chair', x: 40, y: 150),
      PlacedFurniture(itemId: 'fireplace', x: 190, y: 130),
    ];
  }

  CasaRoom get _currentRoom => _rooms.firstWhere((room) => room.id == _selectedRoom);

  RoomThemeStyle get _currentThemeStyle {
    final themeId = _roomThemes[_selectedRoom] ?? 'hyrule';
    return _availableThemes.firstWhere((t) => t.id == themeId, orElse: () => _availableThemes.first);
  }

  List<CasaFurniture> get _currentRoomFurniture {
    return _inventory.where((item) => item.purchased && item.room == _selectedRoom).toList();
  }

  void _addFurniture(CasaFurniture item) {
    final roomFurniture = _placedFurniture[_selectedRoom]!;
    final alreadyPlaced = roomFurniture.any((placed) => placed.itemId == item.id);

    if (alreadyPlaced) {
      setState(() => _selectedFurnitureId = item.id);
      return;
    }

    final newFurniture = PlacedFurniture(itemId: item.id, x: 110, y: 100);
    setState(() {
      roomFurniture.add(newFurniture);
      _selectedFurnitureId = item.id;
    });
  }

  void _removeFurniture(PlacedFurniture furniture) {
    setState(() {
      _placedFurniture[_selectedRoom]!.remove(furniture);
      if (_selectedFurnitureId == furniture.itemId) {
        _selectedFurnitureId = null;
      }
    });
  }

  CasaFurniture? _findFurniture(String id) {
    for (final item in _inventory) {
      if (item.id == id) return item;
    }
    return null;
  }

  void _selectRoom(String roomId) {
    setState(() {
      _selectedRoom = roomId;
      _selectedFurnitureId = null;
    });
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
            'La mia Casa',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Serif',
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Intestazione Stanza e selettore stile Zelda
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(_currentRoom.emoji, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Text(
                              _currentRoom.name,
                              style: const TextStyle(
                                fontFamily: 'Serif',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        // Pulsante per cambiare il tema/stile della stanza
                        GestureDetector(
                          onTap: _showThemeSelectorDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.woodAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.woodAccent),
                            ),
                            child: Row(
                              children: [
                                Text(_currentThemeStyle.symbol, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(
                                  _currentThemeStyle.name,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Il tuo rifugio leggendario, personalizza gli interni ✨',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Area visiva della Stanza
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildRoom(),
                  ),

                  const SizedBox(height: 10),

                  // Selettore delle Stanze (Orizzontale)
                  SizedBox(
                    height: 75,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _rooms.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final room = _rooms[index];
                        final selected = room.id == _selectedRoom;

                        return GestureDetector(
                          onTap: () => _selectRoom(room.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 75,
                            decoration: BoxDecoration(
                              color: selected ? AppColors.woodAccent : AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected ? AppColors.woodAccent : AppColors.border,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(room.emoji, style: const TextStyle(fontSize: 22)),
                                const SizedBox(height: 2),
                                Text(
                                  room.name,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: selected ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Pannello Arredi inferiori
                  Expanded(child: _buildFurniturePanel()),
                ],
              ),
            ),
            // Badge Rupie in alto a destra
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
          ],
        ),
      ),
    );
  }

  // Finestra di dialogo per scegliere lo stile Zelda della stanza
  void _showThemeSelectorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Stile Architettonico',
            style: TextStyle(fontFamily: 'Serif', fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _availableThemes.map((theme) {
              final isSelected = _roomThemes[_selectedRoom] == theme.id;
              return ListTile(
                leading: Text(theme.symbol, style: const TextStyle(fontSize: 24)),
                title: Text(theme.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                trailing: isSelected ? const Icon(Icons.check, color: AppColors.woodAccent) : null,
                onTap: () {
                  setState(() {
                    _roomThemes[_selectedRoom] = theme.id;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildRoom() {
    final roomFurniture = _placedFurniture[_selectedRoom] ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 250,
          width: double.infinity,
          decoration: CozyStyles.woodBoxDecoration(borderWidth: 2.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Sfondo dinamico basato sul tema Zelda scelto
                Positioned.fill(child: _buildRoomBackground()),
                
                // Etichetta Stile/Tema corrente in alto a sinistra
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(_currentThemeStyle.symbol, style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 4),
                        Text(
                          _currentThemeStyle.name,
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Elementi di arredo posizionabili e trascinabili
                ...roomFurniture.map((furniture) {
                  final item = _findFurniture(furniture.itemId);
                  if (item == null) return const SizedBox.shrink();

                  return Positioned(
                    left: furniture.x,
                    top: furniture.y,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFurnitureId = furniture.itemId),
                      onPanUpdate: (details) {
                        setState(() {
                          furniture.x += details.delta.dx;
                          furniture.y += details.delta.dy;
                          furniture.x = furniture.x.clamp(0.0, constraints.maxWidth - 60);
                          furniture.y = furniture.y.clamp(30.0, 180.0);
                        });
                      },
                      child: Transform.rotate(
                        angle: furniture.rotation,
                        child: Transform.scale(
                          scale: furniture.scale,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: _selectedFurnitureId == furniture.itemId
                                ? BoxDecoration(
                                    color: Colors.white.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.woodAccent, width: 2),
                                  )
                                : null,
                            child: Text(item.icon, style: const TextStyle(fontSize: 42)),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                
                if (roomFurniture.isEmpty)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_currentRoom.emoji, style: const TextStyle(fontSize: 28)),
                          const SizedBox(height: 4),
                          const Text(
                            'Stanza vuota',
                            style: TextStyle(
                              fontFamily: 'Serif',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Text(
                            'Trascina gli arredi dal pannello sotto',
                            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Sfondo della stanza che adatta i colori del gradiente in base al tema Zelda selezionato
  Widget _buildRoomBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _currentThemeStyle.gradientColors,
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.15,
          child: Text(
            _currentThemeStyle.symbol,
            style: const TextStyle(fontSize: 120),
          ),
        ),
      ),
    );
  }

  Widget _buildFurniturePanel() {
    final items = _currentRoomFurniture;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'Oggetti per questa stanza',
                style: TextStyle(
                  fontFamily: 'Serif',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text('${items.length} sblocchi', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CozyWoodCard(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: const [
                    Text('✨', style: TextStyle(fontSize: 24)),
                    SizedBox(height: 4),
                    Text(
                      'Nessun arredo disponibile qui.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Serif', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Visita la Bottega delle Meraviglie per trovarne di nuovi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                final placed = _placedFurniture[_selectedRoom]!.any((element) => element.itemId == item.id);

                return GestureDetector(
                  onTap: () => _addFurniture(item),
                  child: SizedBox(
                    width: 100,
                    child: CozyWoodCard(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(item.icon, style: const TextStyle(fontSize: 34)),
                            ),
                          ),
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: placed ? AppColors.woodAccent : AppColors.surfaceDark,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              placed ? 'In stanza' : '＋ Posiziona',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: placed ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        if (_selectedFurnitureId != null) _buildSelectedFurniturePanel(),
      ],
    );
  }

  Widget _buildSelectedFurniturePanel() {
    final furniture = _findFurniture(_selectedFurnitureId!);
    if (furniture == null) return const SizedBox.shrink();

    PlacedFurniture? placed;
    for (final element in _placedFurniture[_selectedRoom]!) {
      if (element.itemId == furniture.id) {
        placed = element;
        break;
      }
    }
    if (placed == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: CozyWoodCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Text(furniture.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                furniture.title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            IconButton(
              tooltip: 'Rimuovi',
              onPressed: () => _removeFurniture(placed!),
              icon: const Icon(Icons.delete_outline, size: 18),
            ),
            IconButton(
              tooltip: 'Deseleziona',
              onPressed: () => setState(() => _selectedFurnitureId = null),
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class CasaFurniture {
  final String id;
  final String title;
  final String room;
  final String icon;
  final bool purchased;

  const CasaFurniture({
    required this.id,
    required this.title,
    required this.room,
    required this.icon,
    required this.purchased,
  });
}
