import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/cozy_styles.dart';
import '../widgets/avatar_view.dart';
import '../models/user_model.dart';

/// 1. PULSANTE CON TRAMA LEGNO (DINAMICO: SCURO SE SELEZIONATO, CHIARO SE INATTIVO)
class CozyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isSecondary;
  final bool isSelected; // Nuovo parametro per gestire lo stato attivo/inattivo
  final String? woodAsset; // Lasciamo opzionale se si vuole forzare un asset manuale

  const CozyButton({
      super.key,
      required this.text,
      this.onPressed,
      this.icon,
      this.isSecondary = false,
      this.isSelected = false,
      this.woodAsset,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;

    // Se è un bottone secondario, manteniamo lo stile pergamena pulito/chiaro
    if (isSecondary) {
      return Opacity(
        opacity: isDisabled ? 0.6 : 1.0,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.border, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onPressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.textPrimary),
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
        ),
      );
    }

    // Determiniamo l'asset, il bordo e il colore del testo in base allo stato "isSelected"
    final String activeWood = woodAsset ?? (isSelected 
      ? 'assets/images/wood_texture_dark.png' 
      : 'assets/images/wood_texture_verylight.png'); // Usa la tua texture light!

    final Color borderColor = isSelected 
    ? const Color(0xFFDAA520) // Bordo dorato se selezionato
    : const Color(0xFF8B5A2B); // Bordo marrone scuro se inattivo

    final Color textColor = isSelected 
    ? const Color(0xFFFFF8DC) // Testo panna/oro chiaro
    : const Color(0xFF3E2723); // Testo marrone scuro per leggibilità sul chiaro

    return Opacity(
      opacity: isDisabled ? 0.6 : 1.0,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(activeWood),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: icon != null
              ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: textColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Serif',
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              )
              : Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Serif',
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
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

/// 4. AVATAR CIRCOLARE STRATIFICATO PER LA HOME / HEADER
class CozyAvatar extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;
  final UserModel user;

  const CozyAvatar({
    super.key,
    this.size = 85,
    this.onTap,
    required this.user,
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
          border: Border.all(
            color: AppColors.woodAccent,
            width: size * 0.03,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: OverflowBox(
            maxHeight: size * 2.0,
            maxWidth: size * 2.0,
            alignment: Alignment.topCenter,
            child: AvatarView(
              bodyPath: user.avatarConfig.bodyPath,
              hairPath: user.avatarConfig.hairPath,
              outfitPath: user.avatarConfig.outfitPath,
            ),
          ),
        ),
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
