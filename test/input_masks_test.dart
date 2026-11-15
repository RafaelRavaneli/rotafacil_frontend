import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotafacil/utils/input_masks.dart';

String typed(TextInputFormatter formatter, String text) => formatter
    .formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    )
    .text;

void main() {
  group('CPF e CNPJ', () {
    test('CPF recebe pontos e traço enquanto digita', () {
      expect(typed(InputMasks.cpf, '1234'), '123.4');
      expect(typed(InputMasks.cpf, '12345678909'), '123.456.789-09');
      expect(typed(InputMasks.cpf, '123.456.789-09'), '123.456.789-09');
    });

    test('CPF ignora letras e números além de 11', () {
      expect(typed(InputMasks.cpf, '12a3456789012'), '123.456.789-01');
    });

    test('CNPJ recebe pontos, barra e traço', () {
      expect(typed(InputMasks.cnpj, '12345678000190'), '12.345.678/0001-90');
      expect(typed(InputMasks.cnpj, '12345'), '12.345');
    });

    test('máscara dinâmica troca de CPF para CNPJ no 12º número', () {
      expect(typed(InputMasks.cpfOrCnpj, '12345678909'), '123.456.789-09');
      expect(typed(InputMasks.cpfOrCnpj, '123456789012'), '12.345.678/9012');
    });

    test('máscara do documento segue o perfil', () {
      expect(typed(InputMasks.documentForRole('Guia'), '12345678909'),
          '123.456.789-09');
      expect(typed(InputMasks.documentForRole('Agência'), '12345678000190'),
          '12.345.678/0001-90');
    });

    test('apagar um separador apaga o número anterior', () {
      final result = InputMasks.cpf.formatEditUpdate(
        const TextEditingValue(
          text: '123.4',
          selection: TextSelection.collapsed(offset: 5),
        ),
        const TextEditingValue(
          text: '1234',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      expect(result.text, '124');
    });

    test('formata valores já salvos', () {
      expect(InputMasks.formatCpf('52998224725'), '529.982.247-25');
      expect(InputMasks.formatCnpj('11222333000181'), '11.222.333/0001-81');
    });
  });

  group('Telefone', () {
    test('fixo e celular', () {
      expect(typed(InputMasks.phone, '3'), '(3');
      expect(typed(InputMasks.phone, '31'), '(31');
      expect(typed(InputMasks.phone, '319'), '(31) 9');
      expect(typed(InputMasks.phone, '3133334444'), '(31) 3333-4444');
      expect(typed(InputMasks.phone, '31912345678'), '(31) 91234-5678');
    });

    test('colar com +55 mantém só DDD e número', () {
      expect(typed(InputMasks.phone, '+55 31 91234-5678'), '(31) 91234-5678');
    });

    test('formata valores já salvos', () {
      expect(InputMasks.formatPhone('31912345678'), '(31) 91234-5678');
      expect(InputMasks.formatPhone('(44) 3333-4444'), '(44) 3333-4444');
      expect(InputMasks.formatPhone(''), '');
    });
  });

  group('Valor em reais', () {
    test('máscara preenche da direita para a esquerda', () {
      expect(typed(InputMasks.currency, '1'), '0,01');
      expect(typed(InputMasks.currency, '150'), '1,50');
      expect(typed(InputMasks.currency, '123456'), '1.234,56');
      expect(typed(InputMasks.currency, '0,015'), '0,15');
      expect(typed(InputMasks.currency, '0'), '');
      expect(typed(InputMasks.currency, ''), '');
    });

    test('Brl.format', () {
      expect(Brl.format(80), 'R\$ 80,00');
      expect(Brl.format(1234.5), 'R\$ 1.234,50');
      expect(Brl.format(0), 'R\$ 0,00');
      expect(Brl.format(45, symbol: false), '45,00');
    });

    test('Brl.parse entende o campo e valores digitados sem máscara', () {
      expect(Brl.parse('1.234,56'), 1234.56);
      expect(Brl.parse('80,5'), 80.5);
      expect(Brl.parse('80.5'), 80.5);
      expect(Brl.parse('1.234'), 1234);
      expect(Brl.parse(''), isNull);
    });
  });

  group('Distância em km', () {
    test('aceita ponto ou vírgula e limita as casas', () {
      expect(typed(InputMasks.km, '12.5'), '12,5');
      expect(typed(InputMasks.km, '12,345'), '12,34');
      expect(typed(InputMasks.km, ',5'), '5');
      expect(typed(InputMasks.km, 'abc'), '');
      expect(typed(InputMasks.km, '12345'), '1234');
    });

    test('formatKm remove zeros desnecessários', () {
      expect(InputMasks.formatKm(12), '12');
      expect(InputMasks.formatKm(12.5), '12,5');
      expect(InputMasks.formatKm(12.25), '12,25');
      expect(InputMasks.formatKm(100), '100');
    });
  });
}
