import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rotafacil/services/session_service.dart';
import 'package:rotafacil/widgets/app_back_button.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionService.instance.clear();
  });

  for (final entry in {
    'usuario': '/explorar',
    'guia': '/painel',
    'agencia': '/painel',
  }.entries) {
    testWidgets(
      'Voltar sem histórico usa página inicial do perfil ${entry.key}',
      (tester) async {
        await SessionService.instance.save(
          selectedRole: entry.key,
          userEmail: 'teste@example.test',
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(appBar: AppBar(leading: const AppBackButton())),
            routes: {
              entry.value: (_) => const Scaffold(body: Text('Destino correto')),
            },
          ),
        );
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('Destino correto'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'Voltar compartilhado respeita bloqueio de saída sem redirecionar',
    (tester) async {
      var attempted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              attempted = !didPop;
            },
            child: Scaffold(
              appBar: AppBar(
                leading: const AppBackButton(fallbackLocation: '/perfil'),
              ),
            ),
          ),
          routes: {
            '/perfil': (_) => const Scaffold(body: Text('Não deve abrir')),
          },
        ),
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(attempted, isTrue);
      expect(find.text('Não deve abrir'), findsNothing);
    },
  );
}
