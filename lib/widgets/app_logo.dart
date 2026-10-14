import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.large = false});

  final bool large;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: large ? 220 : 100,
      height: large ? 220 : 100,
      fit: BoxFit.contain,
      semanticLabel: 'RotaFácil',
    );
  }
}
