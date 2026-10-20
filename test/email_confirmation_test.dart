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

  testWidgets('Confirmação solicita link sem campo de código', (tester) async {
    final gateway = AuthGateway(
      api: ApiClient(
        client: MockClient((request) async {
          expect(request.url.path, '/api/auth/email/solicitar');
          expect(jsonDecode(request.body)['email'], 'ana@example.test');
          return http.Response('{}', 200);
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
    await tester.ensureVisible(find.text('Enviar link'));
    await tester.tap(find.text('Enviar link'));
    await tester.pumpAndSettle();
    expect(find.text('Reenviar link'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('Abra o e-mail'), findsOneWidget);
  });

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
    await tester.ensureVisible(find.text('Enviar link'));
    await tester.tap(find.text('Enviar link'));
    await tester.pumpAndSettle();
    expect(find.text('Envio indisponível'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'ana@example.test',
    );
    await tester.tap(find.text('Enviar link'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Reenviar link'), findsOneWidget);
  });
}
