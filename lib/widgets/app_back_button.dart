import 'package:flutter/material.dart';
import '../navigation/app_routes.dart';

/// Botão de volta que também funciona quando não existe uma rota anterior.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.fallbackLocation,
    this.color,
    this.onPressed,
  });
  final String? fallbackLocation;
  final Color? color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => BackButton(
    color: color,
    onPressed:
        onPressed ??
        () => AppRoutes.back(context, fallbackLocation: fallbackLocation),
  );
}
