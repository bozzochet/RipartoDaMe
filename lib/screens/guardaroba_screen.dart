import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';

class GuardarobaScreen extends StatefulWidget {
  const GuardarobaScreen({super.key});

  @override
  State<GuardarobaScreen> createState() => _GuardarobaScreenState();
}

class _GuardarobaScreenState extends State<GuardarobaScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  late UserModel _user;

  String _equippedHead = '👑'; // Accessorio testa attuale
  String _equippedOutfit = '🧶'; // Abito attuale

  final List<Map<String, String>> clothesList = [
    {'id': '1', 'name': 'Corona Margherita', 'icon': '👑', 'type': 'head'},
    {'id': '2', 'name': 'Maglione Oversize', 'icon': '🧶', 'type': 'outfit'},
    {'id': '3', 'name': 'Mantello Bosco', 'icon': '🧥', 'type': 'outfit'},
    {'id': '4', 'name': 'Stivali Esploratrice', 'icon': '🥾', 'type': 'feet'},
  ];

  @override
  void initState() {
    super.initState();
    _user = _storageService.getUser();
  }

  void _equipItem(Map<String, String> item) {
    setState(() {
      if (item['type'] == 'head') {
        _equippedHead = item['icon']!;
      } else if (item['type'] == 'outfit') {
        _equippedOutfit = item['icon']!;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF8B5A2B),
        content: Text('Hai indossato: ${item['name']}'),
      ),
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
        title: const Text(
          'Il mio Guardaroba',
          style: TextStyle(
            color: Color(0xFF4A3525),
            fontFamily: 'Serif',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // 1. ANTEPRIMA AVATAR CON GLI VESTITI INDOSSATI
          Container(
            width: 160,
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFEFE3CE),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF8B5A2B), width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Faccia/Base Avatar
                const Positioned(bottom: 55, child: Text('🧑', style: TextStyle(fontSize: 60))),
                // Cappello/Accessorio
                Positioned(top: 15, child: Text(_equippedHead, style: const TextStyle(fontSize: 35))),
                // Abito
                Positioned(bottom: 20, child: Text(_equippedOutfit, style: const TextStyle(fontSize: 40))),
              ],
            ),
          ),

          const SizedBox(height: 10),
          Text(
            _user.name,
            style: const TextStyle(
              fontFamily: 'Serif',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A3525),
            ),
          ),
          const SizedBox(height: 20),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Abiti e Accessori Posseduti',
                style: TextStyle(
                  fontFamily: 'Serif',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A3525),
                ),
              ),
            ),
          ),

          // 2. LISTA CAPI DA INDOSSARE
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: clothesList.length,
              itemBuilder: (context, index) {
                final item = clothesList[index];
                bool isEquipped = (_equippedHead == item['icon'] || _equippedOutfit == item['icon']);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isEquipped ? const Color(0xFFE8DFC8) : const Color(0xFFEFE6D5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isEquipped ? const Color(0xFF8B5A2B) : const Color(0xFFC4B296),
                      width: isEquipped ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Text(item['icon']!, style: const TextStyle(fontSize: 28)),
                    title: Text(
                      item['name']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A3525)),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEquipped ? const Color(0xFF2E7D32) : const Color(0xFF8B5A2B),
                      ),
                      onPressed: () => _equipItem(item),
                      child: Text(
                        isEquipped ? 'Indossato' : 'Indossa',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
