import 'dart:math' as math;

import 'package:flutter/services.dart';

import 'role_utils.dart';

/// Máscaras dos campos de texto do app (CPF, CNPJ, telefone, valor e km).
///
/// Todas aceitam só números, reformatam a cada toque e mantêm o cursor no
/// lugar. Apagar um separador (ponto, traço, parêntese) apaga o número que vem
/// antes dele, para a máscara nunca "travar" o usuário.
class InputMasks {
  const InputMasks._();

  static const TextInputFormatter cpf = _CpfFormatter();
  static const TextInputFormatter cnpj = _CnpjFormatter();
  static const TextInputFormatter cpfOrCnpj = _CpfOrCnpjFormatter();
  static const TextInputFormatter phone = _PhoneFormatter();
  static const TextInputFormatter currency = CurrencyInputFormatter();
  static const TextInputFormatter km = DecimalInputFormatter();

  /// Máscara do documento de cada perfil: guia usa CPF; agência, CNPJ.
  static TextInputFormatter documentForRole(String role) {
    switch (normalizeRoleKey(role)) {
      case 'guia':
        return cpf;
      case 'agencia':
        return cnpj;
      default:
        return cpfOrCnpj;
    }
  }

  static String formatCpf(String value) =>
      _CpfFormatter._mask(_onlyDigits(value));

  static String formatCnpj(String value) =>
      _CnpjFormatter._mask(_onlyDigits(value));

  /// Aplica a máscara de telefone a um valor já salvo (com ou sem formatação).
  static String formatPhone(String value) {
    final digits = _PhoneFormatter._normalize(_onlyDigits(value));
    return _PhoneFormatter._mask(
      digits.length > 11 ? digits.substring(0, 11) : digits,
    );
  }

  /// Distância em km para exibir em campos e textos: `12`, `12,5`, `12,25`.
  static String formatKm(double value) {
    var text = value.toStringAsFixed(2);
    text = text.replaceFirst(RegExp(r'\.?0+$'), '');
    return text.replaceAll('.', ',');
  }
}

/// Valores em reais.
class Brl {
  const Brl._();

  /// `80` -> `R$ 80,00`; `1234.5` -> `R$ 1.234,50`.
  static String format(double value, {bool symbol = true}) {
    final cents = (value * 100).round();
    final negative = cents < 0;
    final absolute = cents.abs();
    final reais = _group((absolute ~/ 100).toString());
    final decimals = (absolute % 100).toString().padLeft(2, '0');
    return '${symbol ? 'R\$ ' : ''}${negative ? '-' : ''}$reais,$decimals';
  }

  /// Lê o texto de um campo de valor: `1.234,56` -> `1234.56`.
  /// Também entende `80.5` e `80,5` digitados sem máscara. Vazio vira `null`.
  static double? parse(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9,.]'), '');
    if (cleaned.isEmpty) return null;
    String normalized;
    if (cleaned.contains(',')) {
      normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else if (RegExp(r'^\d+\.\d{1,2}$').hasMatch(cleaned)) {
      normalized = cleaned;
    } else {
      normalized = cleaned.replaceAll('.', '');
    }
    return double.tryParse(normalized);
  }

  static String _group(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

String _onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

bool _isDigit(int codeUnit) => codeUnit >= 0x30 && codeUnit <= 0x39;

int _digitsBefore(String text, int offset) {
  final end = offset.clamp(0, text.length);
  var count = 0;
  for (var i = 0; i < end; i++) {
    if (_isDigit(text.codeUnitAt(i))) count++;
  }
  return count;
}

int _offsetAfterDigits(String formatted, int digitCount) {
  if (digitCount <= 0) return 0;
  var seen = 0;
  for (var i = 0; i < formatted.length; i++) {
    if (_isDigit(formatted.codeUnitAt(i))) {
      seen++;
      if (seen == digitCount) return i + 1;
    }
  }
  return formatted.length;
}

/// Base das máscaras numéricas com separadores fixos.
abstract class _DigitsFormatter extends TextInputFormatter {
  const _DigitsFormatter();

  int get maxDigits;

  String mask(String digits);

  /// [pasted]: o texto foi colado (várias teclas de uma vez ou com `+`), e não
  /// digitado tecla a tecla.
  String normalize(String digits, {bool pasted = false}) => digits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = _onlyDigits(newValue.text);
    final cursor = newValue.selection.isValid
        ? newValue.selection.extentOffset
        : newValue.text.length;
    var cursorDigits = _digitsBefore(newValue.text, cursor);

    // Apagou só um separador: apaga o número anterior.
    if (newValue.text.length < oldValue.text.length &&
        digits == _onlyDigits(oldValue.text) &&
        cursorDigits > 0) {
      digits =
          digits.substring(0, cursorDigits - 1) +
          digits.substring(cursorDigits);
      cursorDigits -= 1;
    }

    final pasted =
        newValue.text.contains('+') ||
        newValue.text.length - oldValue.text.length > 1;
    final before = digits.length;
    digits = normalize(digits, pasted: pasted);
    cursorDigits = math.max(0, cursorDigits - (before - digits.length));
    if (digits.length > maxDigits) digits = digits.substring(0, maxDigits);
    cursorDigits = math.min(cursorDigits, digits.length);

    final text = mask(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: _offsetAfterDigits(text, cursorDigits),
      ),
    );
  }
}

/// `000.000.000-00`
class _CpfFormatter extends _DigitsFormatter {
  const _CpfFormatter();

  @override
  int get maxDigits => 11;

  @override
  String mask(String digits) => _mask(digits);

  static String _mask(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

/// `00.000.000/0000-00`
class _CnpjFormatter extends _DigitsFormatter {
  const _CnpjFormatter();

  @override
  int get maxDigits => 14;

  @override
  String mask(String digits) => _mask(digits);

  static String _mask(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('/');
      if (i == 12) buffer.write('-');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

/// CPF até 11 números; a partir do 12º vira CNPJ.
class _CpfOrCnpjFormatter extends _DigitsFormatter {
  const _CpfOrCnpjFormatter();

  @override
  int get maxDigits => 14;

  @override
  String mask(String digits) => digits.length <= 11
      ? _CpfFormatter._mask(digits)
      : _CnpjFormatter._mask(digits);
}

/// `(00) 0000-0000` e `(00) 00000-0000`
class _PhoneFormatter extends _DigitsFormatter {
  const _PhoneFormatter();

  @override
  int get maxDigits => 11;

  // Colar "+55 31 91234-5678" mantém só DDD e número. Só vale para texto colado:
  // digitar o 12º número de um telefone com DDD 55 (RS) não pode apagar o DDD.
  @override
  String normalize(String digits, {bool pasted = false}) =>
      pasted ? _normalize(digits) : digits;

  static String _normalize(String digits) =>
      digits.length > 11 && digits.startsWith('55')
      ? digits.substring(2)
      : digits;

  @override
  String mask(String digits) => _mask(digits);

  static String _mask(String digits) {
    if (digits.isEmpty) return '';
    final buffer = StringBuffer('(')
      ..write(digits.substring(0, math.min(2, digits.length)));
    if (digits.length < 3) return buffer.toString();
    buffer.write(') ');
    final rest = digits.substring(2);
    final split = digits.length > 10 ? 5 : 4;
    if (rest.length <= split) {
      buffer.write(rest);
    } else {
      buffer
        ..write(rest.substring(0, split))
        ..write('-')
        ..write(rest.substring(split));
    }
    return buffer.toString();
  }
}

/// Valor em reais digitado da direita para a esquerda: `1` -> `0,01`,
/// `150` -> `1,50`, `123456` -> `1.234,56`. Use com `prefixText: 'R\$ '`.
class CurrencyInputFormatter extends TextInputFormatter {
  const CurrencyInputFormatter();

  static const _maxDigits = 9;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = _onlyDigits(newValue.text).replaceFirst(RegExp(r'^0+'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    if (digits.length > _maxDigits) digits = digits.substring(0, _maxDigits);
    final padded = digits.padLeft(3, '0');
    final reais = Brl._group(padded.substring(0, padded.length - 2));
    final text = '$reais,${padded.substring(padded.length - 2)}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Número decimal com vírgula (ex.: km). Aceita `.` ou `,` e converte para
/// vírgula; limita as casas inteiras e decimais.
class DecimalInputFormatter extends TextInputFormatter {
  const DecimalInputFormatter({
    this.maxIntegerDigits = 4,
    this.maxDecimals = 2,
  });

  final int maxIntegerDigits;
  final int maxDecimals;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final buffer = StringBuffer();
    var separator = false;
    var integerDigits = 0;
    var decimalDigits = 0;
    for (final unit in newValue.text.codeUnits) {
      if (_isDigit(unit)) {
        if (!separator) {
          if (integerDigits >= maxIntegerDigits) continue;
          integerDigits++;
        } else {
          if (decimalDigits >= maxDecimals) continue;
          decimalDigits++;
        }
        buffer.writeCharCode(unit);
      } else if ((unit == 0x2C || unit == 0x2E) &&
          !separator &&
          integerDigits > 0 &&
          maxDecimals > 0) {
        separator = true;
        buffer.write(',');
      }
    }
    final text = buffer.toString();
    final offset = newValue.selection.isValid
        ? math.min(newValue.selection.extentOffset, text.length)
        : text.length;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
