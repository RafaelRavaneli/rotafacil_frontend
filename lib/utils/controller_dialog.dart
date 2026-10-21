import 'package:flutter/material.dart';

/// Aguarda a animação de saída antes de liberar controladores usados no diálogo.
Future<T?> showControllerDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required List<TextEditingController> controllers,
}) async {
  final route = DialogRoute<T>(context: context, builder: builder);
  try {
    final result = await Navigator.of(context, rootNavigator: true).push(route);
    await route.completed;
    return result;
  } finally {
    for (final controller in controllers) {
      controller.dispose();
    }
  }
}
