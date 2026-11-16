import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Seletores de data e hora com o tema padrão do app.
///
/// Telas com fundo escuro (como o cadastro) alteram a cor dos botões de texto.
/// Como o diálogo herda o tema do contexto, "Cancelar" e "OK" ficavam claros
/// demais sobre o fundo claro do seletor. Aqui o diálogo sempre usa
/// [AppTheme.light], independentemente de onde foi aberto.
Widget _withAppTheme(BuildContext context, Widget? child) =>
    Theme(data: AppTheme.light, child: child ?? const SizedBox.shrink());

Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
}) => showDatePicker(
  context: context,
  initialDate: initialDate,
  firstDate: firstDate,
  lastDate: lastDate,
  helpText: helpText,
  builder: _withAppTheme,
);
