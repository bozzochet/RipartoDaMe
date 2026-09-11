import 'package:flutter/material.dart';
import 'app_theme.dart';

/// 1. PULSANTE STILE LEGNO / PERGAMENA
class CozyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isSecondary;

  const CozyButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled
            ? AppColors.disabled
            : (isSecondary ? AppColors.surface : AppColors.woodAccent),
        foregroundColor: isSecondary ? AppColors.textPrimary : Colors.white,
        elevation: isSecondary ? 0 : 3,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isSecondary ? AppColors.border : AppColors.woodAccent,
            width: 1.5,
          ),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// 2. CONTAINER STILE PERGAMENA PER LE SCHEDE (CORRETTO PER LISTTILE)
class CozyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const CozyCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      clipBehavior: Clip.antiAlias, // Mantiene i bordi arrotondati puliti
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// 3. INDICATORE DI VALUTA (RUPIE E CUORI) PER L'APPBAR
class CurrencyBadge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;

  const CurrencyBadge({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
