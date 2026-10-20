import 'package:flutter/material.dart';

/// Transição discreta, sem redimensionar o fundo e o formulário durante a rota.
class AuthPageRoute<T> extends MaterialPageRoute<T> {
  AuthPageRoute({required super.builder, super.settings});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 380);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 320);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeOf(context)?.disableAnimations == true) return child;
    final curved = animation.drive(CurveTween(curve: Curves.easeInOutCubic));
    return FadeTransition(
      opacity: curved,
      child: RepaintBoundary(child: child),
    );
  }
}
