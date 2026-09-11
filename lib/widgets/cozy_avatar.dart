import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CozyAvatar extends StatelessWidget {
  final double size;
  final String hairStyle;
  final Color hairColor;
  final Color skinColor;
  final String outfit;
  final String headwear;
  final VoidCallback? onTap;

  const CozyAvatar({
    super.key,
    this.size = 100,
    this.hairStyle = '💇‍♀️',
    this.hairColor = const Color(0xFF4A3525),
    this.skinColor = const Color(0xFFF5D0A9),
    this.outfit = '🧶',
    this.headwear = '👑',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceDark,
          border: Border.all(color: AppColors.border, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Viso / Pelle
            Positioned(
              bottom: size * 0.18,
              child: Container(
                width: size * 0.55,
                height: size * 0.55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: skinColor,
                ),
                child: Center(
                  child: Text(
                    '😊',
                    style: TextStyle(fontSize: size * 0.3),
                  ),
                ),
              ),
            ),

            // Capelli
            Positioned(
              top: size * 0.08,
              child: Text(
                hairStyle,
                style: TextStyle(
                  fontSize: size * 0.33,
                  shadows: [
                    Shadow(
                      color: hairColor,
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),

            // Accessorio Testa
            Positioned(
              top: size * 0.02,
              child: Text(
                headwear,
                style: TextStyle(fontSize: size * 0.22),
              ),
            ),

            // Abito Indossato
            Positioned(
              bottom: 0,
              child: Text(
                outfit,
                style: TextStyle(fontSize: size * 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
