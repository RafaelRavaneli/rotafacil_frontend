String normalizeRoleKey(String? value) {
  final raw = value?.trim().toLowerCase() ?? '';

  switch (raw) {
    case 'usuario':
    case 'turista':
    case 'tourist':
      return 'turista';

    case 'guia':
    case 'guide':
      return 'guia';

    case 'agencia':
    case 'agência':
    case 'agency':
      return 'agencia';

    default:
      return raw;
  }
}

String roleDisplayName(String? value) {
  switch (normalizeRoleKey(value)) {
    case 'turista':
      return 'Turista';

    case 'guia':
      return 'Guia';

    case 'agencia':
      return 'Agência';

    default:
      final raw = value?.trim() ?? '';
      return raw.isEmpty ? 'Turista' : raw;
  }
}
