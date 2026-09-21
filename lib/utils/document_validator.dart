class DocumentValidator {
  const DocumentValidator._();

  static String digitsOnly(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  static bool isValidCpf(String value) {
    final cpf = digitsOnly(value);

    if (cpf.length != 11) return false;
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;

    int firstSum = 0;
    for (int i = 0; i < 9; i++) {
      firstSum += int.parse(cpf[i]) * (10 - i);
    }

    int firstDigit = (firstSum * 10) % 11;
    if (firstDigit == 10) firstDigit = 0;

    if (firstDigit != int.parse(cpf[9])) return false;

    int secondSum = 0;
    for (int i = 0; i < 10; i++) {
      secondSum += int.parse(cpf[i]) * (11 - i);
    }

    int secondDigit = (secondSum * 10) % 11;
    if (secondDigit == 10) secondDigit = 0;

    return secondDigit == int.parse(cpf[10]);
  }

  static bool isValidCnpj(String value) {
    final cnpj = digitsOnly(value);

    if (cnpj.length != 14) return false;
    if (RegExp(r'^(\d)\1{13}$').hasMatch(cnpj)) return false;

    int calculateDigit(String base, List<int> weights) {
      int sum = 0;

      for (int i = 0; i < weights.length; i++) {
        sum += int.parse(base[i]) * weights[i];
      }

      final remainder = sum % 11;
      return remainder < 2 ? 0 : 11 - remainder;
    }

    const firstWeights = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    const secondWeights = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

    final firstDigit = calculateDigit(cnpj.substring(0, 12), firstWeights);

    if (firstDigit != int.parse(cnpj[12])) return false;

    final secondDigit = calculateDigit(
      '${cnpj.substring(0, 12)}$firstDigit',
      secondWeights,
    );

    return secondDigit == int.parse(cnpj[13]);
  }

  static bool isValidForRole(String role, String value) {
    final normalized = role.toLowerCase().trim();

    if (normalized == 'guia') {
      return isValidCpf(value);
    }

    if (normalized == 'agencia' || normalized == 'agência') {
      return isValidCnpj(value);
    }

    return true;
  }

  static String labelForRole(String role) {
    final normalized = role.toLowerCase().trim();

    if (normalized == 'guia') return 'CPF';
    if (normalized == 'agencia' || normalized == 'agência') return 'CNPJ';

    return 'Documento';
  }

  static String formatCpf(String value) {
    final digits = digitsOnly(value);
    if (digits.length != 11) return value;

    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.'
        '${digits.substring(6, 9)}-${digits.substring(9, 11)}';
  }

  static String formatCnpj(String value) {
    final digits = digitsOnly(value);
    if (digits.length != 14) return value;

    return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.'
        '${digits.substring(5, 8)}/${digits.substring(8, 12)}-'
        '${digits.substring(12, 14)}';
  }

  static String formatForRole(String role, String value) {
    final normalized = role.toLowerCase().trim();

    if (normalized == 'guia') return formatCpf(value);
    if (normalized == 'agencia' || normalized == 'agência') {
      return formatCnpj(value);
    }

    return value;
  }
}
