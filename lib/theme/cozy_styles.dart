import 'package:flutter/material.dart';
import 'app_theme.dart';

class CozyStyles {
  // Box con trama di legno e overlay chiaro per massima leggibilità
  static BoxDecoration woodBoxDecoration({
    Color borderColor = const Color(0xFF8B5A2B),
    double borderWidth = 1.5,
    double borderRadius = 16.0,
    String imagePath = 'assets/images/wood_texture_verylight.png', // Il tuo asset
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      // 🪵 Sfondo 1: Trama legno
      image: DecorationImage(
        image: AssetImage(imagePath),
        fit: BoxFit.cover,
      ),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: const [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ],
    );
  }

  static InputDecoration cozyInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      filled: true,
      fillColor: Colors.white.withOpacity(0.85),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF8B5A2B)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF8B5A2B)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.woodAccent, width: 2),
      ),
    );
  }
}
