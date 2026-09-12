import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';

class MappaStage {
  final String id;
  final String title;
  final double targetWeight;
  final double xRatio; // Posizione X relativa sulla mappa (0.0 - 1.0)
  final double yRatio; // Posizione Y relativa sulla mappa (0.0 - 1.0)
  final int rewardCoins; // Premio in monete per lo shop

  MappaStage({
    required this.id,
    required this.title,
    required this.targetWeight,
    required this.xRatio,
    required this.yRatio,
    this.rewardCoins = 50,
  });
}

class LaMiaMappaScreen extends StatefulWidget {
  const LaMiaMappaScreen({super.key});

  @override
  State<LaMiaMappaScreen> createState() => _LaMiaMappaScreenState();
}

class _LaMiaMappaScreenState extends State<LaMiaMappaScreen> with SingleTickerProviderStateMixin {
  final LocalStorageService _storageService = LocalStorageService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late UserModel _user;

  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

// Genera le tappe in modo dinamico in base ai dati dell'utente
  List<MappaStage> _generateDynamicStages() {
    final double startWeight = _user.startWeight > 0 ? _user.startWeight : 95.0;
    final double targetWeight = _user.targetWeight > 0 ? _user.targetWeight : 75.0;

    // Se l'obiettivo è maggiore o uguale al peso iniziale, mostra tappe di default
    if (startWeight <= targetWeight) {
      return [
        MappaStage(id: '1', title: 'Partenza', targetWeight: startWeight, xRatio: 0.65, yRatio: 0.75, rewardCoins: 0),
        MappaStage(id: '2', title: 'Obiettivo', targetWeight: targetWeight, xRatio: 0.35, yRatio: 0.25, rewardCoins: 5),
      ];
    }

    final double totalDiff = startWeight - targetWeight;
    final double step = totalDiff / 3; // Divide il percorso in 3 intervalli (4 tappe)

    // Coordinate percentuali sulla mappa per disegnare il percorso a zig-zag
    final List<Map<String, double>> coordinates = [
      {'x': 0.65, 'y': 0.78}, // Tappa 1: Casa (Partenza)
      {'x': 0.35, 'y': 0.58}, // Tappa 2: Bosco
      {'x': 0.25, 'y': 0.38}, // Tappa 3: Valle
      {'x': 0.70, 'y': 0.20}, // Tappa 4: Castello (Obiettivo Finale)
    ];

    final List<String> titles = [
      'Casa (Partenza)',
      'Bosco della Ripartenza',
      'Valle della Costanza',
      'Castello della Fiducia',
    ];

    List<MappaStage> stages = [];

    for (int i = 0; i < 4; i++) {
      // Calcola il peso target per ogni tappa (arrotondato a 1 decimale)
      double stageWeight = double.parse((startWeight - (step * i)).toStringAsFixed(1));
      if (i == 3) stageWeight = targetWeight; // L'ultima tappa coincide con l'obiettivo

      stages.add(
        MappaStage(
          id: 'stage_$i',
          title: titles[i],
          targetWeight: stageWeight,
          xRatio: coordinates[i]['x']!,
          yRatio: coordinates[i]['y']!,
          rewardCoins: i == 0 ? 0 : 5, // 5 rupie per ogni traguardo (0 per la partenza)
        ),
      );
    }

    return stages;
  }

  @override
  void initState() {
    super.initState();
    _user = _storageService.getUser();

    // Animazione di pulsazione per i nodi attivi
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Effetto sonoro al click / sblocco
  Future<void> _playSound(bool isUnlocked) async {
    try {
      if (isUnlocked) {
        await _audioPlayer.play(AssetSource('sounds/coin_unlock.mp3'));
      } else {
        await _audioPlayer.play(AssetSource('sounds/click.mp3'));
      }
    } catch (_) {
      // Ignora se l'audio non è ancora presente negli assets
    }
  }

  // Mostra il popup di celebrazione con le monete
  void _onStageTap(MappaStage stage, bool isUnlocked) async {
    _playSound(isUnlocked);

    bool justClaimed = false;

    // Se sbloccata e non ancora riscossa
    if (isUnlocked && stage.rewardCoins > 0 && !_user.claimedStageIds.contains(stage.id)) {
      await _storageService.addReward(coinsGained: stage.rewardCoins);
      
      // Segna la tappa come riscossa nel profilo
      _user.claimedStageIds.add(stage.id);
      await _storageService.saveUser(_user);

      setState(() {
        _user = _storageService.getUser();
      });

      justClaimed = true;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF7F1E3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFC4B296), width: 2),
          ),
          title: Row(
            children: [
              Icon(
                isUnlocked ? Icons.stars : Icons.lock,
                color: isUnlocked ? Colors.amber : const Color(0xFF7A6855),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stage.title,
                  style: const TextStyle(
                    fontFamily: 'Serif',
                    color: Color(0xFF4A3525),
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Obiettivo peso: ${stage.targetWeight} kg',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A3525)),
              ),
              const SizedBox(height: 8),
              Text(
                isUnlocked
                    ? (justClaimed 
                        ? '🎉 Traguardo raggiunto! Hai ottenuto la tua ricompensa.' 
                        : '🎉 Traguardo già raggiunto e ricompensa riscossa!')
                    : '🔒 Continua il tuo percorso per sbloccare questa tappa!',
                style: TextStyle(
                  color: isUnlocked ? const Color(0xFF2E7D32) : const Color(0xFF7A6855),
                  fontSize: 13,
                ),
              ),
              if (stage.rewardCoins > 0) ...[
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFE3CE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC4B296)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.diamond_outlined, color: Colors.purpleAccent, size: 26),
                      const SizedBox(width: 8),
                      Text(
                        '+${stage.rewardCoins} Rupie',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B5A2B),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              ]
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5A2B),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Genera le tappe dinamiche
    final List<MappaStage> stages = _generateDynamicStages();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F1E3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEFE3CE),
        elevation: 0,
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              'La mia mappa',
              style: TextStyle(
                color: Color(0xFF4A3525),
                fontFamily: 'Serif',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'Ogni traguardo è una nuova terra.',
              style: TextStyle(
                color: Color(0xFF7A6855),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                const Icon(Icons.diamond, color: Color(0xFF00E676), size: 22),
                const SizedBox(width: 4),
                Text(
                  '${_user.coins}',
                  style: const TextStyle(
                    color: Color(0xFF4A3525),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double mapWidth = constraints.maxWidth;
          final double mapHeight = constraints.maxHeight;

          return Stack(
            children: [
              // Sfondo
              Container(
                width: mapWidth,
                height: mapHeight,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8DFC8),
                ),
                child: Image.asset(
                  'assets/images/map_background.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(
                      Icons.map_rounded,
                      size: 200,
                      color: const Color(0xFFC4B296).withOpacity(0.3),
                    ),
                  ),
                ),
              ),

              // Linea del percorso (Usa "stages" senza underscore)
              CustomPaint(
                size: Size(mapWidth, mapHeight),
                painter: MapPathPainter(stages: stages),
              ),

              // Nodi (Usa "stages" senza underscore)
              ...stages.map((stage) {
                  bool isUnlocked = _user.currentWeight <= stage.targetWeight || stage.id == 'stage_0';

                  return Positioned(
                    left: stage.xRatio * mapWidth - 40,
                    top: stage.yRatio * mapHeight - 40,
                    child: GestureDetector(
                      onTap: () => _onStageTap(stage, isUnlocked),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F1E3).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF8B5A2B)),
                            ),
                            child: Text(
                              '${stage.title}\n${stage.targetWeight} kg',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A3525),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: isUnlocked ? _pulseAnimation.value : 1.0,
                                child: child,
                              );
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isUnlocked ? const Color(0xFF8B5A2B) : const Color(0xFFA89885),
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: isUnlocked
                                    ? Colors.amber.withOpacity(0.6)
                                    : Colors.black.withOpacity(0.2),
                                    blurRadius: isUnlocked ? 12 : 4,
                                    spreadRadius: isUnlocked ? 2 : 0,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isUnlocked ? Icons.stars_rounded : Icons.lock_outline,
                                color: isUnlocked ? Colors.amber : Colors.white70,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
              }),
            ],
          );
        },
      ),
    );
  }

}
  
class MapPathPainter extends CustomPainter {
  final List<MappaStage> stages;
  
  MapPathPainter({required this.stages});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B5A2B).withOpacity(0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < stages.length; i++) {
      double x = stages[i].xRatio * size.width;
      double y = stages[i].yRatio * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
