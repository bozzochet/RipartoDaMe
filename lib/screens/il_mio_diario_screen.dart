import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../theme/cozy_styles.dart';
import '../theme/cozy_background.dart';
import '../theme/cozy_widgets.dart';

class MealEntry {
  final String title;
  final String icon;
  String foodText;
  String? photoPath;
  bool isRewardClaimed;

  MealEntry({
    required this.title,
    required this.icon,
    this.foodText = '',
    this.photoPath,
    this.isRewardClaimed = false,
  });
}

class IlMioDiarioScreen extends StatefulWidget {
  const IlMioDiarioScreen({super.key});

  @override
  State<IlMioDiarioScreen> createState() => _IlMioDiarioScreenState();
}

class _IlMioDiarioScreenState extends State<IlMioDiarioScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  late UserModel _user;

  final List<MealEntry> _meals = [
    MealEntry(title: 'Colazione', icon: '🥐'),
    MealEntry(title: 'Pranzo', icon: '🍲'),
    MealEntry(title: 'Cena', icon: '🌙'),
    MealEntry(title: 'Acqua & Extra', icon: '💧'),
  ];

  @override
  void initState() {
    super.initState();
    _user = _storageService.getUser();
  }

  void _saveMealData(MealEntry meal, String text) async {
    setState(() {
      meal.foodText = text;
      if (text.trim().isNotEmpty && !meal.isRewardClaimed) {
        meal.isRewardClaimed = true;
        _user.coins += 5;
      }
    });

    await _storageService.saveUser(_user);
  }

  void _simulatePhotoUpload(MealEntry meal) async {
    setState(() {
      meal.photoPath = 'assets/images/placeholder_meal.png';
      if (!meal.isRewardClaimed) {
        meal.isRewardClaimed = true;
        _user.coins += 5;
      }
    });

    await _storageService.saveUser(_user);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF2E7D32),
        content: Text('📸 Foto aggiunta! +5 Rupie guadagnate! 💎'),
      ),
    );
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
            'Il mio Diario',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Diario Alimentare & Benessere',
                      style: TextStyle(
                        fontFamily: 'Serif',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'Traccia i tuoi pasti e la tua idratazione. Ogni inserimento ti premia con Rupie!',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _meals.length,
                      itemBuilder: (context, index) {
                        final meal = _meals[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14.0),
                          child: CozyWoodCard(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(meal.icon, style: const TextStyle(fontSize: 24)),
                                    const SizedBox(width: 8),
                                    Text(
                                      meal.title,
                                      style: const TextStyle(
                                        fontFamily: 'Serif',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (meal.isRewardClaimed)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00E676).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          '+5 💎',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  onChanged: (text) => _saveMealData(meal, text),
                                  controller: TextEditingController(text: meal.foodText)
                                    ..selection = TextSelection.fromPosition(TextPosition(offset: meal.foodText.length)),
                                  decoration: InputDecoration(
                                    hintText: 'Cosa hai mangiato per ${meal.title.toLowerCase()}?',
                                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.6),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _simulatePhotoUpload(meal),
                                      icon: const Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.woodAccent),
                                      label: Text(
                                        meal.photoPath == null ? 'Aggiungi Foto' : 'Foto caricata ✓',
                                        style: const TextStyle(fontSize: 11, color: AppColors.woodAccent),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
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
}
