import 'package:flutter/material.dart';
import '../models/trail_accessibility.dart';

/// Informação declarada pelo organizador, sem presumir condições não informadas.
class TrailAccessibilitySection extends StatelessWidget {
  const TrailAccessibilitySection({super.key, required this.value});
  final TrailAccessibility value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Acessibilidade e restrições',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const Text(
        'Condições informadas pelo responsável. Consulte as adaptações antes de reservar.',
      ),
      for (final entry in {
        ...TrailAccessibility.labels,
        'idade_minima': 'Idade mínima (anos)',
        ...TrailAccessibility.textLabels,
      }.entries)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text('${entry.value}: ${value.display(entry.key)}'),
        ),
    ],
  );
}

class TrailAccessibilityEditor extends StatefulWidget {
  const TrailAccessibilityEditor({
    super.key,
    required this.initial,
    required this.onChanged,
  });
  final TrailAccessibility initial;
  final ValueChanged<TrailAccessibility> onChanged;
  @override
  State<TrailAccessibilityEditor> createState() =>
      _TrailAccessibilityEditorState();
}

class _TrailAccessibilityEditorState extends State<TrailAccessibilityEditor> {
  late final Map<String, dynamic> values = widget.initial.toJson();
  void update(String key, dynamic value) {
    setState(() => values[key] = value);
    widget.onChanged(TrailAccessibility(Map.of(values)));
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Acessibilidade e restrições',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const Text(
        'Preencha apenas condições verificadas. Deixe “Não informado” quando não souber.',
      ),
      for (final entry in TrailAccessibility.labels.entries)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: DropdownButtonFormField<String>(
            initialValue: switch (values[entry.key]) {
              true => 'sim',
              false => 'nao',
              _ => 'nao_informado',
            },
            isExpanded: true,
            decoration: InputDecoration(labelText: entry.value),
            items: const [
              DropdownMenuItem(
                value: 'nao_informado',
                child: Text('Não informado'),
              ),
              DropdownMenuItem(value: 'sim', child: Text('Sim')),
              DropdownMenuItem(value: 'nao', child: Text('Não')),
            ],
            onChanged: (value) => update(entry.key, switch (value) {
              'sim' => true,
              'nao' => false,
              _ => null,
            }),
          ),
        ),
      TextFormField(
        initialValue: values['idade_minima']?.toString() ?? '',
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Idade mínima (anos)',
          helperText: 'Vazio: não informado. De 0 a 120 anos.',
        ),
        validator: (value) =>
            value == null ||
                value.trim().isEmpty ||
                (int.tryParse(value.trim()) != null &&
                    int.parse(value.trim()) >= 0 &&
                    int.parse(value.trim()) <= 120)
            ? null
            : 'Informe uma idade entre 0 e 120.',
        onChanged: (value) => update(
          'idade_minima',
          value.trim().isEmpty ? null : int.tryParse(value.trim()) ?? -1,
        ),
      ),
      for (final entry in TrailAccessibility.textLabels.entries)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TextFormField(
            initialValue: values[entry.key]?.toString() ?? '',
            maxLength: 1500,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: entry.value,
              alignLabelWithHint: true,
            ),
            onChanged: (value) => update(entry.key, value.trim()),
          ),
        ),
    ],
  );
}
