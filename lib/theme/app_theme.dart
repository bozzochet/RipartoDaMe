import 'package:flutter/material.dart';

class AppColors {
  // Sfondi e Toni Caldi (Stile Pergamena/Legno)
  static const Color background = Color(0xFFF7F1E3);      // Pergamena chiara (sfondo app)
  static const Color surface = Color(0xFFEFE3CE);         // Card e riquadri
  static const Color surfaceDark = Color(0xFFE8DFC8);     // Card secondarie / slot
  static const Color border = Color(0xFFC4B296);          // Bordi sottili
  
  // Testi e Dettagli Scuri
  static const Color textPrimary = Color(0xFF4A3525);     // Testo principale (Marrone scuro)
  static const Color textSecondary = Color(0xFF7A6855);   // Testo secondario / descrizioni
  static const Color woodAccent = Color(0xFF8B5A2B);      // Marrone Legno (Pulsanti / Dettagli)

  // Valute & Status (Stile Zelda / Fantasy)
  static const Color heartRed = Color(0xFFE53935);        // Cuori Salute/Cura
  static const Color rupeeGreen = Color(0xFF00E676);      // Rupia Verde
  static const Color rupeeBlue = Color(0xFF29B6F6);       // Rupia Blu
  static const Color rupeePurple = Color(0xFFAB47BC);     // Rupia Viola
  static const Color rupeeGold = Color(0xFFFFCA28);       // Rupia Dorata / Stelle
  
  // Stati Azioni
  static const Color success = Color(0xFF2E7D32);        // Verde successo
  static const Color disabled = Color(0xFFA89885);       // Elementi bloccati
}

class AppTheme {
  static ThemeData get cozyTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.woodAccent,
      fontFamily: 'Serif', // Puoi usare un font custom come Cinzel o Georgia

      // Configurazione AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontFamily: 'Serif',
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),

      // Stile Dialog / Pop-up (Aggiornato per Flutter 3.22+)
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 2),
        ),
      ),
    );
  }
}
