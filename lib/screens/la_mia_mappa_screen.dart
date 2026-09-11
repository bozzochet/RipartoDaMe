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

  // Definizione delle tappe del percorso
  final List<MappaStage> _stages = [
    MappaStage(id: '1', title: 'Casa (Partenza)', targetWeight: 94.0, xRatio: 0.65, yRatio: 0.75, rewardCoins: 0),
    MappaStage(id: '2', title: 'Bosco della Ripartenza', targetWeight: 90.0, xRatio: 0.35, yRatio: 0.55, rewardCoins: 50),
    MappaStage(id: '3', title: 'Valle della Costanza', targetWeight: 87.0, xRatio: 0.25, yRatio: 0.35, rewardCoins: 75),
    MappaStage(id: '4', title: 'Castello della Fiducia', targetWeight: 80.0, xRatio: 0.70, yRatio: 0.22, rewardCoins: 100),
  ];

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

    // Se la tappa è sbloccata ed è un traguardo, aggiunge le monete nel database
    if (isUnlocked && stage.rewardCoins > 0) {
      await _storageService.addCoins(stage.rewardCoins);
      setState(() {
        _user = _storageService.getUser(); // Rinfresca il bilancio monete
      });
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
                    ? '🎉 Traguardo raggiunto! Hai dimostrato grande costanza.'
                    : '🔒 Continua il tuo percorso per sbloccare questa tappa!',
                style: TextStyle(
                  color: isUnlocked ? const Color(0xFF2E7D32) : const Color(0xFF7A6855),
                  fontSize: 13,
                ),
              ),
              if (isUnlocked && stage.rewardCoins > 0) ...[
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
                      // Icona o Immagine della Rupia Viola/Dorata
                      const Icon(Icons.diamond_outlined, color: Colors.purpleAccent, size: 26),
                      const SizedBox(width: 8),
                      Text(
                        '+${stage.rewardRupees} Rupie guadagnate!',
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
              child: const Text('Raccogli', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          // Widget contatore Rupie nell'AppBar
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                // Icona a forma di diamante/rupia (oppure un file PNG 'rupee_green.png')
                const Icon(Icons.diamond, color: Color(0xFF00E676), size: 22), 
                const SizedBox(width: 4),
                Text(
                  '${_user.rupees}', // Totale Rupie dell'utente
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
              // 1. Sfondo e Mappa
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

              // 2. Linea del percorso
              CustomPaint(
                size: Size(mapWidth, mapHeight),
                painter: MapPathPainter(stages: _stages),
              ),

              // 3. Nodi delle tappe
              ..._stages.map((stage) {
                bool isUnlocked = _user.currentWeight <= stage.targetWeight || stage.id == '1';

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
              }).toList(),
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
