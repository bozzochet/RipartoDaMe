import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../theme/cozy_widgets.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';

class IlMioCorpoScreen extends StatefulWidget {
  const IlMioCorpoScreen({super.key});

  @override
  State<IlMioCorpoScreen> createState() => _IlMioCorpoScreenState();
}

class _IlMioCorpoScreenState extends State<IlMioCorpoScreen> with SingleTickerProviderStateMixin {
  final LocalStorageService _storageService = LocalStorageService();
  late UserModel _user;
  late TabController _tabController;

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _glycemiaController = TextEditingController();
  final TextEditingController _insulinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = _storageService.getUser();
    _weightController.text = _user.currentWeight?.toString() ?? '';
    _targetController.text = _user.targetWeight.toString() ?? '';
    _tabController = TabController(length: 3, vsync: this);
  }

void _saveWeight() async {
    // Sostituiamo eventuale virgola con il punto prima del parsing
    final cleanText = _weightController.text.replaceAll(',', '.');
    final newWeight = double.tryParse(cleanText);

    if (newWeight != null && newWeight > 0) {
      // Salva sia lo storico delle date che l'utente aggiornato
      await _storageService.addWeightEntry(newWeight);
      
      setState(() {
        _user = _storageService.getUser();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('✨ Rilevazione peso aggiornata!'),
        ),
      );
    } else {
      // Opzionale: mostra un avviso se il formato non è valido
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.heartRed,
          content: Text('⚠️ Inserisci un valore numerico valido.'),
        ),
      );
    }
  }
  
  // Finestra di dialogo per modificare l'obiettivo di peso
  void _showEditTargetDialog() {
    _targetController.text = _user.targetWeight.toString();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifica Obiettivo Peso'),
          content: TextField(
            controller: _targetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Nuovo Obiettivo (kg)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.woodAccent),
              onPressed: () async {
                final cleanText = _targetController.text.replaceAll(',', '.');
                final newTarget = double.tryParse(cleanText);
                if (newTarget != null && newTarget > 0) {
                  setState(() {
                    _user.targetWeight = newTarget;
                  });
                  await _storageService.saveUser(_user);
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text('🎯 Obiettivo aggiornato!'),
                    ),
                  );
                }
              },
              child: const Text('Salva', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Il Mio Corpo'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.woodAccent,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.monitor_weight), text: 'Peso'),
            Tab(icon: Icon(Icons.bloodtype), text: 'Valori & Referti'),
            Tab(icon: Icon(Icons.photo_library), text: 'Foto'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. DIARIO PESO & PROGRESSI
          _buildWeightTab(),

          // 2. VALORI EMATICI & REFERTI MEDICI
          _buildBloodTab(),

          // 3. DIARIO FOTOGRAFICO PROGRESSI
          _buildPhotosTab(),
        ],
      ),
    );
  }

  // TAB 1: Peso & Grafico
  Widget _buildWeightTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CozyCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn('Attuale', '${_user.currentWeight} kg'),
                const Icon(Icons.arrow_forward, color: AppColors.woodAccent),
                
                // Obiettivo reso Cliccabile
                InkWell(
                  onTap: _showEditTargetDialog,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMetricColumn('Obiettivo', '${_user.targetWeight} kg'),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit, size: 18, color: AppColors.woodAccent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CozyCard(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Nuovo Peso (kg)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CozyButton(
                  text: 'Salva',
                  icon: Icons.add,
                  onPressed: _saveWeight,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Andamento Peso',
            style: TextStyle(fontFamily: 'Serif', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          CozyCard(
            child: Container(
              height: 220,
              padding: const EdgeInsets.only(top: 16, right: 16, bottom: 8, left: 8),
              child: _buildWeightGraph(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightGraph() {
    final List<WeightEntry> history = _storageService.getWeightHistory();

    if (history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 36, color: AppColors.textSecondary),
            SizedBox(height: 8),
            Text(
              'Nessuna registrazione presente.\nInserisci il tuo primo peso per attivare il grafico!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Ordiniamo lo storico per data
    history.sort((a, b) => a.date.compareTo(b.date));

    final DateTime startDate = history.first.date;
    final DateTime endDate = history.last.date;

    // Coordinate X basate sui giorni trascorsi dalla prima misurazione (startDate = 0.0)
    final List<FlSpot> spots = history.map((entry) {
        final double xValue = entry.date.difference(startDate).inHours / 24.0;
        return FlSpot(xValue, entry.weight);
    }).toList();

    // MARGINI ASSE X: -1 giorno rispetto al primo punto, +1 giorno rispetto all'ultimo
    final double totalDaysDifference = endDate.difference(startDate).inHours / 24.0;
    final double minX = -1.0; 
    final double maxX = totalDaysDifference + 1.0;

    // Margini per l'Asse Y (Peso)
    final List<double> weights = history.map((e) => e.weight).toList();
    final double minWeight = weights.reduce((a, b) => a < b ? a : b);
    final double maxWeight = weights.reduce((a, b) => a > b ? a : b);
    
    final double minY = (minWeight == maxWeight) ? minWeight - 5.0 : minWeight - 2.0;
    final double maxY = (minWeight == maxWeight) ? maxWeight + 5.0 : maxWeight + 2.0;

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                  final entry = history.reduce((a, b) {
                      final diffA = (a.date.difference(startDate).inHours / 24.0 - spot.x).abs();
                      final diffB = (b.date.difference(startDate).inHours / 24.0 - spot.x).abs();
                      return diffA < diffB ? a : b;
                  });
                  final dateStr = '${entry.date.day}/${entry.date.month}';
                  return LineTooltipItem(
                    '${entry.weight.toStringAsFixed(1)} kg\n$dateStr',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          
          // ASSE VERTICALE (PESO IN KG)
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                final String formatted = (value % 1 == 0)
                ? value.toInt().toString()
                : value.toStringAsFixed(1);
                return Text(
                  '$formatted kg',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                );
              },
            ),
          ),
          
          // ASSE ORIZZONTALE (DATE: COMPRESE INIZIO E FINE ASSE)
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              // Mostra un'etichetta ogni 1 giorno (oppure ogni 2 se l'intervallo è lungo)
              interval: (maxX - minX) > 10 ? ((maxX - minX) / 5) : 1.0,
              getTitlesWidget: (value, meta) {
                // Converte il valore X (giorni trascorsi) nella data calendario corrispondente
                final DateTime calculatedDate = startDate.add(Duration(hours: (value * 24).round()));

                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    '${calculatedDate.day}/${calculatedDate.month}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.disabled.withOpacity(0.3)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: history.length > 2,
            color: AppColors.woodAccent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.woodAccent.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: Valori Ematici & Referti
  Widget _buildBloodTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Valori Ematici Recenti',
            style: TextStyle(fontFamily: 'Serif', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          CozyCard(
            child: Column(
              children: [
                TextField(
                  controller: _glycemiaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Glicemia a digiuno (mg/dL)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _insulinController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Insulina (µIU/mL)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                CozyButton(
                  text: 'Registra Valori',
                  icon: Icons.bookmark_add,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Valori salvati nel registro sanitario.')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Referti & Esami Medici',
            style: TextStyle(fontFamily: 'Serif', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          CozyCard(
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppColors.heartRed, size: 36),
              title: const Text('Carica un nuovo referto (PDF/Foto)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Conserva le analisi del sangue in modo sicuro'),
              trailing: const Icon(Icons.upload_file, color: AppColors.woodAccent),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3: Diario Fotografico
  Widget _buildPhotosTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CozyButton(
            text: 'Aggiungi Foto Progressi 📸',
            icon: Icons.camera_alt,
            onPressed: () {},
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                CozyCard(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.photo, size: 40, color: AppColors.disabled),
                        SizedBox(height: 8),
                        Text('Inizio Percorso', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontFamily: 'Serif', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}
