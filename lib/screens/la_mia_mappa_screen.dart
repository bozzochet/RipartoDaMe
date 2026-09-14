import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../theme/cozy_styles.dart';

class MappaStage {
  final String id;
  final String title;
  final double targetWeight;
  final double xRatio;
  final double yRatio;
  final int rewardCoins;

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

  List<MappaStage> _generateDynamicStages() {
    final double startWeight = _user.startWeight > 0 ? _user.startWeight : 95.0;
    final double targetWeight = _user.targetWeight > 0 ? _user.targetWeight : 75.0;

    if (startWeight <= targetWeight) {
      return [
        MappaStage(id: '1', title: 'Partenza', targetWeight: startWeight, xRatio: 0.65, yRatio: 0.75, rewardCoins: 0),
        MappaStage(id: '2', title: 'Obiettivo', targetWeight: targetWeight, xRatio: 0.35, yRatio: 0.25, rewardCoins: 5),
      ];
    }

    final double totalDiff = startWeight - targetWeight;
    final double step = totalDiff / 3;

    final List<Map<String, double>> coordinates = [
      {'x': 0.65, 'y': 0.78},
      {'x': 0.35, 'y': 0.58},
      {'x': 0.25, 'y': 0.38},
      {'x': 0.70, 'y': 0.20},
    ];

    final List<String> titles = [
      'Casa (Partenza)',
      'Bosco della Ripartenza',
      'Valle della Costanza',
      'Castello della Fiducia',
    ];

    List<MappaStage> stages = [];

    for (int i = 0; i < 4; i++) {
      double stageWeight = double.parse((startWeight - (step * i)).toStringAsFixed(1));
      if (i == 3) stageWeight = targetWeight;

      stages.add(
        MappaStage(
          id: 'stage_$i',
          title: titles[i],
          targetWeight: stageWeight,
          xRatio: coordinates[i]['x']!,
          yRatio: coordinates[i]['y']!,
          rewardCoins: i == 0 ? 0 : 5,
        ),
      );
    }

    return stages;
  }

  @override
  void initState() {
    super.initState();
    _user = _storageService.getUser();

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

  Future<void> _playSound(bool isUnlocked) async {
    try {
      if (isUnlocked) {
        await _audioPlayer.play(AssetSource('sounds/coin_unlock.mp3'));
      } else {
        await _audioPlayer.play(AssetSource('sounds/click.mp3'));
      }
    } catch (_) {}
  }

  void _onStageTap(MappaStage stage, bool isUnlocked) async {
    _playSound(isUnlocked);

    bool justClaimed = false;

    if (isUnlocked && stage.rewardCoins > 0 && !_user.claimedStageIds.contains(stage.id)) {
      await _storageService.addReward(coinsGained: stage.rewardCoins);
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
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.woodAccent, width: 2),
          ),
          title: Row(
            children: [
              Icon(
                isUnlocked ? Icons.stars : Icons.lock,
                color: isUnlocked ? Colors.amber : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stage.title,
                  style: const TextStyle(
                    fontFamily: 'Serif',
                    color: AppColors.textPrimary,
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
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                isUnlocked
                    ? (justClaimed 
                        ? '🎉 Traguardo raggiunto! Hai ottenuto la tua ricompensa.' 
                        : '🎉 Traguardo già raggiunto e ricompensa riscossa!')
                    : '🔒 Continua il tuo percorso per sbloccare questa tappa!',
                style: TextStyle(
                  color: isUnlocked ? const Color(0xFF2E7D32) : AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              if (stage.rewardCoins > 0) ...[
                const SizedBox(height: 15),
                CozyWoodCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.diamond_outlined, color: Colors.purpleAccent, size: 26),
                      const SizedBox(width: 8),
                      Text(
                        '+${stage.rewardCoins} Rupie',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.woodAccent,
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
                backgroundColor: AppColors.woodAccent,
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
    final List<MappaStage> stages = _generateDynamicStages();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              'La mia mappa',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Serif',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'Ogni traguardo è una nuova terra.',
              style: TextStyle(
                color: AppColors.textSecondary,
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
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/map_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double mapWidth = constraints.maxWidth;
            final double mapHeight = constraints.maxHeight;

            return Stack(
              children: [
                CustomPaint(
                  size: Size(mapWidth, mapHeight),
                  painter: MapPathPainter(stages: stages),
                ),
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
                              color: AppColors.background.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.woodAccent),
                            ),
                            child: Text(
                              '${stage.title}\n${stage.targetWeight} kg',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
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
                                color: isUnlocked ? AppColors.woodAccent : AppColors.textSecondary,
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
      ),
    );
  }
} // Chiusura corretta di _LaMiaMappaScreenState

class MapPathPainter extends CustomPainter {
  final List<MappaStage> stages;

  MapPathPainter({required this.stages});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.woodAccent.withOpacity(0.6)
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
