import 'package:flutter/material.dart';

class AvatarView extends StatelessWidget {
  final String bodyPath;
  final String hairPath;
  final String outfitPath;
  final BoxFit fit;

  const AvatarView({
    super.key,
    required this.bodyPath,
    required this.hairPath,
    required this.outfitPath,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (bodyPath.isNotEmpty)
          Image.asset(bodyPath, fit: fit),
        if (outfitPath.isNotEmpty)
          Image.asset(outfitPath, fit: fit),
        if (hairPath.isNotEmpty)
          Image.asset(hairPath, fit: fit),
      ],
    );
  }
}
