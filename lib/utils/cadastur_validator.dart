class CadasturValidator {
  const CadasturValidator._();

  static String normalize(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');

  static String? error(String number, {bool required = true}) {
    final value = number.trim();
    if (value.isEmpty) return required ? 'Informe o número do Cadastur.' : null;
    if (value.length > 40 ||
        !RegExp(r'^[0-9][0-9. /-]*$').hasMatch(value) ||
        normalize(value).length > 30) {
      return 'Informe o número do Cadastur conforme o certificado, usando números e separadores.';
    }
    return null;
  }
}
