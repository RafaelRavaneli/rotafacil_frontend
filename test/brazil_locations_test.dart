import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotafacil/services/brazil_locations.dart';
import 'package:rotafacil/widgets/brazil_location_fields.dart';
import 'package:rotafacil/widgets/auth_scaffold.dart';
import 'package:rotafacil/theme/app_theme.dart';
import 'package:rotafacil/theme/app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'official catalog contains all states and matches full state names',
    () async {
      final states = await BrazilLocations.load();
      expect(states.length, 27);
      expect(states.map((s) => s.uf).toSet().length, 27);
      final parana = BrazilLocations.findState(states, 'Paraná')!;
      expect(parana.uf, 'PR');
      expect(parana.cities, contains('Maringá'));
      expect(parana.cities, isNot(contains('Campinas')));
      expect(BrazilLocations.normalize('São Paulo'), 'sao paulo');
    },
  );

  testWidgets(
    'changing state clears city and search selects official municipality',
    (tester) async {
      final states = await tester.runAsync(BrazilLocations.load);
      expect(states, isNotEmpty);
      final city = TextEditingController(text: 'Maringá');
      final state = TextEditingController(text: 'PR');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrazilLocationFields(city: city, state: state),
          ),
        ),
      );
      expect(
        tester
            .widgetList<TextField>(find.byType(TextField))
            .every((f) => f.readOnly),
        isTrue,
      );
      await tester.runAsync(() => tester.tap(find.byType(TextField).first));
      await tester.pumpAndSettle();
      expect(find.text('Selecionar estado'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'sao paulo');
      await tester.pumpAndSettle();
      await tester.runAsync(() => tester.tap(find.text('SP — São Paulo')));
      await tester.pumpAndSettle();
      expect(state.text, 'SP');
      expect(city.text, isEmpty);
      await tester.runAsync(() => tester.tap(find.byType(TextField).at(1)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'campinas');
      await tester.pumpAndSettle();
      await tester.runAsync(() => tester.tap(find.text('Campinas')));
      await tester.pumpAndSettle();
      expect(city.text, 'Campinas');
      await tester.pumpWidget(const SizedBox());
      city.dispose();
      state.dispose();
    },
  );

  testWidgets(
    'Busca no cadastro mantém contraste e fecha teclado e seletor após escolher cidade',
    (tester) async {
      await tester.runAsync(BrazilLocations.load);
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final city = TextEditingController();
      final state = TextEditingController(text: 'PR');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AuthScaffold(
            title: 'Cadastro',
            body: BrazilLocationFields(
              city: city,
              state: state,
              labelsAbove: true,
            ),
          ),
        ),
      );
      await tester.runAsync(() => tester.tap(find.byType(TextField).at(1)));
      await tester.pumpAndSettle();
      final search = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Buscar',
      );
      expect(tester.widget<TextField>(search).style!.color, AppColors.ink);
      await tester.enterText(search, 'maringa');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(find.text('Maringá'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.runAsync(() => tester.tap(find.text('Maringá')));
      await tester.pumpAndSettle();
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(city.text, 'Maringá');
      expect(find.text('Selecionar cidade'), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.testTextInput.isVisible, isFalse);
      expect(
        tester
            .widgetList<EditableText>(find.byType(EditableText))
            .any((field) => field.focusNode.hasFocus),
        isFalse,
      );
      expect(tester.takeException(), isNull);
      await tester.runAsync(() => tester.tap(find.byType(TextField).first));
      await tester.pumpAndSettle();
      final stateSearch = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Buscar',
      );
      expect(tester.widget<TextField>(stateSearch).style!.color, AppColors.ink);
      await tester.enterText(stateSearch, 'parana');
      await tester.pumpAndSettle();
      expect(find.text('PR — Paraná'), findsOneWidget);
      await tester.runAsync(() => tester.tap(find.byTooltip('Fechar')));
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isFalse);
      await tester.pumpWidget(const SizedBox());
      city.dispose();
      state.dispose();
    },
  );
}
