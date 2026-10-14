import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Fundo compartilhado pelas telas anteriores à entrada na home.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.body, this.welcome = false});

  final Widget body;
  final bool welcome;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/auth_background.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          excludeFromSemantics: true,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: welcome
                  ? const [
                      Color(0x33FFFFFF),
                      Color(0x22000000),
                      Color(0xD914532D),
                    ]
                  : [
                      AppColors.cream.withValues(alpha: .88),
                      AppColors.cream.withValues(alpha: .76),
                      AppColors.cream.withValues(alpha: .88),
                    ],
              stops: const [0, .5, 1],
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: welcome
              ? null
              : AppBar(
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                ),
          body: body,
        ),
      ],
    );
  }
}
