import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_storage_service.dart';
import 'shop_screen.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../theme/cozy_styles.dart';
import '../widgets/cozy_background.dart';
import '../widgets/cozy_widgets.dart';

class HabitItem {
  final String id;
  final String category;
  final String title;
  final String description;
  final String icon;
  final int rewardHearts;
  bool isCompleted;
  bool isLockedToday;

  HabitItem({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
    this.rewardHearts = 1,
    this.isCompleted = false,
    this.isLockedToday = false,
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
    HabitItem(id: 'c1', category: 'Cura di sé e del corpo', title: 'Skincare serale o mattutina', description: 'Dedica 5 minuti a coccolare la pelle con i tuoi prodotti preferiti.', icon: '🧴'),
    HabitItem(id: 'c2', category: 'Cura di sé e del corpo', title: 'Truccarsi o mettersi lo smalto', description: 'Gioca con i colori o sperimenta un look solo per il piacere di farlo.', icon: '💅'),
    HabitItem(id: 'c3', category: 'Cura di sé e del corpo', title: 'Idratarsi con cura', description: 'Concediti un bel bicchiere d’acqua aromatizzata con limone, cetriolo o menta.', icon: '💧'),
    HabitItem(id: 'c4', category: 'Cura di sé e del corpo', title: 'Fare una tisana o un tè speciale', description: 'Preparati una bevanda calda da sorseggiare lentamente, assaporando il momento.', icon: '🍵'),
    HabitItem(id: 'c5', category: 'Cura di sé e del corpo', title: 'Bere un infuso rilassante prima di dormire', description: 'Una camomilla o una tisana alla melissa per prepararsi al riposo.', icon: '🌙'),
    HabitItem(id: 'c6', category: 'Cura di sé e del corpo', title: 'Doccia o bagno rilassante', description: 'Trasforma la doccia quotidiana in un rituale, magari usando un bagnoschiuma profumato.', icon: '🛁'),
    HabitItem(id: 'c7', category: 'Cura di sé e del corpo', title: 'Massaggio ai piedi', description: 'Coccola i piedi con una crema nutriente dopo una lunga giornata.', icon: '🦶'),
    HabitItem(id: 'c8', category: 'Cura di sé e del corpo', title: 'Curare le mani o i piedi', description: 'Fai una crema nutriente o sistema le unghie con calma.', icon: '✨'),
    HabitItem(id: 'c9', category: 'Cura di sé e del corpo', title: 'Fare un trattamento per i capelli', description: 'Applica una maschera nutriente e goditi il tempo di posa per rilassarti.', icon: '💆‍♀️'),

    HabitItem(id: 'r1', category: 'Relax e movimento', title: 'Guardare una puntata di una serie preferita', description: 'Concediti un episodio della tua serie del cuore senza sensi di colpa.', icon: '📺'),
    HabitItem(id: 'r2', category: 'Relax e movimento', title: 'Cinque minuti di stretching per la schiena', description: 'Scarica le tensioni della colonna vertebrale con qualche movimento dolce.', icon: '🧘‍♀'),
    HabitItem(id: 'r3', category: 'Relax e movimento', title: 'Fare stretching leggero', description: 'Allunga dolcemente i muscoli per sciogliere le tensioni accumulate.', icon: '🤸‍♀'),
    HabitItem(id: 'r4', category: 'Relax e movimento', title: 'Ascoltare una canzone del cuore', description: 'Metti le cuffie, chiudi gli occhi e goditi un brano che ami senza distrazioni.', icon: '🎧'),
    HabitItem(id: 'r5', category: 'Relax e movimento', title: 'Creare una playlist del buon umore', description: 'Raccogli 5-10 brani che ti danno subito energia positiva.', icon: '🎶'),
    HabitItem(id: 'r6', category: 'Relax e movimento', title: 'Profumare l’ambiente', description: 'Accendi una candela profumata o usa degli oli essenziali rilassanti (lavanda, agrumi).', icon: '🕯'),

    HabitItem(id: 'a1', category: 'Creatività e spazio', title: 'Leggere qualche pagina di un libro', description: 'Anche solo un capitolo di una storia che ti appassiona.', icon: '📖'),
    HabitItem(id: 'a2', category: 'Creatività e spazio', title: 'Disegnare o colorare liberamente', description: 'Lascia andare la mano su un foglio senza pensare al risultato finale.', icon: '🎨'),
    HabitItem(id: 'a3', category: 'Creatività e spazio', title: 'Curare una pianta', description: 'Dedica un po\' di attenzione a una pianta di casa, annaffiandola o pulendo le foglie con calma.', icon: '🌱'),
    HabitItem(id: 'a4', category: 'Creatività e spazio', title: 'Cambiare la disposizione di un piccolo spazio', description: 'Sposta un soprammobile o riorganizza una mensola per dare un\'aria nuova.', icon: '🪴'),
  ];

  @override
  void initState() {
    super.initState();
    _user = _storageService.getUser();
    if (_user.maxHearts < 10) {
      _user.maxHearts = 10;
    }
    _verificaCambioGiornoEcarica();
  }

  Future<void> _verificaCambioGiornoEcarica() async {
    final prefs = await SharedPreferences.getInstance();
    final oggi = DateTime.now().toIso8601String().split('T')[0];
    final ultimoGiorno = prefs.getString('ultimo_giorno_attivo');

    // Se la data odierna è diversa dall'ultimo accesso registrato, è mezzanotte passata!
    if (ultimoGiorno != oggi) {
      // 1. Azzeriamo i cuori giornalieri
      _user.currentHearts = 0;
      await _storageService.saveUser(_user);

      // 2. Registriamo il nuovo giorno
      await prefs.setString('ultimo_giorno_attivo', oggi);
      
      // (Le chiavi SharedPreferences 'completate_$oggi' e 'bloccate_$oggi' saranno vuote per il nuovo giorno,
      // azzerando così in modo naturale tutte le spunte e i lock precedenti).
    }

    _caricaStatoAzioni();
  }

  Future<void> _caricaStatoAzioni() async {
    final prefs = await SharedPreferences.getInstance();
    final oggi = DateTime.now().toIso8601String().split('T')[0];
    
    final List<String>? completateOggi = prefs.getStringList('completate_$oggi');
    final List<String>? bloccateOggi = prefs.getStringList('bloccate_$oggi');

    setState(() {
      for (var habit in _habits) {
        habit.isCompleted = false;
        habit.isLockedToday = false;

        if (completateOggi != null && completateOggi.contains(habit.id)) {
          habit.isCompleted = true;
        }
        if (bloccateOggi != null && bloccateOggi.contains(habit.id)) {
          habit.isLockedToday = true;
          habit.isCompleted = true;
        }
      }
      _user = _storageService.getUser();
    });
  }

  Future<void> _salvaStatoAzioni() async {
    final prefs = await SharedPreferences.getInstance();
    final oggi = DateTime.now().toIso8601String().split('T')[0];
    
    List<String> idCompletati = _habits
        .where((h) => h.isCompleted && !h.isLockedToday)
        .map((h) => h.id)
        .toList();

    List<String> idBloccati = _habits
        .where((h) => h.isLockedToday)
        .map((h) => h.id)
        .toList();

    await prefs.setStringList('completate_$oggi', idCompletati);
    await prefs.setStringList('bloccate_$oggi', idBloccati);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _toggleHabit(HabitItem habit) async {
    if (habit.isLockedToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFC62828),
          content: Text('🔒 Questa attività è già stata completata e riscattata oggi!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      habit.isCompleted = !habit.isCompleted;
    });

    if (habit.isCompleted) {
      try {
        await _audioPlayer.play(AssetSource('sounds/heart_gain.mp3'));
      } catch (_) {}

      _user.currentHearts = (_user.currentHearts + habit.rewardHearts).clamp(0, 10);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF2E7D32),
          content: Row(
            children: [
              const Icon(Icons.favorite, color: Colors.white),
              const SizedBox(width: 8),
              Text('+${habit.rewardHearts} Cuore ripristinato! Continua così.', style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    } else {
      _user.currentHearts = (_user.currentHearts - habit.rewardHearts).clamp(0, 10);
    }

    await _storageService.saveUser(_user);
    await _salvaStatoAzioni();

    setState(() {
      _user = _storageService.getUser();
    });
  }

  Future<void> _riscattaCassaOggi() async {
    _user.goldenChests++;
    _user.currentHearts = 0;
    
    for (var habit in _habits) {
      if (habit.isCompleted) {
        habit.isLockedToday = true;
      }
    }

    await _storageService.saveUser(_user);
    await _salvaStatoAzioni();

    setState(() {
      _user = _storageService.getUser();
    });

    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: CozyWoodCard(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '✨ Cassa Riscattata! ✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Serif',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                const SizedBox(height: 12),
                const Icon(
                  Icons.card_giftcard,
                  size: 52,
                  color: Color(0xFFD4AF37),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Hai ottenuto una Cassa Dorata! I cuori sono stati azzerati. Le attività usate per questo traguardo sono state bloccate per oggi, mentre le altre sono pronte per un nuovo ciclo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Chiudi',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    CozyButton(
                      text: 'Vai alla Bottega',
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ShopScreen(),
                          ),
                        );
                      },
                    ),                    
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool puoRiscattare = _user.currentHearts >= 10;

    return CozyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
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
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16.0,
                MediaQuery.of(context).padding.top + kToolbarHeight + 16.0,
                16.0,
                16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. BARRA CUORI & PULSANTE RISCATTA
                  CozyWoodCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Energia Vitale & Pozione dei Cuori',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Serif',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          alignment: WrapAlignment.center,
                          children: List.generate(10, (index) {
                            bool isFilled = index < _user.currentHearts;
                            return AnimatedScale(
                              duration: const Duration(milliseconds: 300),
                              scale: isFilled ? 1.1 : 1.0,
                              child: Icon(
                                isFilled ? Icons.favorite : Icons.favorite_border,
                                color: isFilled ? const Color(0xFFE53935) : AppColors.textSecondary,
                                size: 22,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_user.currentHearts} / 10 Cuori di oggi',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (puoRiscattare) ...[
                          const SizedBox(height: 12),
                          CozyButton(
                            text: 'Riscatta Cassa Dorata!',
                            icon: Icons.card_giftcard,
                            onPressed: _riscattaCassaOggi,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'I Piccoli Rituali di Benessere',
                    style: TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Scegli tra i rituali disponibili per ricaricare i tuoi cuori.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. LISTA DELLE ATTIVITÀ
                  ..._habits.map((habit) {
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
                            child: Text(habit.icon, style: const TextStyle(fontSize: 22)),
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
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '[${habit.category}]',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.woodAccent),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                habit.description,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          trailing: InkWell(
                            onTap: () => _toggleHabit(habit),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: habit.isLockedToday
                                    ? Colors.grey.withOpacity(0.6)
                                    : (habit.isCompleted ? const Color(0xFF2E7D32) : Colors.transparent),
                                border: Border.all(
                                  color: habit.isLockedToday
                                      ? Colors.grey
                                      : (habit.isCompleted ? const Color(0xFF2E7D32) : AppColors.woodAccent),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                habit.isLockedToday
                                    ? Icons.lock
                                    : (habit.isCompleted ? Icons.check : Icons.favorite_outline),
                                size: 18,
                                color: habit.isLockedToday || habit.isCompleted ? Colors.white : AppColors.woodAccent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),                  
                ],
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
}
