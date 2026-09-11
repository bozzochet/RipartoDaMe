import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';

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

  // Lista delle abitudini giornaliere di self-care
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
      icon: '🌿',
    ),
    HabitItem(
      id: 'walk',
      title: 'Passeggiata nel Bosco',
      description: 'Fai una breve camminata all\'aria aperta',
      icon: '👟',
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

  // Completa o annulla un'abitudine
  void _toggleHabit(HabitItem habit) async {
    setState(() {
      habit.isCompleted = !habit.isCompleted;
    });

    if (habit.isCompleted) {
      // Suono di recupero vita/cuore
      try {
        await _audioPlayer.play(AssetSource('sounds/heart_gain.mp3'));
      } catch (_) {}

      // Aggiunge cuori senza superare il massimo sbloccato
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
              Text('+${habit.rewardHearts} Cuore ripristinato! Continuai così.'),
            ],
          ),
        ),
      );
    } else {
      // Se si deseleziona, riduce il cuore
      _user.currentHearts = (_user.currentHearts - habit.rewardHearts).clamp(0, _user.maxHearts);
    }

    await _storageService.saveUser(_user);
    setState(() {
      _user = _storageService.getUser();
    });
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
          'Cura di Me',
          style: TextStyle(
            color: Color(0xFF4A3525),
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
            // 1. BARRA CUORI STILE ZELDA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFE3CE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC4B296), width: 1.5),
              ),
              child: Column(
                children: [
                  const Text(
                    'Energia Vitalizio & Salute',
                    style: TextStyle(
                      fontFamily: 'Serif',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF4A3525),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Griglia/Riga dei Cuori Rossi/Vuoti
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
                          color: isFilled ? const Color(0xFFE53935) : const Color(0xFFA89885),
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
                      color: Color(0xFF7A6855),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // TITOLO SEZIONE
            const Text(
              'Abitudini di Oggi',
              style: TextStyle(
                fontFamily: 'Serif',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A3525),
              ),
            ),
            const Text(
              'Completa le routine quotidiane per recuperare cuori.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF7A6855),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),

            // 2. LISTA SCHEDE ABITUDINI
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _habits.length,
              itemBuilder: (context, index) {
                final habit = _habits[index];

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: habit.isCompleted ? const Color(0xFFE8DFC8) : const Color(0xFFF7F1E3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: habit.isCompleted ? const Color(0xFF2E7D32) : const Color(0xFFC4B296),
                      width: habit.isCompleted ? 1.5 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFE3CE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(habit.icon, style: const TextStyle(fontSize: 24)),
                    ),
                    title: Text(
                      habit.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: const Color(0xFF4A3525),
                        decoration: habit.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(
                      habit.description,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF7A6855)),
                    ),
                    trailing: InkWell(
                      onTap: () => _toggleHabit(habit),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: habit.isCompleted ? const Color(0xFF2E7D32) : Colors.transparent,
                          border: Border.all(
                            color: habit.isCompleted ? const Color(0xFF2E7D32) : const Color(0xFF8B5A2B),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          habit.isCompleted ? Icons.check : Icons.favorite_outline,
                          size: 18,
                          color: habit.isCompleted ? Colors.white : const Color(0xFF8B5A2B),
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
    );
  }
}
