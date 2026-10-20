import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rotafacil/pages/auth/verify_email_screen.dart';
import 'package:rotafacil/services/api_client.dart';
import 'package:rotafacil/services/auth_gateway.dart';

void main() {
  test(
    'Erro de e-mail não confirmado preserva código sem expor token',
    () async {
      final api = ApiClient(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'erro': 'Confirme seu e-mail antes de entrar.',
              'codigo': 'EMAIL_NAO_CONFIRMADO',
            }),
            403,
          ),
        ),
      );
      await expectLater(
        api.post('/api/auth/login', auth: false),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'EMAIL_NAO_CONFIRMADO',
          ),
        ),
      );
    },
  );

  testWidgets(
    'Confirmação envia código por e-mail e retorna sucesso ao fluxo anterior',
    (tester) async {
      final calls = <String>[];
      final gateway = AuthGateway(
        api: ApiClient(
          client: MockClient((request) async {
            calls.add(request.url.path);
            final body = jsonDecode(request.body);
            expect(body['email'], 'ana@example.test');
            expect(request.headers['Authorization'], isNull);
            if (request.url.path.endsWith('/confirmar')) {
              expect(body['token'], 'codigo-recebido-pelo-email');
            }
            return http.Response('{}', 200);
          }),
        ),
      );
      bool? verified;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  verified = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VerifyEmailScreen(
                        initialEmail: ' ANA@example.test ',
                        gateway: gateway,
                      ),
                    ),
                  );
                },
                child: const Text('Abrir confirmação'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir confirmação'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Enviar código'));
      await tester.tap(find.text('Enviar código'));
      await tester.pumpAndSettle();
      expect(find.text('Reenviar código'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField).at(1),
        'codigo-recebido-pelo-email',
      );
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Confirmar e-mail'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar e-mail'));
      await tester.pumpAndSettle();
      expect(verified, isTrue);
      expect(calls, ['/api/auth/email/solicitar', '/api/auth/email/confirmar']);
    },
  );

  testWidgets('Falha de envio mantém dados e permite nova tentativa', (
    tester,
  ) async {
    var calls = 0;
    final gateway = AuthGateway(
      api: ApiClient(
        client: MockClient((_) async {
          calls++;
          return http.Response(
            calls == 1 ? '{"erro":"Envio indisponível"}' : '{}',
            calls == 1 ? 503 : 200,
              headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: VerifyEmailScreen(
          initialEmail: 'ana@example.test',
          gateway: gateway,
        ),
      ),
    );
    await tester.ensureVisible(find.text('Enviar código'));
    await tester.tap(find.text('Enviar código'));
    await tester.pumpAndSettle();
    expect(find.text('Envio indisponível'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'ana@example.test',
    );
    await tester.tap(find.text('Enviar código'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Reenviar código'), findsOneWidget);
  });
}
