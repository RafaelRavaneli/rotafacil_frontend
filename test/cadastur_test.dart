import 'package:flutter_test/flutter_test.dart';
import 'package:rotafacil/models/app_user.dart';
import 'package:rotafacil/utils/cadastur_validator.dart';
import 'package:rotafacil/services/auth_gateway.dart';
import 'package:rotafacil/models/user_role.dart';

void main() {
  test('Cadastro não envia guia ou agência sem Cadastur', () async {
    for (final role in [UserRole.guide, UserRole.agency]) {
      await expectLater(
        AuthGateway.instance.register(
          role: role,
          name: 'Pessoa',
          email: 'pessoa@example.test',
          password: 'senha123',
        ),
        throwsA(isA<StateError>()),
      );
    }
  });
  test('Cadastur valida preenchimento e normaliza certificado', () {
    expect(CadasturValidator.error(''), isNotNull);
    expect(CadasturValidator.error('abc'), isNotNull);
    expect(CadasturValidator.error('1' * 41), isNotNull);
    expect(CadasturValidator.error('12.345.678/0001-90'), isNull);
    expect(CadasturValidator.normalize('12.345.678/0001-90'), '12345678000190');
  });

  test('Perfil mantém Cadastur ao salvar localmente e aceita conta legada', () {
    final user = AppUser.fromJson({
      'nome': 'Guia',
      'tipo': 'guia',
      'cadastur_numero': '123456789',
      'cadastur_validade': '2099-12-31',
    });
    final saved = AppUser.fromJson(user.toJson());
    expect(saved.cadasturNumber, '123456789');
    expect(saved.cadasturValidUntil, '2099-12-31');
    expect(AppUser.fromJson({'tipo': 'guia'}).cadasturNumber, isEmpty);
  });
}
