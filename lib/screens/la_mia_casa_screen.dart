import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/cozy_widgets.dart';
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

class LaMiaCasaScreen extends StatefulWidget {
  const LaMiaCasaScreen({super.key});

  @override
  State<LaMiaCasaScreen> createState() => _LaMiaCasaScreenState();
}

class _LaMiaCasaScreenState extends State<LaMiaCasaScreen> {
  final LocalStorageService _storageService = LocalStorageService();

  late UserModel _user;

  // ============================================================
  // STANZE
  // ============================================================

  final List<CasaRoom> _rooms = const [
    CasaRoom(
      id: 'salone',
      name: 'Salone',
      emoji: '🛋️',
    ),
    CasaRoom(
      id: 'bagno',
      name: 'Bagno',
      emoji: '🛁',
    ),
    CasaRoom(
      id: 'camera',
      name: 'Camera',
      emoji: '🛏️',
    ),
    CasaRoom(
      id: 'cucina',
      name: 'Cucina',
      emoji: '🍳',
    ),
    CasaRoom(
      id: 'giardino',
      name: 'Giardino',
      emoji: '🌿',
    ),
  ];

  String _selectedRoom = 'salone';

  // ============================================================
  // INVENTARIO CASA
  //
  // PER ORA È LO STESSO CATALOGO CHE HAI NELLA BOTTEGA.
  //
  // Successivamente questo elenco verrà collegato direttamente
  // all'inventario persistente della Bottega.
  // ============================================================

  final List<CasaFurniture> _inventory = [
    CasaFurniture(
      id: 'plant_moon',
      title: 'Pianta della Luna',
      room: 'giardino',
      icon: '🪴',
      purchased: true,
    ),
    CasaFurniture(
      id: 'tea_set',
      title: 'Set Tisana Relax',
      room: 'cucina',
      icon: '🫖',
      purchased: true,
    ),
    CasaFurniture(
      id: 'vintage_chair',
      title: 'Poltrona da Lettura',
      room: 'salone',
      icon: '🛋️',
      purchased: true,
    ),
    CasaFurniture(
      id: 'fireplace',
      title: 'Caminetto in Pietra',
      room: 'salone',
      icon: '🪵',
      purchased: true,
    ),
  ];

  // ============================================================
  // OGGETTI POSIZIONATI
  // ============================================================

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

    // Posizioni iniziali di esempio.
    // In seguito saranno caricate dal salvataggio.
    _placedFurniture['salone'] = [
      PlacedFurniture(
        itemId: 'vintage_chair',
        x: 40,
        y: 150,
      ),
      PlacedFurniture(
        itemId: 'fireplace',
        x: 190,
        y: 130,
      ),
    ];
  }

  // ============================================================
  // STANZA SELEZIONATA
  // ============================================================

  CasaRoom get _currentRoom {
    return _rooms.firstWhere(
      (room) => room.id == _selectedRoom,
    );
  }

  // ============================================================
  // ARREDI DISPONIBILI NELLA STANZA
  // ============================================================

  List<CasaFurniture> get _currentRoomFurniture {
    return _inventory
    .where(
      (item) =>
      item.purchased &&
      item.room == _selectedRoom,
    )
    .toList();
  }

  // ============================================================
  // AGGIUNGI ARREDO ALLA STANZA
  // ============================================================

  void _addFurniture(CasaFurniture item) {
    final roomFurniture = _placedFurniture[_selectedRoom]!;

    // Evita di aggiungere lo stesso oggetto più volte.
    final alreadyPlaced = roomFurniture.any(
      (placed) => placed.itemId == item.id,
    );

    if (alreadyPlaced) {
      setState(() {
          _selectedFurnitureId = item.id;
      });
      return;
    }

    final newFurniture = PlacedFurniture(
      itemId: item.id,
      x: 110,
      y: 100,
    );

    setState(() {
        roomFurniture.add(newFurniture);
        _selectedFurnitureId = item.id;
    });
  }

  // ============================================================
  // RIMUOVI ARREDO
  // ============================================================

  void _removeFurniture(PlacedFurniture furniture) {
    setState(() {
        _placedFurniture[_selectedRoom]!.remove(furniture);

        if (_selectedFurnitureId == furniture.itemId) {
          _selectedFurnitureId = null;
        }
    });
  }

  // ============================================================
  // CERCA OGGETTO
  // ============================================================

  CasaFurniture? _findFurniture(String id) {
    for (final item in _inventory) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  // ============================================================
  // CAMBIO STANZA
  // ============================================================

  void _selectRoom(String roomId) {
    setState(() {
        _selectedRoom = roomId;
        _selectedFurnitureId = null;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text('La mia Casa'),
      ),

      body: SafeArea(
        child: Column(
          children: [

            // ====================================================
            // TITOLO
            // ====================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                4,
              ),
              child: Row(
                children: [
                  const Text(
                    '🏡',
                    style: TextStyle(fontSize: 26),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentRoom.name,
                    style: const TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
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
                  'Il tuo piccolo mondo, costruito un passo alla volta ✨',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ====================================================
            // GRANDE STANZA
            // ====================================================

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildRoom(),
            ),

            const SizedBox(height: 14),

            // ====================================================
            // SELETTORE STANZE
            // ====================================================

            SizedBox(
              height: 82,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _rooms.length,
                separatorBuilder: (_, __) =>
                const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final room = _rooms[index];

                  final selected =
                  room.id == _selectedRoom;

                  return GestureDetector(
                    onTap: () => _selectRoom(room.id),

                    child: AnimatedContainer(
                      duration:
                      const Duration(milliseconds: 200),

                      width: 82,

                      decoration: BoxDecoration(
                        color: selected
                        ? AppColors.woodAccent
                        : AppColors.surface,

                        borderRadius:
                        BorderRadius.circular(16),

                        border: Border.all(
                          color: selected
                          ? AppColors.woodAccent
                          : AppColors.border,
                          width: selected ? 2 : 1,
                        ),

                        boxShadow: selected
                        ? [
                          BoxShadow(
                            color: Colors.black
                            .withOpacity(0.12),
                            blurRadius: 6,
                            offset:
                            const Offset(0, 3),
                          ),
                        ]
                        : null,
                      ),

                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,

                        children: [
                          Text(
                            room.emoji,
                            style:
                            const TextStyle(fontSize: 27),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            room.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                              FontWeight.bold,
                              color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ====================================================
            // ARREDI
            // ====================================================

            Expanded(
              child: _buildFurniturePanel(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STANZA
  // ============================================================

  Widget _buildRoom() {
    final roomFurniture =
    _placedFurniture[_selectedRoom] ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 290,
          width: double.infinity,

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),

            border: Border.all(
              color: AppColors.woodAccent,
              width: 2,
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],

            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.surface,
                AppColors.surfaceDark,
              ],
            ),
          ),

          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),

            child: Stack(
              children: [

                // =================================================
                // SFONDO AMBIENTE
                // =================================================

                Positioned.fill(
                  child: _buildRoomBackground(),
                ),

                // =================================================
                // NOME AMBIENTE
                // =================================================

                Positioned(
                  top: 12,
                  left: 14,

                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),

                    decoration: BoxDecoration(
                      color:
                      Colors.white.withOpacity(0.75),
                      borderRadius:
                      BorderRadius.circular(10),
                    ),

                    child: Text(
                      '${_currentRoom.emoji} ${_currentRoom.name}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),

                // =================================================
                // ARREDI POSIZIONATI
                // =================================================

                ...roomFurniture.map(
                  (furniture) {
                    final item =
                    _findFurniture(
                      furniture.itemId,
                    );

                    if (item == null) {
                      return const SizedBox.shrink();
                    }

                    return Positioned(
                      left: furniture.x,
                      top: furniture.y,

                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                              _selectedFurnitureId =
                              furniture.itemId;
                          });
                        },

                        onPanUpdate: (details) {
                          setState(() {
                              furniture.x +=
                              details.delta.dx;

                              furniture.y +=
                              details.delta.dy;

                              // Limiti orizzontali
                              furniture.x =
                              furniture.x.clamp(
                                0.0,
                                constraints.maxWidth -
                                65,
                              );

                              // Limiti verticali
                              furniture.y =
                              furniture.y.clamp(
                                40.0,
                                225.0,
                              );
                          });
                        },

                        child: Transform.rotate(
                          angle: furniture.rotation,

                          child: Transform.scale(
                            scale: furniture.scale,

                            child: Container(
                              padding:
                              const EdgeInsets.all(6),

                              decoration:
                              _selectedFurnitureId ==
                              furniture.itemId
                              ? BoxDecoration(
                                color: Colors.white
                                .withOpacity(
                                  0.45),
                                borderRadius:
                                BorderRadius
                                .circular(
                                  14),
                                border:
                                Border.all(
                                  color: AppColors
                                  .woodAccent,
                                  width: 2,
                                ),
                              )
                              : null,

                              child: Text(
                                item.icon,
                                style:
                                const TextStyle(
                                  fontSize: 48,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // =================================================
                // INDICAZIONE SE VUOTA
                // =================================================

                if (roomFurniture.isEmpty)
                Center(
                  child: Container(
                    padding:
                    const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color:
                      Colors.white.withOpacity(0.72),
                      borderRadius:
                      BorderRadius.circular(16),
                    ),

                    child: Column(
                      mainAxisSize:
                      MainAxisSize.min,

                      children: [
                        Text(
                          _currentRoom.emoji,
                          style:
                          const TextStyle(
                            fontSize: 35,
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          'Questa stanza è ancora vuota',
                          style: TextStyle(
                            fontFamily: 'Serif',
                            fontWeight:
                            FontWeight.bold,
                            color:
                            AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 3),

                        const Text(
                          'Scegli un arredo qui sotto',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                            AppColors.textSecondary,
                          ),
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

  // ============================================================
  // SFONDO STANZA
  // ============================================================

  Widget _buildRoomBackground() {
    switch (_selectedRoom) {
      case 'bagno':
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE7E3D6),
              Color(0xFFCFC8B5),
            ],
          ),
        ),
        child: const Center(
          child: Text(
            '🛁  🪞  🕯️',
            style: TextStyle(fontSize: 32),
          ),
        ),
      );

      case 'camera':
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE6D9D2),
              Color(0xFFCDB9A9),
            ],
          ),
        ),
        child: const Center(
          child: Text(
            '🛏️  🌙  🕯️',
            style: TextStyle(fontSize: 32),
          ),
        ),
      );

      case 'cucina':
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8DFC8),
              Color(0xFFCAB894),
            ],
          ),
        ),
        child: const Center(
          child: Text(
            '🍳  🫖  🥖',
            style: TextStyle(fontSize: 32),
          ),
        ),
      );

      case 'giardino':
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFDDE2C8),
              Color(0xFF9BA56C),
            ],
          ),
        ),
        child: const Center(
          child: Text(
            '🌳  🌿  🌸',
            style: TextStyle(fontSize: 32),
          ),
        ),
      );

      case 'salone':
      default:
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEFE3CE),
              Color(0xFFC8B28D),
            ],
          ),
        ),
        child: const Center(
          child: Text(
            '🪟  🌲  🕯️',
            style: TextStyle(fontSize: 32),
          ),
        ),
      );
    }
  }

  // ============================================================
  // PANNELLO ARREDI
  // ============================================================

  Widget _buildFurniturePanel() {
    final items = _currentRoomFurniture;

    return Column(
      children: [

        Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 16),

          child: Row(
            children: [
              const Text(
                'I tuoi arredi',
                style: TextStyle(
                  fontFamily: 'Serif',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const Spacer(),

              Text(
                '${items.length} disponibili',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        if (items.isEmpty)
        Padding(
          padding:
          const EdgeInsets.all(16),

          child: CozyCard(
            child: Column(
              children: [
                const Text(
                  '✨',
                  style:
                  TextStyle(fontSize: 30),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Non hai ancora arredi per questa stanza.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Serif',
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Visita la Bottega delle Meraviglie per trovarne di nuovi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        )
        else
        Expanded(
          child: ListView.separated(
            padding:
            const EdgeInsets.fromLTRB(
              16,
              4,
              16,
              20,
            ),

            scrollDirection: Axis.horizontal,

            itemCount: items.length,

            separatorBuilder: (_, __) =>
            const SizedBox(width: 10),

            itemBuilder: (context, index) {
              final item = items[index];

              final placed =
              _placedFurniture[
                _selectedRoom]!
              .any(
                (element) =>
                element.itemId == item.id,
              );

              return GestureDetector(
                onTap: () {
                  _addFurniture(item);
                },

                child: SizedBox(
                  width: 115,

                  child: CozyCard(
                    padding:
                    const EdgeInsets.all(10),

                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,

                      children: [

                        Expanded(
                          child: Center(
                            child: Text(
                              item.icon,
                              style:
                              const TextStyle(
                                fontSize: 42,
                              ),
                            ),
                          ),
                        ),

                        Text(
                          item.title,
                          textAlign:
                          TextAlign.center,
                          maxLines: 2,
                          overflow:
                          TextOverflow.ellipsis,
                          style:
                          const TextStyle(
                            fontSize: 10,
                            fontWeight:
                            FontWeight.bold,
                            color:
                            AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Container(
                          padding:
                          const EdgeInsets
                          .symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),

                          decoration:
                          BoxDecoration(
                            color: placed
                            ? AppColors
                            .woodAccent
                            : AppColors
                            .surfaceDark,
                            borderRadius:
                            BorderRadius.circular(
                              8),
                          ),

                          child: Text(
                            placed
                            ? 'Nella stanza'
                            : '＋ Posiziona',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight:
                              FontWeight.bold,
                              color: placed
                              ? Colors.white
                              : AppColors
                              .textPrimary,
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

        // ========================================================
        // PANNELLO DELL'OGGETTO SELEZIONATO
        // ========================================================

        if (_selectedFurnitureId != null)
        _buildSelectedFurniturePanel(),
      ],
    );
  }

  // ============================================================
  // PANNELLO OGGETTO SELEZIONATO
  // ============================================================

  Widget _buildSelectedFurniturePanel() {
    final furniture = _findFurniture(
      _selectedFurnitureId!,
    );

    if (furniture == null) {
      return const SizedBox.shrink();
    }

    PlacedFurniture? placed;
    
    for (final element in _placedFurniture[_selectedRoom]!) {
      if (element.itemId == furniture.id) {
        placed = element;
        break;
      }
    }

    if (placed == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin:
      const EdgeInsets.fromLTRB(16, 0, 16, 12),

      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),

      decoration: BoxDecoration(
        color: AppColors.surface,

        borderRadius:
        BorderRadius.circular(14),

        border: Border.all(
          color: AppColors.border,
        ),
      ),

      child: Row(
        children: [

          Text(
            furniture.icon,
            style:
            const TextStyle(fontSize: 28),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              furniture.title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          IconButton(
            tooltip: 'Rimuovi',
            onPressed: () {
              _removeFurniture(placed!);
            },
            icon: const Icon(
              Icons.delete_outline,
              size: 21,
            ),
          ),

          IconButton(
            tooltip: 'Deseleziona',
            onPressed: () {
              setState(() {
                  _selectedFurnitureId = null;
              });
            },
            icon: const Icon(
              Icons.close,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// MODELLO TEMPORANEO DEGLI ARREDI
// ================================================================

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
