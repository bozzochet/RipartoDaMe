import 'package:flutter/material.dart';

class CozyBackground extends StatelessWidget {
  final Widget child;
  final String imagePath;
  final double opacity;

  const CozyBackground({
    super.key,
    required this.child,
    this.imagePath = 'assets/images/default_bg.png', // Sfondo predefinito
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
      child: opacity < 1.0
          ? Container(
              color: Colors.white.withOpacity(1.0 - opacity),
              child: child,
            )
          : child,
    );
  }
}
