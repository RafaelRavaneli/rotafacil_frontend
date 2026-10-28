import '../utils/app_pickers.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/date_time_format.dart';

class CadasturFields extends StatelessWidget {
  const CadasturFields({
    super.key,
    required this.number,
    required this.validUntil,
    this.enabled = true,
    this.labelsAbove = false,
    this.labelStyle,
  });

  final TextEditingController number;
  final TextEditingController validUntil;
  final bool enabled;
  final bool labelsAbove;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (labelsAbove) ...[
        Text('Número do Cadastur', style: labelStyle),
        const SizedBox(height: 6),
      ],
      TextField(
        controller: number,
        enabled: enabled,
        keyboardType: TextInputType.number,
        maxLength: 40,
        style: const TextStyle(color: AppColors.ink),
        decoration: InputDecoration(
          labelText: labelsAbove ? null : 'Número do Cadastur',
          counterText: '',
          helperText: 'Informe o registro conforme o certificado.',
          helperStyle: labelsAbove ? labelStyle?.copyWith(fontSize: 12) : null,
        ),
      ),
      const SizedBox(height: 12),
      if (labelsAbove) ...[
        Text('Validade do Cadastur (opcional)', style: labelStyle),
        const SizedBox(height: 6),
      ],
      TextField(
        controller: validUntil,
        enabled: enabled,
        readOnly: true,
        style: const TextStyle(color: AppColors.ink),
        decoration: InputDecoration(
          labelText: labelsAbove ? null : 'Validade do Cadastur (opcional)',
          hintText: 'DD/MM/AAAA',
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: IconButton(
            tooltip: 'Limpar validade',
            onPressed: enabled ? validUntil.clear : null,
            icon: const Icon(Icons.close),
          ),
        ),
        onTap: () async {
          final selected = parseAppDateTime(validUntil.text);
          final now = DateTime.now();
          final date = await showAppDatePicker(
            context: context,
            initialDate: selected ?? now,
            firstDate: DateTime(1900),
            lastDate: DateTime(now.year + 100),
            helpText: 'Validade do Cadastur',
          );
          if (date != null) {
            validUntil.text = formatBrazilianDate(date.toIso8601String());
          }
        },
      ),
      const SizedBox(height: 8),
      const Text(
        'O número informado será conferido pela equipe. Envie o certificado em Documentos profissionais após entrar na conta.',
        style: TextStyle(fontSize: 12),
      ),
    ],
  );
}
