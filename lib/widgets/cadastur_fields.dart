import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/date_time_format.dart';

class CadasturFields extends StatelessWidget {
  const CadasturFields({
    super.key,
    required this.number,
    required this.validUntil,
    this.enabled = true,
  });

  final TextEditingController number;
  final TextEditingController validUntil;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        controller: number,
        enabled: enabled,
        keyboardType: TextInputType.number,
        maxLength: 40,
        style: const TextStyle(color: AppColors.ink),
        decoration: const InputDecoration(
          labelText: 'Número do Cadastur',
          counterText: '',
          helperText: 'Informe o registro conforme o certificado.',
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: validUntil,
        enabled: enabled,
        readOnly: true,
        style: const TextStyle(color: AppColors.ink),
        decoration: InputDecoration(
          labelText: 'Validade do Cadastur (opcional)',
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
          final date = await showDatePicker(
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
