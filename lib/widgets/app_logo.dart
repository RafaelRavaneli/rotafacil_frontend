import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.large = false,
    this.iconOnly = false,
    this.scale = 1,
  });

  final bool large;
  final bool iconOnly;

  /// Multiplicador do símbolo (só vale com [iconOnly]).
  final double scale;

  @override
  Widget build(BuildContext context) {
    if (iconOnly) {
      // Exibe o símbolo do PNG original, sem redesenhar nem recolorir a marca.
      return Semantics(
        label: 'RotaFácil',
        image: true,
        child: SizedBox(
          width: 40 * scale,
          height: 48 * scale,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: -24 * scale,
                top: -12 * scale,
                width: 88 * scale,
                height: 88 * scale,
                child: Image.asset(
                  'assets/images/logo.png',
                  excludeFromSemantics: true,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Image.asset(
      'assets/images/logo.png',
      width: large ? 220 : 100,
      height: large ? 220 : 100,
      fit: BoxFit.contain,
      semanticLabel: 'RotaFácil',
    );
  }
}
