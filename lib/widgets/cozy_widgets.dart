import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/cozy_styles.dart';
import '../widgets/avatar_view.dart';
import '../models/user_model.dart';

/// 1. PULSANTE CON TRAMA LEGNO SCURO E BORDO DORATO
class CozyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isSecondary;
  final String woodAsset; // Permette di specificare la trama (default: legno scuro)

  const CozyButton({
      super.key,
      required this.text,
      this.onPressed,
      this.icon,
      this.isSecondary = false,
      this.woodAsset = 'assets/images/wood_texture_dark.png', // Trama in legno scuro di default
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

    // Bottone principale: Trama in legno scuro e bordo dorato stile RPG
    return Opacity(
      opacity: isDisabled ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(woodAsset),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFDAA520), // Bordo dorato
            width: 1.5,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    const Icon(Icons.star, color: Color(0xFFFFF8DC), size: 18), // o l'icona passata
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontFamily: 'Serif',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFF8DC), // Testo color panna/oro chiaro
                      fontSize: 14,
                    ),
                  ),
                ],
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
