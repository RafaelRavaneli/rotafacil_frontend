import 'package:flutter_test/flutter_test.dart';
import 'package:rotafacil/utils/date_time_format.dart';

void main() {
  test('Formata datas ISO e brasileiras sem alterar valores inválidos', () {
    expect(formatBrazilianDate('2026-10-24'), '24/10/2026');
    expect(formatBrazilianDate('24/10/2026'), '24/10/2026');
    expect(formatBrazilianDate('Data a combinar'), 'Data a combinar');
  });

  test('Formata data e hora em padrão brasileiro de 24 horas', () {
    expect(
      formatBrazilianDateTime(DateTime(2026, 10, 24, 18, 5)),
      '24/10/2026 às 18:05',
    );
  });
}
