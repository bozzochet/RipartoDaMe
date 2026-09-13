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

// Widget Card con filtro semi-trasparente
class CozyWoodCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  /// Opacità dello strato panna sopra il legno (0.0 = legno puro, 1.0 = panna solido)
  final double overlayOpacity;

  const CozyWoodCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.overlayOpacity = 0.65, // Bilanciamento ideale tra trama visibile e leggibilità
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: CozyStyles.woodBoxDecoration(),
      clipBehavior: Clip.antiAlias, // Mantiene i bordi arrotondati puliti
      child: Container(
        padding: padding ?? const EdgeInsets.all(16.0),
        // 📄 Sfondo 2: Overlay effetto pergamena/panna semi-trasparente
        color: const Color(0xFFFDF6E3).withOpacity(overlayOpacity),
        child: child,
      ),
    );
  }
}
