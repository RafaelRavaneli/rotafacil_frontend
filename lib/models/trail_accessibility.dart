class TrailAccessibility {
  const TrailAccessibility([this.values = const {}]);
  final Map<String, dynamic> values;
  static const labels = {
    'mobilidade_reduzida': 'Acesso para mobilidade reduzida',
    'apoio_visual': 'Apoio para deficiência visual',
    'apoio_auditivo': 'Apoio para deficiência auditiva',
    'acompanhante_necessario': 'Acompanhante necessário',
    'trechos_acessiveis': 'Trechos acessíveis',
    'banheiro_acessivel': 'Banheiro acessível',
    'transporte_acessivel': 'Transporte acessível',
  };
  static const textLabels = {
    'restricoes_fisicas': 'Restrições físicas',
    'condicionamento': 'Condicionamento recomendado',
    'adaptacoes': 'Adaptações oferecidas',
    'observacoes': 'Observações de acessibilidade',
  };
  static Iterable<String> get filterKeys =>
      labels.keys.where((key) => key != 'acompanhante_necessario');
  bool? answer(String key) => values[key] is bool ? values[key] as bool : null;
  bool matches(Iterable<String> resources) =>
      resources.every((key) => answer(key) == true);
  String display(String key) {
    if (labels.containsKey(key)) {
      return switch (answer(key)) {
        true => 'Sim',
        false => 'Não',
        null => 'Não informado',
      };
    }
    final value = values[key];
    return value == null || value.toString().trim().isEmpty
        ? 'Não informado'
        : value.toString();
  }

  Map<String, dynamic> toJson() => Map.of(values);
  factory TrailAccessibility.fromJson(Object? value) => TrailAccessibility(
    value is Map ? Map<String, dynamic>.from(value) : const {},
  );
}
