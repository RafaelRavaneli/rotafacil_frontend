import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.large = false, this.iconOnly = false});

  final bool large;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    if (iconOnly) {
      // Exibe o símbolo do PNG original, sem redesenhar nem recolorir a marca.
      return Semantics(
        label: 'RotaFácil',
        image: true,
        child: SizedBox(
          width: 40,
          height: 48,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: -24,
                top: -12,
                width: 88,
                height: 88,
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
