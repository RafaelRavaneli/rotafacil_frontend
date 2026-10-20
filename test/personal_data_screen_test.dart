import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rotafacil/pages/common/settings/personal_data_screen.dart';
import 'package:rotafacil/state/app_store.dart';
import 'package:rotafacil/config/app_config.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppStore.instance.initialize();
  });

  testWidgets('Guia existente informa Cadastur no perfil', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const PersonalDataScreen(role: 'Guia'),
        routes: {'/perfil': (_) => const Scaffold(body: Text('Perfil'))},
      ),
    );
    final number = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Número do Cadastur',
    );
    await tester.scrollUntilVisible(
      number,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(number, '12.345.678/0001-90');
    await tester.scrollUntilVisible(
      find.text('Salvar alterações'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();
    expect(AppStore.instance.guide.cadasturNumber, '12345678000190');
    expect(find.text('Perfil'), findsOneWidget);
  }, skip: AppConfig.useBackend);

  testWidgets('avisa antes de descartar edição de perfil', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PersonalDataScreen(role: 'Turista'),
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Nome alterado');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Descartar alterações?'), findsOneWidget);
    await tester.tap(find.text('Continuar editando'));
    await tester.pumpAndSettle();
    expect(find.byType(PersonalDataScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.byType(PersonalDataScreen), findsNothing);
  });
}
