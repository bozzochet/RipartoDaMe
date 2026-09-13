import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../theme/cozy_styles.dart';
import '../theme/cozy_background.dart';

class HabitItem {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int rewardHearts;
  bool isCompleted;

  HabitItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.rewardHearts = 1,
    this.isCompleted = false,
  });
}

class CuraDiMeScreen extends StatefulWidget {
  const CuraDiMeScreen({super.key});

  @override
  State<CuraDiMeScreen> createState() => _CuraDiMeScreenState();
}

class _CuraDiMeScreenState extends State<CuraDiMeScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late UserModel _user;

  final List<HabitItem> _habits = [
    HabitItem(
      id: 'water',
      title: 'Idratazione Profonda',
      description: 'Bevi almeno 1.5L d\'acqua durante il giorno',
      icon: '💧',
    ),
    HabitItem(
      id: 'skincare',
      title: 'Routine Skincare / Relax',
      description: 'Prenditi 5 minuti per la cura della pelle o un bagno caldo',
      icon: '🧼',
    ),
    HabitItem(
      id: 'walk',
      title: 'Passeggiata nel Bosco',
      description: 'Fai una breve camminata all\'aria aperta',
      icon: '🌲',
    ),
    HabitItem(
      id: 'journal',
      title: 'Pensiero di Gratitudine',
      description: 'Scrivi sul diario una cosa bella accaduta oggi',
      icon: '📖',
    ),
    HabitItem(
      id: 'rest',
      title: 'Pausa Senza Schermi',
      description: 'Stacca dai dispositivi per 15 minuti prima di dormire',
      icon: '🌙',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _user = _storageService.getUser();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _toggleHabit(HabitItem habit) async {
    setState(() {
      habit.isCompleted = !habit.isCompleted;
    });

    if (habit.isCompleted) {
      try {
        await _audioPlayer.play(AssetSource('sounds/heart_gain.mp3'));
      } catch (_) {}

      _user.currentHearts = (_user.currentHearts + habit.rewardHearts).clamp(0, _user.maxHearts);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF2E7D32),
          content: Row(
            children: [
              const Icon(Icons.favorite, color: Colors.redAccent),
              const SizedBox(width: 8),
              Text('+${habit.rewardHearts} Cuore ripristinato! Continua così.'),
            ],
          ),
        ),
      );
    } else {
      _user.currentHearts = (_user.currentHearts - habit.rewardHearts).clamp(0, _user.maxHearts);
    }

    await _storageService.saveUser(_user);
    setState(() {
      _user = _storageService.getUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CozyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Cura di Me',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Serif',
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. BARRA CUORI IN COZY WOOD CARD
              CozyWoodCard(
                child: Column(
                  children: [
                    const Text(
                      'Energia Vitale & Salute',
                      style: TextStyle(
                        fontFamily: 'Serif',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: List.generate(_user.maxHearts, (index) {
                        bool isFilled = index < _user.currentHearts;
                        return AnimatedScale(
                          duration: const Duration(milliseconds: 300),
                          scale: isFilled ? 1.1 : 1.0,
                          child: Icon(
                            isFilled ? Icons.favorite : Icons.favorite_border,
                            color: isFilled ? const Color(0xFFE53935) : AppColors.textSecondary,
                            size: 28,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_user.currentHearts} / ${_user.maxHearts} Cuori disponibili',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Abitudini di Oggi',
                style: TextStyle(
                  fontFamily: 'Serif',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                'Completa le routine quotidiane per recuperare cuori.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),

              // 2. LISTA SCHEDE ABITUDINI IN COZY WOOD CARD
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _habits.length,
                itemBuilder: (context, index) {
                  final habit = _habits[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: CozyWoodCard(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      overlayOpacity: habit.isCompleted ? 0.90 : 0.78,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(habit.icon, style: const TextStyle(fontSize: 24)),
                        ),
                        title: Text(
                          habit.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            decoration: habit.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Text(
                          habit.description,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        trailing: InkWell(
                          onTap: () => _toggleHabit(habit),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: habit.isCompleted ? const Color(0xFF2E7D32) : Colors.transparent,
                              border: Border.all(
                                color: habit.isCompleted ? const Color(0xFF2E7D32) : AppColors.woodAccent,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              habit.isCompleted ? Icons.check : Icons.favorite_outline,
                              size: 18,
                              color: habit.isCompleted ? Colors.white : AppColors.woodAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
