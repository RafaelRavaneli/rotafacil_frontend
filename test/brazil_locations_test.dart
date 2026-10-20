import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotafacil/services/brazil_locations.dart';
import 'package:rotafacil/widgets/brazil_location_fields.dart';

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
      await tester.runAsync(() => tester.tap(find.byType(TextField).at(1)));
      await tester.pumpAndSettle();
      expect(find.text('Selecionar estado'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'sao paulo');
      await tester.pumpAndSettle();
      await tester.runAsync(() => tester.tap(find.text('SP — São Paulo')));
      await tester.pumpAndSettle();
      expect(state.text, 'SP');
      expect(city.text, isEmpty);
      await tester.runAsync(() => tester.tap(find.byType(TextField).first));
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
}
