import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotafacil/services/legal_documents.dart';
import 'package:rotafacil/pages/common/legal_document_screen.dart';
import 'package:rotafacil/app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rotafacil/config/app_config.dart';
import 'package:rotafacil/models/user_role.dart';
import 'package:rotafacil/services/api_client.dart';
import 'package:rotafacil/services/auth_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Cadastro sem aceite não envia dados à API', () async {
    var calls = 0;
    final gateway = AuthGateway(
      api: ApiClient(
        client: MockClient((_) async {
          calls++;
          return http.Response('{}', 201);
        }),
      ),
    );
    await expectLater(
      gateway.register(
        role: UserRole.tourist,
        name: 'Pessoa',
        email: 'pessoa@example.test',
        password: 'senha123',
      ),
      throwsStateError,
    );
    expect(calls, 0);
  });

  test('Cadastro envia aceite e versões exibidas para a API', () async {
    Map<String, dynamic>? body;
    final gateway = AuthGateway(
      api: ApiClient(
        client: MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{"id":"u1"}', 201);
        }),
      ),
    );
    await gateway.register(
      role: UserRole.tourist,
      name: 'Pessoa',
      email: 'pessoa@example.test',
      password: 'senha123',
      acceptedLegal: true,
    );
    final expected = await LegalDocuments.acceptance();
    for (final entry in expected.entries) {
      expect(body![entry.key], entry.value);
    }
    expect(body!.containsKey('registrado_em'), isFalse);
  }, skip: !AppConfig.useBackend);

  test(
    'Aceite usa versões e hashes correspondentes ao documento exibido',
    () async {
      final documents = await LegalDocuments.load();
      expect(
        (await LegalDocuments.acceptance())['termos_versao'],
        documents['termos']['version'],
      );
      for (final document in documents.values) {
        final content = Map<String, dynamic>.from(document as Map);
        final hash = content.remove('sha256');
        final sorted = Map.fromEntries(
          content.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
        );
        expect(
          sha256.convert(utf8.encode(jsonEncode(sorted))).toString(),
          hash,
        );
      }
    },
  );

  testWidgets('Documento público permite leitura sem conta', (tester) async {
    await tester.runAsync(LegalDocuments.load);
    await tester.pumpWidget(
      const MaterialApp(home: LegalDocumentScreen(documentKey: 'privacidade')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Responsável e contato'), findsOneWidget);
    expect(find.textContaining('Rafael Ravaneli Schiavon'), findsOneWidget);
    expect(find.text('Registrar aceite na minha conta'), findsNothing);
  });

  for (final path in ['/termos', '/privacidade']) {
    testWidgets('URL pública $path abre sem sessão', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(LegalDocuments.load);
      tester.binding.platformDispatcher.defaultRouteNameTestValue = path;
      addTearDown(
        tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
      );
      await tester.pumpWidget(const RotaFacilApp());
      await tester.pumpAndSettle();
      expect(find.byType(LegalDocumentScreen), findsOneWidget);
      expect(find.text('Registrar aceite na minha conta'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
